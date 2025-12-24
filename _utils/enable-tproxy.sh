#!/bin/bash - https://xtls.github.io/document/level-2/iptables_gid.html

set -e

IPTABLES="/usr/sbin/iptables"
IP="/sbin/ip"
SS="/bin/ss"
CURL="/usr/bin/curl"

[ -x "$IPTABLES" ] || IPTABLES="/sbin/iptables"
[ -x "$IP" ] || IP="/usr/sbin/ip"
[ -x "$SS" ] || SS="/sbin/ss"
[ -x "$CURL" ] || CURL="/bin/curl"

TPROXY_PORT=12345
SOCKS_PORT=10808
TIMEOUT=60

FATAL_EXIT=99

abort() {
    echo "ERROR: $1"
    /usr/local/bin/disable-tproxy.sh || true
    exit $FATAL_EXIT
}


start=$(date +%s)
while ! $SS -tlnp 2>/dev/null | grep -q ":${TPROXY_PORT}"; do
    if [ $(($(date +%s) - start)) -ge $TIMEOUT ]; then
        abort "Timeout waiting for port $TPROXY_PORT"
    fi
    sleep 1
done
echo "    ✓ Port $TPROXY_PORT ready"

echo "[2/3] Verifying SOCKS proxy..."
success=0
for i in 1 2 3; do
    if $CURL -s -m 10 -x socks5://127.0.0.1:$SOCKS_PORT http://ifconfig.me >/dev/null 2>&1; then
        success=$((success + 1))
        echo "    Attempt $i: ✓"
    else
        echo "    Attempt $i: ✗"
        sleep 2
    fi
done

if [ $success -eq 0 ]; then
    abort "All 3 SOCKS proxy verification attempts failed"
fi
echo "    ✓ SOCKS proxy verified ($success/3 successful)"


$IP rule add fwmark 1 table 100
$IP route add local 0.0.0.0/0 dev lo table 100

$IPTABLES -t mangle -N XRAY
$IPTABLES -t mangle -A XRAY -d 127.0.0.0/8 -j RETURN
$IPTABLES -t mangle -A XRAY -d 10.0.0.0/8 -j RETURN
$IPTABLES -t mangle -A XRAY -d 100.64.0.0/10 -j RETURN
$IPTABLES -t mangle -A XRAY -d 169.254.0.0/16 -j RETURN
$IPTABLES -t mangle -A XRAY -d 172.16.0.0/12 -j RETURN
$IPTABLES -t mangle -A XRAY -d 192.168.0.0/16 -j RETURN
$IPTABLES -t mangle -A XRAY -d 224.0.0.0/4 -j RETURN
$IPTABLES -t mangle -A XRAY -d 240.0.0.0/4 -j RETURN
$IPTABLES -t mangle -A XRAY -d 255.255.255.255/32 -j RETURN
$IPTABLES -t mangle -A XRAY ! -s 192.168.1.0/24 -j RETURN
$IPTABLES -t mangle -A XRAY -p tcp -j TPROXY --on-port $TPROXY_PORT --tproxy-mark 1
$IPTABLES -t mangle -A XRAY -p udp -j TPROXY --on-port $TPROXY_PORT --tproxy-mark 1

$IPTABLES -t mangle -N XRAY_MASK
$IPTABLES -t mangle -A XRAY_MASK -m owner --gid-owner 23333 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -d 127.0.0.0/8 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -d 10.0.0.0/8 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -d 100.64.0.0/10 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -d 169.254.0.0/16 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -d 172.16.0.0/12 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -d 192.168.0.0/16 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -d 224.0.0.0/4 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -d 240.0.0.0/4 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -d 255.255.255.255/32 -j RETURN
$IPTABLES -t mangle -A XRAY_MASK -j MARK --set-mark 1

$IPTABLES -t mangle -I PREROUTING -i lo -m mark --mark 1 -p udp -j TPROXY --on-port $TPROXY_PORT --tproxy-mark 1
$IPTABLES -t mangle -I PREROUTING -i lo -m mark --mark 1 -p tcp -j TPROXY --on-port $TPROXY_PORT --tproxy-mark 1
$IPTABLES -t mangle -A PREROUTING -j XRAY
$IPTABLES -t mangle -A OUTPUT -p tcp -j XRAY_MASK
$IPTABLES -t mangle -A OUTPUT -p udp -j XRAY_MASK

echo "Verifying TPROXY connectivity..."
sleep 2
if ! $CURL -s -m 15 http://ifconfig.me >/dev/null 2>&1; then
    abort "TPROXY connectivity test failed (curl ifconfig.me)"
fi

echo "✓ TPROXY enabled successfully"