#!/usr/bin/env bash
# ==============================================================================
# HyperDebloat-Agent :: scripts/debloat.sh
# ------------------------------------------------------------------------------
# Safe interactive / batch debloating execution engine with strict validation.
# Non-Root, reversible, deterministic user-space uninstaller.
# ==============================================================================

set -euo pipefail

# --- Color Codes & Terminal Styling ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Determine script directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && (pwd -W 2>/dev/null || pwd))"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && (pwd -W 2>/dev/null || pwd))"
DATA_FILE="${ROOT_DIR}/data/packages.json"
BACKUP_DIR="${ROOT_DIR}/backups"
LOGS_DIR="${ROOT_DIR}/logs"
LAST_REMOVED_FILE="${LOGS_DIR}/last_removed.txt"

mkdir -p "${BACKUP_DIR}" "${LOGS_DIR}"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
DEBLOAT_LOG="${LOGS_DIR}/debloat_${TIMESTAMP}.log"

# --- Logging Helpers ---
log_info()  { echo -e "${CYAN}[INFO]${NC}  $*" | tee -a "${DEBLOAT_LOG}"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*" | tee -a "${DEBLOAT_LOG}"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "${DEBLOAT_LOG}"; }
log_err()   { echo -e "${RED}[ERROR]${NC} $*" | tee -a "${DEBLOAT_LOG}" >&2; }
log_step()  { echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$*${NC}" | tee -a "${DEBLOAT_LOG}"; }

# --- Argument Parsing Defaults ---
BATCH_MODE=false
DRY_RUN=false
TARGET_TIER="SAFE"
SPECIFIC_PACKAGE=""

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -y, --batch             Execute without interactive confirmation prompts (Agent mode)
  -t, --tier <TIER>       Target safety tier: SAFE (default) or CAUTION
  -p, --package <PKG>     Debloat a single specific package ID
  -d, --dry-run           Simulate actions without executing commands on the device
  -h, --help              Show this help message and exit

Examples:
  ./scripts/debloat.sh --tier SAFE
  ./scripts/debloat.sh --batch --tier SAFE
  ./scripts/debloat.sh --package com.xiaomi.joyose
  ./scripts/debloat.sh --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--batch|--yes)
            BATCH_MODE=true
            shift
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -t|--tier)
            TARGET_TIER="$(echo "$2" | tr '[:lower:]' '[:upper:]')"
            if [[ "${TARGET_TIER}" != "SAFE" && "${TARGET_TIER}" != "CAUTION" ]]; then
                echo "Invalid tier: $2. Allowed values: SAFE, CAUTION"
                exit 1
            fi
            shift 2
            ;;
        -p|--package)
            SPECIFIC_PACKAGE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

echo -e "${BOLD}${CYAN}======================================================${NC}"
echo -e "${BOLD}${CYAN}   HyperDebloat-Agent :: Execution Engine             ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"
echo -e "  - Mode      : $([ "${BATCH_MODE}" = true ] && echo "${MAGENTA}BATCH (Autonomous)${NC}" || echo "${GREEN}INTERACTIVE${NC}")"
echo -e "  - Tier      : ${BOLD}${TARGET_TIER}${NC}"
echo -e "  - Dry Run   : $([ "${DRY_RUN}" = true ] && echo "${YELLOW}YES (Simulation)${NC}" || echo "NO (Live ADB Execution)")"
[ -n "${SPECIFIC_PACKAGE}" ] && echo -e "  - Target Pkg: ${BOLD}${SPECIFIC_PACKAGE}${NC}"
echo -e "  - Log File  : ${DEBLOAT_LOG}"
echo -e "------------------------------------------------------"

# ------------------------------------------------------------------------------
# 1. Device Health & Pre-Flight Validation
# ------------------------------------------------------------------------------
log_step "Validating ADB connection..."
if ! command -v adb >/dev/null 2>&1; then
    log_err "ADB executable not found. Aborting."
    exit 2
fi

ADB_STATE="$(adb get-state 2>/dev/null || echo "disconnected")"
if [ "${ADB_STATE}" != "device" ]; then
    log_err "Device is not ready. ADB state is: '${ADB_STATE}'."
    log_err "Ensure device is connected, unlocked, and USB Debugging is authorized."
    exit 3
fi

# ------------------------------------------------------------------------------
# 2. Mandatory Snapshot Rule
# ------------------------------------------------------------------------------
SNAPSHOT_FILE="${BACKUP_DIR}/installed_packages_${TIMESTAMP}.txt"
log_step "Executing mandatory pre-flight package snapshot..."
adb shell pm list packages | sed 's/^package://' | tr -d '\r' | sort > "${SNAPSHOT_FILE}"
cp "${SNAPSHOT_FILE}" "${BACKUP_DIR}/installed_packages_latest.txt"
log_ok "Saved device package snapshot: ${SNAPSHOT_FILE}"

