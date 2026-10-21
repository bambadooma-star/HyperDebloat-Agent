# HyperDebloat-Agent

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android%2010--15%20%7C%20HyperOS%201.0--2.0%20%7C%20MIUI-007ACC?style=for-the-badge&logo=android&logoColor=white" alt="Platform" />
  <img src="https://img.shields.io/badge/Privilege-Zero--Root%20(Non--Root)-success?style=for-the-badge&logo=securityscorecard&logoColor=white" alt="Zero-Root" />
  <img src="https://img.shields.io/badge/Play%20Integrity-Pass%20%E2%9C%94-blue?style=for-the-badge&logo=googleplay&logoColor=white" alt="Play Integrity" />
  <img src="https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge" alt="License" />
</p>

---

## Overview

**HyperDebloat-Agent** is a deterministic, non-root ADB debloating, privacy hardening, and telemetry-stripping framework designed specifically for Android power users and autonomous AI coding agents (Claude Code, Cursor, MCP servers).

While built to safely optimize any Android system, it specializes in tackling the notoriously aggressive advertising daemons, continuous analytics loggers, and thermal-throttling background engines preloaded on **Xiaomi HyperOS** and **MIUI** devices (Xiaomi, Redmi, POCO).

Every action in this framework is **100% reversible in user-space without root**, preserves **SafetyNet and Play Integrity** for banking and Google Pay, and leaves core system partitions untouched.

---

## Architecture & How It Works

```
                     +---------------------------------------+
                     |         HyperDebloat-Agent            |
                     |   CLI Scripts & Autonomous Agents     |
                     +-------------------+-------------------+
                                         |
                       [Strict Safety Tier Verification]
                                         |
                   +---------------------+---------------------+
                   |                                           |
       +-----------v-----------+                   +-----------v-----------+
       |   Tier: SAFE / CAUTION |                   |     Tier: CRITICAL    |
       |  (Analytics, Adware,  |                   | (SystemUI, Security,  |
       |   Telemetry, Bloat)   |                   |    Dialer, Launcher)  |
       +-----------+-----------+                   +-----------+-----------+
                   |                                           |
      adb shell pm uninstall -k --user 0                  [BLOCKED]
                   |                                (Hardcoded Safety Gate)
     +-------------v-------------+
     |  User 0 Environment Clean |
     |  APK preserved in /system |
     |  Play Integrity PASS      |
     |  Google Pay / Banking OK  |
     +---------------------------+
                   |
     [Need to revert anytime?]
                   |
     adb shell cmd package install-existing <pkg>
```

### The Non-Root Mechanism
HyperDebloat uses Android's native multi-user package management command:
```bash
adb shell pm uninstall -k --user 0 <package_name>
```
1. **Partition Integrity Preserved:** System partitions (`/system`, `/product`, `/vendor`) remain strictly read-only and cryptographically verified by `dm-verity`.
2. **Zero Wake-Locks & Memory Allocation:** The target package is uninstalled for the primary user (`user 0`). Its services cannot be scheduled, its broadcast receivers cannot fire, and it consumes 0 MB of RAM.
3. **Instant Reversibility:** Because the original APK remains in the read-only system image, packages can be restored instantly without internet access or factory resets:
   ```bash
   adb shell cmd package install-existing <package_name>
   ```

---

## Repository Structure

```
HyperDebloat-Agent/
├── .github/
│   └── workflows/
│       └── validate-json.yml     # Automated schema validation & shellcheck CI
├── agent/
│   └── protocol.md               # Deterministic execution protocol for AI agents
├── backups/                      # Auto-generated pre-flight package snapshots
├── data/
│   └── packages.json             # Machine-readable categorized package registry
├── logs/                         # Execution logs & last_removed.txt rollback tracker
├── scripts/
│   ├── audit.sh                  # Pre-flight query, fingerprint & package backup
│   ├── debloat.sh                # Interactive/batch debloat engine with validation
│   ├── harden-privacy.sh         # DoT Private DNS & captive portal neutralization
│   └── restore.sh                # One-click restoration of uninstalled packages
├── LANDING_PAGE.md               # Dual-language guide (English & עברית)
├── LICENSE                       # MIT License
└── README.md                     # Project documentation & quick start
```

---

## Package Safety Classification

All target packages in [`data/packages.json`](data/packages.json) are classified into three strict tiers:

