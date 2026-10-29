#!/bin/bash 

echo "[*] Starting mgetty on ttyUSB0..."
while sleep 1; do
    /usr/sbin/mgetty ttyUSB0
    echo "[!] Restarting mgetty on ttyUSB0..."
done

