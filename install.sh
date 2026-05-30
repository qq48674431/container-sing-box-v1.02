#!/usr/bin/env bash
set -euo pipefail

# ============================================================
#  container-sing-box-v1.02 一键拉取脚本（Linux）
#  用法: bash <(curl -sL https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/install.sh)
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

WORK_DIR="/opt/container-sing-box-v1.02"
BASE_URL="https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

dl() {
    local file="$1"
    info "下载 ${file}..."
    curl -fSL --retry 3 "${BASE_URL}/${file}" -o "${WORK_DIR}/${file}" || error "下载 ${file} 失败"
}

dl config.json
dl index.html
dl proxy-parser.js
dl install.rsc
dl May.container1.02.tar

mkdir -p "${WORK_DIR}/pages" "${WORK_DIR}/assets/vendor"
dl pages/pc.js
dl pages/vpn.js
dl pages/wifi.js
dl assets/vendor/vue.global.js
dl assets/vendor/tailwindcss.js

TAR_SIZE=$(wc -c < "${WORK_DIR}/May.container1.02.tar" 2>/dev/null || echo 0)
[[ "$TAR_SIZE" -lt 1048576 ]] && error "May.container1.02.tar 文件异常，请重试"

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  拉取完成！${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo -e "  本地目录: ${YELLOW}${WORK_DIR}${NC}"
echo -e "  ROS 安装脚本: ${YELLOW}${WORK_DIR}/install.rsc${NC}"
echo -e "  容器镜像: ${YELLOW}${WORK_DIR}/May.container1.02.tar${NC}"
echo ""
echo "  可在 RouterOS 中执行："
echo "  /tool/fetch url=\"${BASE_URL}/install.rsc\" dst-path=install.rsc"
echo "  /import file-name=install.rsc"
echo ""
