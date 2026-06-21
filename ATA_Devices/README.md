# Configuring ATA Devices for Dial-Up Connections

> **Purpose**: Configuration guide for building a retro Dial-Up network running at speeds up to 38400 baud using ATA (Analog Telephone Adapter) devices and modems.

## Table of Contents
- [Overview](#overview)
- [Network Architecture](#network-architecture)
- [Prerequisites](#prerequisites)
- [DHCP Router Configuration](#dhcp-router-configuration)
- [ATA Device Settings](#ata-device-settings)
  - [Cisco SPA122 (ISP Lines 101-102)](#cisco-spa122)
  - [Cisco SPA112 (ISP Lines 111-112)](#cisco-spa112)
  - [Linksys PAP2T (Client Lines 201-202)](#linksys-pap2t)
- [Dial Plan Explanation](#dial-plan-explanation)
- [Critical Settings for Modem Compatibility](#critical-settings-for-modem-compatibility)
- [Verification Steps](#verification-steps)
- [Troubleshooting](#troubleshooting)

---

## Overview

This setup creates a retro Dial-Up network infrastructure consisting of:

**Client Side:**
- **Linksys PAP2T** (192.168.8.20): Two clients with modems connecting via analog phone lines

**ISP Provider Side (Server Hub):**
- **Cisco SPA122** (192.168.8.10): ISP with 2 modem lines
- **Cisco SPA112** (192.168.8.11): ISP with 2 modem lines
- **Server**: Running `mgetty + ppp` for handling dial-in connections

All devices operate on an isolated network with a dedicated router providing DHCP to avoid interference with the main home network.

---

## Network Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Isolated Dial-Up Network                    │
│                    (192.168.8.0/24 - DHCP)                      │
└─────────────────────────────────────────────────────────────────┘

CLIENT SIDE                         ISP PROVIDER SIDE
┌──────────────────┐               ┌──────────────────────────────┐
│ Linksys PAP2T    │               │  Cisco SPA122                │
│ 192.168.8.20     │               │  192.168.8.10                │
│                  │               │  ---                         │
│ Line 1: 201      │◄─────────────►│  Line 1: 101 (port 5060)     │
│   (port 5060)    │   VoIP/SIP    │  Line 2: 102 (port 5061)     │
│ Line 2: 202      │               │                              │
│   (port 5061)    │               │  =======                     │
│                  │               │                              │
│ [Modem] [Modem]  │               │  Cisco SPA112                │
│    ↕       ↕     │               │  192.168.8.11                │
│ [PC-1] [PC-2]    │               │  ---                         │
└──────────────────┘               │  Line 1: 111 (port 5060)     │
                                   │  Line 2: 112 (port 5061)     │
                                   └──────────┬───────────────────┘
                                              │ USB/Serial
                                              │ (Modem per line)
                                   ┌──────────▼───────────────────┐
                                   │  Server (mgetty + ppp)       │
                                   │  Handles 4 incoming lines    │
                                   └──────────────────────────────┘
```

### Phone Number to IP/Port Mapping

| Device | Line | Number | IP Address    | SIP Port | User ID |
|--------|------|--------|---------------|----------|---------|
| PAP2T  | 1    | 201    | 192.168.8.20  | 5060     | 201     |
| PAP2T  | 2    | 202    | 192.168.8.20  | 5061     | 202     |
| SPA122 | 1    | 101    | 192.168.8.10  | 5060     | 101     |
| SPA122 | 2    | 102    | 192.168.8.10  | 5061     | 102     |
| SPA112 | 1    | 111    | 192.168.8.11  | 5060     | 111     |
| SPA112 | 2    | 112    | 192.168.8.11  | 5061     | 112     |

> **Note**: IP addresses follow the pattern `192.168.8.X` where X matches the last digit(s) of User ID/phone number.

---

## Prerequisites

- 3x ATA devices: Cisco SPA122, Cisco SPA112, Linksys PAP2T
- 4x analog modems for ISP side (connected to Cisco devices)
- 2x analog modems for client side (connected to PAP2T)
- Server running Linux with `mgetty` and `ppp` configured
- Dedicated router/switch for isolated network
- Standard analog phone cables (RJ11)

---

## DHCP Router Configuration

The isolated router must assign static IP addresses based on MAC addresses to ensure consistent IP-to-phone-number mapping.

### Required Static DHCP Reservations

Configure the following in your router's DHCP settings:

| Device Hostname    | MAC Address         | Reserved IP    | Notes                |
|--------------------|---------------------|----------------|----------------------|
| SPA122-DialUP      | `xx:xx:xx:xx:xx:xx` | 192.168.8.10   | ISP Lines 101-102    |
| SPA112-DialUP      | `xx:xx:xx:xx:xx:xx` | 192.168.8.11   | ISP Lines 111-112    |
| LinkSysPAP2T-20    | `xx:xx:xx:xx:xx:xx` | 192.168.8.20   | Client Lines 201-202 |
| (server)           | `xx:xx:xx:xx:xx:xx` | 192.168.8.5    | mgetty+ppp server    |

> **Important**: Replace `xx:xx:xx:xx:xx:xx` with actual MAC addresses from your devices.

### Router Settings
- **Network**: 192.168.8.0/24
- **Gateway**: 192.168.8.1
- **DHCP Range**: 192.168.8.100-192.168.8.200 (avoid .10, .11, .20, .5)
- **DNS**: 8.8.8.8, 8.8.4.4
- **Isolation**: Enable network isolation from main network if supported

---

## ATA Device Settings

> **Legend**: Settings marked in **bold** are critical for modem compatibility and must be configured exactly as specified.

### Cisco SPA122

#### Networking
- Networking Service:
  - Networking Service = BRIDGE
  - Monitor Network Drop on WAN Port Only: OFF
- Internet Settings:
  - Connection Type = DHCP
  - MTU = Auto
  - Host Name = SPA122-DialUP
  - Domain Name = lan
  - DNS Server Order = DHCP-Manual
  - Primary DNS = 8.8.8.8
  - Secondary DNS = 8.8.4.4

#### Voice / Regional
Miscellaneous:
- FXS Port Impedance = 600+2.16uF

#### Voice / Line 1
Network Settings:
- Network Jitter Level = **low**
- Jitter Buffer Adjustment = **no**

Call Feature Settings:
- Enable IP Dialing = **yes**

Proxy and Registration:
- Register = **no**
- Use OB Proxy In Dialog = **no**
- Make Call Without Reg = **yes**
- Ans Call Without Reg = **yes**

Subscriber Information:
- User ID = **101**
- Use Auth ID = no

Audio Configuration table

| Option                        | Value       | Option                      | Value            |
|-------------------------------|-------------|-----------------------------|------------------|
| Preferred Codec               | **G711u**   | Second Preferred Codec      | Unspecified      |
| Third Preferred Codec         | Unspecified | Use Pref Codec Only         | **yes**          |
| Use Remote Pref Codec         | no          | Codec Negotiation           | Default          |
| G729a Enable                  | **no**      | Silence Supp Enable         | no               |
| G726-32 Enable                | **no**      | Silence Threshold           | medium           |
| FAX V21 Detect Enable         | **no**      | Echo Canc Enable            | **no**           |    
| FAX CNG Detect Enable         | **no**      | FAX Passthru Codec          | G711u            | 
| FAX Codec Symmetric           | **no**      | DTMF Process INFO           | yes              |
| FAX Passthru Method           | **None**    | DTMF Process AVT            | yes              |
| FAX Process NSE               | **no**      | DTMF Tx Method              | Auto             |
| FAX Disable ECAN              | no          | DTMF Tx Mode                | Strict           |
| DTMF Tx Strict Hold Off Time  | 70          | FAX Enable T38              | no               |
| Hook Flash Tx Method          | None        | FAX T38 Redundancy          | 1                |
| FAX T38 ECM Enable            | **no**      | FAX Tone Detect Mode        | caller or callee |
| Symmetric RTP                 | no          | FAX T38 Return to Voice     | no               |
| Modem Line                    | **yes**     | RTP to Proxy in Remote Hold | no               |

Dial Plan:
- Dial Plan: `(<101:101>S0<:@192.168.8.10:5060> | <102:102>S0<:@192.168.8.10:5061> | <111:111>S0<:@192.168.8.11:5060> | <112:112>S0<:@192.168.8.11:5061> | <201:201>S0<:@192.168.8.20:5060> | <202:202>S0<:@192.168.8.20:5061> | <211:211>S0<:@192.168.8.21:5060> | <212:212>S0<:@192.168.8.21:5061>)`

#### Voice / Line 2
Almost all settings for `Line 2` are identical to `Voice / Line 1` except next settings below.

Subscriber Information:
- User ID = **102**
- Use Auth ID = no

### Cisco SPA112

#### Networking
- Internet Settings:
  - Connection Type = DHCP
  - MTU = Auto
  - Host Name = SPA112-DialUP
  - Domain Name = lan
  - DNS Server Order = DHCP-Manual
  - Primary DNS = 8.8.8.8
  - Secondary DNS = 8.8.4.4

#### Voice

Almost all settings for `Voice` are identical to `SPA122` except next settings below.

#### Voice / Line 1
Subscriber Information:
- User ID = **111**
- Use Auth ID = no

#### Voice / Line 2
Subscriber Information:
- User ID = **112**
- Use Auth ID = no


### LynkSys PAP2T
#### Networking
- Internet Settings:
  - DHCP = yes
  - Host Name = LinkSysPAP2T-20
  - Domain Name = lan
  - DNS Server Order = Manual
  - Primary DNS = 8.8.8.8
  - Secondary DNS = 8.8.4.4

#### Voice / Regional
Miscellaneous:
- FXS Port Impedance = 600+2.16uF

#### Voice / Line 1
Network Settings:
- Network Jitter Level = **low**
- Jitter Buffer Adjustment = **up and down** -> **!!! maybe missconfiguration, need test with  `disable`**

Proxy and Registration:
- Register = **no**
- Use OB Proxy In Dialog = **no**
- Make Call Without Reg = **yes**
- Ans Call Without Reg = **yes**

Subscriber Information:
- User ID = **201**
- Use Auth ID = no

Audio Configuration table

| Option              | Value     | Option                 | Value    |
|---------------------|-----------|------------------------|----------|
| Preferred Codec     | **G711u** | Silence Supp Enable    | no       |
| Use Pref Codec Only | **yes**   | Silence Threshold      | medium   |
| G729a Enable        | **no**    | Echo Canc Enable       | **no**   |
| G723 Enable         | **no**    | Echo Canc Adapt Enable | **no**   |
| G726-16 Enable      | **no**    | Echo Supp Enable       | **no**   |
| G726-24 Enable      | **no**    | FAX CED Detect Enable  | **no**   |
| G726-32 Enable      | **no**    | FAX CNG Detect Enable  | **no**   |
| G726-40 Enable      | **no**    | FAX Passthru Codec     | G711u    |
| DTMF Process INFO   | yes       | FAX Codec Symmetric    | **no**   |
| DTMF Process AVT    | yes       | FAX Passthru Method    | **None** |
| DTMF Tx Method      | Auto      | DTMF Tx Mode           | Strict   |
| FAX Process NSE     | **no**    | Hook Flash Tx Method   | None     |
| FAX Disable ECAN    | **no**    | Release Unused Codec   | yes      |

> `Modem Line` option is absent on Linksys PAP2T

Dial Plan:
- Dial Plan: `(<101:101>S0<:@192.168.8.10:5060> | <102:102>S0<:@192.168.8.10:5061> | <111:111>S0<:@192.168.8.11:5060> | <112:112>S0<:@192.168.8.11:5061> | <201:201>S0<:@192.168.8.20:5060> | <202:202>S0<:@192.168.8.20:5061> | <211:211>S0<:@192.168.8.21:5060> | <212:212>S0<:@192.168.8.21:5061>)`
- Enable IP Dialing: **yes**

---

## Dial Plan Explanation

The Dial Plan defines how phone numbers are mapped to SIP endpoints. The syntax used is specific to Cisco/Linksys ATA devices.

### Dial Plan Syntax

```
(<number:number>S0<:@IP:PORT> | ...)
```

- `<number:number>` - Matches dialed number pattern
- `S0` - No dial timeout (immediate dial)
- `<:@IP:PORT>` - Route to specific IP address and SIP port
- `|` - OR separator for multiple routes

### Complete Dial Plan Breakdown

```
Dialed Number → Destination
─────────────────────────────────────────────────────────
101 → 192.168.8.10:5060  (SPA122 Line 1)
102 → 192.168.8.10:5061  (SPA122 Line 2)
111 → 192.168.8.11:5060  (SPA112 Line 1)
112 → 192.168.8.11:5061  (SPA112 Line 2)
201 → 192.168.8.20:5060  (PAP2T Line 1)
202 → 192.168.8.20:5061  (PAP2T Line 2)
211 → 192.168.8.21:5060  (Reserved - future expansion)
212 → 192.168.8.21:5061  (Reserved - future expansion)
```

### Usage Example

1. Client on line 201 picks up phone
2. Dials `101` to connect to ISP line 1
3. ATA routes call via SIP to `192.168.8.10:5060`
4. Modems on both ends negotiate connection
5. PPP session established via mgetty

---

## Critical Settings for Modem Compatibility

To ensure reliable modem-to-modem communication at 38400 baud over VoIP, several settings **must** be configured correctly:

### 1. Audio Codec Settings
- **Preferred Codec = G711u** (uncompressed, 64 kbps)
- **Use Pref Codec Only = yes** (prevents codec negotiation issues)
- **G729a/G726/G723 Enable = no** (compressed codecs interfere with modem signals)

> **Why**: Modem signals require uncompressed audio transmission. Compressed codecs (G729, G726) destroy the analog modem carrier tones.

### 2. Echo Cancellation - MUST BE DISABLED
- **Echo Canc Enable = no**
- **Echo Canc Adapt Enable = no** (PAP2T only)
- **Echo Supp Enable = no** (PAP2T only)

> **Why**: Echo cancellation algorithms treat modem tones as echo and attempt to cancel them, destroying the modem connection. This is the #1 cause of modem failures over VoIP.

### 3. FAX Detection - MUST BE DISABLED
- **FAX V21 Detect Enable = no**
- **FAX CNG Detect Enable = no**
- **FAX CED Detect Enable = no**
- **FAX Passthru Method = None**
- **FAX Process NSE = no**
- **FAX Enable T38 = no**

> **Why**: FAX detection interferes with modem negotiation handshakes which use similar tone patterns.

### 4. Modem Line Setting (Cisco SPA122/SPA112 only)
- **Modem Line = yes**

> **Critical**: This setting optimizes the ATA for modem passthrough. Unfortunately, this option is **absent on Linksys PAP2T**, which may limit maximum connection speeds on the client side.

### 5. Jitter Buffer
- **Network Jitter Level = low**
- **Jitter Buffer Adjustment = no** (or disable on PAP2T)

> **Why**: Minimizes latency and prevents buffer-induced signal distortion.

### 6. SIP Registration
- **Register = no**
- **Make Call Without Reg = yes**
- **Ans Call Without Reg = yes**

> **Why**: Direct peer-to-peer SIP calling without a SIP server/registrar.

---

## Verification Steps

After configuration, verify the setup:

### 1. Network Connectivity
```bash
# From each ATA device (if SSH/telnet available) or from server:
ping 192.168.8.10  # SPA122
ping 192.168.8.11  # SPA112
ping 192.168.8.20  # PAP2T
```

### 2. IP Address Verification
- Check each ATA web interface (Status → Network)
- Confirm IP addresses match the mapping table
- Verify DNS servers are set to 8.8.8.8 / 8.8.4.4

### 3. Test Call Between Lines
1. Pick up phone on line 201 (client)
2. Dial 101 (ISP line 1)
3. Should hear modem carrier tone from ISP side
4. Verify modems can negotiate connection

### 4. Check Audio Quality
- Listen for clear carrier tones (no distortion, crackling, or warbling)
- Modem handshake should complete within 20-30 seconds
- Connection should be stable without frequent retrains

### 5. PPP Connection Test
```bash
# On server, monitor mgetty logs:
tail -f /var/log/mgetty/mgetty.log.ttyUSB0

# Successful connection shows:
# - Modem CONNECT at 38400
# - PPP negotiation
# - IP address assignment
```

---

## Troubleshooting

### Issue: No Dial Tone
**Symptoms**: Picking up phone on any line produces no dial tone

**Solutions**:
1. Check physical phone cable connections (RJ11)
2. Verify ATA device has power and network connectivity
3. Check ATA web interface - ensure Line 1/2 is enabled
4. Verify FXS Port Impedance = 600+2.16uF

---

### Issue: Can't Dial Out / Call Doesn't Connect
**Symptoms**: Dial tone works, but dialing a number produces silence or "fast busy"

**Solutions**:
1. Verify Dial Plan is configured correctly (check for typos)
2. Confirm IP addresses match the Dial Plan
3. Check **Enable IP Dialing = yes**
4. Ensure **Register = no** and **Make Call Without Reg = yes**
5. Verify network connectivity between devices (ping test)
6. Check SIP ports not blocked by firewall

---

### Issue: Modem Connection Fails During Handshake
**Symptoms**: Modem tones heard but connection drops before completing

**Solutions**:
1. **Verify Echo Cancellation is DISABLED** - most common cause
2. Check **Modem Line = yes** (on Cisco devices)
3. Confirm **Preferred Codec = G711u** only
4. Disable all FAX detection features
5. Set **Network Jitter Level = low**
6. Try different modem initialization strings (disable error correction/compression)

**Recommended modem AT commands**:
```
AT&F           # Factory reset
ATE1           # Echo on
ATX3           # Basic dialing
AT&Q0          # Async mode
ATS0=1         # Auto-answer on 1 ring (ISP side)
```

---

### Issue: Connection Drops Randomly
**Symptoms**: Modem connects successfully but disconnects after a few seconds/minutes

**Solutions**:
1. Check for network packet loss: `ping -c 100 192.168.8.10`
2. Verify no QoS/traffic shaping on isolated router
3. Ensure sufficient bandwidth (minimum 100 kbps per line)
4. Check **Jitter Buffer Adjustment = no**
5. Disable any SIP ALG (Application Layer Gateway) on router
6. Monitor server-side PPP logs for errors

---

### Issue: Low Connection Speed
**Symptoms**: Modem connects at speeds lower than 38400 baud

**Solutions**:
1. Test different number combinations (different Cisco device)
2. Verify cable quality (use short, high-quality RJ11 cables)
3. Check modem supports 38400 baud (V.32bis minimum)
4. Try disabling modem error correction: `AT&M0`
5. **Known limitation**: PAP2T lacks "Modem Line" option, may limit speeds
6. Check `Jitter Buffer Adjustment` on PAP2T (test with **disable** instead of **up and down**)

> **Note on PAP2T**: The configuration shows `Jitter Buffer Adjustment = up and down` with a note about possible misconfiguration. Test with `disable` for better modem performance.

---

### Issue: One-Way Audio
**Symptoms**: Can hear modem tones from one side only

**Solutions**:
1. Check **Symmetric RTP = no** (should be disabled)
2. Verify firewall allows bidirectional RTP traffic
3. Check router NAT settings (shouldn't affect isolated network)
4. Ensure **FAX Codec Symmetric = no**

---

## Additional Resources

- [Configuring SPA122 ATA For Dial-Through](https://www.gekk.info/articles/ata-config.html)
- [dogemicrosystems.ca: Dial-up server](https://dogemicrosystems.ca/wiki/Dial_up_server)
- [dogemicrosystems.ca: Dial-up pool](https://dogemicrosystems.ca/wiki/Dial-up_pool)
