#!/usr/bin/env bash
# DESC: Configures GNOME/Wayland with anti-fatigue optimizations
# REQUIRES: gnome-shell
# TAGS: gnome, wayland, accessibility

set -euo pipefail

source "${DEBOOST_HOME}/lib/utils.sh" 2>/dev/null || {
  run() { echo "[RUN] $*"; eval "$@"; }
  log_info() { echo "[INFO] $*"; }
  log_success() { echo "[OK] $*"; }
}

module_check() {
  if ! command -v gsettings &>/dev/null; then
    log_error "gsettings not found. This module requires GNOME."
    return 1
  fi
}

module_run() {
  log_info "Applying GNOME settings..."
  
  # Dark theme
  log_info "→ Enabling dark theme"
  run "gsettings set org.gnome.desktop.interface color-scheme '${GNOME_COLOR_SCHEME:-prefer-dark}'"
  
  # Animations
  log_info "→ Disabling animations"
  run "gsettings set org.gnome.desktop.interface enable-animations ${GNOME_ENABLE_ANIMATIONS:-false}"
  run "gsettings set org.gnome.desktop.interface gtk-enable-animations ${GNOME_ENABLE_ANIMATIONS:-false}"
  
  # Text scaling
  log_info "→ Adjusting text scaling"
  run "gsettings set org.gnome.desktop.interface text-scaling-factor ${GNOME_TEXT_SCALING:-1.05}"
  
  # Cursor
  log_info "→ Adjusting cursor size"
  run "gsettings set org.gnome.desktop.interface cursor-size ${GNOME_CURSOR_SIZE:-24}"
  
  # Mouse
  log_info "→ Configuring mouse (flat acceleration)"
  run "gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'"
  
  # Touchpad
  log_info "→ Configuring touchpad (natural scroll)"
  run "gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true"
  
  # Night Light (blue filter)
  log_info "→ Enabling Night Light"
  run "gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true"
  run "gsettings set org.gnome.settings-daemon.plugins.color night-light-temperature ${GNOME_NIGHT_LIGHT_TEMP:-3700}"
  run "gsettings set org.gnome.settings-daemon.plugins.color night-light-schedule-automatic true"
  
  # Font rendering
  log_info "→ Configuring font rendering"
  run "gsettings set org.gnome.settings-daemon.plugins.xsettings hinting '${FONT_HINTING:-slight}'"
  run "gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing '${FONT_ANTIALIASING:-rgba}'"
  
  if [ -n "${FONT_MONOSPACE:-}" ]; then
    run "gsettings set org.gnome.desktop.interface monospace-font-name '${FONT_MONOSPACE}'"
  fi
  
  # Power settings (avoid suspension during installations)
  log_info "→ Adjusting power settings"
  run "gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0"
  run "gsettings set org.gnome.desktop.session idle-delay 900"
  
  log_success "GNOME settings applied!"
  log_info "Some changes may require logout/login"
}

module_check
module_run