#!/usr/bin/env bash
# Deboost - Utility functions library
# This file is imported by modules

# Prevent multiple sourcing
if [ -n "${DEBOOST_UTILS_LOADED:-}" ]; then
    return 0
fi
export DEBOOST_UTILS_LOADED=true

# ============================================================================
# LOGGING
# ============================================================================

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log_info() {
  echo -e "\033[1;34m[INFO] $*\033[0m"
}

log_success() {
  echo -e "\033[1;32m[OK] $*\033[0m"
}

log_warn() {
  echo -e "\033[1;33m[WARN] $*\033[0m" >&2
}

log_error() {
  echo -e "\033[1;31m[ERROR] $*\033[0m" >&2
}

log_debug() {
  if [ "${VERBOSE:-false}" = true ]; then
    echo -e "\033[1;90m[DEBUG] $*\033[0m"
  fi
}

# ============================================================================
# EXECUTION
# ============================================================================

run() {
  if [ "${DRYRUN:-false}" = true ]; then
    log_info "[DRYRUN] $*"
    return 0
  else
    log_debug "[RUN] $*"
    eval "$@"
  fi
}

# ============================================================================
# CHECKS
# ============================================================================

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    log_error "Command '$cmd' not found."
    return 1
  fi
  return 0
}

# Verifica se o comando existe; se não, tenta instalar via apt_install
require_or_install() {
  local cmd="$1"
  if ! command -v "$cmd" &>/dev/null; then
    log_warn "Command '$cmd' not found. Attempting to install..."
    apt_install "$cmd"
    if ! command -v "$cmd" &>/dev/null; then
      log_error "Failed to install '$cmd'. Aborting."
      exit 1
    fi
  fi
}

require_sudo() {
  if [ "$EUID" -ne 0 ] && [ "${DRYRUN:-false}" = false ]; then
    if ! sudo -v &>/dev/null; then
      log_error "This module requires superuser privileges."
      return 1
    fi
  fi
  return 0
}

check_internet() {
  if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    log_warn "No internet connection."
    return 1
  fi
  return 0
}

is_wayland() {
  [ "${XDG_SESSION_TYPE:-}" = "wayland" ]
}

is_gnome() {
  [ "${XDG_CURRENT_DESKTOP:-}" = "GNOME" ]
}

# ============================================================================
# USER INTERACTION
# ============================================================================

ask_yes_no() {
  local prompt="$1"
  local default="${2:-n}"
  
  if [ "$default" = "y" ]; then
    prompt="$prompt (Y/n): "
  else
    prompt="$prompt (y/N): "
  fi
  
  read -rp "$prompt" response
  response="${response:-$default}"
  
  [[ "$response" =~ ^[yY]$ ]]
}

# ============================================================================
# PACKAGE MANAGEMENT
# ============================================================================

apt_install() {
  local packages=("$@")
  
  log_info "Installing packages: \033[1;32m${packages[*]}\033[0m"
  
  if [ "${DRYRUN:-false}" = true ]; then
    log_info "[DRYRUN] apt install -y -qq ${packages[*]} --fix-broken --ignore-missing --no-install-recommends --no-install-suggests --show-progress"
  else
    sudo apt install -y -qq "${packages[@]} --fix-broken --ignore-missing --no-install-recommends --no-install-suggests --show-progress"
  fi
}

apt_remove() {
  local packages=("$@")
  
  log_info "Removing packages: ${packages[*]}"
  
  if [ "${DRYRUN:-false}" = true ]; then
    log_info "[DRYRUN] apt remove -y ${packages[*]}"
  else
    sudo apt remove -y "${packages[@]}"
  fi
}

# ============================================================================
# GSETTINGS (GNOME)
# ============================================================================

gsettings_set() {
  local schema="$1"
  local key="$2"
  local value="$3"
  
  if ! command -v gsettings &>/dev/null; then
    log_warn "gsettings not available. Skipping: $schema $key"
    return 0
  fi
  
  run "gsettings set '$schema' '$key' '$value'"
}

# ============================================================================
# CONFIGURATION FILES
# ============================================================================

backup_file() {
  local file="$1"
  
  if [ -f "$file" ]; then
    local backup="${file}.deboost-backup-$(date +%Y%m%d-%H%M%S)"
    run "cp '$file' '$backup'"
    log_info "Backup created: $backup"
  fi
}

append_to_file() {
  local content="$1"
  local file="$2"
  
  if ! grep -qF "$content" "$file" 2>/dev/null; then
    if [ "${DRYRUN:-false}" = true ]; then
      log_info "[DRYRUN] Would append to $file: $content"
    else
      echo "$content" >> "$file"
      log_debug "Appended to $file"
    fi
  else
    log_debug "Content already exists in $file"
  fi
}

# ============================================================================
# SYSTEM DETECTION
# ============================================================================

get_debian_version() {
  if [ -f /etc/debian_version ]; then
    cat /etc/debian_version
  else
    echo "unknown"
  fi
}

get_cpu_info() {
  grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | xargs
}

get_gpu_info() {
  lspci | grep -i vga | cut -d: -f3 | xargs
}

# ============================================================================
# FUNCTION EXPORTS
# ============================================================================

export -f log log_info log_success log_warn log_error log_debug
export -f run
export -f require_command require_sudo check_internet is_wayland is_gnome
export -f ask_yes_no
export -f apt_install apt_remove
export -f gsettings_set
export -f backup_file append_to_file
export -f get_debian_version get_cpu_info get_gpu_info