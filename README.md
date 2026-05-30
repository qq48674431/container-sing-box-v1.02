# container-sing-box-v1.02

基于 sing-box 的容器方案，提供 RouterOS 一键导入脚本与容器镜像文件。

## 文件说明

- `May.container1.02.tar`: RouterOS 容器镜像
- `install.rsc`: RouterOS 一键安装脚本
- `install.sh`: Linux 一键拉取脚本（用于快速下载完整安装包）
- `config.json`: sing-box 配置
- `index.html`: Web 管理面板前端
- `proxy-parser.js`: 代理链接解析库
- `pages/`: 前端页面拆分文件
- `assets/vendor/`: 前端依赖

## Linux 一键拉取

在 Linux 机器执行：

```bash
bash <(curl -sL https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/install.sh)
```

执行后会将所需文件下载到：

`/opt/container-sing-box-v1.02`

## RouterOS 一键拉取

前提：

- RouterOS 7.4+
- x86_64 架构
- 已安装 `container` 包
- 已启用 `container` 设备模式（`/system/device-mode/update container=yes`）

在 RouterOS Terminal 执行：

```routeros
/tool/fetch url="https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/install.rsc" dst-path=install.rsc
/import file-name=install.rsc
```

`install.rsc` 默认拉取镜像文件：

`May.container1.02.tar`

安装完成后默认访问：

<!-- CHECKPOINT id="ckpt_mps4lec5_uaqiuq" time="2026-05-30T09:05:38.261Z" note="auto" fixes=0 questions=0 highlights=0 sections="" -->
