#!/usr/bin/env bash
# DESC: Installs popular browsers (Firefox, Chrome, Brave)
# REQUIRES: sudo
# TAGS: browsers, firefox, chrome, brave

set -euo pipefail

source "${DEBOOST_HOME}/lib/utils.sh" 2>/dev/null || {
  run() { echo "[RUN] $*"; eval "$@"; }
  log_info() { echo "[INFO] $*"; }
  log_success() { echo "[OK] $*"; }
}

install_firefox() {
  log_info "Installing latest Firefox..."
  
  require_sudo
  
  # Remove Firefox ESR if present
  if dpkg -l | grep -q firefox-esr; then
      log_info "Removing Firefox ESR..."
      apt_remove firefox-esr
  fi

  # Add Mozilla repository
  log_info "Adding Mozilla repository..."
  run "sudo install -d -m 0755 /etc/apt/keyrings"
  run "wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null"
  run "bash -c 'sudo tee /etc/apt/sources.list.d/mozilla.sources > /dev/null <<EOF
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF'"

  run "bash -c 'sudo tee /etc/apt/preferences.d/mozilla > /dev/null <<EOF
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF'"

  log_info "Update with Mozilla repository..."
  run "sudo apt -qq update"
  apt_install firefox firefox-l10n-pt-br

  log_success "Firefox installed!"
}

install_chrome() {
  log_info "Installing Google Chrome..."
  
  local chrome_deb="/tmp/google-chrome-stable_current_amd64.deb"
  
  if [ -f "$chrome_deb" ]; then
    log_info "→ Using local file"
    run "sudo dpkg -i $chrome_deb || true"
    run "sudo apt -f install -y"
  else
    log_info "→ Downloading Chrome..."
    if check_internet; then
      run "wget -q --show-progress -O '$chrome_deb' https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
      run "sudo dpkg -i '$chrome_deb' || true"
      run "sudo apt -f install -y"
      rm -f "$chrome_deb"
    else
      log_warn "No connection. Download manually from: https://www.google.com/chrome/. Skipping Chrome."
      return 1
    fi
  fi
  
  log_success "Chrome installed!"
}

install_brave() {
  log_info "Installing Brave Browser..."
  
  if ! check_internet; then
    log_warn "No connection. Skipping Brave."
    return 1
  fi
  
  log_info "→ Adding Brave GPG key..."
  run "sudo wget -q --show-progress -O /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"
  
  log_info "→ Adding repository..."
  run "echo 'deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main' | sudo tee /etc/apt/sources.list.d/brave-browser-release.list"
  
  log_info "Update with Brave repository..."
  run "sudo apt -qq update"
  apt_install brave-browser
  
  log_success "Brave installed!"
}

install_vivaldi() {
  log_info "Installing Vivaldi Browser..."
  
  if ! check_internet; then
    log_warn "No connection. Skipping Vivaldi."
    return 1
  fi
  
  log_info "→ Adding Vivaldi GPG key..."
  run "wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | gpg --dearmor | sudo dd of=/usr/share/keyrings/vivaldi-browser.gpg"
  
  log_info "→ Adding repository..."
  run "echo 'deb [signed-by=/usr/share/keyrings/vivaldi-browser.gpg arch=amd64] https://repo.vivaldi.com/archive/deb/ stable main' | sudo dd of=/etc/apt/sources.list.d/vivaldi-archive.list"
  
  log_info "Update with Vivaldi repository..."
  run "sudo apt -qq update"
  apt_install vivaldi-stable
  
  log_success "Vivaldi installed!"
}

module_run() {
  log_info "Browser Installer"
  echo ""
  echo "Choose browsers to install:"
  echo ""
  
  local install_list=()
  
  if ask_yes_no "Install Firefox?" "y"; then
    install_list+=("firefox")
  fi
  
  if ask_yes_no "Install Google Chrome?" "y"; then
    install_list+=("chrome")
  fi
  
  if ask_yes_no "Install Brave Browser?" "n"; then
    install_list+=("brave")
  fi
  
  if ask_yes_no "Install Vivaldi?" "n"; then
    install_list+=("vivaldi")
  fi
  
  if [ ${#install_list[@]} -eq 0 ]; then
    log_info "No browsers selected."
    return 0
  fi
  
  echo ""
  log_info "Installing: ${install_list[*]}"
  echo ""
  
  for browser in "${install_list[@]}"; do
    case "$browser" in
      firefox) install_firefox ;;
      chrome) install_chrome ;;
      brave) install_brave ;;
      vivaldi) install_vivaldi ;;
    esac
  done
  
  log_success "Browsers installed!"
}

module_run