#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  container-sing-box-v1.02 Linux 一键安装
#  下载到 /root 并直接启动 app（不用容器、不用 tar）
#  用法: bash <(curl -sL https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/install.sh)
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

WORK_DIR="/root"
BASE_URL="https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main"
SERVICE_NAME="sing-box-panel"
PANEL_PORT="8080"

if [[ "${EUID}" -ne 0 ]]; then
    error "请用 root 运行：sudo bash <(curl -sL ${BASE_URL}/install.sh)"
fi

command -v curl >/dev/null 2>&1 || error "未找到 curl，请先安装：apt install -y curl 或 yum install -y curl"

mkdir -p "${WORK_DIR}/pages" "${WORK_DIR}/assets/vendor"
cd "${WORK_DIR}"

dl() {
    local file="$1"
    info "下载 ${file} -> ${WORK_DIR}/${file}"
    curl -fSL --retry 3 "${BASE_URL}/${file}" -o "${WORK_DIR}/${file}" || error "下载 ${file} 失败"
}

info "开始下载运行所需文件到 ${WORK_DIR} ..."

# 五类文件：app + config + 前端(index/proxy-parser) + pages + assets
dl app
dl config.json
dl index.html
dl proxy-parser.js
dl pages/pc.js
dl pages/vpn.js
dl pages/wifi.js
dl assets/vendor/vue.global.js
dl assets/vendor/tailwindcss.js

chmod +x "${WORK_DIR}/app"

APP_SIZE=$(wc -c < "${WORK_DIR}/app" 2>/dev/null || echo 0)
[[ "${APP_SIZE}" -lt 1048576 ]] && error "app 文件异常（大小 ${APP_SIZE}），请重试"

# config.json 使用 tun 入站
if [[ ! -c /dev/net/tun ]]; then
    info "创建 /dev/net/tun ..."
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200 2>/dev/null || true
fi
modprobe tun 2>/dev/null || true

# 若已有旧进程，先停掉
pkill -f "^${WORK_DIR}/app$" 2>/dev/null || pkill -f "${WORK_DIR}/app" 2>/dev/null || true
sleep 1

info "在 ${WORK_DIR} 启动 ./app ..."

if command -v systemctl >/dev/null 2>&1; then
    cat > "/etc/systemd/system/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=sing-box panel (container-sing-box-v1.02)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=${WORK_DIR}
ExecStart=${WORK_DIR}/app
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable "${SERVICE_NAME}" >/dev/null 2>&1 || true
    systemctl restart "${SERVICE_NAME}"
    sleep 2
    if systemctl is-active --quiet "${SERVICE_NAME}"; then
        RUN_MODE="systemd 已启动（开机自启）"
    else
        warn "systemd 启动异常，改用 nohup"
        nohup "${WORK_DIR}/app" >"${WORK_DIR}/app.log" 2>&1 &
        RUN_MODE="nohup 后台（日志 ${WORK_DIR}/app.log）"
    fi
else
    nohup "${WORK_DIR}/app" >"${WORK_DIR}/app.log" 2>&1 &
    sleep 2
    RUN_MODE="nohup 后台（日志 ${WORK_DIR}/app.log）"
fi

IP_ADDR=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
[[ -z "${IP_ADDR}" ]] && IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
[[ -z "${IP_ADDR}" ]] && IP_ADDR="<本机IP>"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  安装完成，app 已在 /root 运行${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "  目录: ${YELLOW}${WORK_DIR}${NC}"
echo -e "  文件: app, config.json, index.html, proxy-parser.js, pages/, assets/"
echo -e "  面板: ${YELLOW}http://${IP_ADDR}:${PANEL_PORT}${NC}"
echo ""
echo "  手动启动（如需）："
echo "    cd /root && ./app"
echo ""
if command -v systemctl >/dev/null 2>&1; then
    echo "  服务管理："
    echo "    systemctl status ${SERVICE_NAME}"
    echo "    systemctl restart ${SERVICE_NAME}"
    echo "    journalctl -u ${SERVICE_NAME} -f"
    echo ""
fi
