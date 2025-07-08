#!/bin/bash

IPTABLES_RULES="/etc/iptables/rules.v4"

install_iptables() {
    if ! command -v iptables &> /dev/null; then
        apt update && apt install -y iptables iptables-persistent
    fi
    read -p "安装完成，按回车返回首页..."
}

enable_ip_forwarding() {
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sysctl -w net.ipv4.ip_forward=1 > /dev/null

    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    sysctl -p > /dev/null

    read -p "IP 转发已开启，并在重启后自动生效！按回车返回首页..."
}

disable_ip_forwarding() {
    echo 0 > /proc/sys/net/ipv4/ip_forward
    sysctl -w net.ipv4.ip_forward=0 > /dev/null

    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    sysctl -p > /dev/null

    read -p "IP 转发已关闭，系统已恢复默认。按回车返回首页..."
}

restore_rules() {
    if [ -f "$IPTABLES_RULES" ]; then
        iptables-restore < "$IPTABLES_RULES"
        read -p "规则已恢复，按回车返回首页..."
    else
        read -p "没有找到规则文件，无法恢复。按回车返回首页..."
    fi
}

add_tcp_forwarding() {
    read -p "本机监听 IP: " LOCAL_IP
    read -p "本机监听端口: " LOCAL_PORT
    read -p "目标服务器 IP: " TARGET_IP
    read -p "目标服务器端口: " TARGET_PORT

    iptables -t nat -A PREROUTING -d "$LOCAL_IP" -p tcp --dport "$LOCAL_PORT" -j DNAT --to-destination "$TARGET_IP:$TARGET_PORT"
    iptables -t nat -A POSTROUTING -d "$TARGET_IP" -p tcp --dport "$TARGET_PORT" -j MASQUERADE

    read -p "TCP 端口转发已添加，按回车返回首页..."
}

delete_tcp_forwarding() {
    echo "当前 TCP 端口转发规则:"
    iptables -t nat -L PREROUTING --line-numbers -n -v | grep "tcp"

    read -p "请输入要删除的规则编号: " RULE_NUM
    if [[ ! "$RULE_NUM" =~ ^[0-9]+$ ]]; then
        read -p "无效输入，请输入正确的规则编号。按回车返回首页..."
        return
    fi

    iptables -t nat -D PREROUTING "$RULE_NUM"
    read -p "TCP 规则 $RULE_NUM 已删除，按回车返回首页..."
}

add_udp_forwarding() {
    read -p "本机监听 IP: " LOCAL_IP
    read -p "本机监听端口: " LOCAL_PORT
    read -p "目标服务器 IP: " TARGET_IP
    read -p "目标服务器端口: " TARGET_PORT

    iptables -t nat -A PREROUTING -d "$LOCAL_IP" -p udp --dport "$LOCAL_PORT" -j DNAT --to-destination "$TARGET_IP:$TARGET_PORT"
    iptables -t nat -A POSTROUTING -d "$TARGET_IP" -p udp --dport "$TARGET_PORT" -j MASQUERADE

    read -p "UDP 端口转发已添加，按回车返回首页..."
}

delete_udp_forwarding() {
    echo "当前 UDP 端口转发规则:"
    iptables -t nat -L PREROUTING --line-numbers -n -v | grep "udp"

    read -p "请输入要删除的规则编号: " RULE_NUM
    if [[ ! "$RULE_NUM" =~ ^[0-9]+$ ]]; then
        read -p "无效输入，请输入正确的规则编号。按回车返回首页..."
        return
    fi

    iptables -t nat -D PREROUTING "$RULE_NUM"
    read -p "UDP 规则 $RULE_NUM 已删除，按回车返回首页..."
}

view_forwarding() {
    iptables -t nat -L PREROUTING --line-numbers -n -v
    read -p "按回车返回首页..."
}

save_rules() {
    mkdir -p /etc/iptables
    iptables-save > "$IPTABLES_RULES"
    read -p "规则已保存，按回车返回首页..."
}

while true; do
    echo "=============================="
    echo "1) 添加 TCP 端口转发"
    echo "2) 删除 TCP 端口转发"
    echo "3) 添加 UDP 端口转发"
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