# Retrieve set of installed packages on device for fast lookup
INSTALLED_PKGS_MAP="$(adb shell pm list packages | sed 's/^package://' | tr -d '\r')"

# ------------------------------------------------------------------------------
# 3. Load & Filter Packages from JSON Registry
# ------------------------------------------------------------------------------
log_step "Reading package registry: ${DATA_FILE}..."

if [ ! -f "${DATA_FILE}" ]; then
    log_err "Package database missing: ${DATA_FILE}"
    exit 1
fi

CANDIDATES_LIST="$(python3 -c "
import json, sys

with open(r'${DATA_FILE}', 'r', encoding='utf-8') as f:
    db = json.load(f)

specific_pkg = '${SPECIFIC_PACKAGE}'
target_tier = '${TARGET_TIER}'

candidates = []
for item in db.get('packages', []):
    pkg = item['package']
    tier = item['tier']
    name = item['name']
    cmd = item['uninstall_cmd']
    impact = item.get('impact_summary', '')
    
    # If specific package requested
    if specific_pkg:
        if pkg == specific_pkg:
            candidates.append(f'{pkg}|{tier}|{name}|{cmd}|{impact}')
            break
        continue
    
    # Match tier rules
    if target_tier == 'SAFE' and tier == 'SAFE':
        candidates.append(f'{pkg}|{tier}|{name}|{cmd}|{impact}')
    elif target_tier == 'CAUTION' and tier in ('SAFE', 'CAUTION'):
        candidates.append(f'{pkg}|{tier}|{name}|{cmd}|{impact}')

for c in candidates:
    print(c)
" 2>/dev/null || python -c "
import json, sys

with open(r'${DATA_FILE}', 'r', encoding='utf-8') as f:
    db = json.load(f)

specific_pkg = '${SPECIFIC_PACKAGE}'
target_tier = '${TARGET_TIER}'

candidates = []
for item in db.get('packages', []):
    pkg = item['package']
    tier = item['tier']
    name = item['name']
    cmd = item['uninstall_cmd']
    impact = item.get('impact_summary', '')
    
    if specific_pkg:
        if pkg == specific_pkg:
            candidates.append(f'{pkg}|{tier}|{name}|{cmd}|{impact}')
            break
        continue
    
    if target_tier == 'SAFE' and tier == 'SAFE':
        candidates.append(f'{pkg}|{tier}|{name}|{cmd}|{impact}')
    elif target_tier == 'CAUTION' and tier in ('SAFE', 'CAUTION'):
        candidates.append(f'{pkg}|{tier}|{name}|{cmd}|{impact}')

for c in candidates:
    print(c)
")"

if [ -z "${CANDIDATES_LIST}" ]; then
    log_warn "No candidate packages found for Tier=${TARGET_TIER} $([ -n "${SPECIFIC_PACKAGE}" ] && echo "and Package=${SPECIFIC_PACKAGE}")."
    exit 0
fi

# Filter only candidates that are currently installed on the target device
ACTIVE_TARGETS=""
while IFS='|' read -r pkg tier name cmd impact; do
    [ -z "${pkg}" ] && continue
    if echo "${INSTALLED_PKGS_MAP}" | grep -qx "${pkg}"; then
        ACTIVE_TARGETS="${ACTIVE_TARGETS}${pkg}|${tier}|${name}|${cmd}|${impact}\n"
    fi
done <<< "${CANDIDATES_LIST}"

ACTIVE_COUNT=$(echo -e "${ACTIVE_TARGETS}" | grep -v -c '^[[:space:]]*$' | tr -d ' ')

if [ "${ACTIVE_COUNT}" -eq 0 ]; then
    log_ok "All selected candidate packages are already uninstalled from user 0. Device is clean!"
    exit 0
fi

log_info "Identified ${ACTIVE_COUNT} target packages currently installed on device."

# ------------------------------------------------------------------------------
# 4. Interactive Confirmation (Skipped in Batch Mode)
# ------------------------------------------------------------------------------
if [ "${BATCH_MODE}" = false ] && [ "${DRY_RUN}" = false ]; then
    echo -e "\n${BOLD}Packages scheduled for uninstallation:${NC}"
    echo -e "${ACTIVE_TARGETS}" | grep -v '^[[:space:]]*$' | while IFS='|' read -r pkg tier name cmd impact; do
        printf "  - [${GREEN}%-7s${NC}] %-30s (%s)\n" "${tier}" "${pkg}" "${name}"
    done
    echo ""
    read -p "Do you want to proceed with uninstallation? [y/N]: " -r CONFIRM
    if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
        log_warn "Debloat aborted by user."
        exit 0
    fi
fi

# ------------------------------------------------------------------------------
# 5. Execution Loop with Strict Anomaly Checks
# ------------------------------------------------------------------------------
log_step "Executing debloat sequence..."

# Initialize or rotate last_removed.txt
: > "${LAST_REMOVED_FILE}"

SUCCESS_COUNT=0
SKIPPED_COUNT=0
FAILED_COUNT=0