| Tier | Description | Examples | Default Action |
| :--- | :--- | :--- | :--- |
| **`SAFE`** | Telemetry, ad pushers, duplicate bloat, and thermal throttlers. Removing these causes zero system instability or functional breakage. | `com.miui.analytics`<br>`com.miui.msa.global`<br>`com.xiaomi.joyose`<br>`com.miui.hybrid`<br>`com.miui.bugreport`<br>`com.miui.yellowpage` | **Uninstalled by default** |
| **`CAUTION`** | Useful stock apps or cloud sync providers. Safe to remove only if you do not use that specific service or have a 3rd party replacement installed. | `com.miui.cloudservice`<br>`com.miui.gallery`<br>`com.miui.cleanmaster`<br>`com.mi.globalbrowser`<br>`com.google.android.apps.tachyon` | **Requires explicit flag** (`--tier CAUTION`) |
| **`CRITICAL`** | Essential OS components, telephony services, security framework, or default launcher. | `com.miui.securitycenter`<br>`com.android.incallui`<br>`com.android.systemui`<br>`com.miui.home`<br>`com.android.phone`<br>`com.google.android.gms` | **HARD BLOCKED** (Scripts and agents will refuse to touch) |

---

## Quick Start Guide

### 1. Requirements
- Linux, macOS, or Windows (with Bash, WSL, or Git Bash).
- Android Debug Bridge (`adb`) installed and configured in your PATH.
- USB cable.

### 2. Device Setup (Crucial for Xiaomi HyperOS / MIUI)
1. Navigate to **Settings > About Phone**.
2. Tap **OS Version** (or **MIUI Version**) **7 times** to unlock Developer Options.
3. Open **Settings > Additional Settings > Developer Options**.
4. Enable **USB Debugging**.
5. **IMPORTANT:** Scroll down and enable **USB Debugging (Security Settings)**.
   > *Note:* Xiaomi requires a connected Mi Account and an inserted SIM card to authorize this security toggle. This toggle permits `pm uninstall` commands via ADB.

### 3. Step 1: Pre-Flight Audit
Connect your phone and run:
```bash
chmod +x scripts/*.sh
./scripts/audit.sh
```
The audit script validates ADB communication, captures device fingerprints (`ro.product.model`, `ro.miui.ui.version.name`), verifies battery level, saves a complete backup snapshot in `backups/installed_packages_<timestamp>.txt`, and prints detected debloat candidates.

### 4. Step 2: Execute Debloat
```bash
# Safe Interactive Mode (prompts before proceeding)
./scripts/debloat.sh --tier SAFE

# Autonomous / AI Agent Mode (batch mode, no prompts)
./scripts/debloat.sh --batch --tier SAFE

# Dry Run Simulation (shows what would be executed)
./scripts/debloat.sh --dry-run --tier SAFE

# Debloat a single package ID
./scripts/debloat.sh --package com.xiaomi.joyose
```

### 5. Step 3: Privacy & Network Hardening
Block tracking queries at the DNS layer and prevent periodic captive portal reporting:
```bash
# Apply Quad9 DNS-over-TLS (Strict privacy, malware blocking, no logs)
./scripts/harden-privacy.sh --dns quad9

# Or apply AdGuard DNS-over-TLS (Ad & tracker blocking)
./scripts/harden-privacy.sh --dns adguard
```

### 6. Step 4: Instant One-Click Restoration
Want to bring back any removed package?
```bash
# Restore all packages removed during the last session
./scripts/restore.sh

# Or restore a specific package ID
./scripts/restore.sh --package com.miui.gallery

# Or restore all SAFE packages from the registry
./scripts/restore.sh --all-safe
```

---

## Autonomous AI Agent Integration

This framework is built to be consumed directly by autonomous coding agents (Claude Code, Cursor, MCP ADB agents):

1. **Structured Package Database:** Agents parse `data/packages.json` directly for package metadata, dependencies, impact analysis, and commands.
2. **Deterministic Protocol:** Detailed operational steps, state machines, heartbeat checks, and rollback triggers are specified in [`agent/protocol.md`](agent/protocol.md).
3. **Non-Interactive Batch Mode:** All scripts support `--batch` / `-y` and emit standard POSIX exit codes (0 for success, non-zero for specific errors) for automated pipeline orchestration.

---

## Dual-Language Landing Page & Hebrew Guide

For marketing copy, community overviews, and a comprehensive guide in Hebrew, refer to:
👉 [**LANDING_PAGE.md**](LANDING_PAGE.md) (כולל הסבר מפורט בעברית על יתרונות ה-Non-Root והמדריך המלא למכשירי שיאומי).

---

## Security & Privacy Notice

HyperDebloat-Agent is an open-source, community-driven framework.
- **No telemetry is collected by this project.**
- **No private user or device identifiers are stored.**
- All scripts run locally on your machine via direct ADB communication with your device.

---

## License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
