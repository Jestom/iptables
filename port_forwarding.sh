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

    # 确保 `sysctl.conf` 配置持久化
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    sysctl -p > /dev/null

    # 检查是否启用 rc.local，如果存在则添加
    if [ -f "/etc/rc.local" ]; then
        if ! grep -q "echo 1 > /proc/sys/net/ipv4/ip_forward" /etc/rc.local; then
            echo "echo 1 > /proc/sys/net/ipv4/ip_forward" >> /etc/rc.local
        fi
        chmod +x /etc/rc.local
    else
        # Debian 12+ 使用 systemd 方式
        cat <<EOF > /etc/systemd/system/ip_forwarding.service
[Unit]
Description=Enable IPv4 Forwarding
After=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable ip_forwarding
        systemctl start ip_forwarding
    fi

    read -p "IP 转发已开启，并在重启后自动生效！按回车返回首页..."
}

disable_ip_forwarding() {
    echo 0 > /proc/sys/net/ipv4/ip_forward
    sysctl -w net.ipv4.ip_forward=0 > /dev/null

    # 从 sysctl.conf 中移除持久化设置
    sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
    sysctl -p > /dev/null

    # 移除 rc.local 配置
    if [ -f "/etc/rc.local" ]; then
        sed -i '/echo 1 > \/proc\/sys\/net\/ipv4\/ip_forward/d' /etc/rc.local
    fi

    # 移除 systemd 服务
    if [ -f "/etc/systemd/system/ip_forwarding.service" ]; then
        systemctl stop ip_forwarding
        systemctl disable ip_forwarding
        rm -f /etc/systemd/system/ip_forwarding.service
        systemctl daemon-reload
    fi

    read -p "IP 转发已关闭，并恢复默认设置。按回车返回首页..."
}

restore_rules() {
    if [ -f "$IPTABLES_RULES" ]; then
        iptables-restore < "$IPTABLES_RULES"
        read -p "规则已恢复，按回车返回首页..."
    else
        read -p "没有找到规则文件，无法恢复。按回车返回首页..."
    fi
}

add_forwarding() {
    read -p "本机监听 IP: " LOCAL_IP
    read -p "本机监听端口: " LOCAL_PORT
    read -p "目标服务器 IP: " TARGET_IP
    read -p "目标服务器端口: " TARGET_PORT

    iptables -t nat -A PREROUTING -d "$LOCAL_IP" -p tcp --dport "$LOCAL_PORT" -j DNAT --to-destination "$TARGET_IP:$TARGET_PORT"
    iptables -t nat -A POSTROUTING -d "$TARGET_IP" -p tcp --dport "$TARGET_PORT" -j MASQUERADE

    read -p "端口转发已添加，按回车返回首页..."
}

delete_forwarding() {
    echo "当前端口转发规则:"
    iptables -t nat -L PREROUTING --line-numbers -n -v

    read -p "请输入要删除的规则编号: " RULE_NUM
    if [[ ! "$RULE_NUM" =~ ^[0-9]+$ ]]; then
        read -p "无效输入，请输入正确的规则编号。按回车返回首页..."
        return
    fi

    iptables -t nat -D PREROUTING "$RULE_NUM"
    read -p "规则 $RULE_NUM 已删除，按回车返回首页..."
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
    echo "1) 添加端口转发"
    echo "2) 删除端口转发（输入编号删除）"
    echo "3) 查看端口转发规则"
    echo "4) 保存规则"
    echo "5) 恢复规则"
    echo "6) 安装 iptables"
    echo "7) 开启 IP 转发（永久生效）"
    echo "8) 关闭 IP 转发（恢复默认）"
    echo "9) 退出"
    echo "=============================="
    read -p "选择操作 (1-9): " choice
    case $choice in
        1) add_forwarding ;;
        2) delete_forwarding ;;
        3) view_forwarding ;;
        4) save_rules ;;
        5) restore_rules ;;
        6) install_iptables ;;
        7) enable_ip_forwarding ;;
        8) disable_ip_forwarding ;;
        9) exit 0 ;;
        *) read -p "无效输入，请重新选择。按回车返回首页..." ;;
    esac
done
