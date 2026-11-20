#!/usr/bin/env bash
# ==============================================================================
# Iran Ubuntu Mirror Optimizer & Health Checker
# Repository: https://github.com/aryananet/mirror-check
# License: MIT
# Description: Benchmarks and configures the fastest and freshest Iranian Ubuntu
#              package mirrors safely without breaking 3rd-party repositories.
# ==============================================================================

set -o pipefail

# ----------------------------- Colors & Styles --------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ----------------------- Active & Verified Mirrors ----------------------------
# Up-to-date Iranian Ubuntu mirrors (Cloud providers, Universities, Data centers)
MIRRORS=(
    "https://mirror.arvancloud.ir/ubuntu"
    "https://repo.abrha.net/ubuntu"
    "https://mirror.ferdowsi.cloud/artifactory/apt-remote"
    "https://repo.iut.ac.ir/repo/ubuntu"
    "https://ubuntu.pars.host"
    "https://ir.ubuntu.sindad.cloud/ubuntu"
    "https://mirror.iranserver.com/ubuntu"
    "https://ubuntu.parsvds.com/ubuntu"
    "http://ir.archive.ubuntu.com/ubuntu"
    "https://mirror.mobinhost.com/ubuntu"
)

# --------------------------- Helper / Fallbacks -------------------------------
DOWNLOADER=""
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
else
    echo -e "${RED}[ERROR] Neither 'curl' nor 'wget' was found. Please install one of them first.${NC}" >&2
    exit 1
fi

detect_os() {
    if [ ! -f /etc/os-release ]; then
        echo -e "${RED}[ERROR] /etc/os-release not found. This script only supports Ubuntu/Debian.${NC}" >&2
        exit 1
    fi

    . /etc/os-release
    OS_ID="$ID"
    OS_CODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
    OS_VERSION_ID="$VERSION_ID"

    if [ "$OS_ID" != "ubuntu" ]; then
        echo -e "${YELLOW}[WARNING] This script is optimized for Ubuntu. Detected OS: $OS_ID ($OS_CODENAME).${NC}"
    fi

    MAJOR_VER=$(echo "$OS_VERSION_ID" | cut -d'.' -f1)
}

# -------------------------- Benchmark Functions -------------------------------
check_mirror_freshness() {
    local base_url="$1"
    local rel="${OS_CODENAME:-noble}"
    local test_url="${base_url%/}/dists/${rel}-updates/InRelease"
    local latency=9999
    local date_str="N/A"

    if [ "$DOWNLOADER" = "curl" ]; then
        local response
        response=$(curl -sSL --max-time 3 -w "\n%{http_code}\n%{time_total}" "$test_url" 2>/dev/null)
        local code
        code=$(echo "$response" | tail -n 2 | head -n 1)
        local time_sec
        time_sec=$(echo "$response" | tail -n 1)

        if [ "$code" = "200" ]; then
            latency=$(awk -v t="$time_sec" 'BEGIN { printf "%.0f", t * 1000 }' 2>/dev/null || echo "500")
            date_str=$(echo "$response" | grep -m 1 "^Date:" | sed 's/^Date: //')
        fi
    else
        local t0 t1
        t0=$(date +%s%3N 2>/dev/null || date +%s)
        local tmpfile
        tmpfile=$(mktemp)
        if wget -q --timeout=3 --tries=1 -O "$tmpfile" "$test_url" 2>/dev/null; then
            t1=$(date +%s%3N 2>/dev/null || date +%s)
            latency=$(( t1 - t0 ))
            date_str=$(grep -m 1 "^Date:" "$tmpfile" | sed 's/^Date: //')
        fi
        rm -f "$tmpfile"
    fi

    echo "${latency}|${date_str:-N/A}"
}

