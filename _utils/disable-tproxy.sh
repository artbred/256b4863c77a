#!/bin/bash

exec 2>&1

IPTABLES="/usr/sbin/iptables"
IP="/sbin/ip"

[ -x "$IPTABLES" ] || IPTABLES="/sbin/iptables"
[ -x "$IP" ] || IP="/usr/sbin/ip"

$IPTABLES -t mangle -D PREROUTING -j XRAY 2>/dev/null || true
$IPTABLES -t mangle -D OUTPUT -p tcp -j XRAY_MASK 2>/dev/null || true
$IPTABLES -t mangle -D OUTPUT -p udp -j XRAY_MASK 2>/dev/null || true
$IPTABLES -t mangle -D PREROUTING -i lo -m mark --mark 1 -p tcp -j TPROXY --on-port 12345 --tproxy-mark 1 2>/dev/null || true
$IPTABLES -t mangle -D PREROUTING -i lo -m mark --mark 1 -p udp -j TPROXY --on-port 12345 --tproxy-mark 1 2>/dev/null || true
$IPTABLES -t mangle -F XRAY 2>/dev/null || true
$IPTABLES -t mangle -X XRAY 2>/dev/null || true
$IPTABLES -t mangle -F XRAY_MASK 2>/dev/null || true
$IPTABLES -t mangle -X XRAY_MASK 2>/dev/null || true

$IP rule del fwmark 1 table 100 2>/dev/null || true
$IP route del local 0.0.0.0/0 dev lo table 100 2>/dev/null || true

echo "=== TPROXY Disabled ==="
exit 0