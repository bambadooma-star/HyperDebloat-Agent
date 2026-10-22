---
name: "\U0001F50B Battery Telemetry Report"
about: Share empirical battery/wakelock data from your device (before vs. after debloating)
title: "[TELEMETRY] Device Model — Before/After HyperDebloat Results"
labels: ["telemetry-data", "community-verified"]
---

## Device Information

- **Device Model:** <!-- e.g., Redmi Note 13 Pro+, Galaxy A55 -->
- **OS Version:** <!-- e.g., HyperOS 1.0.8, One UI 6.1 -->
- **Android Version:** <!-- e.g., Android 14, API 34 -->
- **Physical RAM:** <!-- e.g., 8GB, 12GB -->

## Before HyperDebloat (Stock)

- **Overnight Standby Drain (7-8h):** <!-- e.g., ~7.2% total (~1.0%/hr) -->
- **CPU Idle in Deep Sleep:** <!-- e.g., ~78% -->
- **Notable Wakelocks:** <!-- e.g., "WLAN Rx Worker: 312 wakeups, GMS NetworkLocation: 890 wakeups" -->
- **ANRs Observed:** <!-- e.g., "Facebook, Moovit — 'No response to onStopJob'" -->

## After HyperDebloat

- **Debloat Tier Used:** <!-- SAFE / SAFE + CAUTION -->
- **Privacy Hardening Applied:** <!-- Yes/No, which DNS provider -->
- **Overnight Standby Drain (7-8h):** <!-- e.g., ~1.8% total (~0.25%/hr) -->
- **CPU Idle in Deep Sleep:** <!-- e.g., ~96.4% -->
- **Notable Changes:** <!-- e.g., "WLAN Rx Worker: 8 wakeups, zero ANRs" -->

## Privacy Confirmation

- [ ] I have stripped all personal identifiers (IMEI, serial numbers, MAC addresses, Wi-Fi SSIDs) from this report.
- [ ] No banking app names or financial account details are included.

## Raw Data (Optional)

<!-- Paste PII-scrubbed excerpts from `adb shell dumpsys batterystats` or `adb shell dumpsys alarm` if available. Use code blocks. -->
