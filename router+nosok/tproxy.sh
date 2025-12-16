#!/bin/bash - https://xtls.github.io/document/level-2/iptables_gid.html

ip rule add fwmark 1 table 100
ip route add local 0.0.0.0/0 dev lo table 100


iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5353
iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-ports 5353

iptables -t nat -N XRAY_DNS_OUT
iptables -t nat -A XRAY_DNS_OUT -m owner --gid-owner 23333 -j RETURN
iptables -t nat -A XRAY_DNS_OUT -p udp -j REDIRECT --to-ports 5353
iptables -t nat -A XRAY_DNS_OUT -p tcp -j REDIRECT --to-ports 5353
iptables -t nat -A OUTPUT -p udp --dport 53 -j XRAY_DNS_OUT
iptables -t nat -A OUTPUT -p tcp --dport 53 -j XRAY_DNS_OUT


iptables -t mangle -N XRAY
iptables -t mangle -A XRAY -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A XRAY -d 100.64.0.0/10 -j RETURN
iptables -t mangle -A XRAY -d 192.168.1.0/24 -j RETURN
iptables -t mangle -A XRAY -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A XRAY -d 224.0.0.0/3 -j RETURN
iptables -t mangle -A XRAY ! -s 192.168.1.0/24 -j RETURN

iptables -t mangle -A XRAY -p udp --dport 53 -j RETURN
iptables -t mangle -A XRAY -p tcp --dport 53 -j RETURN
iptables -t mangle -A XRAY -p tcp -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A XRAY -p udp -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A PREROUTING -j XRAY

iptables -t mangle -N XRAY_MASK
iptables -t mangle -A XRAY_MASK -m owner --gid-owner 23333 -j RETURN
iptables -t mangle -A XRAY_MASK -p udp --dport 53 -j RETURN
iptables -t mangle -A XRAY_MASK -p tcp --dport 53 -j RETURN
iptables -t mangle -A XRAY_MASK -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A XRAY_MASK -d 100.64.0.0/10 -j RETURN
iptables -t mangle -A XRAY_MASK -d 192.168.1.0/24 -j RETURN
iptables -t mangle -A XRAY_MASK -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A XRAY_MASK -d 224.0.0.0/3 -j RETURN
iptables -t mangle -A XRAY_MASK -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -p tcp -j XRAY_MASK
iptables -t mangle -A OUTPUT -p udp -j XRAY_MASK