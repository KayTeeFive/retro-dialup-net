#!/bin/bash
# usage: ./start_mgetty.sh [ttyUSB0 ttyUSB1 ...]

PORTS=("$@")
[ ${#PORTS[@]} -eq 0 ] && PORTS=(ttyUSB0 ttyUSB1)

run_port() {
    local port=$1
    while true; do
        local start=$SECONDS
        echo "[*] Starting mgetty on $port..."
        /usr/sbin/mgetty "$port"
        echo "[!] mgetty on $port exited (rc=$?), restarting..."

        if (( SECONDS - start < 5 )); then
            sleep 5
        else
            sleep 1
        fi
    done
}

cleanup() {
    trap '' INT TERM        # ігноруємо повторні сигнали, щоб не було рекурсії
    echo "[*] Stopping..."
    kill 0 2>/dev/null      # зупиняє цикли і mgetty (сам скрипт сигнал ігнорує)
    wait
    exit 0
}
trap cleanup INT TERM

for p in "${PORTS[@]}"; do
    run_port "$p" &
done
wait
