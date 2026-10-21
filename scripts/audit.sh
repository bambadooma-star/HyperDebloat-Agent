#!/usr/bin/env bash
# ==============================================================================
# HyperDebloat-Agent :: scripts/audit.sh
# ------------------------------------------------------------------------------
# Pre-flight device query, fingerprinting, battery check, and package snapshot.
# Deterministic, safe, non-root Android debloating framework.
# ==============================================================================

set -euo pipefail

# --- Color Codes & Terminal Styling ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Determine script directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DATA_FILE="${ROOT_DIR}/data/packages.json"
BACKUP_DIR="${ROOT_DIR}/backups"
LOGS_DIR="${ROOT_DIR}/logs"

mkdir -p "${BACKUP_DIR}" "${LOGS_DIR}"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
SNAPSHOT_FILE="${BACKUP_DIR}/installed_packages_${TIMESTAMP}.txt"
LATEST_SNAPSHOT_LINK="${BACKUP_DIR}/installed_packages_latest.txt"
AUDIT_LOG="${LOGS_DIR}/audit_${TIMESTAMP}.log"

# --- Logging Helpers ---
log_info()  { echo -e "${CYAN}[INFO]${NC}  $*" | tee -a "${AUDIT_LOG}"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*" | tee -a "${AUDIT_LOG}"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "${AUDIT_LOG}"; }
log_err()   { echo -e "${RED}[ERROR]${NC} $*" | tee -a "${AUDIT_LOG}" >&2; }
log_step()  { echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$*${NC}" | tee -a "${AUDIT_LOG}"; }

echo -e "${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${CYAN}   HyperDebloat-Agent :: Pre-Flight Audit & Snapshot  ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"

# ------------------------------------------------------------------------------
# 1. ADB Binary Check
# ------------------------------------------------------------------------------
log_step "Checking Android Debug Bridge (ADB) installation..."
if ! command -v adb >/dev/null 2>&1; then
    log_err "ADB executable not found in PATH."
    log_err "Please install Android Platform Tools and ensure 'adb' is accessible."
    exit 2
fi
ADB_VERSION="$(adb version | head -n 1)"
log_ok "ADB detected: ${ADB_VERSION}"

# ------------------------------------------------------------------------------
# 2. Device Connectivity & Authorization Verification
# ------------------------------------------------------------------------------
log_step "Validating device connection and authorization status..."
DEVICES_OUTPUT="$(adb devices -l)"

# Count active devices
ATTACHED_COUNT="$(echo "${DEVICES_OUTPUT}" | sed '1d' | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')"

if [ "${ATTACHED_COUNT}" -eq 0 ]; then
    log_err "No Android device detected over USB or Wireless ADB."
    log_err "Steps to resolve:"
    log_err "  1. Connect your device via USB cable."
    log_err "  2. Enable Developer Options: Settings > About Phone > Tap 'OS version / MIUI version' 7 times."
    log_err "  3. In Developer Options, enable 'USB Debugging'."
    log_err "  4. On Xiaomi/HyperOS/MIUI, MUST enable 'USB Debugging (Security Settings)'."
    exit 3
fi

# Check for unauthorized status
if echo "${DEVICES_OUTPUT}" | grep -q "unauthorized"; then
    log_err "Device attached but UNAUTHORIZED."
    log_err "Check your phone's screen and approve the 'Allow USB debugging?' dialog prompt."
    exit 4
fi

# Check for offline status
if echo "${DEVICES_OUTPUT}" | grep -q "offline"; then
    log_err "Device attached but reported as OFFLINE."
    log_err "Try reconnecting the cable or restarting ADB: 'adb kill-server && adb start-server'."
    exit 5
fi

# Resolve target serial if single device
DEVICE_SERIAL="$(adb get-serialno 2>/dev/null || echo "default")"
log_ok "Device connected and authorized: Serial [${DEVICE_SERIAL}]"

# ------------------------------------------------------------------------------
# 3. Hardware & OS Fingerprint Inspection
# ------------------------------------------------------------------------------
log_step "Querying device properties via ADB getprop..."

get_device_prop() {
    local prop_key="$1"
    adb shell getprop "${prop_key}" 2>/dev/null | tr -d '\r' || echo "Unknown"
}

PROP_BRAND="$(get_device_prop "ro.product.brand")"
PROP_MANUFACTURER="$(get_device_prop "ro.product.manufacturer")"
PROP_MODEL="$(get_device_prop "ro.product.model")"
PROP_DEVICE="$(get_device_prop "ro.product.device")"
PROP_ANDROID_VER="$(get_device_prop "ro.build.version.release")"
PROP_SDK="$(get_device_prop "ro.build.version.sdk")"
PROP_BUILD_ID="$(get_device_prop "ro.build.display.id")"

# Xiaomi / HyperOS / MIUI Specific Props
PROP_MIUI_VER="$(get_device_prop "ro.miui.ui.version.name")"
PROP_HYPEROS_FLAG="$(get_device_prop "ro.mi.os.version.name")"
PROP_MIUI_INCR="$(get_device_prop "ro.build.version.incremental")"

# Battery Level Verification
BATTERY_LEVEL="$(adb shell dumpsys battery 2>/dev/null | grep -i "level:" | awk '{print $2}' | tr -d '\r' || echo "0")"

echo -e "  - Manufacturer : ${BOLD}${PROP_MANUFACTURER}${NC}"
echo -e "  - Model        : ${BOLD}${PROP_MODEL}${NC} (${PROP_DEVICE})"
echo -e "  - Android Ver  : ${BOLD}${PROP_ANDROID_VER}${NC} (API ${PROP_SDK})"
echo -e "  - OS UI String : ${BOLD}${PROP_MIUI_VER:-AOSP / Standard}${NC} ${PROP_HYPEROS_FLAG:+(HyperOS: $PROP_HYPEROS_FLAG)}"
echo -e "  - Build ID     : ${PROP_BUILD_ID}"
echo -e "  - Battery Lvl  : ${BOLD}${BATTERY_LEVEL}%${NC}"

if [ "${BATTERY_LEVEL}" -ne 0 ] && [ "${BATTERY_LEVEL}" -lt 20 ]; then
    log_warn "Battery level (${BATTERY_LEVEL}%) is below recommended safe threshold (20%)."
    log_warn "Please connect charger before running debloat operations."
fi

# ------------------------------------------------------------------------------
# 4. Export Installed Packages Snapshot
# ------------------------------------------------------------------------------
log_step "Capturing complete installed package snapshot..."
adb shell pm list packages | sed 's/^package://' | tr -d '\r' | sort > "${SNAPSHOT_FILE}"
TOTAL_INSTALLED="$(wc -l < "${SNAPSHOT_FILE}" | tr -d ' ')"

# Maintain latest pointer
cp "${SNAPSHOT_FILE}" "${LATEST_SNAPSHOT_LINK}"

log_ok "Exported ${TOTAL_INSTALLED} packages to snapshot: ${SNAPSHOT_FILE}"
log_ok "Updated latest pointer: ${LATEST_SNAPSHOT_LINK}"

# ------------------------------------------------------------------------------
# 5. Cross-Reference against Package Database
# ------------------------------------------------------------------------------
log_step "Cross-referencing device packages with HyperDebloat registry..."

if [ ! -f "${DATA_FILE}" ]; then
    log_err "Package database not found at: ${DATA_FILE}"
    exit 1
fi

# Parse packages using python helper (100% portable across Linux/Mac/Windows)
AUDIT_SUMMARY="$(python3 -c "
import json, sys

with open(r'${DATA_FILE}', 'r', encoding='utf-8') as f:
    db = json.load(f)

with open(r'${SNAPSHOT_FILE}', 'r', encoding='utf-8') as f:
    installed = set(line.strip() for line in f if line.strip())

safe_found = []
caution_found = []
critical_found = []

for item in db.get('packages', []):
    pkg = item['package']
    tier = item['tier']
    name = item['name']
    cat = item['category']
    if pkg in installed:
        if tier == 'SAFE':
            safe_found.append((pkg, name, cat))
        elif tier == 'CAUTION':
            caution_found.append((pkg, name, cat))
        elif tier == 'CRITICAL':
            critical_found.append((pkg, name, cat))

print(f'SAFE_COUNT={len(safe_found)}')
print(f'CAUTION_COUNT={len(caution_found)}')
print(f'CRITICAL_COUNT={len(critical_found)}')

print('---DETAILS---')
for p, n, c in safe_found:
    print(f'SAFE|{p}|{n}|{c}')
for p, n, c in caution_found:
    print(f'CAUTION|{p}|{n}|{c}')
for p, n, c in critical_found:
    print(f'CRITICAL|{p}|{n}|{c}')
" 2>/dev/null || python -c "
import json, sys

with open(r'${DATA_FILE}', 'r', encoding='utf-8') as f:
    db = json.load(f)

with open(r'${SNAPSHOT_FILE}', 'r', encoding='utf-8') as f:
    installed = set(line.strip() for line in f if line.strip())

safe_found = []
caution_found = []
critical_found = []

for item in db.get('packages', []):
    pkg = item['package']
    tier = item['tier']
    name = item['name']
    cat = item['category']
    if pkg in installed:
        if tier == 'SAFE':
            safe_found.append((pkg, name, cat))
        elif tier == 'CAUTION':
            caution_found.append((pkg, name, cat))
        elif tier == 'CRITICAL':
            critical_found.append((pkg, name, cat))

print(f'SAFE_COUNT={len(safe_found)}')
print(f'CAUTION_COUNT={len(caution_found)}')
print(f'CRITICAL_COUNT={len(critical_found)}')

print('---DETAILS---')
for p, n, c in safe_found:
    print(f'SAFE|{p}|{n}|{c}')
for p, n, c in caution_found:
    print(f'CAUTION|{p}|{n}|{c}')
for p, n, c in critical_found:
    print(f'CRITICAL|{p}|{n}|{c}')
")"

SAFE_COUNT="$(echo "${AUDIT_SUMMARY}" | grep '^SAFE_COUNT=' | cut -d'=' -f2)"
CAUTION_COUNT="$(echo "${AUDIT_SUMMARY}" | grep '^CAUTION_COUNT=' | cut -d'=' -f2)"
CRITICAL_COUNT="$(echo "${AUDIT_SUMMARY}" | grep '^CRITICAL_COUNT=' | cut -d'=' -f2)"

echo -e "\n${BOLD}Audit Results:${NC}"
echo -e "  - ${GREEN}SAFE Debloat Candidates Found   : ${SAFE_COUNT}${NC}"
echo -e "  - ${YELLOW}CAUTION Candidates Found        : ${CAUTION_COUNT}${NC}"
echo -e "  - ${RED}CRITICAL Core System Protected  : ${CRITICAL_COUNT}${NC}"

echo -e "\n${BOLD}Identified Target Packages on Device:${NC}"
echo "--------------------------------------------------------------------------------"
printf "%-10s | %-32s | %-32s\n" "TIER" "PACKAGE ID" "NAME"
echo "--------------------------------------------------------------------------------"
echo "${AUDIT_SUMMARY}" | grep -E '^(SAFE|CAUTION|CRITICAL)\|' | while IFS='|' read -r tier pkg name cat; do
    case "${tier}" in
        SAFE)
            printf "${GREEN}%-10s${NC} | %-32s | %-32s\n" "[SAFE]" "${pkg}" "${name}"
            ;;
        CAUTION)
            printf "${YELLOW}%-10s${NC} | %-32s | %-32s\n" "[CAUTION]" "${pkg}" "${name}"
            ;;
        CRITICAL)
            printf "${RED}%-10s${NC} | %-32s | %-32s\n" "[CRITICAL]" "${pkg}" "${name}"
            ;;
    esac
done
echo "--------------------------------------------------------------------------------"

log_ok "Audit complete. Safe to proceed with scripts/debloat.sh"
exit 0
