# DialUp ISP Emulator in Docker

This repository contains a **Docker-based DialUp ISP emulator** using `mgetty` and `pppd`.  
It allows you to emulate a PPP DialUp server for testing old clients or embedded devices.

---

## Features

- mgetty handles modem signals and incoming calls (`RING`) on `/dev/ttyUSB0`.
- pppd handles PPP authentication (PAP/CHAP) and IP assignment.
- Automatic restart of mgetty on crash.
- PPP logging to file and stdout for Docker logs.
- IP forwarding and NAT support for connected clients.
- Fully contained in a Docker container for portability.

---

## Requirements

- Docker 20+ / Docker Compose 1.29+
- A USB modem or virtual serial device mapped to `/dev/ttyUSB0`
- Capability `--privileged`, `NET_ADMIN` and `SYS_ADMIN` are used.

---

### Build

```commandline
docker compose build
```

---

### Run

```commandline
docker compose up
```
- Logs are visible via docker logs -f <container>
- mgetty automatically restarts if it crashes
- pppd writes debug logs to /var/log/pppd_ttyUSB0.log and stdout

---

### Notes

- `ttyUSB0` must be accessible to the container. Use `--device` or map physical modem.
- `SYS_ADMIN` or `privileged` is required for controlling tty (ioctl) and NAT.
- All configurations (IP range, PAP/CHAP secrets, DNS) are editable in:
  - **ppp**:
    - `/etc/ppp/options.ttyUSB0`
    - `pap-secrets`.
    - `chap-secrets`.
  - **mgetty**:
    - `dialin.config`
    - `login.config`
    - `mgetty.config`
  - system env:
    - `runner.sh`
- Logs are written both to files and stdout for Docker logging.
