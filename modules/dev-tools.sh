#!/usr/bin/env bash
# DESC: Installs mise and development tools
# REQUIRES: git, curl
# TAGS: development, mise, java, nodejs, python

set -euo pipefail

source "${DEBOOST_HOME}/lib/utils.sh" 2>/dev/null || {
  run() { echo "[RUN] $*"; eval "$@"; }
  log_info() { echo "[INFO] $*"; }
  log_success() { echo "[OK] $*"; }
}

# Lista de aplicativos Flatpak para instalação
DEV_PACKAGES=(
  "build-essential"
  "git-lfs"
  "ripgrep"
  "fd-find"
  "pkg-config"
  "libssl-dev"
  "jq"
  "tree"
  "neofetch"
  "meld"
  "git-delta"
  "git-subrepo"
  "hexedit"
  "automake"
  "make"
  "cmake"
  "autoconf"
  "libtool"
  "pkg-config"
  "pkgconf"
  "bison"
  "clang"
  "htop"
  "iotop"
  "python3-pip"
  "python3-virtualenv"
  "python3-wheel"
  "python3-setuptools"
  "perl"
  "lua"
)

install_mise() {
  log_info "Installing mise..."

  if command -v mise >/dev/null 2>&1; then
    log_info "mise already installed. Updating..."
    run "mise self-update"
  else
    run "curl https://mise.jdx.dev/install.sh | sh"
  fi

  # Configure shell
  local shell_config="${HOME}/.bashrc"

  if ! grep -q 'mise activate' "$shell_config" 2>/dev/null; then
    log_info "Adding mise to $shell_config"
    cat >> "$shell_config" <<'EOF'

# mise version manager
eval "$(mise activate bash)"
EOF
  fi

  # Load mise for current session
  eval "$(mise activate bash)"
}

install_mise_tools() {
  log_info "Installing tools with mise..."

  # Java
  if [ -n "${MISE_JAVA_VERSION:-}" ]; then
    log_info "Installing Java ${MISE_JAVA_VERSION}..."
    run "mise install java@${MISE_JAVA_VERSION}"
    run "mise use --global java@${MISE_JAVA_VERSION}"
  fi

  # Node.js
  if [ -n "${MISE_NODE_VERSION:-}" ]; then
    log_info "Installing Node.js ${MISE_NODE_VERSION}..."
    run "mise install node@${MISE_NODE_VERSION}"
    run "mise use --global node@${MISE_NODE_VERSION}"
  fi

  # Python
  if [ -n "${MISE_PYTHON_VERSION:-}" ]; then
    log_info "Installing Python ${MISE_PYTHON_VERSION}..."
    run "mise install python@${MISE_PYTHON_VERSION}"
    run "mise use --global python@${MISE_PYTHON_VERSION}"
  fi

  # Go
  if [ -n "${MISE_GO_VERSION:-}" ]; then
    log_info "Installing Go ${MISE_GO_VERSION}..."
    run "mise install go@${MISE_GO_VERSION}"
    run "mise use --global go@${MISE_GO_VERSION}"
  fi
}

install_dev_packages() {
  log_info "Installing development packages..."
  # Instalar com continue-on-error
  apt_install "${DEV_PACKAGES[@]}" || {
    log_warn "Some packages may have failed, keep going..."
    return 1
  }
  log_success "Development packages installed successfully."
}

install_containers() {
  log_info "Installing Docker and Podman..."
  install_docker_engine
  install_podman
  log_success "Docker and Podman installed successfully."
}

install_docker_engine() {
  log_info "Step Docker..."

  # Add Docker's official GPG key:
  run "sudo install -m 0755 -d /etc/apt/keyrings"
  run "sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc"
  run "sudo chmod a+r /etc/apt/keyrings/docker.asc"

  # Add the repository to Apt sources:
  sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

  log_info "Update with Docker repository..."
  run "sudo apt -qq update"

  run "sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
  run "sudo usermod -aG docker ${USER}"
  run "sudo systemctl enable docker"
  log_info "Verify docker installation..."
  run "sudo docker run hello-world"
  log_info \"Docker installed. Logout/login to use without sudo.\"
  log_success "Docker installed!"
}

install_podman() {
  log_info "Step Podman..."
  run "sudo apt install -y podman buildah podman-compose skopeo"
  log_success "Podman installed!"
}

module_run() {
  install_mise
  install_mise_tools
  install_dev_packages
  install_containers

  log_success "Development tools installed!"
  log_info "Run 'mise ls' to see installed versions"
}

module_run