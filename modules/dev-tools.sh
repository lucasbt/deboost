#!/usr/bin/env bash
# DESC: Installs mise and development tools
# REQUIRES: git, curl
# TAGS: development, mise, java, nodejs, python

set -euo pipefail

source "${DEBOOST_HOME}/lib/utils.sh" 2>/dev/null || {
  log_info() { echo "[INFO] $*"; }
  log_success() { echo "[OK] $*"; }
  log_warn() { echo "[WARN] $*"; }
  log_error() { echo "[ERROR] $*"; }
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
  "perl"
  "lua"
)

install_sdkman() {
  log_info "Installing SDKMAN!..."
  
  if [ -d "${HOME}/.sdkman" ]; then
    log_info "SDKMAN! already installed. Updating..."
    # shellcheck disable=SC1091
    source "${HOME}/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true
    run "sdk selfupdate force" || true
  else
    if ! check_internet; then
      log_warn "No internet connection. Skipping SDKMAN!."
      return 1
    fi
    
    log_info "→ Downloading and installing SDKMAN!..."
    run "curl -s 'https://get.sdkman.io' | bash"
  fi
  
  # Configure shell
  local shell_config="${HOME}/.bashrc"
  
  if ! grep -q 'sdkman-init.sh' "$shell_config" 2>/dev/null; then
    log_info "Adding SDKMAN! to $shell_config"
    run "bash -c 'cat >> \"$shell_config\" <<'\''EOF'\''

# SDKMAN!
export SDKMAN_DIR=\"\$HOME/.sdkman\"
[[ -s \"\$HOME/.sdkman/bin/sdkman-init.sh\" ]] && source \"\$HOME/.sdkman/bin/sdkman-init.sh\"
EOF'"
  fi
  
  # Load SDKMAN! in current session
  if [ -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]; then
    # shellcheck disable=SC1091
    source "${HOME}/.sdkman/bin/sdkman-init.sh"
  fi
  
  log_success "SDKMAN! installed!"
}

# Install JDKS
install_sdkman_jdks() {
    log_info "Installing SDKMAN JDKs..."

    source "$HOME/.sdkman/bin/sdkman-init.sh"

    if [ ! -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]; then
      log_warn "SDKMAN! not installed. Skipping Java install."
      return 1
    fi

    # Install Java
    local jdks=("25.0.1-tem")
    if [ -n "${SDKMAN_JAVA_VERSION:-}" ]; then
      log_info "→ Installing Java ${SDKMAN_JAVA_VERSION}..."
      run "sdk install java ${SDKMAN_JAVA_VERSION}" || true
      run "sdk default java ${SDKMAN_JAVA_VERSION}" || true
    else
      log_info "→ Installing latest Java LTS..."
      run "sdk install java ${jdks}" || true
      # Set default JDK
      run "sdk default java ${jdks}" || log_warning "Failed to set default Java"
    fi
  
    log_success "SDKMAN JDKs installed"
}

install_java_tools() {
  log_info "Installing Java, Maven, and Gradle via SDKMAN!..."
  
  if [ ! -f "${HOME}/.sdkman/bin/sdkman-init.sh" ]; then
    log_warn "SDKMAN! not installed. Skipping Java tools."
    return 1
  fi
  
  # shellcheck disable=SC1091
  source "${HOME}/.sdkman/bin/sdkman-init.sh"
  
  # Install Maven
  if [ -n "${SDKMAN_MAVEN_VERSION:-}" ]; then
    log_info "→ Installing Maven ${SDKMAN_MAVEN_VERSION}..."
    run "sdk install maven ${SDKMAN_MAVEN_VERSION}" || true
  else
    log_info "→ Installing latest Maven..."
    run "sdk install maven" || true
  fi
  
  # Install Gradle
  if [ -n "${SDKMAN_GRADLE_VERSION:-}" ]; then
    log_info "→ Installing Gradle ${SDKMAN_GRADLE_VERSION}..."
    run "sdk install gradle ${SDKMAN_GRADLE_VERSION}" || true
  else
    log_info "→ Installing latest Gradle..."
    run "sdk install gradle" || true
  fi
  
  log_success "Java tools installed!"
}

install_nodejs() {
  log_info "Installing Node.js and npm..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping Node.js."
    return 1
  fi
  
  # Install Node.js using official NodeSource repository
  log_info "→ Adding NodeSource repository..."
  
  local node_version="${NODEJS_VERSION:-24}"
  
  run "curl -fsSL https://deb.nodesource.com/setup_${node_version}.x | sudo -E bash -"
  run "sudo apt -qq update"
  run "sudo apt install -y nodejs"
  
  # Verify npm is installed
  if command -v npm &>/dev/null; then
    log_info "→ Updating npm to latest version..."
    run "sudo npm install -g npm@latest"
  fi
  
  log_success "Node.js and npm installed!"
  log_info "Node.js version: $(node --version 2>/dev/null || echo 'not available')"
  log_info "npm version: $(npm --version 2>/dev/null || echo 'not available')"
}

install_pyenv() {
  log_info "Installing pyenv..."
  
  # Verificar se já está instalado
  if command -v pyenv >/dev/null 2>&1 || [ -d "${HOME}/.pyenv" ]; then
    log_info "pyenv already installed. Updating..."
    
    if [ -d "${HOME}/.pyenv" ]; then
      local current_branch
      current_branch=$(git -C "${HOME}/.pyenv" symbolic-ref --short HEAD 2>/dev/null || echo "master")
      run "git -C '${HOME}/.pyenv' fetch origin"
      run "git -C '${HOME}/.pyenv' reset --hard 'origin/${current_branch}'"
    fi
    return 0
  fi
  
  # Verificar internet
  if ! check_internet; then
    log_warn "No internet connection. Skipping pyenv."
    return 1
  fi
  
  # Instalar dependências e pyenv
  log_info "→ Installing dependencies and pyenv..."
  run "sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev curl"
  
  log_info "→ Running official installer..."
  run "curl -fsSL https://pyenv.run | bash"
  
  log_success "pyenv installed!"
}

install_python() {
  log_info "Installing Python via pyenv..."
  
  if ! command -v pyenv &>/dev/null; then
    log_warn "pyenv not found. Skipping Python installation."
    return 1
  fi
  
  if [ -n "${PYENV_PYTHON_VERSION:-}" ]; then
    log_info "→ Installing Python ${PYENV_PYTHON_VERSION}..."
    run "pyenv install ${PYENV_PYTHON_VERSION}" || true
    run "pyenv global ${PYENV_PYTHON_VERSION}" || true
  else
    log_info "→ Installing latest Python 3..."
    local latest_python=$(pyenv install --list | grep -E '^\s*3\.[0-9]+\.[0-9]+$' | tail -1 | xargs)
    if [ -n "$latest_python" ]; then
      run "pyenv install ${latest_python}" || true
      run "pyenv global ${latest_python}" || true
    fi
  fi
  
  log_success "Python installed!"
}

install_golang() {
  log_info "Installing Golang..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping Go."
    return 1
  fi
  
  local go_version=""
  
  # Check if version is specified in config
  if [ -n "${GOLANG_VERSION:-}" ]; then
    go_version="${GOLANG_VERSION}"
    log_info "→ Using configured Go version: ${go_version}"
  else
    # Get latest Go version from official site
    log_info "→ Fetching latest Go version from official site..."
    go_version=$(curl -s https://go.dev/VERSION?m=text | head -1 | sed 's/go//')
    
    if [ -z "$go_version" ]; then
      log_error "Could not fetch latest Go version from official site."
      return 1
    fi
    
    log_info "→ Latest Go version available: ${go_version}"
  fi
  
  # Check if Go is already installed with the same version
  if command -v go &>/dev/null; then
    local current_version=$(go version | awk '{print $3}' | sed 's/go//')
    if [ "$current_version" = "$go_version" ]; then
      log_info "Go ${go_version} already installed."
      return 0
    fi
    log_info "→ Upgrading from Go ${current_version} to ${go_version}"
  fi
  
  log_info "→ Downloading Go ${go_version}..."
  local go_tar="/tmp/go${go_version}.linux-amd64.tar.gz"
  run "curl -fsSL -o '$go_tar' https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
  
  log_info "→ Installing Go..."
  run "sudo rm -rf /usr/local/go"
  run "sudo tar -C /usr/local -xzf '$go_tar'"
  run "rm -f '$go_tar'"
  
  # Configure shell
  local shell_config="${HOME}/.bashrc"
  
  if ! grep -q '/usr/local/go/bin' "$shell_config" 2>/dev/null; then
    log_info "Adding Go to PATH in $shell_config"
    run "bash -c 'cat >> \"$shell_config\" <<'\''EOF'\''

# Go
export PATH=\$PATH:/usr/local/go/bin
export GOPATH=\$HOME/go
export PATH=\$PATH:\$GOPATH/bin
EOF'"
  fi
  
  # Add to current session
  export PATH=$PATH:/usr/local/go/bin
  export GOPATH=$HOME/go
  export PATH=$PATH:$GOPATH/bin
  
  log_success "Go ${go_version} installed!"
}

install_rust() {
  log_info "Installing Rust..."
  
  if ! check_internet; then
    log_warn "No internet connection. Skipping Rust."
    return 1
  fi
  
  if command -v rustc &>/dev/null; then
    log_info "Rust already installed. Updating..."
    run "rustup update stable"
  else
    log_info "→ Downloading and installing Rust..."
    run "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    
    # Load cargo env in current session
    if [ -f "${HOME}/.cargo/env" ]; then
      # shellcheck disable=SC1091
      source "${HOME}/.cargo/env"
    fi
  fi
  
  log_success "Rust installed!"
  log_info "Rust version: $(rustc --version 2>/dev/null || echo 'not available')"
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
Suites: $(. /etc/os-release && echo \"\$VERSION_CODENAME\")
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
  log_info "Docker installed. Logout/login to use without sudo."
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
  run "rm -f '$aws_zip'"
  run "rm -rf /tmp/aws"
  
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
  run "rm -f /tmp/packages.microsoft.gpg"
  
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
    
    run "rm -f '$idea_tar'"
  fi
  
  # Create symlink
  run "sudo ln -sf /opt/${idea_dir}/bin/idea.sh /usr/local/bin/idea"
  
  # Create desktop entry
  log_info "→ Creating desktop entry..."
  local desktop_file="$HOME/.local/share/applications/intellij.desktop"
  
  run "mkdir -p \"$HOME/.local/share/applications\""
  run "bash -c 'cat > \"$desktop_file\" <<EOF
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
  run "chmod +x \"$desktop_file\""
  
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
    run "rm -f '$postman_tar'"
  fi
  
  # Create symlink
  run "sudo ln -sf /opt/Postman/Postman /usr/local/bin/postman"
  
  # Create desktop entry
  run "bash -c 'sudo tee /usr/share/applications/postman.desktop > /dev/null <<EOF
[Desktop Entry]
Type=Application
Name=Postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Exec=/opt/Postman/Postman
Comment=API Development Environment
Categories=Development;
EOF'"
  
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
    run "rm -f '$drawio_deb'"
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
    run "rm -f '$dbeaver_deb'"
  fi
  
  log_success "DBeaver installed!"
}


module_run() {
  log_info "Installing base development packages..."
  install_dev_packages
  install_containers
  
  echo ""
  log_info "Installing language managers and runtimes..."
  
  # Language managers and runtimes
  install_sdkman || log_warn "SDKMAN! installation failed"
  install_sdkman_jdks || log_warn "Java SDKs installation failed"
  install_java_tools || log_warn "Java tools installation failed"
  install_nodejs || log_warn "Node.js installation failed"
  install_pyenv || log_warn "pyenv installation failed"
  install_python || log_warn "Python installation failed"
  install_golang || log_warn "Go installation failed"
  install_rust || log_warn "Rust installation failed"
  
  echo ""
  log_info "Installing cloud and container tools..."
  
  # CLI tools
  install_kubectl || log_warn "kubectl installation failed"
  install_minikube || log_warn "Minikube installation failed"
  install_awscli || log_warn "AWS CLI installation failed"
  
  echo ""
  log_info "Installing IDEs and GUI tools..."
  
  # IDEs and GUI tools
  install_vscode || log_warn "VS Code installation failed"
  install_intellij || log_warn "IntelliJ installation failed"
  install_postman || log_warn "Postman installation failed"
  install_drawio || log_warn "Draw.io installation failed"
  install_dbeaver || log_warn "DBeaver installation failed"
  
  log_success "Development tools installation completed!"
  echo ""
  log_info "Installed tools:"
  log_info "  • SDKMAN! (Java, Maven, Gradle)"
  log_info "  • Node.js & npm"
  log_info "  • pyenv & Python"
  log_info "  • Go"
  log_info "  • Rust"
  log_info "  • Docker & Podman"
  log_info "  • kubectl & Minikube"
  log_info "  • AWS CLI"
  log_info "  • VS Code (launch: code)"
  log_info "  • IntelliJ IDEA (launch: idea)"
  log_info "  • Postman (launch: postman)"
  log_info "  • Draw.io (in app menu)"
  log_info "  • DBeaver (in app menu)"
  echo ""
  log_info "IMPORTANT: Restart your terminal or run 'source ~/.bashrc'"
  log_info "Then check installed versions:"
  log_info "  • Java: java -version"
  log_info "  • Maven: mvn -version"
  log_info "  • Gradle: gradle -version"
  log_info "  • Node.js: node --version"
  log_info "  • Python: python --version"
  log_info "  • Go: go version"
  log_info "  • Rust: rustc --version"
}

module_run