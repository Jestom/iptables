#!/bin/bash

IPTABLES_RULES="/etc/iptables/rules.v4"

install_iptables() {
    if ! command -v iptables &> /dev/null; then
        apt update && apt install -y iptables iptables-persistent
    fi
    if ! command -v ip6tables &> /dev/null; then
        apt install -y ip6tables
    fi
    read -p "安装完成，按回车返回首页..."
}

enable_ip_forwarding() {
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sysctl -w net.ipv4.ip_forward=1 > /dev/null
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
    sysctl -w net.ipv6.conf.all.forwarding=1 > /dev/null
    if ! grep -q "net.ipv6.conf.all.forwarding=1" /etc/sysctl.conf; then
        echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    fi
    sysctl -p > /dev/null
    read -p "IP 转发已开启，并在重启后自动生效！按回车返回首页..."
}

disable_ip_forwarding() {
    echo 0 > /proc/sys/net/ipv4/ip_forward
    sysctl -w net.ipv4.ip_forward=0 > /dev/null
    echo 0 > /proc/sys/net/ipv6/conf/all/forwarding
    sysctl -w net.ipv6.conf.all.forwarding=0 > /dev/null
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    sed -i '/net.ipv6.conf.all.forwarding/d' /etc/sysctl.conf
    sysctl -p > /dev/null
    read -p "IP 转发已关闭，系统已恢复默认。按回车返回首页..."
}

resolve_domain() {
    local DOMAIN="$1"
    local IP=""
    IP=$(getent ahosts "$DOMAIN" | grep -m1 "STREAM" | awk '{print $1}')
    echo "$IP"
}

clean_ipv6() {
    local INPUT="$1"
    echo "$INPUT" | sed 's/\[\|\]//g'
}

inner_add_forwarding() {
    read -p "本机监听 IP: " LOCAL_IP
    read -p "本机监听端口: " LOCAL_PORT
    read -p "目标服务器 IP 或域名: " TARGET_INPUT
    read -p "目标服务器端口: " TARGET_PORT

    if [[ "$TARGET_INPUT" =~ [a-zA-Z] ]]; then
        TARGET_IP=$(resolve_domain "$TARGET_INPUT")
    else
        TARGET_IP="$TARGET_INPUT"
    fi

    if [[ "$TARGET_IP" =~ : ]]; then
        # IPv6
        CLEANED_IP=$(clean_ipv6 "$TARGET_IP")
        ip6tables -t nat -A PREROUTING -d "$LOCAL_IP" -p "$PROTOCOL" --dport "$LOCAL_PORT" -j DNAT --to-destination "[$CLEANED_IP]:$TARGET_PORT"
        ip6tables -t nat -A POSTROUTING -d "$CLEANED_IP" -p "$PROTOCOL" --dport "$TARGET_PORT" -j MASQUERADE
    else
        # IPv4
        iptables -t nat -A PREROUTING -d "$LOCAL_IP" -p "$PROTOCOL" --dport "$LOCAL_PORT" -j DNAT --to-destination "$TARGET_IP:$TARGET_PORT"
        iptables -t nat -A POSTROUTING -d "$TARGET_IP" -p "$PROTOCOL" --dport "$TARGET_PORT" -j MASQUERADE
    fi
    read -p "$PROTOCOL 端口转发已添加，按回车返回首页..."
}

add_tcp_forwarding() {
    PROTOCOL=tcp
    inner_add_forwarding
}

add_udp_forwarding() {
    PROTOCOL=udp
    inner_add_forwarding
}

# 其他函数保持不变

while true; do
    echo "=============================="
    echo "1) 添加 TCP 端口转发（支持 IPv4/IPv6 + 域名）"
    echo "2) 删除 TCP 端口转发"
    echo "3) 添加 UDP 端口转发（支持 IPv4/IPv6 + 域名）"
    echo "4) 删除 UDP 端口转发"
    echo "5) 查看端口转发规则"
    echo "6) 保存规则"
    echo "7) 恢复规则"
    echo "8) 安装 iptables"
    echo "9) 开启 IP 转发（永久生效）"
    echo "10) 关闭 IP 转发（恢复默认）"
    echo "11) 退出"
    echo "=============================="
    read -p "选择操作 (1-11): " choice
    case $choice in
        1) add_tcp_forwarding ;;
        2) delete_tcp_forwarding ;;
        3) add_udp_forwarding ;;
        4) delete_udp_forwarding ;;
        5) view_forwarding ;;
        6) save_rules ;;
        7) restore_rules ;;
        8) install_iptables ;;
        9) enable_ip_forwarding ;;
        10) disable_ip_forwarding ;;
        11) exit 0 ;;
        *) read -p "无效输入，请重新选择。按回车返回首页..." ;;
    esac
done
