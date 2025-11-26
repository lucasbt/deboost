#!/usr/bin/env bash
# Deboost - Quick installer
# curl -fsSL https://raw.githubusercontent.com/lucasbt/deboost/main/install.sh | bash

set -euo pipefail

readonly DEBOOST_GIT_URL="https://github.com/lucasbt/deboost"
readonly DEBOOST_HOME="${HOME}/.local/share/deboost"
readonly DEBOOST_BIN="${HOME}/.local/bin"

echo "════════════════════════════════════════════════════════════"
echo "  🚀 Deboost Installer"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check dependencies
echo "→ Checking dependencies..."
for cmd in git curl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "❌ Error: '$cmd' not found. Install it first:"
    echo "   sudo apt install $cmd"
    exit 1
  fi
done
echo "✓ Dependencies OK"
echo ""

# Check if already installed
if [ -d "${DEBOOST_HOME}" ]; then
  echo "⚠️  Deboost is already installed at: ${DEBOOST_HOME}"
  read -rp "   Do you want to reinstall? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[yY]$ ]]; then
    echo "   Installation cancelled."
    exit 0
  fi
  echo "→ Removing previous installation..."
  rm -rf "${DEBOOST_HOME}"
fi

# Clone repository
echo "→ Cloning repository..."
git clone --quiet "${DEBOOST_GIT_URL}" "${DEBOOST_HOME}"
echo "✓ Repository cloned"
echo ""

# Create structure
echo "→ Creating directory structure..."
mkdir -p "${DEBOOST_BIN}"
mkdir -p "${DEBOOST_HOME}/lib"
mkdir -p "${DEBOOST_HOME}/modules"
mkdir -p "${DEBOOST_HOME}/config"

# Create symlink
echo "→ Installing executable..."
ln -sf "${DEBOOST_HOME}/deboost" "${DEBOOST_BIN}/deboost"
chmod +x "${DEBOOST_BIN}/deboost"
echo "✓ Executable installed at: ${DEBOOST_BIN}/deboost"
echo ""

# Check PATH
if [[ ":$PATH:" != *":${DEBOOST_BIN}:"* ]]; then
  echo "⚠️  ${DEBOOST_BIN} is not in your PATH"
  echo ""
  echo "   Add to your ~/.bashrc:"
  echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo ""
  read -rp "   Add it now? (Y/n): " add_path
  if [[ ! "$add_path" =~ ^[nN]$ ]]; then
    if ! grep -q "${DEBOOST_BIN}" "${HOME}/.bashrc"; then
      echo "" >> "${HOME}/.bashrc"
      echo "# Deboost" >> "${HOME}/.bashrc"
      echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "${HOME}/.bashrc"
      echo "✓ PATH added to ~/.bashrc"
      echo "  Run: source ~/.bashrc"
    else
      echo "✓ PATH already configured"
    fi
  fi
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ✅ Deboost installed successfully!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo ""
echo "1. Reload your shell:"
echo "   source ~/.bashrc"
echo ""
echo "2. See available commands:"
echo "   deboost help"
echo ""
echo "3. List modules:"
echo "   deboost list"
echo ""
echo "4. Run installation (test first):"
echo "   deboost install --dry-run"
echo "   deboost install --apply"
echo ""
echo "5. Customize your settings:"
echo "   deboost config"
echo ""
echo "Documentation: https://github.com/lucasbt/deboost"
echo ""