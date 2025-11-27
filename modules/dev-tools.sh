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
  run "bash -c 'sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF'"

  log_info "Update with Docker repository..."
  run "sudo apt -qq update"

  apt_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  run "sudo usermod -aG docker ${USER}"
  run "sudo systemctl enable docker"
  log_info "Verify docker installation..."
  run "sudo docker run hello-world"
  log_info \"Docker installed. Logout/login to use without sudo.\"
  log_success "Docker installed!"
}

install_podman() {
  log_info "Step Podman..."
  apt_install podman buildah podman-compose skopeo
  log_success "Podman installed!"
}

install_kubectl() {
  log_info "Installing kubectl..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping kubectl."
    return 1
  fi
    
  log_info "→ Adding Kubernetes GPG key..."
  run "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg"
  
  log_info "→ Adding Kubernetes repository..."
  run "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list"
  
  log_info "Update repository..."
  run "sudo apt -qq update"
  apt_install kubectl
  
  log_success "kubectl installed!"
}

install_minikube() {
  log_info "Installing Minikube..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping Minikube."
    return 1
  fi
  
  local minikube_deb="/tmp/minikube_latest_amd64.deb"
  
  log_info "→ Downloading Minikube..."
  run "curl -fsSL -o '$minikube_deb' https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb"
  run "sudo dpkg -i '$minikube_deb' || true"
  run "sudo apt -qq -f install -y > /dev/null 2>&1"
  run "rm -f '$minikube_deb'"
  
  log_success "Minikube installed!"
}

install_awscli() {
  log_info "Installing AWS CLI..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping AWS CLI."
    return 1
  fi
  
  local aws_zip="/tmp/awscli.zip"
  
  log_info "→ Downloading AWS CLI..."
  run "curl -fsSL -o '$aws_zip' https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  run "unzip -q '$aws_zip' -d /tmp"
  run "sudo /tmp/aws/install --update"
  rm -f "$aws_zip"
  rm -rf /tmp/aws
  
  log_success "AWS CLI installed!"
}

install_vscode() {
  log_info "Installing Visual Studio Code..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping VS Code."
    return 1
  fi
  
  run "sudo apt install -y wget gpg apt-transport-https"
  
  log_info "→ Adding Microsoft GPG key..."
  run "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg"
  run "sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg"
  rm -f /tmp/packages.microsoft.gpg
  
  log_info "→ Adding VS Code repository..."
  run "echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee /etc/apt/sources.list.d/vscode.list"
  
  log_info "Update repository..."
  run "sudo apt -qq update"
  run "sudo apt install -y code"
  
  log_success "VS Code installed!"
}

# Install IntelliJ IDEA (Community Edition) from JetBrains site
install_intellij() {
  log_info "Installing IntelliJ IDEA Community..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping IntelliJ."
    return 1
  fi
  
  local idea_dir=""
  local idea_tar="/tmp/ideaIC.tar.gz"
  
  # Check if there's a local .tar.gz file
  if [ -f "$idea_tar" ]; then
    log_info "→ Using local tar.gz file"
    run "sudo tar -xzf ${idea_tar} -C /opt/"
    idea_dir=$(tar -tzf ${idea_tar} | head -1 | cut -f1 -d"/")
  else
    log_info "→ Getting latest IntelliJ IDEA version from JetBrains API..."
    local product="IIC"
    
    # Get the latest version info via JetBrains API
    local json_url="https://data.services.jetbrains.com/products/releases?code=${product}&latest=true&type=release"
    local download_url=$(curl -s "$json_url" | jq -r ".${product}[0].downloads.linux.link")
    local version=$(curl -s "$json_url" | jq -r ".${product}[0].version")
    
    if [ -z "$download_url" ] || [ "$download_url" = "null" ]; then
      log_error "Failed to get IntelliJ IDEA download URL from JetBrains API"
      return 1
    fi
    
    log_info "→ Downloading IntelliJ IDEA Community ${version}..."    
    run "curl -fsSL -o '$idea_tar' '$download_url'"
    run "sudo tar -xzf '$idea_tar' -C /opt/"
    
    # Find the extracted directory name
    idea_dir=$(tar -tzf "$idea_tar" | head -1 | cut -f1 -d"/")
    
    rm -f "$idea_tar"
  fi
  
  # Create symlink
  run "sudo ln -sf /opt/${idea_dir}/bin/idea.sh /usr/local/bin/idea"
  
  # Create desktop entry
  log_info "→ Creating desktop entry..."
  local desktop_file="$HOME/.local/share/applications/intellij.desktop"
  
  if [ "$DRYRUN" = false ]; then
    mkdir -p "$HOME/.local/share/applications"
    run "bash -c 'cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=IntelliJ IDEA Community
Icon=/opt/${idea_dir}/bin/idea.png
Exec=/opt/${idea_dir}/bin/idea.sh %f
Comment=Capable and Ergonomic IDE for JVM
Categories=Development;IDE;
Terminal=false
StartupWMClass=IntelliJ CE
EOF'"
    chmod +x "$desktop_file"
  else
    echo "[DRYRUN] would create $desktop_file"
  fi
  
  log_success "IntelliJ IDEA installed!"
}

