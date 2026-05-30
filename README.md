# container-sing-box-v1.02

基于 sing-box 的代理管理方案：**RouterOS 跑容器**，**Linux 直接跑 `app`**。

## 文件说明

| 文件 | 用途 |
|------|------|
| `May.container1.02.tar` | RouterOS 容器镜像 |
| `ros-download.rsc` | RouterOS **仅下载** tar 镜像 |
| `install.rsc` | RouterOS **全自动**（建网 + 下载 + 建容器） |
| `install.sh` | Linux **一键部署**（下载 `app` 等并启动服务） |
| `app` | Linux x86-64 主程序 |
| `config.json` | sing-box 配置 |
| `index.html` / `pages/` / `assets/` / `proxy-parser.js` | Web 管理面板 |

---

## 一、RouterOS：一键下载 tar

前提：RouterOS 7.4+、x86_64、已装 `container` 包，并已启用容器模式（冷重启确认）：

```routeros
/system/device-mode/update container=yes
```

### 方式 A：只下载镜像（推荐，网络自己配）

终端执行一行即可：

```routeros
/tool fetch url="https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/May.container1.02.tar" dst-path=May.container1.02.tar
```

或导入仅下载脚本：

```routeros
/tool fetch url="https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/ros-download.rsc" dst-path=ros-download.rsc
/import file-name=ros-download.rsc
```

下载完成后**手动**建容器（接口名按你实际 veth 修改，例如 `proxy`）：

```routeros
/container/config set tmpdir=disk1/tmp
/container add file=May.container1.02.tar interface=proxy logging=yes name=May.container root-dir=/root start-on-boot=yes workdir=/
/container start [find where name=May.container]
```

面板：`http://192.168.101.2:8080`

### 方式 B：全自动安装（建网 + 下载 + 容器）

```routeros
/tool fetch url="https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/install.rsc" dst-path=install.rsc
/import file-name=install.rsc
```

---

## 二、Linux：一键安装并运行

在 Linux 服务器执行（**需 root**）。脚本会把运行所需文件**全部下载到 `/root`**，并自动启动 `app`（**不下载** tar / install.rsc）：

```bash
bash <(curl -sL https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/install.sh)
```

下载到 `/root` 的内容：

| 类型 | 文件 |
|------|------|
| 主程序 | `app` |
| 配置 | `config.json` |
| 前端 | `index.html`、`proxy-parser.js` |
| 页面 | `pages/pc.js`、`pages/vpn.js`、`pages/wifi.js` |
| 依赖 | `assets/vendor/vue.global.js`、`assets/vendor/tailwindcss.js` |

- 工作目录：`/root`（`cd /root && ./app`）
- 默认面板：`http://<本机IP>:8080`
- 有 systemd 时会注册服务 `sing-box-panel`（开机自启）

常用命令：

```bash
systemctl status sing-box-panel
systemctl restart sing-box-panel
journalctl -u sing-box-panel -f
```

---

## 两种方式对比

| | RouterOS | Linux |
|--|----------|-------|
| 安装方式 | 容器 `May.container1.02.tar` | 直接运行 `app` |
| 一键命令 | `install.sh` **不适用** | `install.sh` |
| 下载位置 | RouterOS 本地文件 | 全部下载到 `/root` 并启动 |
| 面板地址 | 一般为 `192.168.101.2:8080` | `http://服务器IP:8080` |
