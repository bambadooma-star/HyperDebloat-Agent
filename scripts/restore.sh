#!/usr/bin/env bash
# ==============================================================================
# HyperDebloat-Agent :: scripts/restore.sh
# ------------------------------------------------------------------------------
# One-click restoration engine for uninstalled packages via install-existing.
# Non-Root, safe, reinstates packages without requiring factory reset or flashing.
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && (pwd -W 2>/dev/null || pwd))"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && (pwd -W 2>/dev/null || pwd))"
DATA_FILE="${ROOT_DIR}/data/packages.json"
LOGS_DIR="${ROOT_DIR}/logs"
LAST_REMOVED_FILE="${LOGS_DIR}/last_removed.txt"

mkdir -p "${LOGS_DIR}"

TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"
RESTORE_LOG="${LOGS_DIR}/restore_${TIMESTAMP}.log"

# --- Logging Helpers ---
log_info()  { echo -e "${CYAN}[INFO]${NC}  $*" | tee -a "${RESTORE_LOG}"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*" | tee -a "${RESTORE_LOG}"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" | tee -a "${RESTORE_LOG}"; }
log_err()   { echo -e "${RED}[ERROR]${NC} $*" | tee -a "${RESTORE_LOG}" >&2; }
log_step()  { echo -e "\n${BOLD}${BLUE}==>${NC} ${BOLD}$*${NC}" | tee -a "${RESTORE_LOG}"; }

# --- Argument Parsing Defaults ---
RESTORE_SOURCE="LAST_REMOVED"
CUSTOM_FILE=""
SPECIFIC_PACKAGE=""

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -p, --package <PKG>     Restore a single specific package ID
  -f, --file <PATH>       Restore all packages listed in a custom text file
  -a, --all-safe          Restore all SAFE packages registered in data/packages.json
  -h, --help              Show this help message and exit

Default behavior:
  If no options are specified, restores packages recorded in '${LAST_REMOVED_FILE}'.

Examples:
  ./scripts/restore.sh
  ./scripts/restore.sh --package com.miui.analytics
  ./scripts/restore.sh --file backups/custom_list.txt
  ./scripts/restore.sh --all-safe
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--package)
            SPECIFIC_PACKAGE="$2"
            RESTORE_SOURCE="SPECIFIC"
            shift 2
            ;;
        -f|--file)
            CUSTOM_FILE="$2"
            RESTORE_SOURCE="CUSTOM_FILE"
            shift 2
            ;;
        -a|--all-safe)
            RESTORE_SOURCE="ALL_SAFE"
            shift
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
echo -e "${BOLD}${CYAN}   HyperDebloat-Agent :: Restoration Engine           ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"

# ------------------------------------------------------------------------------
# 1. Device Pre-Flight Check
# ------------------------------------------------------------------------------
log_step "Validating ADB connection..."
if ! command -v adb >/dev/null 2>&1; then
    log_err "ADB executable not found. Aborting."
    exit 2
fi

ADB_STATE="$(adb get-state 2>/dev/null || echo "disconnected")"
if [ "${ADB_STATE}" != "device" ]; then
    log_err "Device is not ready. ADB state is: '${ADB_STATE}'."
    exit 3
fi

# ------------------------------------------------------------------------------
# 2. Compile Target Package List
# ------------------------------------------------------------------------------
TARGETS_TO_RESTORE=()

if [ "${RESTORE_SOURCE}" = "SPECIFIC" ]; then
    TARGETS_TO_RESTORE+=("${SPECIFIC_PACKAGE}")
elif [ "${RESTORE_SOURCE}" = "CUSTOM_FILE" ]; then
    if [ ! -f "${CUSTOM_FILE}" ]; then
        log_err "File not found: ${CUSTOM_FILE}"
        exit 1
    fi
    while IFS= read -r line || [ -n "${line}" ]; do
        pkg="$(echo "${line}" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -n "${pkg}" ] && [[ ! "${pkg}" =~ ^# ]] && TARGETS_TO_RESTORE+=("${pkg}")
    done < "${CUSTOM_FILE}"
elif [ "${RESTORE_SOURCE}" = "ALL_SAFE" ]; then
    if [ ! -f "${DATA_FILE}" ]; then
        log_err "Database file missing: ${DATA_FILE}"
        exit 1
    fi
    SAFE_PKGS="$(python3 -c "
import json
with open(r'${DATA_FILE}', 'r', encoding='utf-8') as f:
    db = json.load(f)
for p in db.get('packages', []):
    if p.get('tier') == 'SAFE':
        print(p['package'])
