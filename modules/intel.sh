#!/usr/bin/env bash
# DESC: Configures Intel i965 drivers for Haswell and earlier GPUs (Dell 2014)
# REQUIRES: sudo
# TAGS: graphics, intel, mesa, drivers

set -euo pipefail

source "${DEBOOST_HOME}/lib/utils.sh" 2>/dev/null || {
  run() { echo "[RUN] $*"; eval "$@"; }
  log_info() { echo "[INFO] $*"; }
  log_success() { echo "[OK] $*"; }
}

module_run() {
  log_info "Installing Mesa drivers and Intel i965 support..."
  run "sudo apt install -y \
    libegl-mesa0 \
    libgl1-mesa-dri \
    libglx-mesa0 \
    mesa-utils \
    mesa-va-drivers \
    i965-va-driver \
    intel-media-va-driver-non-free \
    libva2 \
    libva-drm2 \
    vainfo"
  
  log_info "Configuring LIBVA_DRIVER_NAME=i965..."
  
  # /etc/environment
  if ! grep -q "LIBVA_DRIVER_NAME" /etc/environment 2>/dev/null; then
    run "echo 'LIBVA_DRIVER_NAME=${LIBVA_DRIVER_NAME:-i965}' | sudo tee -a /etc/environment > /dev/null"
  else
    log_info "LIBVA_DRIVER_NAME already configured in /etc/environment"
  fi
  
  # /etc/profile.d/
  run "sudo mkdir -p /etc/profile.d"
  
  if [ "$DRYRUN" = false ]; then
    sudo tee /etc/profile.d/deboost_libva.sh >/dev/null <<EOF
# Deboost: Intel i965 LIBVA driver for Haswell GPUs (Dell 2014)
export LIBVA_DRIVER_NAME=${LIBVA_DRIVER_NAME:-i965}
EOF
    sudo chmod 644 /etc/profile.d/deboost_libva.sh
  else
    echo "[DRYRUN] would create /etc/profile.d/deboost_libva.sh"
  fi
  
  log_info "Testing video acceleration..."
  if command -v vainfo &>/dev/null; then
    log_info "Run 'vainfo' to verify VA-API driver"
  fi
  
  log_success "Intel drivers configured!"
  log_info "Restart your session to apply environment variables."
}

module_run