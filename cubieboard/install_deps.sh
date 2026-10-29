#!/bin/bash

apt-get update && apt-get install -y \
    mgetty \
    ppp \
    iproute2 \
    iputils-ping \
    net-tools \
    procps \
    iptables

# mgetty expects spool dirs
mkdir -p /var/spool/mgetty /var/log/mgetty

touch /var/log/pppd_ttyUSB0.log
touch /var/log/pppd_ttyUSB1.log

chown root:root /etc/ppp/*
chown root:root /etc/mgetty/*
