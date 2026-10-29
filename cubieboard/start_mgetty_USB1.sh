#!/bin/bash 

echo "[*] Starting mgetty on ttyUSB1..."
while sleep 1; do
    /usr/sbin/mgetty ttyUSB1
    echo "[!] Restarting mgetty on ttyUSB1..."
done

