#!/bin/bash
set -e

NET=192.168.127.0/24

echo "[*] Enabling IP forward"
sysctl -w net.ipv4.ip_forward=1

ipt() {  # ipt <table> <chain> <rule...>
    local t=$1 c=$2; shift 2
    iptables -t "$t" -C "$c" "$@" 2>/dev/null || iptables -t "$t" -I "$c" "$@"
}

echo "[*] Enabling NAT"
ipt nat    POSTROUTING -s $NET ! -o ppp+ -j MASQUERADE
ipt filter FORWARD -i ppp+ ! -o ppp+ -j ACCEPT
ipt filter FORWARD ! -i ppp+ -o ppp+ -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -n -L FORWARD -v
iptables -t nat -n -L POSTROUTING -v

