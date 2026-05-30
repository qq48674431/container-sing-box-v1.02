# Sing-box MikroTik Container v1.02 一键安装脚本
# https://github.com/qq48674431/container-sing-box-v1.02

:local tarUrl "https://raw.githubusercontent.com/qq48674431/container-sing-box-v1.02/main/May.container1.02.tar"
:local tarFile "May.container1.02.tar"
:local subnetPrefix "192.168.101."
:local bridgeName "sing-box"
:local vethName "veth-Linux"
:local vethAddr "192.168.101.2/24"
:local gwAddr "192.168.101.1"
:local gwCidr "192.168.101.1/24"
:local subnet "192.168.101.0/24"
:local containerName "singbox"

:put ">>> [1/5] 检查容器设备模式..."
:local devMode [/system/device-mode/get container]
:if ($devMode != true) do={
    :put "!!! 容器模式未启用，请先执行:"
    :put "/system/device-mode/update container=yes"
    :put "然后在 5 分钟内冷重启（拔电源 -> 等 5 秒 -> 插电源）"
    :error "container mode not enabled"
}
:put "    container: yes"

:put ">>> [2/5] 配置容器网络..."
# 优先复用已有的、地址在 192.168.101.x 网段的 veth（兼容已手动配置的环境）
:local existVeth ""
:foreach v in=[/interface/veth/find] do={
    :local a [/interface/veth/get $v address]
    :if ([:find $a $subnetPrefix] >= 0) do={
        :set existVeth [/interface/veth/get $v name]
    }
}

:if ($existVeth != "") do={
    :set vethName $existVeth
    :put "    检测到已有 veth: $vethName，复用现有网络，跳过创建"
} else={
    :if ([:len [/interface/bridge/find where name=$bridgeName]] = 0) do={
        /interface/bridge/add name=$bridgeName
        :put "    创建 bridge: $bridgeName"
    } else={
        :put "    bridge $bridgeName 已存在，跳过"
    }

    :if ([:len [/ip/address/find where interface=$bridgeName]] = 0) do={
        /ip/address/add address=$gwCidr interface=$bridgeName
        :put "    分配 IP: $gwCidr -> $bridgeName"
    } else={
        :put "    $bridgeName IP 已配置，跳过"
    }

    :if ([:len [/interface/veth/find where name=$vethName]] = 0) do={
        /interface/veth/add name=$vethName address=$vethAddr gateway=$gwAddr
        :put "    创建 veth: $vethName ($vethAddr)"
    } else={
        :put "    veth $vethName 已存在，跳过"
    }

    :if ([:len [/interface/bridge/port/find where interface=$vethName]] = 0) do={
        /interface/bridge/port/add bridge=$bridgeName interface=$vethName
        :put "    veth 加入 bridge"
    } else={
        :put "    bridge port 已存在，跳过"
    }

    :if ([:len [/ip/firewall/nat/find where chain=srcnat action=masquerade src-address=$subnet]] = 0) do={
        /ip/firewall/nat/add chain=srcnat action=masquerade src-address=$subnet comment="singbox-container-v102"
        :put "    添加 NAT 规则"
    } else={
        :put "    NAT 规则已存在，跳过"
    }
}

:put ">>> [3/5] 设置容器仓库..."
/container/config/set tmpdir=disk1/tmp

:put ">>> [4/5] 下载容器镜像..."
:if ([:len [/file/find where name=$tarFile]] = 0) do={
    :put "    正在从 GitHub 下载 $tarFile ..."
    /tool/fetch url=$tarUrl dst-path=$tarFile
    :put "    下载完成"
} else={
    :put "    $tarFile 已存在，跳过下载"
}

:put ">>> [5/5] 创建并启动容器..."
:if ([:len [/container/find where name=$containerName]] = 0) do={
    /container/add file=$tarFile interface=$vethName logging=yes \
        name=$containerName root-dir=/root start-on-boot=yes workdir=/
    :put "    容器挂载接口: $vethName"
    :put "    等待镜像解压..."
    :delay 8s
    /container/start $containerName
    :put "    容器已启动"
} else={
    :put "    容器 $containerName 已存在，跳过创建"
    :local status [/container/get [find where name=$containerName] status]
    :if ($status = "stopped") do={
        /container/start $containerName
        :put "    容器已启动"
    }
}

:delay 3s
:put ""
:put "=== 安装完成 ==="
:put "容器状态:"
/container/print where name=$containerName
:put ""
:put "Web 管理面板: http://192.168.101.2:8080"
