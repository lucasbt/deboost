#!/usr/bin/env bash
# DESC: System tuning and performance optimizations for Debian
# REQUIRES: sudo
# TAGS: performance, tuning, optimization, swap, cache

set -euo pipefail

source "${DEBOOST_HOME}/lib/utils.sh" 2>/dev/null || {
  run() { echo "[RUN] $*"; eval "$@"; }
  log_info() { echo "[INFO] $*"; }
  log_success() { echo "[OK] $*"; }
}

tune_swappiness() {
  log_info "Configuring swappiness..."
  
  local swappiness="${SWAPPINESS:-10}"
  
  log_info "→ Setting swappiness to ${swappiness}"
  run "sudo sysctl vm.swappiness=${swappiness}"
  
  # Make it persistent
  if ! grep -q "vm.swappiness" /etc/sysctl.conf 2>/dev/null; then
    run "echo 'vm.swappiness=${swappiness}' | sudo tee -a /etc/sysctl.conf > /dev/null"
  else
    run "sudo sed -i 's/^vm.swappiness=.*/vm.swappiness=${swappiness}/' /etc/sysctl.conf"
  fi
  
  log_success "Swappiness configured to ${swappiness}"
}

tune_cache_pressure() {
  log_info "Configuring VFS cache pressure..."
  
  local cache_pressure="${VFS_CACHE_PRESSURE:-50}"
  
  log_info "→ Setting vfs_cache_pressure to ${cache_pressure}"
  run "sudo sysctl vm.vfs_cache_pressure=${cache_pressure}"
  
  # Make it persistent
  if ! grep -q "vm.vfs_cache_pressure" /etc/sysctl.conf 2>/dev/null; then
    run "echo 'vm.vfs_cache_pressure=${cache_pressure}' | sudo tee -a /etc/sysctl.conf > /dev/null"
  else
    run "sudo sed -i 's/^vm.vfs_cache_pressure=.*/vm.vfs_cache_pressure=${cache_pressure}/' /etc/sysctl.conf"
  fi
  
  log_success "VFS cache pressure configured to ${cache_pressure}"
}

tune_dirty_ratio() {
  log_info "Configuring dirty page ratios..."
  
  local dirty_ratio="${DIRTY_RATIO:-10}"
  local dirty_bg_ratio="${DIRTY_BACKGROUND_RATIO:-5}"
  
  log_info "→ Setting dirty_ratio to ${dirty_ratio}%"
  run "sudo sysctl vm.dirty_ratio=${dirty_ratio}"
  
  log_info "→ Setting dirty_background_ratio to ${dirty_bg_ratio}%"
  run "sudo sysctl vm.dirty_background_ratio=${dirty_bg_ratio}"
  
  # Make it persistent
  if ! grep -q "vm.dirty_ratio" /etc/sysctl.conf 2>/dev/null; then
    run "echo 'vm.dirty_ratio=${dirty_ratio}' | sudo tee -a /etc/sysctl.conf > /dev/null"
  else
    run "sudo sed -i 's/^vm.dirty_ratio=.*/vm.dirty_ratio=${dirty_ratio}/' /etc/sysctl.conf"
  fi
  
  if ! grep -q "vm.dirty_background_ratio" /etc/sysctl.conf 2>/dev/null; then
    run "echo 'vm.dirty_background_ratio=${dirty_bg_ratio}' | sudo tee -a /etc/sysctl.conf > /dev/null"
  else
    run "sudo sed -i 's/^vm.dirty_background_ratio=.*/vm.dirty_background_ratio=${dirty_bg_ratio}/' /etc/sysctl.conf"
  fi
  
  log_success "Dirty ratios configured"
}

