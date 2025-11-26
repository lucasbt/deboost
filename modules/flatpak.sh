#!/usr/bin/env bash
# DESC: Installs and configures Flatpak + Flathub
# REQUIRES: sudo
# TAGS: flatpak, apps, flathub

set -euo pipefail

source "${DEBOOST_HOME}/lib/utils.sh" 2>/dev/null || {
  run() { echo "[RUN] $*"; eval "$@"; }
  log_info() { echo "[INFO] $*"; }
  log_success() { echo "[OK] $*"; }
}

# Lista de aplicativos Flatpak para instalação
FLATPAK_APPS=(
  "com.mattjakeman.ExtensionManager"  # Extension Manager
  "com.github.tchx84.Flatseal"        # Flatseal (permissions)
  "io.bassi.Amberol"
  "rest.insomnia.Insomnia"
  "com.rafaelmardojai.Blanket"
  "md.obsidian.Obsidian"
  "io.github.alainm23.planify"
  "org.gnome.gitlab.somas.Apostrophe"
  "be.alexandervanhee.gradia"
  "it.mijorus.gearlever"
  "org.telegram.desktop"
)

module_run() {
  log_info "Installing Flatpak..."
  apt_install flatpak
  
  log_info "Installing GNOME Software plugin for Flatpak..."
  apt_install "gnome-software-plugin-flatpak"
  
  log_info "Adding Flathub repository..."
  run "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
  
  log_info "Verifying installation..."
  if flatpak remotes | grep -q "flathub"; then
    log_success "Flathub configured!"
  else
    log_warn "Flathub may not be configured correctly"
  fi
  
  # Suggested applications
  if ask_yes_no "Install essential applications via Flatpak?" "n"; then
    log_info "Installing applications..."
    
    for app in "${FLATPAK_APPS[@]}"; do
      log_info "→ Installing $app..."
      run "flatpak install -y flathub $app" || true
    done
    
    log_success "Applications installed!"
  fi
  
  log_info "List available apps with: flatpak search <name>"
  log_info "Install apps with: flatpak install flathub <app-id>"
  
  log_success "Flatpak configured!"
  log_info "Restart to see Flatpak apps in the application menu"
}

module_run