#!/bin/bash
# Copyright (c) 2026 WeAct Studio
# Description: Automatic flash tool for WeAct N002 carrier board
#              Supports Jetson Nano, TX2 NX, Xavier NX, Orin Nano, Orin NX
#              User must define FULL flash commands in FLASH_CMDS array.
# Options:
#   -n        Use non-super board (for Orin Nano/NX only)
#   -s        Use SD card flash commands (for Jetson Nano / Xavier NX)
#   -h        Show this help message

# ============================================
# Configuration & Global Variables
# ============================================

LINUX_FOR_TEGRA_DIR=""
USE_NON_SUPER=false
USE_SD=false

# Core board identifier mapping (from path -> short name)
declare -A BOARD_MAP=(
    ["JETSON_NANO"]="nano"
    ["JETSON_TX2"]="tx2"
    ["JETSON_XAVIER_NX"]="xnx"
    ["JETSON_ORIN_NANO"]="ono"
    ["JETSON_ORIN_NX"]="onx"
)

# ============================================
# FLASH COMMANDS - CUSTOMIZE HERE
# ============================================
# Key format (applied in order): <short_name>_<major_version>[ _s ][ _non ]
#   - Super mode (default):                  nano_4
#   - SD card mode:                          nano_4_s
#   - Non-super mode (Orin):                 onx_5_non
#   - Both SD + Non-super:                   onx_5_s_non  (if needed)
# Write the FULL flash command (including sudo, board name, device, etc.)
# ============================================
declare -A FLASH_CMDS=(
    # JetPack 4.x (legacy flash.sh) - eMMC/NVMe default
    ["nano_4"]="sudo ./flash.sh jetson-nano-emmc mmcblk0p1"
    ["tx2_4"]="sudo ./flash.sh jetson-xavier-nx-devkit-tx2-nx mmcblk0p1"
    ["xnx_4"]="sudo ./flash.sh jetson-xavier-nx-devkit-emmc mmcblk0p1"

    # JetPack 4.x - SD card versions (user to fill)
    ["nano_4_s"]="sudo ./flash.sh jetson-nano-qspi-sd mmcblk0p1"
    ["xnx_4_s"]="sudo ./flash.sh jetson-xavier-nx-devkit-qspi mmcblk0p1"
    
    # JetPack 5.x / 6.x / 7.x (l4t_initrd_flash.sh with NVMe)
    ["xnx_5"]="sudo ./flash.sh jetson-xavier-nx-devkit-emmc mmcblk0p1"
    # Super mode (default)
    ["ono_5"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/t186ref/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit-super internal"
    ["onx_5"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/t186ref/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit-super internal"
    ["ono_6"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/generic/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit-super internal"
    ["onx_6"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/generic/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit-super internal"
    ["ono_7"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/generic/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit-super internal"
    ["onx_7"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/generic/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit-super internal"

    # Non-super mode (Orin) - add _non suffix
    ["ono_5_non"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/t186ref/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit internal"
    ["onx_5_non"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/t186ref/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit internal"
    ["ono_6_non"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/generic/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit internal"
    ["onx_6_non"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/generic/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit internal"
    ["ono_7_non"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/generic/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit internal"
    ["onx_7_non"]="sudo ./tools/kernel_flash/l4t_initrd_flash.sh --external-device nvme0n1p1 -c tools/kernel_flash/flash_l4t_t234_nvme.xml -p \"-c bootloader/generic/cfg/flash_t234_qspi.xml\" --showlogs --network usb0 jetson-orin-nano-devkit internal"

    # For SD + Non-super combination (if needed), define as <core>_<major>_s_non
    # ["onx_5_s_non"]="..."
)

# ============================================
# Logging Functions
# ============================================

log_info()    { echo "[INFO]    $1"; }
log_success() { echo "[SUCCESS] $1"; }
log_error()   { echo "[ERROR]   $1"; }
log_warning() { echo "[WARNING] $1"; }

# ============================================
# Helper Functions
# ============================================

# Check if running with sufficient privileges (root)
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_warning "This script may require root privileges to copy files and execute flash commands."
        log_warning "If you encounter permission errors, please run with 'sudo'."
    fi
}

check_and_extract_path() {
    local current_path="$1"
    if [[ "$current_path" != *"Linux_for_Tegra"* ]]; then
        log_error "Current path does not contain 'Linux_for_Tegra'. Please run this script inside the Linux_for_Tegra directory tree."
        return 1
    fi

    if [[ "$current_path" == */Linux_for_Tegra/* ]]; then
        LINUX_FOR_TEGRA_DIR="${current_path%/Linux_for_Tegra/*}/Linux_for_Tegra"
    elif [[ "$current_path" == */Linux_for_Tegra ]]; then
        LINUX_FOR_TEGRA_DIR="$current_path"
    else
        local temp="$current_path"
        while [[ "$temp" != "/" ]]; do
            if [[ "$temp" == *Linux_for_Tegra* ]]; then
                LINUX_FOR_TEGRA_DIR="${temp%Linux_for_Tegra*}Linux_for_Tegra"
                break
            fi
            temp=$(dirname "$temp")
        done
    fi

    LINUX_FOR_TEGRA_DIR=$(cd "$LINUX_FOR_TEGRA_DIR" && pwd)
    if [[ ! -d "$LINUX_FOR_TEGRA_DIR" ]]; then
        log_error "Failed to locate Linux_for_Tegra directory."
        return 1
    fi
    log_success "Found Linux_for_Tegra: $LINUX_FOR_TEGRA_DIR"
    return 0
}

extract_version_and_board() {
    local path="$1"
    if [[ "$path" =~ JetPack_([0-9]+\.[0-9]+(\.[0-9]+)?)_Linux_(JETSON_[A-Z0-9_]+)_TARGETS ]]; then
        VERSION="${BASH_REMATCH[1]}"
        BOARD_ID="${BASH_REMATCH[3]}"
        log_info "Detected JetPack version: $VERSION, Board ID: $BOARD_ID"
        return 0
    else
        log_error "Cannot extract version and board from current path. Make sure you are inside a valid NVIDIA SDK directory."
        return 1
    fi
}

get_major_version() {
    echo "${1%%.*}"
}

# ============================================
# Core Functions
# ============================================

copy_files() {
    local core_abbr="$1"
    local major_ver="$2"
    local script_dir="$3"
    local dtb_root="$script_dir/DTB/$core_abbr/JP$major_ver"

    if [[ ! -d "$dtb_root" ]]; then
        log_error "DTB directory not found: $dtb_root"
        return 1
    fi

    local cfg_file="$dtb_root/cfg"
    if [[ ! -f "$cfg_file" ]]; then
        log_error "Configuration file not found: $cfg_file"
        return 1
    fi

    log_info "Using config file: $cfg_file"
    local line_num=0
    local copy_failed=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        if [[ "$line" =~ ^[[:space:]]*([^:]+)[[:space:]]*:[[:space:]]*(.*)[[:space:]]*$ ]]; then
            local src_rel="${BASH_REMATCH[1]}"
            local dst_rel="${BASH_REMATCH[2]}"
            src_rel=$(echo "$src_rel" | xargs | tr -d '\r')
            dst_rel=$(echo "$dst_rel" | xargs | tr -d '\r')

            local src_dir="$dtb_root/$src_rel"
            local dst_dir="$LINUX_FOR_TEGRA_DIR/$dst_rel"

            if [[ ! -d "$src_dir" ]]; then
                log_error "Source directory does not exist: $src_dir (line $line_num)"
                copy_failed=true
                continue
            fi

            # Create destination directory if it doesn't exist
            mkdir -p "$dst_dir" || {
                log_error "Failed to create destination directory: $dst_dir"
                copy_failed=true
                continue
            }

            # Check if source directory is empty
            if [[ -z "$(ls -A "$src_dir")" ]]; then
                log_warning "Source directory $src_dir is empty; nothing to copy (line $line_num)"
                continue
            fi

            log_info "Copying from $src_dir to $dst_dir"
            # Improved copy: includes hidden files and handles empty dirs gracefully
            cp -a "$src_dir"/. "$dst_dir"/ 2>/dev/null
            local cp_ret=$?
            if [[ $cp_ret -ne 0 ]]; then
                log_error "Failed to copy files from $src_dir to $dst_dir (error code $cp_ret)"
                copy_failed=true
            else
                log_success "Copied files from $src_dir to $dst_dir"
            fi
        else
            log_warning "Skipping malformed line $line_num: $line"
        fi
    done < "$cfg_file"

    if [[ "$copy_failed" == true ]]; then
        return 1
    fi
    return 0
}

execute_flash() {
    local core_abbr="$1"
    local major_ver="$2"

    # Build key: base + _s (if set) + _non (if set)
    local cmd_key="${core_abbr}_${major_ver}"
    if [[ "$USE_SD" == true ]]; then
        cmd_key="${cmd_key}_s"
    fi
    if [[ "$USE_NON_SUPER" == true ]]; then
        cmd_key="${cmd_key}_non"
    fi

    local cmd="${FLASH_CMDS[$cmd_key]}"
    if [[ -z "$cmd" ]]; then
        log_error "No flash command defined for key '$cmd_key'."
        log_error "Current options: SD=$USE_SD, NON_SUPER=$USE_NON_SUPER"
        log_error "Available keys in FLASH_CMDS:"
        for key in "${!FLASH_CMDS[@]}"; do
            echo "  $key"
        done | sort
        return 1
    fi

    log_info "Executing flash command: $cmd"
    # Use eval carefully; user-provided command, we trust it
    (cd "$LINUX_FOR_TEGRA_DIR" && eval "$cmd")
    local ret=$?
    if [[ $ret -ne 0 ]]; then
        log_error "Flash command failed with exit code $ret."
        return 1
    fi
    return 0
}

# ============================================
# Main Script
# ============================================

# Parse command line options
while getopts "nsh" opt; do
    case $opt in
        n) USE_NON_SUPER=true ;;
        s) USE_SD=true ;;
        h)
            echo "Usage: $0 [-n] [-s] [-h]"
            echo "  -n    Use non-super board (for Orin Nano/NX only)"
            echo "  -s    Use SD card flash commands (for Jetson Nano / Xavier NX)"
            echo "  -h    Show this help message"
            exit 0
            ;;
        \?)
            echo "Usage: $0 [-n] [-s] [-h]"
            echo "  -n    Use non-super board (for Orin Nano/NX only)"
            echo "  -s    Use SD card flash commands (for Jetson Nano / Xavier NX)"
            echo "  -h    Show this help message"
            exit 1
            ;;
    esac
done

# Check root privileges hint
check_privileges

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="$(pwd)"

log_info "Script directory: $SCRIPT_DIR"
log_info "Current directory: $CURRENT_DIR"

if ! check_and_extract_path "$CURRENT_DIR"; then
    exit 1
fi

if ! extract_version_and_board "$CURRENT_DIR"; then
    exit 1
fi

MAJOR_VERSION=$(get_major_version "$VERSION")
log_info "Major version: $MAJOR_VERSION"

CORE_ABBR="${BOARD_MAP[$BOARD_ID]}"
if [[ -z "$CORE_ABBR" ]]; then
    log_error "Unsupported board: $BOARD_ID"
    exit 1
fi
log_info "Board short name: $CORE_ABBR"

# Validate options for unsupported boards (warning only)
if [[ "$USE_NON_SUPER" == true && "$CORE_ABBR" != "ono" && "$CORE_ABBR" != "onx" ]]; then
    log_warning "-n option is typically for Orin boards; ensure you have defined a corresponding command."
fi
if [[ "$USE_SD" == true && "$CORE_ABBR" != "nano" && "$CORE_ABBR" != "xnx" ]]; then
    log_warning "-s option is typically for Jetson Nano and Xavier NX; ensure you have defined a corresponding command."
fi

if [[ "$USE_NON_SUPER" == true ]]; then
    log_info "Non-super mode enabled."
fi
if [[ "$USE_SD" == true ]]; then
    log_info "SD card mode enabled."
fi

if ! copy_files "$CORE_ABBR" "$MAJOR_VERSION" "$SCRIPT_DIR"; then
    log_error "Failed to copy DTB/files. Please ensure you have write permissions (run with sudo if needed)."
    exit 1
fi

if ! execute_flash "$CORE_ABBR" "$MAJOR_VERSION"; then
    log_error "Flash execution failed. Please check the command and try again."
    exit 1
fi

log_success "Flashing completed. Please wait for the device to boot."