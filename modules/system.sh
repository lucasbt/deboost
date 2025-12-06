#!/usr/bin/env bash
# DESC: Updates system and installs essential firmware
# REQUIRES: sudo
# TAGS: system, update, firmware

set -euo pipefail

# Import Deboost functions
# shellcheck disable=SC1091
source "${DEBOOST_HOME}/lib/utils.sh" 2>/dev/null || {
  run() { echo "[RUN] $*"; eval "$@"; }
  log_info() { echo "[INFO] $*"; }
  log_success() { echo "[OK] $*"; }
}

module_check() {
  if [ "$EUID" -eq 0 ]; then
    log_warn "This module should not be run as root directly."
    log_warn "Use sudo when necessary."
  fi
}

module_run() {
  log_info "Updating package list..."
  
  sudo apt-add-repository contrib non-free -y

  run "sudo apt update"
  
  log_info "Upgrading system..."
  run "sudo apt full-upgrade -y"
  
  if [ "${INSTALL_PROPRIETARY_FIRMWARE:-true}" = "true" ]; then
    log_info "Installing proprietary firmware..."
    run "sudo apt install -y firmware-linux firmware-misc-nonfree firmware-iwlwifi firmware-realtek"
  fi
  
  log_info "Installing basic system tools and dependencies..."
  run "sudo apt install -y apt-transport-https curl wget git ca-certificates gnupg lsb-release software-properties-common"
  
  log_info "Cleaning unnecessary packages..."
  run "sudo apt autoremove -y"
  run "sudo apt autoclean"
  
  log_success "System updated!"
}

# Run module
module_check
module_run