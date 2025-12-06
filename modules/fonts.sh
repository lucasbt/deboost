#!/usr/bin/env bash
# DESC: Installs and configures optimized fonts
# REQUIRES: sudo, fontconfig
# TAGS: fonts, typography

set -euo pipefail

source "${DEBOOST_HOME}/lib/utils.sh" 2>/dev/null || {
  run() { echo "[RUN] $*"; eval "$@"; }
  log_info() { echo "[INFO] $*"; }
  log_success() { echo "[OK] $*"; }
}

FONTS_NERD_LIST=(
    Cousine
    FiraMono
    Hack
    iA-Writer
    IBMPlexMono
    Inconsolata
    Iosevka
    IosevkaTerm
    IosevkaTermSlab
    Meslo
    SourceCodePro
)

FONTS_APT_LIST=(
    fonts-cantarell
    fonts-inter
    fonts-roboto
    fonts-noto
    fonts-noto-color-emoji
    fonts-jetbrains-mono
    fonts-firacode
    fonts-liberation
    fonts-dejavu
    fonts-bebas-neue
    fonts-cascadia-code
    fonts-clear-sans
    fonts-comfortaa
    fonts-comic-neue
    fonts-courier-prime
    fonts-crosextra-caladea
    fonts-crosextra-carlito
    fonts-dejavu
    fonts-dejavu-core
    fonts-agave
    fonts-adobe-sourcesans3
    fonts-anonymous-pro
    fonts-atarist
    fonts-atkinson-hyperlegible-ttf
    fonts-atkinson-hyperlegible-web
    fonts-atkinson-hyperlegible
    fonts-beteckna
    fonts-blankenburg
    fonts-breip
    fonts-cabin
    fonts-cabinsketch
    fonts-chomsky
    fonts-ubuntu-console
    fonts-opensymbol
    fonts-ubuntu
    ttf-mscorefonts-installer
)

FONTS_URLS_LIST=(
	https://www.omnibus-type.com/wp-content/uploads/Asap.zip
	https://www.omnibus-type.com/wp-content/uploads/Asap-Condensed.zip
	https://www.omnibus-type.com/wp-content/uploads/Archivo.zip
	https://www.omnibus-type.com/wp-content/uploads/Archivo-Narrow.zip
)