tune_io_scheduler() {
  log_info "Configuring I/O scheduler..."
  
  local scheduler="${IO_SCHEDULER:-mq-deadline}"
  
  # Detect disk type (SSD or HDD)
  local disk_device=$(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//' | xargs basename)
  
  if [ -n "$disk_device" ] && [ -f "/sys/block/${disk_device}/queue/scheduler" ]; then
    log_info "→ Setting I/O scheduler to ${scheduler} for ${disk_device}"
    
    # Check if scheduler is available
    if grep -q "$scheduler" "/sys/block/${disk_device}/queue/scheduler" 2>/dev/null; then
      run "echo '${scheduler}' | sudo tee /sys/block/${disk_device}/queue/scheduler > /dev/null"
      
      # Make it persistent via udev rule
      if [ "$DRYRUN" = false ]; then
        sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null <<EOF
# Set I/O scheduler for all block devices
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="${scheduler}"
ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="${scheduler}"
EOF
      else
        echo "[DRYRUN] would create /etc/udev/rules.d/60-ioschedulers.rules"
      fi
      
      log_success "I/O scheduler configured to ${scheduler}"
    else
      log_warn "Scheduler ${scheduler} not available for ${disk_device}"
    fi
  else
    log_warn "Could not detect disk device for I/O scheduler configuration"
  fi
}

tune_network() {
  log_info "Configuring network tuning..."
  
  # TCP optimizations
  log_info "→ Applying TCP optimizations"
  
  run "sudo sysctl net.core.rmem_max=16777216"
  run "sudo sysctl net.core.wmem_max=16777216"
  run "sudo sysctl net.ipv4.tcp_rmem='4096 87380 16777216'"
  run "sudo sysctl net.ipv4.tcp_wmem='4096 65536 16777216'"
  run "sudo sysctl net.ipv4.tcp_congestion_control=bbr"
  
  # Make persistent
  local sysctl_conf="/etc/sysctl.d/99-network-tuning.conf"
  
  if [ "$DRYRUN" = false ]; then
    sudo tee "$sysctl_conf" > /dev/null <<EOF
# Network tuning for performance
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
EOF
  else
    echo "[DRYRUN] would create $sysctl_conf"
  fi
  
  log_success "Network tuning applied"
}

disable_unnecessary_services() {
  log_info "Disabling unnecessary services..."
  
  local services_to_disable=(
    "bluetooth.service"
    "cups.service"
    "cups-browsed.service"
    "ModemManager.service"
  )
  
  for service in "${services_to_disable[@]}"; do
    if systemctl is-enabled "$service" &>/dev/null; then
      log_info "→ Disabling $service"
      run "sudo systemctl disable $service" || true
      run "sudo systemctl stop $service" || true
    else
      log_debug "$service already disabled or not present"
    fi
  done
  
  log_success "Unnecessary services disabled"
}

configure_journal() {
  log_info "Configuring systemd journal..."
  
  local max_size="${JOURNAL_MAX_SIZE:-100M}"
  
  if [ "$DRYRUN" = false ]; then
    sudo mkdir -p /etc/systemd/journald.conf.d
    sudo tee /etc/systemd/journald.conf.d/00-journal-size.conf > /dev/null <<EOF
[Journal]
SystemMaxUse=${max_size}
SystemMaxFileSize=50M
MaxRetentionSec=1month
EOF
    
    run "sudo systemctl restart systemd-journald"
  else
    echo "[DRYRUN] would create /etc/systemd/journald.conf.d/00-journal-size.conf"
  fi
  
  log_success "Journal configured with max size ${max_size}"
}

configure_tmpfs() {
  log_info "Configuring tmpfs for /tmp..."
  
  if ! grep -q "tmpfs.*\/tmp" /etc/fstab 2>/dev/null; then
    log_info "→ Adding tmpfs mount for /tmp to fstab"
    
    if [ "$DRYRUN" = false ]; then
      echo "tmpfs /tmp tmpfs defaults,noatime,mode=1777,size=2G 0 0" | sudo tee -a /etc/fstab > /dev/null
      log_info "Tmpfs configuration added. Will take effect after reboot."
    else
      echo "[DRYRUN] would add tmpfs to /etc/fstab"
    fi
  else
    log_info "/tmp already configured as tmpfs"
  fi
  
  log_success "Tmpfs configuration complete"
}

tune_cpu_governor() {
  log_info "Configuring CPU governor..."
  
  local governor="${CPU_GOVERNOR:-performance}"
  
  if [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
    log_info "→ Setting CPU governor to ${governor}"
    
    run "sudo apt install -y cpufrequtils"
    
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      if [ -f "$cpu" ]; then
        run "echo '${governor}' | sudo tee $cpu > /dev/null" || true
      fi
    done
    
    # Make persistent
    if [ "$DRYRUN" = false ]; then
      sudo tee /etc/default/cpufrequtils > /dev/null <<EOF
# CPU governor configuration
GOVERNOR="${governor}"
EOF
    else
      echo "[DRYRUN] would create /etc/default/cpufrequtils"
    fi
    
    log_success "CPU governor set to ${governor}"
  else
    log_warn "CPU frequency scaling not available"
  fi
}

reduce_boot_time() {
  log_info "Optimizing boot time..."
  
  # Reduce GRUB timeout
  local grub_timeout="${GRUB_TIMEOUT:-2}"
  
  if [ -f "/etc/default/grub" ]; then
    log_info "→ Setting GRUB timeout to ${grub_timeout} seconds"
    run "sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=${grub_timeout}/' /etc/default/grub"
    run "sudo update-grub"
  fi
  
  # Disable plymouth (boot splash)
  if grep -q "quiet splash" /etc/default/grub 2>/dev/null; then
    log_info "→ Disabling plymouth splash screen"
    run "sudo sed -i 's/quiet splash/quiet/' /etc/default/grub"
    run "sudo update-grub"
  fi
  
  log_success "Boot time optimizations applied"
}

configure_preload() {
  log_info "Installing and configuring preload..."
  
  if ! command -v preload &>/dev/null; then
    run "sudo apt install -y preload"
    run "sudo systemctl enable preload"
    run "sudo systemctl start preload"
    log_success "Preload installed and enabled"
  else
    log_info "Preload already installed"
  fi
}

clean_system() {
  log_info "Cleaning unnecessary packages and cache..."
  
  run "sudo apt autoremove -y"
  run "sudo apt autoclean"
  run "sudo apt clean"
  
  # Clear old journal logs
  run "sudo journalctl --vacuum-time=7d"
  
  log_success "System cleaned"
}

show_tuning_summary() {
  echo ""
  log_info "═══════════════════════════════════════════════════════"
  log_info "Tuning Summary"
  log_info "═══════════════════════════════════════════════════════"
  
  if [ "$DRYRUN" = false ]; then
    echo ""
    log_info "Current System Values:"
    echo "  Swappiness: $(cat /proc/sys/vm/swappiness)"
    echo "  VFS Cache Pressure: $(cat /proc/sys/vm/vfs_cache_pressure)"
    echo "  Dirty Ratio: $(cat /proc/sys/vm/dirty_ratio)%"
    echo "  Dirty Background Ratio: $(cat /proc/sys/vm/dirty_background_ratio)%"
    
    if [ -d "/sys/devices/system/cpu/cpu0/cpufreq" ]; then
      echo "  CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
    fi
    
    echo ""
    log_info "Recommendations:"
    echo "  • Reboot system to apply all changes"
    echo "  • Monitor system performance with 'htop' or 'btop'"
    echo "  • Check disk I/O with 'iotop'"
    echo "  • Review journal logs with 'journalctl -xe'"
  fi
  
  log_info "═══════════════════════════════════════════════════════"
}

module_run() {
  log_info "Starting system tuning..."
  echo ""
  
  # Memory and swap tuning
  tune_swappiness
  tune_cache_pressure
  tune_dirty_ratio
  
  # I/O tuning
  tune_io_scheduler
  
  # Network tuning
  tune_network
  
  # System services
  disable_unnecessary_services
  configure_journal
  configure_tmpfs
  
  # CPU tuning
  tune_cpu_governor
  
  # Boot optimization
  reduce_boot_time
  
  # Application preloading
  if [ "${INSTALL_PRELOAD:-true}" = "true" ]; then
    configure_preload
  fi
  
  # Cleanup
  clean_system
  
  log_success "System tuning completed!"
  
  show_tuning_summary
}

module_run