install_postman() {
  log_info "Installing Postman..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping Postman."
    return 1
  fi

  local postman_tar="/tmp/postman-linux-x64.tar.gz"
  
  # Check for local tar.gz file first
  if [ -f "$postman_tar" ]; then
    log_info "→ Using local tar.gz file"
    run "sudo tar -xzf ${postman_tar} -C /opt/"
  else
    log_info "→ Downloading Postman..."    
    run "curl -fsSL -o '$postman_tar' https://dl.pstmn.io/download/latest/linux64"
    run "sudo tar -xzf '$postman_tar' -C /opt/"
    rm -f "$postman_tar"
  fi
  
  # Create symlink
  run "sudo ln -sf /opt/Postman/Postman /usr/local/bin/postman"
  
  # Create desktop entry
  if [ "$DRYRUN" = false ]; then
    run "bash -c 'sudo tee /usr/share/applications/postman.desktop > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Exec=/opt/Postman/Postman
Comment=API Development Environment
Categories=Development;
EOF'"
  else
    echo "[DRYRUN] would create /usr/share/applications/postman.desktop"
  fi
  
  log_success "Postman installed!"
}

install_drawio() {
  log_info "Installing Draw.io..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping Draw.io."
    return 1
  fi

  local drawio_deb="/tmp/drawio-amd64.deb"
  
  # Check for local .deb file
  if [ -f "$drawio_deb" ]; then
    log_info "→ Using local .deb file"
    run "sudo dpkg -i ${drawio_deb} || true"
    run "sudo apt -f install -y"
  else
    log_info "→ Getting latest Draw.io version..."
    local latest_version=$(curl -s https://api.github.com/repos/jgraph/drawio-desktop/releases/latest | grep 'tag_name' | cut -d'v' -f2 | cut -d'"' -f1)
    
    if [ -z "$latest_version" ]; then
      log_warn "Could not determine latest version. Using direct download..."
      latest_version="latest"
    fi
    
    log_info "→ Downloading Draw.io ${latest_version}..."
        
    if [ "$latest_version" = "latest" ]; then
      run "curl -fsSL -o '$drawio_deb' 'https://github.com/jgraph/drawio-desktop/releases/latest/download/drawio-amd64.deb'"
    else
      run "curl -fsSL -o '$drawio_deb' \"https://github.com/jgraph/drawio-desktop/releases/download/v${latest_version}/drawio-amd64-${latest_version}.deb\""
    fi
    
    run "sudo dpkg -i '$drawio_deb' || true"
    run "sudo apt -f install -y"
    rm -f "$drawio_deb"
  fi
  
  log_success "Draw.io installed!"
}

install_dbeaver() {
  log_info "Installing DBeaver..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping DBeaver."
    return 1
  fi

  local dbeaver_deb="/tmp/dbeaver-ce.deb"
  
  # Check for local .deb file
  if [ -f "$dbeaver_deb" ]; then
    log_info "→ Using local .deb file"
    run "sudo dpkg -i ${dbeaver_deb} || true"
    run "sudo apt -f install -y"
  else
    log_info "→ Downloading DBeaver..."
    
    run "curl -fsSL -o '$dbeaver_deb' https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb"
    run "sudo dpkg -i '$dbeaver_deb' || true"
    run "sudo apt -f install -y"
    rm -f "$dbeaver_deb"
  fi
  
  log_success "DBeaver installed!"
}


module_run() {
  log_info "Installing base development tools..."
  install_mise
  install_mise_tools
  install_dev_packages
  install_containers

  echo ""
  log_info "Installing additional development tools..."  # CLI tools

  install_kubectl || log_warn "kubectl installation failed"
  install_minikube || log_warn "Minikube installation failed"
  install_awscli || log_warn "AWS CLI installation failed"
  
  # IDEs and GUI tools
  install_vscode || log_warn "VS Code installation failed"
  install_intellij || log_warn "IntelliJ installation failed"
  install_postman || log_warn "Postman installation failed"
  install_drawio || log_warn "Draw.io installation failed"
  install_dbeaver || log_warn "DBeaver installation failed"
  
  log_success "Development tools installation completed!"
  echo ""
  log_info "Installed tools:"
  log_info "  • mise (version manager)"
  log_info "  • Docker & Podman"
  log_info "  • kubectl & Minikube"
  log_info "  • AWS CLI"
  log_info "  • VS Code (launch: code)"
  log_info "  • IntelliJ IDEA (launch: idea)"
  log_info "  • Postman (launch: postman)"
  log_info "  • Draw.io (in app menu)"
  log_info "  • DBeaver (in app menu)"
  echo ""
  log_info "Some tools may require logout/login to work properly"
}

module_run