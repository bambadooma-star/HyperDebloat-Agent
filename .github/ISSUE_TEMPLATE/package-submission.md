---
name: "\U0001F4E6 New Package Submission"
about: Submit a new bloatware/telemetry package for inclusion in the registry
title: "[PACKAGE] com.vendor.package.name — Human-Readable Name"
labels: ["package-submission", "needs-verification"]
---

## Package Details

- **Package ID:** `com.vendor.package.name`
- **Human-Readable Name:** 
- **Target OS:** <!-- HyperOS / One UI / Universal / Other -->
- **Proposed Tier:** <!-- SAFE / CAUTION / CRITICAL -->
- **Category:** <!-- telemetry / adware / bloatware / cloud_sync / core_framework -->

## Device Tested On

- **Device Model:** <!-- e.g., Xiaomi 14 Pro, Samsung Galaxy S24 -->
- **OS Version:** <!-- e.g., HyperOS 2.0, One UI 6.1 -->
- **Android Version:** <!-- e.g., Android 15, API 35 -->

## Verification Checklist

- [ ] I have uninstalled this package via `pm uninstall -k --user 0` on a physical device.
- [ ] I have verified the device remains stable after removal (no bootloop, no SystemUI crash).
- [ ] I have verified the package can be restored via `cmd package install-existing`.
- [ ] I have checked that banking apps and Google Pay still function after removal.
- [ ] I have stripped all personal identifiers (IMEI, serial, MAC) from this submission.

## Impact Summary

<!-- Describe what happens when this package is removed. Be specific about battery, RAM, or stability changes observed. -->

## Additional Context

<!-- Any screenshots, batterystats excerpts (PII-scrubbed), or community references (XDA/Reddit threads) supporting this submission. -->
