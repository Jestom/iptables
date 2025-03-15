# iptables 一键脚本使用指南
***
## 脚本

* 启动脚本  
  `wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/Jestom/iptables/master/port_forwarding.sh && chmod +x port_forwarding.sh && ./port_forwarding.sh`  
* 再次运行本脚本只需要输入`./port_forwarding.sh`回车即可
* 运行脚本请使用 root 身份

## 功能
支持本机多IP转发

（如本机192.168.1.2:80转发到192.168.1.50:8080以及192.168.1.3:80转发到192.168.1.50:8081）

如果系统没有iptables可以选择6-安装 iptables
添加完规则之后记 得4-保存规则 以及 选择 7-开启 IP 转发

## 支持系统
Debian、Ubuntu

其他系统未测

## 展示

![image.png](https://s2.loli.net/2025/03/15/ZXHmVwbYoF65v48.png)