" 2>/dev/null || python -c "
import json
with open(r'${DATA_FILE}', 'r', encoding='utf-8') as f:
    db = json.load(f)
for p in db.get('packages', []):
    if p.get('tier') == 'SAFE':
        print(p['package'])
")"
    while IFS= read -r pkg; do
        [ -n "${pkg}" ] && TARGETS_TO_RESTORE+=("${pkg}")
    done <<< "${SAFE_PKGS}"
else
    # Default: LAST_REMOVED_FILE
    if [ ! -f "${LAST_REMOVED_FILE}" ] || [ ! -s "${LAST_REMOVED_FILE}" ]; then
        log_warn "No previous uninstalled packages found at: ${LAST_REMOVED_FILE}"
        log_info "If you want to restore all safe packages from database, use: ./scripts/restore.sh --all-safe"
        exit 0
    fi
    while IFS= read -r line || [ -n "${line}" ]; do
        pkg="$(echo "${line}" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        [ -n "${pkg}" ] && TARGETS_TO_RESTORE+=("${pkg}")
    done < "${LAST_REMOVED_FILE}"
fi

TOTAL_CANDIDATES=${#TARGETS_TO_RESTORE[@]}
if [ "${TOTAL_CANDIDATES}" -eq 0 ]; then
    log_warn "Target list is empty. Nothing to restore."
    exit 0
fi

log_info "Preparing to restore ${TOTAL_CANDIDATES} package(s)..."

# ------------------------------------------------------------------------------
# 3. Restoration Loop
# ------------------------------------------------------------------------------
SUCCESS_COUNT=0
FAILED_COUNT=0
ALREADY_INSTALLED_COUNT=0

# Fetch currently active packages on user 0 (both installed and enabled)
CURRENTLY_ACTIVE="$(adb shell pm list packages | sed 's/^package://' | tr -d '\r')"
DISABLED_PACKAGES="$(adb shell pm list packages -d | sed 's/^package://' | tr -d '\r')"

for pkg in "${TARGETS_TO_RESTORE[@]}"; do
    # Check if disabled, re-enable it
    if echo "${DISABLED_PACKAGES}" | grep -qx "${pkg}"; then
        echo -e "--> Re-enabling disabled package: ${BOLD}${pkg}${NC}"
        ENABLE_OUT="$(adb shell pm enable "${pkg}" 2>&1 | tr -d '\r')"
        if echo "${ENABLE_OUT}" | grep -qi "new state"; then
            log_ok "Successfully re-enabled: ${pkg}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            continue
        fi
    fi

    # Check if already present on user 0 and not disabled
    if echo "${CURRENTLY_ACTIVE}" | grep -qx "${pkg}"; then
        log_info "${pkg} is already installed and enabled for user 0. Skipping."
        ALREADY_INSTALLED_COUNT=$((ALREADY_INSTALLED_COUNT + 1))
        continue
    fi

    echo -e "--> Restoring: ${BOLD}${pkg}${NC}"

    # Primary restoration command: cmd package install-existing <pkg>
    RESTORE_OUTPUT="$(adb shell cmd package install-existing "${pkg}" 2>&1 | tr -d '\r')"

    # Fallback command if cmd package is unsupported: pm install-existing <pkg>
    if echo "${RESTORE_OUTPUT}" | grep -qiE "not found|Unknown command"; then
        RESTORE_OUTPUT="$(adb shell pm install-existing "${pkg}" 2>&1 | tr -d '\r')"
    fi

    # Validate output
    if echo "${RESTORE_OUTPUT}" | grep -qiE "installed for user|Success"; then
        log_ok "Successfully restored: ${pkg}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        log_err "Failed to restore ${pkg}. ADB Output: ${RESTORE_OUTPUT}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
done

# ------------------------------------------------------------------------------
# 4. Summary Report
# ------------------------------------------------------------------------------
log_step "Restoration Summary Report"
echo -e "  - Total Candidates        : ${TOTAL_CANDIDATES}"
echo -e "  - ${GREEN}Successfully Restored   : ${SUCCESS_COUNT}${NC}"
echo -e "  - Already Active          : ${ALREADY_INSTALLED_COUNT}"
echo -e "  - ${RED}Failed                  : ${FAILED_COUNT}${NC}"
echo -e "  - Log File                : ${RESTORE_LOG}"

if [ "${SUCCESS_COUNT}" -gt 0 ]; then
    log_ok "All selected packages have been reinstated into user 0 environment."
fi

exit 0
