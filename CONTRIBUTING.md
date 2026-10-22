# Contributing to HyperDebloat-Agent

Thank you for your interest in contributing to HyperDebloat-Agent! This project thrives on community-driven package research, empirical device testing, and safety verification.

---

## How You Can Contribute

### 1. Submit New Package Entries

The most impactful contribution is expanding [`data/packages.json`](data/packages.json) with new bloatware, telemetry, or adware packages for supported OEMs.

**To submit a new package entry:**

1. Fork this repository.
2. Add your entry to `data/packages.json` following the exact schema:

```json
{
  "package": "com.vendor.package.name",
  "name": "Human-Readable Package Name",
  "target_os": "HyperOS|One UI|Universal",
  "tier": "SAFE|CAUTION|CRITICAL",
  "category": "telemetry|adware|bloatware|cloud_sync|core_framework",
  "uninstall_cmd": "pm uninstall -k --user 0 com.vendor.package.name",
  "restore_cmd": "cmd package install-existing com.vendor.package.name",
  "impact_summary": "Clear, specific description of what happens when this package is removed.",
  "dependencies": []
}
```

3. Run the CI validation locally:
```bash
python3 -c "
import json
with open('data/packages.json') as f:
    data = json.load(f)
print(f'Validated {len(data[\"packages\"])} packages')
"
```

4. Submit a Pull Request with:
   - The device model and OS version you tested on.
   - Whether you verified the package can be safely restored via `cmd package install-existing`.
   - Any observations about battery, performance, or stability impact.

### 2. Safety Tier Classification Rules

Please follow these strict classification guidelines:

| Tier | Criteria | `uninstall_cmd` |
| :--- | :--- | :--- |
| **`SAFE`** | Telemetry, ads, duplicate bloat. Removal causes zero system instability. Verified on at least one physical device. | `pm uninstall -k --user 0 <pkg>` |
| **`CAUTION`** | Useful stock apps or cloud services. Safe to remove only if the user has an alternative or does not use the feature. | `pm uninstall -k --user 0 <pkg>` |
| **`CRITICAL`** | Essential OS components. Removal causes bootloop, breaks telephony, breaks lockscreen, or disables core system functions. | **`BLOCKED`** (hardcoded) |

> **⚠️ When in doubt, classify as `CAUTION` rather than `SAFE`.** It is always better to be conservative. We can promote a package to `SAFE` later after community verification, but a wrongly classified `SAFE` package that causes a bootloop destroys user trust.

### 3. Report Empirical Battery & Stability Findings

If you have access to a physical device and can run `adb shell dumpsys batterystats`, we welcome empirical telemetry contributions:

- Overnight standby drain measurements (before vs. after debloating).
- Wakelock and suspend abort counts.
- ANR (Application Not Responding) observations.
- Thermal behavior changes.

Please **strip all personal identifiers** (IMEI, serial numbers, MAC addresses, Wi-Fi SSIDs) from any data you submit.

### 4. Expand OEM Coverage

We are actively seeking contributors with devices from:
- **Samsung One UI** (Galaxy S, A, M, F series)
- **Google Pixel** (Stock Android / Tensor)
- **OnePlus OxygenOS / ColorOS**
- **Oppo ColorOS / Realme UI**
- **Nothing OS**
- **Motorola MyUX**

### 5. Fix ShellCheck Warnings & Improve Scripts

All shell scripts must pass [ShellCheck](https://www.shellcheck.net/) with zero warnings. If you find an issue:

1. Run ShellCheck on the affected script.
2. Fix the warning.
3. Verify the script still passes `bash -n scripts/<name>.sh`.
4. Submit a PR.

---

## Code of Conduct

- **Safety First:** Never submit a package classification that you have not personally verified on a physical device or that you are unsure about.
- **Privacy:** Never include personal data, device serial numbers, or identifiable information in commits, issues, or pull requests.
- **Respect:** Be constructive in discussions. This project serves a global community of power users who depend on accurate, safe package data.

---

## Development Setup

```bash
# Clone the repository
git clone https://github.com/bambadooma-star/HyperDebloat-Agent.git
cd HyperDebloat-Agent

# Validate the package registry
python3 -c "
import json
with open('data/packages.json') as f:
    data = json.load(f)
print(f'Validated {len(data[\"packages\"])} packages')
"

# Check shell script syntax
bash -n scripts/audit.sh
bash -n scripts/debloat.sh
bash -n scripts/harden-privacy.sh
bash -n scripts/restore.sh
```

---

## License

By contributing to HyperDebloat-Agent, you agree that your contributions will be licensed under the [MIT License](LICENSE).
