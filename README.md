

https://edafe.de/2025/09/how-to-install-debian-13-trixie-with-a-gnome-desktop/

# 🚀 Deboost
***Automated setup • Performance tuned • Ready-to-code***

**The ultimate modular, intelligent post-install booster for Debian 13 GNOME/Wayland.**

Deboost is a set of modular bash scripts to automate Debian 13 post-installation configuration with GNOME, specially optimized for older machines.

## ✨ Features

- 🧩 **Modular architecture**: each functionality is an independent module
- ⚙️ **Highly configurable**: `config/env` file for customization
- 🔄 **Auto-update**: update Deboost itself via git
- 🎯 **Wayland-focused**: optimized for Wayland/GNOME sessions
- ♿ **Anti-fatigue**: accessibility and visual comfort settings
- 🖥️ **Old hardware compatibility**: support for Intel i965 (Haswell)
- 🛡️ **Dry-run mode**: test before applying changes

## 📦 Installation

### Method 1: Direct Bootstrap (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/lucasbt/deboost/main/deboost | bash -s -- bootstrap
```

### Method 2: Manual Clone

```bash
git clone https://github.com/lucasbt/deboost.git ~/.local/share/deboost
cd ~/.local/share/deboost
./deboost bootstrap
```

### Add to PATH

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

## 🎯 Basic Usage

```bash
# Show help
deboost help

# List available modules
deboost list

# Run all modules (dry-run)
deboost install --dry-run

# Run all modules (apply changes)
deboost install --apply

# Run specific module
deboost install system-update --apply
deboost install gnome-settings --apply

# Update Deboost
deboost update

# Edit settings
deboost config

# Uninstall
deboost uninstall
```

## 📁 Project Structure

```
~/.local/share/deboost/
├── deboost                 # Main executable
├── lib/
│   └── utils.sh           # Utility functions
├── modules/               # Installation modules
│   ├── system-update.sh
│   ├── intel-graphics.sh
│   ├── gnome-settings.sh
│   ├── fonts.sh
│   ├── dev-tools.sh
│   └── ...
└── config/
    └── env                # Configuration file

~/.local/bin/
└── deboost -> ~/.local/share/deboost/deboost
```

## 🧩 Available Modules

| Module | Description |
|--------|-----------|
| `system-update` | Updates system and installs firmware |
| `intel-graphics` | Configures Intel i965 drivers (Haswell) |
| `gnome-settings` | GNOME/Wayland anti-fatigue optimizations |
| `fonts` | Installs and configures modern fonts |
| `dev-tools` | Installs asdf, Docker, dev tools |

## ⚙️ Configuration

Edit `~/.local/share/deboost/config/env` to customize:

```bash
# Drivers
LIBVA_DRIVER_NAME=i965

# GNOME
GNOME_COLOR_SCHEME=prefer-dark
GNOME_ENABLE_ANIMATIONS=false
GNOME_TEXT_SCALING=1.05
GNOME_NIGHT_LIGHT_TEMP=3700

# Fonts
FONT_MONOSPACE="JetBrains Mono 11"
FONT_HINTING=slight
FONT_ANTIALIASING=rgba

# Dev Tools
ASDF_JAVA_VERSION=temurin-25
ASDF_NODEJS_VERSION=lts
ASDF_PYTHON_VERSION=3.12.0
```

## 🔧 Creating Custom Modules

Create a file in `~/.local/share/deboost/modules/my-module.sh`:

```bash
#!/usr/bin/env bash
# DESC: Description of your module
# REQUIRES: command1, command2
# TAGS: tag1, tag2

set -euo pipefail

# Import functions
source "${DEBOOST_HOME}/lib/utils.sh"

module_run() {
  log_info "Running my module..."
  
  run "sudo apt install -y my-package"
  
  log_success "Module completed!"
}

module_run
```

Make it executable:

```bash
chmod +x ~/.local/share/deboost/modules/my-module.sh
```

Run it:

```bash
deboost install my-module --apply
```

## 🎨 Implemented Features

### Anti-Fatigue Visual
- ✅ Night Light (blue filter) set to 3700K
- ✅ Text scaling 1.05 (105%)
- ✅ Larger cursor (24px)
- ✅ Optimized font hinting (slight)
- ✅ Dark theme by default
- ✅ Animations disabled

### Optimizations for Old Machines
- ✅ Intel i965 driver (Haswell)
- ✅ Mesa VA-API configured
- ✅ Persistent environment variables
- ✅ Proprietary firmware installed

### Development
- ✅ asdf version manager (Java, Node, Python, Go)
- ✅ Docker + Podman
- ✅ Modern tools (ripgrep, fd, jq)
- ✅ Git LFS

## 🐛 Troubleshooting

### Deboost not found in PATH

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Module failed

Run with verbose for debugging:

```bash
deboost install module-name --verbose --apply
```

### Check Intel video acceleration

```bash
vainfo
```

Should show:
```
libva info: VA-API version 1.x.x
libva info: Driver version: Intel i965 driver...
```

### Night Light not working

Make sure you're on Wayland:

```bash
echo $XDG_SESSION_TYPE
# Should return: wayland
```

## 🤝 Contributing

Contributions are welcome! To add new modules:

1. Fork the project
2. Create a branch (`git checkout -b feature/new-module`)
3. Add your module in `modules/`
4. Test with `--dry-run` and `--apply`
5. Commit your changes
6. Push and open a Pull Request

## 📝 License

GPL-3.0 - see LICENSE for details.

## 🙏 Credits

Developed to optimize the Debian experience on older machines, focusing on accessibility and productivity.

---

**Project**: [github.com/lucasbt/deboost](https://github.com/lucasbt/deboost)  
**Maintainer**: [Lucas Bittencourt (lucasbt@gmail.com)](mailto:lucasbt@gmail.com?subject=[GitHub]%20About%20Deboost)