#!/bin/bash
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "Run as root"; exit 1; }
cd "$(dirname "$0")"

apt-get update && apt-get install -y \
    mgetty \
    ppp \
    iproute2 \
    iputils-ping \
    net-tools \
    procps \
    iptables \
    logrotate

# mgetty expects spool dirs
mkdir -p /var/spool/mgetty /var/log/mgetty

touch /var/log/pppd_ttyUSB0.log
touch /var/log/pppd_ttyUSB1.log

# PPP kernel modules at boot
printf 'ppp_generic\nppp_async\n' > /etc/modules-load.d/ppp.conf
modprobe ppp_generic ppp_async || true

# Configs
cp -rv ./ppp/* /etc/ppp/
cp -rv ./mgetty/* /etc/mgetty/

chown root:root /etc/mgetty/* /etc/ppp/*
chmod 600 /etc/ppp/pap-secrets /etc/ppp/chap-secrets

# Log rotation (copytruncate, keep 1 backup), checked hourly
install -m 644 ./mgetty-dialin.logrotate /etc/logrotate.d/mgetty-dialin
mkdir -p /etc/systemd/system/logrotate.timer.d
cat > /etc/systemd/system/logrotate.timer.d/hourly.conf <<'EOF'
[Timer]
OnCalendar=
OnCalendar=hourly
EOF

# Scripts and units
install -m 755 ./ppp_nat.sh /usr/local/sbin/ppp_nat.sh
install -m 755 ./start_mgetty.sh /usr/local/sbin/start_mgetty.sh
cp -v ./ppp-nat.service /etc/systemd/system/ppp-nat.service
cp -v ./mgetty-dialin.service /etc/systemd/system/mgetty-dialin.service

# Stop any manually started instance (port would be busy)
pkill -f start_mgetty.sh || true
pkill mgetty || true

systemctl daemon-reload
systemctl restart logrotate.timer
systemctl enable --now ppp-nat.service mgetty-dialin.service
systemctl --no-pager status ppp-nat mgetty-dialin || true