function install_nerd_fonts(){
	log_info "Installing preferred nerd fonts"
	local FONT_URL_DL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

	if [ ! ${#FONTS_NERD_LIST[@]} -eq 0 ]; then
	    log_info "List of fonts that will be installed: \n\n$(echo "${FONTS_NERD_LIST[@]}" | tr ' ' '\n')\n"
	    run "mkdir -p /tmp/fonts/"
	    log_info "Installing Nerd Fonts:"

   	    for FONT in "${FONTS_NERD_LIST[@]}"; do
	    	if [[ $FONT != "" ]] && [[ $FONT != "#"* ]]; then
	    		if [ -d "$FONTS_DOTS_DIR/$FONT/" ] && [ "$(ls -A "$FONTS_DOTS_DIR/$FONT/")" ]; then
	    			log_info "The font '$FONT' already exists. Skipping download..."
	    		else
	    			log_info "Downloading and installing font '$FONT'..."
	    			run "curl -L --progress-bar -o /tmp/fonts/$FONT.zip $FONT_URL_DL/$FONT.zip"
	    			if [ $? -ne 0 ]; then
	        			log_failed "Error downloading font '$FONT'."
	        		else
	        			run "mkdir -p $FONTS_DOTS_DIR/$FONT/"
	        			log_info "Extract font '$FONT' in '$FONTS_DOTS_DIR/$FONT/'..."
	        			run "unzip -qq -o /tmp/fonts/$FONT.zip -d $FONTS_DOTS_DIR/$FONT/"
	        			log_success "Font '$FONT' was installed."
	        		fi
	    		fi
	    	fi
	    done
	else
		log_warning "The list of fonts is empty. Moving on..."
	fi

	log_success "Preferred Nerd fonts installation complete."
}

function install_urls_fonts(){
	log_info "Installing preferred fonts from sites"

	if [ ! ${#FONTS_URLS_LIST[@]} -eq 0 ]; then
	    log_info "List of URLs where the fonts will be downloaded: \n\n$(echo "${FONTS_URLS_LIST[@]}" | tr ' ' '\n')\n"
	    run "mkdir -p /tmp/fonts/"
	    log_info "Installing Fonts:"

   	    for FONT in "${FONTS_URLS_LIST[@]}"; do
			FONTNAME=$(basename "$FONT" .zip)
	    	if [[ $FONT != "" ]] && [[ $FONT != "#"* ]]; then
	    		if [ -d "$FONTS_DOTS_DIR/$FONTNAME/" ] && [ "$(ls -A "$FONTS_DOTS_DIR/$FONTNAME/")" ]; then
	    			log_info "The font '$FONTNAME' already exists. Skipping download..."
	    		else
	    			log_info "Downloading and installing font '$FONTNAME'..."
					run "curl -L --progress-bar -o /tmp/fonts/$FONTNAME.zip $FONT"

	    			if [ $? -ne 0 ]; then
	        			log_failed "Error downloading font '$FONTNAME'."
	        		else
	        			run "mkdir -p $FONTS_DOTS_DIR/$FONTNAME/"
	        			log_info "Extract font '$FONT' in '$FONTS_DOTS_DIR/$FONTNAME/'..."
	        			run "unzip -qq -o /tmp/fonts/$FONTNAME.zip -d $FONTS_DOTS_DIR/$FONTNAME/"
	        			log_success "Font '$FONTNAME' was installed."
	        		fi
	    		fi
	    	fi
	    done
	else
		log_warning "The list of fonts is empty. Moving on..."
	fi

	log_success "Preferred fonts from sites installation complete."
}

install_apt_fonts() {
    log_info "Installing preferred fonts from oficial repos via APT"

    if [ ${#FONTS_APT_LIST[@]} -eq 0 ]; then
        log_warning "The list of DNF fonts is empty. Moving on..."
        return 0
    fi

    log_info "List of fonts that will be installed:\n\n$(printf '%s\n' "${FONTS_APT_LIST[@]}")\n"
    run "mkdir -p /tmp/fonts/"

    log_info "Installing all DNF fonts in a single transaction..."
    run "sudo apt install -y ${FONTS_APT_LIST[*]}"
    local exit_code=$?

    if [ $exit_code -ne 0 ]; then
        log_failed "Some fonts failed to install (exit code $exit_code)."
    else
        log_success "All fonts were installed successfully."
    fi

    log_success "Preferred fonts from repos installation complete."
}

module_run() {
  log_info "Installing fonts..."

  install_apt_fonts
  install_nerd_fonts
  install_urls_fonts
  
  log_info "Configuring fontconfig..."
  run "mkdir -p ~/.config/fontconfig"
  
  if [ "$DRYRUN" = false ]; then
    cat > ~/.config/fontconfig/fonts.conf <<'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Anti-aliasing -->
  <match target="font">
    <edit name="antialias" mode="assign">
      <bool>true</bool>
    </edit>
  </match>
  
  <!-- Hinting -->
  <match target="font">
    <edit name="hinting" mode="assign">
      <bool>true</bool>
    </edit>
    <edit name="hintstyle" mode="assign">
      <const>hintslight</const>
    </edit>
  </match>
  
  <!-- Subpixel rendering -->
  <match target="font">
    <edit name="rgba" mode="assign">
      <const>rgb</const>
    </edit>
  </match>
  
  <!-- LCD filter -->
  <match target="font">
    <edit name="lcdfilter" mode="assign">
      <const>lcddefault</const>
    </edit>
  </match>
  
  <!-- Preferred fonts by family -->
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Inter</family>
      <family>Cantarell</family>
      <family>Noto Sans</family>
    </prefer>
  </alias>
  
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Serif</family>
      <family>Liberation Serif</family>
    </prefer>
  </alias>
  
  <alias>
    <family>monospace</family>
    <prefer>
      <family>JetBrains Mono</family>
      <family>Fira Code</family>
      <family>DejaVu Sans Mono</family>
    </prefer>
  </alias>
</fontconfig>
EOF
  else
    echo "[DRYRUN] would create ~/.config/fontconfig/fonts.conf"
  fi
  
  log_info "Updating font cache..."
  run "fc-cache -fv"
  
  log_success "Fonts installed and configured!"
}

module_run