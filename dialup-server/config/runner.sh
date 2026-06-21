#!/bin/sh
set -e

# Some fixes
mkdir -p /run/lock && chmod 777 /run/lock
cp -rvf /app/ppp/* /etc/ppp/ && chown root:root /etc/ppp/*
cp -rvf /app/mgetty/* /etc/mgetty/ && chown root:root /etc/mgetty/*
touch /var/log/pppd_ttyUSB0.log

# ensure permissions
#chown root:dialout /dev/ttyUSB0 || true
#chmod 660 /dev/ttyUSB0 || true

# Setup password for 'dial' user
USER='dial'
PASSWD='dial'
echo "${USER}:${PASSWD}" | chpasswd

# Final stage: Networking

echo "[*] Enabling IP forward"
sysctl -w net.ipv4.ip_forward=1

echo "[*] Enabling NAT"
iptables -t nat -A POSTROUTING -s 192.168.127.0/24 -j MASQUERADE
#iptables -A FORWARD -i ppp0 -o wlp8s0 -j ACCEPT
#iptables -A FORWARD -i wlp8s0 -o ppp0 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i ppp0 -j ACCEPT
iptables -A FORWARD -o ppp0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Sleep before 'mgetty' starts to avoid tail fail
(sleep 3 && tail -F /var/log/mgetty/*.log /var/log/pppd_*.log) &

echo "[*] Starting mgetty on ttyUSB0..."
while sleep 1; do
    exec /usr/sbin/mgetty ttyUSB0
    echo "[!] Restarting mgetty on ttyUSB0..."
done