while IFS='|' read -r pkg tier name cmd impact <&3; do
    [ -z "${pkg}" ] && continue

    # STRICT SAFETY CHECK: Refuse CRITICAL or BLOCKED packages
    if [ "${tier}" = "CRITICAL" ] || [ "${cmd}" = "BLOCKED" ]; then
        log_err "CRITICAL SAFETY VIOLATION: Package '${pkg}' is protected. SKIPPING IMMEDIATELY."
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi

    echo -e "\n--> Processing: ${BOLD}${name}${NC} [${pkg}]"
    log_info "Target Impact: ${impact}"

    if [ "${DRY_RUN}" = true ]; then
        echo -e "    ${YELLOW}[SIMULATED]${NC} adb shell pm uninstall -k --user 0 ${pkg}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        continue
    fi

    # Empirical 500mA Runaway Prevention for HyperOS / MIUI:
    # Purge hidden /data/app updates and kill lingering binders before uninstalling base package
    if [ "${pkg}" = "com.miui.msa.global" ] || [ "${pkg}" = "com.miui.analytics" ]; then
        log_info "Applying loop-prevention: purging hidden updates and terminating binders for ${pkg}..."
        adb shell pm uninstall "${pkg}" >/dev/null 2>&1 || true
        adb shell am force-stop "${pkg}" >/dev/null 2>&1 || true
        adb shell am force-stop com.miui.notes >/dev/null 2>&1 || true
    fi

    # Issue ADB command (temporarily allow non-zero exit from adb without terminating script)
    UNINSTALL_OUTPUT="$(adb shell pm uninstall -k --user 0 "${pkg}" 2>&1 || true)"
    UNINSTALL_OUTPUT="$(echo "${UNINSTALL_OUTPUT}" | tr -d '\r')"
    
    # Check for success, or fallback to pm disable-user if system blocks uninstallation (Failure [-1000])
    if echo "${UNINSTALL_OUTPUT}" | grep -qi "Success"; then
        log_ok "Successfully uninstalled: ${pkg}"
        echo "${pkg}" >> "${LAST_REMOVED_FILE}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    elif echo "${UNINSTALL_OUTPUT}" | grep -qi "Failure \[-1000\]"; then
        log_warn "System blocked uninstall (Failure [-1000]). Applying non-root fallback: pm disable-user..."
        DISABLE_OUTPUT="$(adb shell pm disable-user --user 0 "${pkg}" 2>&1 | tr -d '\r')"
        if echo "${DISABLE_OUTPUT}" | grep -qi "new state: disabled"; then
            log_ok "Successfully neutralized & disabled: ${pkg}"
            echo "${pkg}" >> "${LAST_REMOVED_FILE}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            log_err "Fallback disable failed for ${pkg}. Output: ${DISABLE_OUTPUT}"
            FAILED_COUNT=$((FAILED_COUNT + 1))
        fi
    else
        log_err "Failed to uninstall ${pkg}. Output: ${UNINSTALL_OUTPUT}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        
        # Check if Xiaomi Security Setting error
        if echo "${UNINSTALL_OUTPUT}" | grep -qi "SecurityException"; then
            log_err "Xiaomi SecurityException encountered!"
            log_err "Action required on device: Open Developer Options -> Enable 'USB Debugging (Security Settings)'"
            log_err "Note: Requires an active Mi Account and SIM card inserted to toggle this setting."
        fi
    fi

    # Anomaly / Heartbeat Check: Ping ADB state after each modification
    CURRENT_STATE="$(adb get-state 2>/dev/null || echo "lost")"
    if [ "${CURRENT_STATE}" != "device" ]; then
        log_err "DEVICE ANOMALY DETECTED! Connection lost after modifying ${pkg}."
        log_err "Immediate Rollback Recommended. Run: ./scripts/restore.sh"
        exit 10
    fi

done 3<<< "$(echo -e "${ACTIVE_TARGETS}" | grep -v '^[[:space:]]*$')"

# ------------------------------------------------------------------------------
# 6. Summary Report
# ------------------------------------------------------------------------------
log_step "Debloat Summary Report"
echo -e "  - Total Targets Processed : $((SUCCESS_COUNT + SKIPPED_COUNT + FAILED_COUNT))"
echo -e "  - ${GREEN}Successfully Removed    : ${SUCCESS_COUNT}${NC}"
echo -e "  - ${YELLOW}Skipped (Protected)     : ${SKIPPED_COUNT}${NC}"
echo -e "  - ${RED}Failed                  : ${FAILED_COUNT}${NC}"
echo -e "  - Last removed log saved  : ${LAST_REMOVED_FILE}"
echo -e "  - Full execution log      : ${DEBLOAT_LOG}"

if [ "${SUCCESS_COUNT}" -gt 0 ]; then
    log_ok "Debloat successfully finished. You can restore uninstalled packages at any time using: ./scripts/restore.sh"
fi

exit 0
