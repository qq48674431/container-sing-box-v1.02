# RouterOS 一键下载容器镜像（仅下载 tar，不建网、不建容器）
# https://github.com/qq48674431/container-sing-box-v1.02
# 用法：/import file-name=ros-download.rsc
# 或终端直接执行下面 fetch 那一行

:local tarUrl "https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/May.container1.02.tar"
:local tarFile "May.container1.02.tar"

:if ([:len [/file/find where name=$tarFile]] > 0) do={
    :put ">>> $tarFile 已存在，跳过下载"
} else={
    :put ">>> 正在下载 $tarFile ..."
    /tool/fetch url=$tarUrl dst-path=$tarFile
    :put ">>> 下载完成"
}

:put ""
:put "=== 下载完成，请手动创建并启动容器，例如： ==="
:put "/container/config set tmpdir=disk1/tmp"
:put "/container add file=May.container1.02.tar interface=proxy logging=yes name=May.container root-dir=/root start-on-boot=yes workdir=/"
:put "/container start [find where name=May.container]"
:put "面板: http://192.168.101.2:8080"
