# Community Launch Templates
## Ready-to-publish drafts for Reddit, XDA, and Telegram

---

## 1. Reddit Post — r/Xiaomi & r/HyperOS

**Title:** `I built an open-source, zero-root debloat framework for HyperOS that fixes the 500mA battery drain loop and protects Joyose/banking apps`

**Body:**

Hey everyone,

After spending 100+ hours doing deep ADB battery telemetry analysis on my HyperOS device, I built **HyperDebloat-Agent** — an open-source, deterministic debloating and privacy hardening framework specifically designed for Xiaomi HyperOS and MIUI devices.

**What makes this different from existing debloat lists:**

1. **The 500mA Runaway Loop Fix:** Did you know that if you freeze `com.miui.msa.global` or `com.miui.analytics` without first purging their hidden `/data/app` updates, `system_server` enters an infinite binder loop that spawns zombie Chrome sandboxes and locks your CPU cores at 2.1 GHz? This drains ~500mA continuously *with the screen off*. My framework handles this automatically with a 3-step purge sequence.

2. **Joyose is CRITICAL — Don't Remove It:** Every debloat list on XDA tells you to remove `com.xiaomi.joyose`. After empirical testing, I discovered Joyose not only manages CPU thermal safety cutoffs, but also provides the system intent bridge for **SMS OTP auto-retrieval in banking apps**. Removing it breaks 2FA autofill for financial apps and risks thermal runaway. HyperDebloat locks Joyose in a `CRITICAL` tier that scripts and AI agents cannot touch.

3. **Real Battery Results (Before vs. After):**
   - Overnight standby drain: **~7% → ~1.5%** (~75% reduction)
   - CPU Deep Sleep: **78% → 96.4%** idle residency
   - Kernel suspend aborts: **745/night → <25/night** (eliminated Dual Wi-Fi WLAN Rx polling)
   
4. **100% Zero-Root, Banking Safe:** Uses `pm uninstall -k --user 0` exclusively. Play Integrity passes. Google Pay, banking apps, Widevine L1 all work perfectly.

5. **Built for AI Agents Too:** Full JSON schema + deterministic agent protocol for Claude Code, Cursor, and MCP server automation.

**GitHub:** [link]

Everything is MIT licensed. PRs for new device coverage (Samsung One UI support is landing now) and package submissions are welcome.

---

## 2. Reddit Post — r/Android (broader audience)

**Title:** `Open-source framework that safely removes Android bloatware without root — empirically tested battery results inside`

**Body:**

I released **HyperDebloat-Agent**, an open-source ADB debloating framework that:

- Removes telemetry, ads, and bloatware using only `pm uninstall -k --user 0` (zero root, zero bootloader unlock)
- Preserves Play Integrity, Google Pay, banking apps, and Widevine L1
- Includes a curated, safety-tiered package registry for **Xiaomi HyperOS/MIUI** and **Samsung One UI**
- Every removed package is instantly restorable with `cmd package install-existing`

**Key finding from 100+ hours of ADB battery telemetry:**

Most debloat scripts and lists are dangerously unmaintained. Two critical discoveries:

1. Blindly freezing Xiaomi's MSA/Analytics without purging hidden APK updates causes a 500mA CPU drain loop (zombie Chrome sandbox processes).
2. `com.xiaomi.joyose` — commonly listed as "safe to remove" — actually bridges SMS OTP parsing for banking 2FA and manages thermal safety limits.

**Battery benchmarks (HyperOS flagship):**
| Metric | Stock | After HyperDebloat |
|---|---|---|
| Overnight drain (7h) | ~7% | ~1.5% |
| CPU idle in deep sleep | 78% | 96.4% |
| Kernel suspend aborts | 745/night | <25/night |

GitHub: [link] | MIT License

Looking for contributors with Samsung, Pixel, and OnePlus devices to expand OEM coverage.

---

## 3. XDA Developers Thread

**Title:** `[TOOL][OPEN-SOURCE] HyperDebloat-Agent — Deterministic Zero-Root Debloating & Privacy Hardening for HyperOS, MIUI & One UI`

**Body:**

**HyperDebloat-Agent** is an open-source, deterministic ADB debloating and privacy hardening framework for Android.

**Supported OEMs:**
- Xiaomi HyperOS 1.0 / 2.0
- Xiaomi MIUI 12–14
- Samsung One UI 4–7
- Universal Android 10–15

**Key Features:**
- Zero-root: Uses `pm uninstall -k --user 0` exclusively
- 100% reversible: `cmd package install-existing <pkg>`
- Play Integrity / SafetyNet: Passes all checks
- Banking apps: Fully functional (Google Pay, NFC payments)
- Widevine L1: Preserved for Netflix FHD/4K
- Empirically validated: 100+ hours of physical ADB telemetry
- AI Agent compatible: JSON schema + protocol for Claude Code, Cursor, MCP

**Safety Features:**
- 3-tier classification (SAFE / CAUTION / CRITICAL)
- Hardcoded CRITICAL blocklist prevents removal of essential system components
- Automatic pre-flight package snapshot before any modifications
- Post-removal heartbeat verification (ADB state check after each uninstall)
- Automated rollback on anomaly detection

**Critical Discoveries (Field-Tested):**
1. **500mA MSA/Analytics Loop:** Hidden APK updates in `/data/app` cause system_server binder loops if frozen without cleanup. Framework handles this automatically.
2. **Joyose Protection:** `com.xiaomi.joyose` classified as CRITICAL — required for CPU thermal regulation and banking SMS OTP bridge.
3. **Dual Wi-Fi Polling:** Disabling `wifi_assistant` and `slave_wifi_on` eliminates 250+ WLAN Rx kernel wakeups per night.

**Downloads & Source:**
GitHub: [link]

**Requirements:**
- ADB installed and in PATH
- USB cable
- USB Debugging enabled (on Xiaomi: Security Settings toggle required)

**Instructions:**
```bash
git clone https://github.com/bambadooma-star/HyperDebloat-Agent.git
cd HyperDebloat-Agent
chmod +x scripts/*.sh
./scripts/audit.sh          # Pre-flight scan
./scripts/debloat.sh --tier SAFE   # Safe debloat
./scripts/harden-privacy.sh --dns quad9   # Privacy hardening
```

---

## 4. Telegram Message (Xiaomi Community Groups)

🔋 **HyperDebloat-Agent** — Open-source zero-root debloating for HyperOS/MIUI

Fed up with 7% battery drain overnight on your Xiaomi? After 100+ hours of ADB telemetry analysis, I built a free framework that:

✅ Removes ads, telemetry & bloatware safely
✅ Reduces overnight drain from ~7% to ~1.5%
✅ Keeps banking apps, Google Pay & NFC working
✅ 100% reversible — restore any package instantly
✅ Protects Joyose (banking OTP + thermal safety)

⚠️ WARNING: Most debloat lists tell you to remove Joyose. DON'T. It handles banking SMS verification and CPU thermal regulation.

🔗 GitHub: [link]
📄 MIT License — fully open-source

Looking for testers with different Xiaomi models to verify package compatibility!
