#!/usr/bin/env bash
# ==============================================================================
# HyperDebloat-Agent :: scripts/harden-privacy.sh
# ------------------------------------------------------------------------------
# Non-Root Network & Telemetry Hardening: Private DNS (DoT), Captive Portal
# Telemetry Neutralization, and Global Ad Tracking Disabling.
# ==============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

DNS_PROVIDER="quad9"
CUSTOM_DNS_HOST=""

show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --dns <quad9|nextdns|adguard|custom>  Select DoT DNS provider (default: quad9)
  --host <hostname>                     Custom DNS-over-TLS hostname
  --revert                              Revert network hardening to Android system defaults
  -h, --help                            Show this help message

Presets:
  quad9    : dns.quad9.net (Strict privacy, malware blocking, no logs)
  adguard  : dns.adguard-dns.com (Ad-blocking, tracking protection)
  nextdns  : Provide your custom ID via --host <id>.dns.nextdns.io
EOF
}

REVERT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dns)
            DNS_PROVIDER="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
            shift 2
            ;;
        --host)
            CUSTOM_DNS_HOST="$2"
            DNS_PROVIDER="custom"
            shift 2
            ;;
        --revert)
            REVERT=true
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
echo -e "${BOLD}${CYAN}   HyperDebloat-Agent :: Privacy & Network Hardening   ${NC}"
echo -e "${BOLD}${CYAN}======================================================${NC}"

if ! command -v adb >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] ADB not found in PATH.${NC}"
    exit 2
fi

if [ "$(adb get-state 2>/dev/null || echo "disconnected")" != "device" ]; then
    echo -e "${RED}[ERROR] Device not ready.${NC}"
    exit 3
fi

if [ "${REVERT}" = true ]; then
    echo -e "\n${BOLD}Reverting network hardening to default Android configuration...${NC}"
    adb shell settings put global private_dns_mode "opportunistic"
    adb shell settings delete global private_dns_specifier || true
    adb shell settings put global captive_portal_mode 1
    adb shell settings put global captive_portal_detection_enabled 1
    adb shell settings put secure send_action_app_error 1
    echo -e "${GREEN}[OK] Successfully restored default network & diagnostic settings.${NC}"
    exit 0
fi

# Determine DoT Hostname
case "${DNS_PROVIDER}" in
    quad9)
        DOT_HOST="dns.quad9.net"
        ;;
    adguard)
        DOT_HOST="dns.adguard-dns.com"
        ;;
    nextdns)
        if [ -z "${CUSTOM_DNS_HOST}" ]; then
            echo -e "${RED}[ERROR] For NextDNS, please specify your endpoint via --host <id>.dns.nextdns.io${NC}"
            exit 1
        fi
        DOT_HOST="${CUSTOM_DNS_HOST}"
        ;;
    custom)
        if [ -z "${CUSTOM_DNS_HOST}" ]; then
            echo -e "${RED}[ERROR] Custom DNS selected without --host parameter.${NC}"
            exit 1
        fi
        DOT_HOST="${CUSTOM_DNS_HOST}"
        ;;
    *)
        echo -e "${RED}[ERROR] Unknown DNS provider: ${DNS_PROVIDER}${NC}"
        exit 1
        ;;
esac

echo -e "\n${BOLD}1. Applying Private DNS over TLS (DoT): ${DOT_HOST}${NC}"
adb shell settings put global private_dns_mode "hostname"
adb shell settings put global private_dns_specifier "${DOT_HOST}"
echo -e "${GREEN}[OK] Encrypted DNS configured (Hostname: ${DOT_HOST})${NC}"

echo -e "\n${BOLD}2. Neutralizing Captive Portal Telemetry & HTTP Probes${NC}"
adb shell settings put global captive_portal_mode 0
adb shell settings put global captive_portal_detection_enabled 0
echo -e "${GREEN}[OK] Captive portal telemetry pings disabled${NC}"

echo -e "\n${BOLD}3. Disabling System Diagnostic & Crash Telemetry Beacons${NC}"
adb shell settings put secure send_action_app_error 0
echo -e "${GREEN}[OK] Crash action telemetry disabled${NC}"

echo -e "\n${BOLD}4. Disabling Personalized Advertising Identifiers (HyperOS/MIUI)${NC}"
adb shell settings put secure limit_ad_tracking 1 2>/dev/null || true
adb shell settings put system personalized_ad_enabled 0 2>/dev/null || true
echo -e "${GREEN}[OK] Ad-tracking limitation enforced${NC}"

echo -e "\n${BOLD}${GREEN}==> Network and Privacy Hardening Complete!${NC}"