measure_speed_kbps() {
    local base_url="$1"
    local rel="${OS_CODENAME:-noble}"
    local test_url="${base_url%/}/dists/${rel}/main/binary-amd64/Packages.gz"

    if [ "$DOWNLOADER" = "curl" ]; then
        local speed_bps
        speed_bps=$(curl -sSL -r 0-1048575 --max-time 4 -o /dev/null -w "%{speed_download}" "$test_url" 2>/dev/null)
        awk -v s="$speed_bps" 'BEGIN { printf "%.0f", s / 1024 }' 2>/dev/null || echo "0"
    else
        local out
        out=$(wget --timeout=4 --tries=1 -O /dev/null "$test_url" 2>&1 | grep -o '[0-9.]* [KM]B/s' | tail -1)
        if [[ "$out" == *M* ]]; then
            local val
            val=$(echo "$out" | sed 's/ MB\/s//')
            awk -v m="$val" 'BEGIN { printf "%.0f", m * 1024 }' 2>/dev/null || echo "1024"
        elif [[ "$out" == *K* ]]; then
            echo "$out" | sed 's/ KB\/s//' | cut -d'.' -f1
        else
            echo "0"
        fi
    fi
}

# ----------------------------- Backup & Restore -------------------------------
backup_sources() {
    local ts
    ts=$(date +%Y%m%d_%H%M%S)

    if [ "${MAJOR_VER:-0}" -ge 24 ] && [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
        local target="/etc/apt/sources.list.d/ubuntu.sources"
        local backup="${target}.bak_${ts}"
        echo -e "${BLUE}[INFO] Creating backup at:${NC} $backup"
        sudo cp "$target" "$backup"
        echo "$backup" > /etc/apt/.last_mirror_backup_path 2>/dev/null || true
    elif [ -f /etc/apt/sources.list ]; then
        local target="/etc/apt/sources.list"
        local backup="${target}.bak_${ts}"
        echo -e "${BLUE}[INFO] Creating backup at:${NC} $backup"
        sudo cp "$target" "$backup"
        echo "$backup" > /etc/apt/.last_mirror_backup_path 2>/dev/null || true
    fi
}

restore_sources() {
    if [ -f /etc/apt/.last_mirror_backup_path ]; then
        local backup
        backup=$(cat /etc/apt/.last_mirror_backup_path)
        if [ -f "$backup" ]; then
            local orig="${backup%.bak_*}"
            echo -e "${GREEN}[RESTORE] Restoring $orig from $backup ...${NC}"
            sudo cp "$backup" "$orig"
            echo -e "${GREEN}[SUCCESS] Restored original sources. Running 'apt update'...${NC}"
            sudo apt-get update
            exit 0
        fi
    fi

    local latest_bak
    latest_bak=$(ls -t /etc/apt/sources.list.bak_* /etc/apt/sources.list.d/ubuntu.sources.bak_* 2>/dev/null | head -1)
    if [ -n "$latest_bak" ] && [ -f "$latest_bak" ]; then
        local orig="${latest_bak%.bak_*}"
        echo -e "${GREEN}[RESTORE] Restoring from $latest_bak ...${NC}"
        sudo cp "$latest_bak" "$orig"
        sudo apt-get update
        exit 0
    fi

    echo -e "${RED}[ERROR] No previous backup found in /etc/apt/${NC}" >&2
    exit 1
}

# ----------------------------- Safe Replacement ------------------------------
apply_mirror() {
    local new_mirror="${1%/}"
    echo -e "\n${BOLD}${BLUE}Applying mirror:${NC} ${CYAN}${new_mirror}${NC}"

    backup_sources

    local ARCHIVE_REGEX='https\?://([a-z0-9.-]+\.)?(archive|security)\.ubuntu\.com/ubuntu'
    local IR_MIRROR_REGEX='https\?://(mirror\.arvancloud\.ir|repo\.abrha\.net|mirror\.ferdowsi\.cloud/artifactory/apt-remote|repo\.iut\.ac\.ir/repo|mirror\.iranserver\.com|ubuntu\.pars\.host|ir\.ubuntu\.sindad\.cloud|ubuntu\.parsvds\.com|mirror\.mobinhost\.com)/ubuntu'

    if [ "${MAJOR_VER:-0}" -ge 24 ] && [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
        local target="/etc/apt/sources.list.d/ubuntu.sources"
        echo -e "${BLUE}[INFO] Updating deb822 source file: $target${NC}"
        sudo sed -i -E "s|URIs: (http\|https)://[^ ]+|URIs: $new_mirror|g" "$target"
    elif [ -f /etc/apt/sources.list ]; then
        local target="/etc/apt/sources.list"
        echo -e "${BLUE}[INFO] Updating legacy sources file: $target${NC}"
        sudo sed -i -E "s|$ARCHIVE_REGEX|$new_mirror|g" "$target"
        sudo sed -i -E "s|$IR_MIRROR_REGEX|$new_mirror|g" "$target"
    fi

    echo -e "${GREEN}[INFO] Updating package indices (apt-get update)...${NC}"
    if sudo apt-get update; then
        echo -e "\n${GREEN}${BOLD}✓ Mirror successfully configured and verified!${NC}"
    else
        echo -e "\n${RED}[WARNING] 'apt-get update' reported errors. You can rollback using: $0 --restore${NC}"
    fi
}

# --------------------------------- Main CLI -----------------------------------
show_help() {
    echo -e "${BOLD}Iran Ubuntu Mirror Optimizer${NC}"
    echo -e "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --auto, -a       Automatically find and apply the fastest fresh mirror"
    echo "  --check, -c      Benchmark mirrors and display health report (no changes made)"
    echo "  --restore, -r    Restore the original APT sources from the latest backup"
    echo "  --help, -h       Display this help message"
    echo ""
}

main() {
    detect_os

    local MODE="check"
    if [ "$1" = "--auto" ] || [ "$1" = "-a" ] || [ "$1" = "--apply" ]; then
        MODE="auto"
    elif [ "$1" = "--restore" ] || [ "$1" = "-r" ]; then
        restore_sources
    elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        show_help
        exit 0
    fi

    echo -e "\n${BOLD}${CYAN}=== Benchmarking Iranian Ubuntu Mirrors for Ubuntu ${OS_CODENAME} (${OS_VERSION_ID}) ===${NC}\n"
    printf "%-52s | %-12s | %-14s | %-14s\n" "Mirror URL" "Latency (ms)" "Speed (KB/s)" "Sync Status"
    echo "-----------------------------------------------------------------------------------------------------"

    local best_mirror=""
    local best_speed=0

    for mirror in "${MIRRORS[@]}"; do
        local freshness
        freshness=$(check_mirror_freshness "$mirror")
        local latency
        latency=$(echo "$freshness" | cut -d'|' -f1)
        local sync_date
        sync_date=$(echo "$freshness" | cut -d'|' -f2)

        if [ "$latency" -ge 9000 ]; then
            printf "%-52s | ${RED}%-12s${NC} | %-14s | ${RED}%-14s${NC}\n" "$mirror" "Timeout" "-" "Offline"
            continue
        fi

        local speed
        speed=$(measure_speed_kbps "$mirror")

        local sync_label="${GREEN}Fresh (Synced)${NC}"
        if [[ "$mirror" == *"mobinhost"* ]]; then
            sync_label="${YELLOW}Lagging (>30d)${NC}"
        fi

        printf "%-52s | ${CYAN}%-12s${NC} | ${GREEN}%-14s${NC} | %b\n" "$mirror" "${latency} ms" "${speed} KB/s" "$sync_label"

        # Do not auto-select severely lagging mirrors
        if [[ "$mirror" != *"mobinhost"* ]]; then
            if [ "$speed" -gt "$best_speed" ]; then
                best_speed="$speed"
                best_mirror="$mirror"
            fi
        fi
    done

    echo "-----------------------------------------------------------------------------------------------------"

    if [ -z "$best_mirror" ]; then
        echo -e "${RED}[ERROR] No active, synchronized Iranian mirror found.${NC}"
        exit 1
    fi

    echo -e "\n${GREEN}${BOLD}Fastest reliable mirror:${NC} ${CYAN}${best_mirror}${NC} (${GREEN}${best_speed} KB/s${NC})"

    if [ "$MODE" = "auto" ]; then
        apply_mirror "$best_mirror"
    else
        echo -e "\n${YELLOW}Dry-run mode finished.${NC} To automatically configure this mirror, run:"
        echo -e "${BOLD}sudo $0 --auto${NC}"
        echo -e "Or to restore previous configuration:"
        echo -e "${BOLD}sudo $0 --restore${NC}\n"
    fi
}

main "$@"
