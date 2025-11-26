#!/usr/bin/env bash

# Deboost main controller
set -euo pipefail

# --- config ---
DEBOOST_HOME="${DEBOOST_HOME:-$HOME/.local/share/deboost}"
DEBOOST_BIN="${DEBOOST_BIN:-$HOME/.local/bin}"
VERSION_FILE="${DEBOOST_HOME}/.version"
MODULE_DIR="${DEBOOST_HOME}/modules"
INSTALLER_REPO="https://raw.githubusercontent.com/lucasbt/deboost/main"

mkdir -p "$DEBOOST_HOME" "$DEBOOST_BIN" "$MODULE_DIR"

# load utils
source "${MODULE_DIR}/utils.sh"

VERSION=$(cat "$VERSION_FILE")

cmd="${1:-help}"
shift || true

case "$cmd" in
  install)
    # support --background and --dry-run in any position
    DRYRUN=false
    while (( "$#" )); do
      case "$1" in
        --dry-run) DRYRUN=true; shift ;;
        --background) BACKGROUND=true; shift ;;
        *) shift ;;
      esac
    done

    if $BACKGROUND; then
      info "Starting background install (logs -> $LOGFILE)."
      if $DRYRUN; then
        info "Dry-run + background requested: running dry-run now in foreground."
        "$DEBOOST_HOME/modules/system.sh" dry-run >>"$LOGFILE" 2>&1 &
      else
        nohup "$DEBOOST_HOME/modules/system.sh" install >>"$LOGFILE" 2>&1 &
      fi
      info "Background job launched. Use 'deboost update' or check $LOGFILE"
      exit 0
    else
      info "Starting install. Dry-run: $DRYRUN"
      bash "$DEBOOST_HOME/modules/system.sh" install ${DRYRUN:+--dry-run}
      info "Install finished"
    fi
    ;;

  uninstall)
    info "Uninstalling deboost"
    bash "${MODULE_DIR}/utils.sh" log "uninstall started"
    # remove installed files
    rm -rf "$DEBOOST_HOME"
    rm -f "$DEBOOST_BIN/deboost"
    info "Deboost removed"
    ;;

  update)
    info "Updating Deboost (semantic bump + git optional)"
    # simple approach: bump patch
    IFS='.' read -r MAJ MIN PAT <<<"$VERSION"
    PAT=$((PAT+1))
    NEW="${MAJ}.${MIN}.${PAT}"
    echo "$NEW" > "$VERSION_FILE"
    info "Version bumped $VERSION -> $NEW"
    # If source repo available, pull new files (if installed from git we could fetch; else just notify)
    info "If installed from a remote repo, implement pulling logic here."
    ;;

  version)
    echo "$VERSION"
    ;;

  help|--help|-h|"")
    cat <<EOF
Deboost $VERSION - helper
Usage: deboost <command> [options]

Commands:
  install [--dry-run] [--background]   Install or simulate install
  uninstall                             Remove deboost from home
  update                                Bump version and attempt update
  version                               Show installed version
  help                                  This help
EOF
    ;;

  *)
    echo "Unknown command: $cmd"
    exit 2
    ;;
esac
