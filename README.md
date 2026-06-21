# retro-dialup-net

🔊 **Retro Dial-Up network over VoIP** — Connect vintage modems at up to **38400 baud** via SIP/RTP using ATA devices and a Dockerised PPP server.

---

## Overview

This project recreates a fully functional dial-up ISP environment using modern VoIP hardware and Docker, allowing you to connect real analog modems over an isolated IP network without a traditional PSTN.

**Key components:**

| Component                                            | Role                                                                   |
|------------------------------------------------------|------------------------------------------------------------------------|
| **ATA Devices** (Cisco SPA122/SPA112, Linksys PAP2T) | Convert analog modem signals to VoIP (SIP/RTP)                         |
| **Isolated Router**                                  | Provides DHCP with static reservations; keeps traffic off the main LAN |
| **Dial-Up Server** (Docker + mgetty + pppd)          | Handles incoming modem calls, PPP authentication, and IP assignment    |

---

## Network Architecture

```
CLIENT SIDE                          ISP PROVIDER SIDE
┌──────────────────┐                ┌──────────────────────────────┐
│ Linksys PAP2T    │                │  Cisco SPA122 (192.168.8.10) │
│ 192.168.8.20     │                │  Line 1: 101  Line 2: 102    │
│                  │◄──────────────►│                              │
│ Line 1: 201      │   VoIP / SIP   │  Cisco SPA112 (192.168.8.11) │
│ Line 2: 202      │                │  Line 1: 111  Line 2: 112    │
│                  │                └──────────────┬───────────────┘
│ [Modem] [Modem]  │                               │ USB/Serial
│   [PC-1] [PC-2]  │                ┌──────────────▼───────────────┐
└──────────────────┘                │  Server — mgetty + pppd      │
                                    │  Docker container            │
                                    │  4 incoming modem lines      │
                                    └──────────────────────────────┘
```

All devices share an isolated **192.168.8.0/24** network.  
Static DHCP reservations keep the IP-to-phone-number mapping consistent.

---

## Repository Structure

```
retro-dialup-net/
├── ATA_Devices/          # ATA configuration guides
│   ├── README.md         # Full ATA setup & critical modem settings
│   ├── Cisco_SPA112/
│   │   └── SPA112_1.4.1.cfg
│   └── Cisco_SPA122/
│       └── SPA122_1.4.1.cfg
└── dialup-server/        # Docker-based PPP dial-up server
    ├── README.md         # Build, run, and configuration guide
    ├── Dockerfile
    ├── docker-compose.yml
    ├── entrypoint.sh
    └── config/
        ├── runner.sh
        ├── mgetty/       # mgetty.config, dialin.config, login.config
        └── ppp/          # options.ttyUSB0, pap-secrets, chap-secrets
```

---

## Quick Start

### 1 — Set up the isolated network

Configure your router to assign static IPs via DHCP:

| Device        | Reserved IP  | Phone Lines  |
|---------------|--------------|--------------|
| Cisco SPA122  | 192.168.8.10 | 101, 102     |
| Cisco SPA112  | 192.168.8.11 | 111, 112     |
| Linksys PAP2T | 192.168.8.20 | 201, 202     |
| Server        | 192.168.8.5  | —            |

### 2 — Configure ATA devices

Follow **[ATA_Devices/README.md](ATA_Devices/README.md)** for:
- Per-device web-UI settings (Cisco SPA122, SPA112, Linksys PAP2T)
- Dial plans that route numbers directly to SIP endpoints (no SIP registrar needed)
- Critical modem-compatibility settings (G.711u codec, echo cancellation off, FAX detection off, Modem Line mode)

### 3 — Start the dial-up server

Follow **[dialup-server/README.md](dialup-server/README.md)** for full details, or run:

```bash
cd dialup-server
docker compose build
docker compose up
```

The container starts `mgetty` on `/dev/ttyUSB0`, which auto-answers incoming modem calls and hands off PPP sessions to `pppd`.

### 4 — Dial in

1. Pick up the phone/modem on **line 201** (client PAP2T).
2. Dial **101** — the ATA routes the SIP call to `192.168.8.10:5060` (SPA122 Line 1).
3. Both modems negotiate; `mgetty` detects `CONNECT` and starts a PPP session.
4. Client receives an IP address and is online. 🎉

---

## Critical Settings Summary

> Full details in [ATA_Devices/README.md → Critical Settings](ATA_Devices/README.md#critical-settings-for-modem-compatibility)

| Setting             | Required Value          | Reason                                             |
|---------------------|-------------------------|----------------------------------------------------|
| Preferred Codec     | **G711u**               | Uncompressed audio; modem tones survive intact     |
| Use Pref Codec Only | **yes**                 | Prevents fallback to compressed codecs             |
| Echo Cancellation   | **disabled**            | Echo cancellers destroy modem carrier tones        |
| FAX detection (all) | **disabled**            | FAX tone detection interferes with modem handshake |
| Modem Line          | **yes** (Cisco only)    | Optimises ATA DSP for modem passthrough            |
| Jitter Buffer Level | **low / no adjustment** | Minimises latency and signal distortion            |
| SIP Registration    | **Register = no**       | Pure peer-to-peer SIP, no registrar required       |

---

## Additional Resources

- [Configuring SPA122 ATA For Dial-Through](https://www.gekk.info/articles/ata-config.html)
- [dogemicrosystems.ca — Dial-up server](https://dogemicrosystems.ca/wiki/Dial_up_server)
- [dogemicrosystems.ca — Dial-up pool](https://dogemicrosystems.ca/wiki/Dial-up_pool)
