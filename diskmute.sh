#!/usr/bin/env bash

# ░█▀▄░▀█▀░█▀▀░█░█░█▄█░█░█░▀█▀░█▀▀
# ░█░█░░█░░▀▀█░█▀▄░█░█░█░█░░█░░█▀▀
# ░▀▀░░▀▀▀░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀

# DiskMute - version 0.0.1
# Usage: diskmute <volume>
# Example: diskmute /Volumes/MyDisk
# Options:
#   -h, --help      Show this help message and exit
#   -v, --version   Show version number and exit

# This script will turn off all indexing and remove all metadata on a mounted volume.
# This is destructive and if used on the wrong drive, it can cause data loss.
# DO NOT USE THIS ON YOUR SYSTEM VOLUME.

# This script will modify or remove the following files and directories:
#   .DS_Store
#   ._*
#   .Spotlight-V100
#   .Trashes
#   .fseventsd
#   .TemporaryItems
#   .VolumeIcon.icns
#   .com.apple.timemachine.supported
#   .com.apple.timemachine.donotpresent
#   .AppleDB
#   .AppleDesktop
#   .apdisk
#   .DocumentRevisions-V100

# This script will create the following files and directories:
#   .metadata_never_index
#   .fseventsd/no_log
#   .Trashes

# The author is not responsible for any loss of data, financial loss or damage to your system.

set -euo pipefail

VERSION=1.0.0
DRY_RUN=false
VOLUME=""

function usage {
  echo ""
  echo "Usage: sudo $0 <volume>"
  echo ""
  echo "Options:"
  echo "  -h, --help      Show this help message and exit"
  echo "  -v, --version   Show version number and exit"
  echo "  -d, --dry-run   Show files to be modified and exit without making changes."
  echo ""
  echo "Example: sudo $0 /Volumes/MyDisk"
  echo ""
  exit 0
}

function version {
  echo "$VERSION"
  exit 0
}

function parse_args {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) usage ;;
      -v|--version) version ;;
      -d|--dry-run) DRY_RUN=true ;;
      -*) fatal "Unknown option: $1" ;;
      *) VOLUME="$1" ;;
    esac
    shift
  done
  [ -z "$VOLUME" ] && fatal "No volume specified."
}

function fatal {
  printf "ERROR: %s\n" "$@"
  exit 1
}

function is_darwin {
  if [ "$(uname)" != "Darwin" ]; then
    fatal "This script is only supported on macOS."
  fi
  return 0
}

function stop_stupidity {
  if echo "$VOLUME" | grep "System" >/dev/null; then
    fatal "ERROR: Cannot run on a system volume. Exiting..."
  fi
  if echo "$VOLUME" | grep "Recovery" >/dev/null; then
    fatal "ERROR: Cannot run on a recovery volume. Exiting..."
  fi
  if echo "$VOLUME" | grep "Library" >/dev/null; then
    fatal "ERROR: Cannot run on a simulator volume. Exiting..."
  fi
  if [ "$VOLUME" = "/" ]; then
    fatal "ERROR: Cannot run on the root volume. Exiting..."
  fi
  if echo "$VOLUME" | grep "~" >/dev/null; then
    fatal "ERROR: Cannot run on a home volume. Exiting..."
  fi
  if [ "$VOLUME" = "/Volumes" ]; then
    fatal "ERROR: Cannot run on the volumes root. Exiting..."
  fi
}

function banner {
  echo ""
  echo -e "\033[0;36m░█▀▄░▀█▀░█▀▀░█░█░█▄█░█░█░▀█▀░█▀▀\033[0m"
  echo -e "\033[0;36m░█░█░░█░░▀▀█░█▀▄░█░█░█░█░░█░░█▀▀\033[0m"
  echo -e "\033[0;36m░▀▀░░▀▀▀░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀\033[0m"
  echo -e ""
}

function warning_message {
  echo -e "\033[0;31mWARNING:\033[0m"
  echo -e "This script will turn off all indexing and remove all metadata on drive $VOLUME"
  echo -e "This is destructive and if used on the wrong drive, it can cause data loss"
  echo -e ""
  echo -e "DO NOT USE THIS ON YOUR SYSTEM VOLUME."
  echo -e "Use at your own risk."
  echo -e ""
}

function consent {
  echo "Do you want to continue? (y/n)"
  read -r ANSWER
  if [ "$ANSWER" != "y" ]; then
    echo "Exiting..."
    exit 1
  fi
}

function check_root {
  if [ "$(id -u)" != "0" ]; then
    fatal "ERROR: This script must be run as root. Exiting..."
  fi
}

function check_volume {
  if mount | grep "$VOLUME"; then
    cd "$VOLUME" || exit 1
  else
    fatal "Volume not mounted. Exiting..."
  fi
}

function remove_files_dry_run {
  echo ""
  echo "The following files will be removed:"
  find "$VOLUME" -name ".DS_Store" || true
  find "$VOLUME" -name '._*' || true
  find "$VOLUME" -name ".Spotlight-V100" || true
  find "$VOLUME" -name ".Trashes" || true
  find "$VOLUME" -name ".fseventsd" || true
  find "$VOLUME" -name ".TemporaryItems" || true
  find "$VOLUME" -name ".VolumeIcon.icns" || true
  find "$VOLUME" -name ".com.apple.timemachine.supported" || true
  find "$VOLUME" -name ".com.apple.timemachine.donotpresent" || true
  find "$VOLUME" -name ".AppleDB" || true
  find "$VOLUME" -name ".AppleDesktop" || true
  find "$VOLUME" -name ".apdisk" || true
  find "$VOLUME" -name ".DocumentRevisions-V100" || true
  echo ""
}

function disable_timemachine {
  echo "Disabling Time Machine..."
  sudo tmutil addexclusion -v "$VOLUME" || fatal "Failed to disable Time Machine"
  sudo tmutil isexcluded "$VOLUME" || fatal "Failed to disable Time Machine"
}

function disable_spotlight {
  echo "Disabling Spotlight..."
  sudo mdutil -i off -dE -V "$VOLUME" || fatal "Failed to disable Spotlight"
  sudo mdutil -s || fatal "Failed to disable Spotlight"
}

function create_noindex {
  touch "$VOLUME"/.metadata_never_index || fatal "Failed to create .metadata_never_index"
  mkdir "$VOLUME"/.fseventsd || fatal "Failed to create .fseventsd"
  touch "$VOLUME"/.fseventsd/no_log || fatal "Failed to create .fseventsd/no_log"
  touch "$VOLUME"/.Trashes || fatal "Failed to create .Trashes"
}

# function remove_files {
#   find "$VOLUME" -name ".DS_Store" -delete || fatal "Failed to remove .DS_Store"
#   find "$VOLUME" -name "._*" -delete || fatal "Failed to remove ._"
#   find "$VOLUME" -name ".Spotlight-V100" -delete || fatal "Failed to remove .Spotlight-V100"
#   find "$VOLUME" -name ".Trashes" -delete || fatal "Failed to remove .Trashes"
#   find "$VOLUME" -name ".fseventsd" -delete || fatal "Failed to remove .fseventsd"
#   find "$VOLUME" -name ".TemporaryItems" -delete || fatal "Failed to remove .TemporaryItems"
#   find "$VOLUME" -name ".VolumeIcon.icns" -delete || fatal "Failed to remove .VolumeIcon.icns"
#   find "$VOLUME" -name ".com.apple.timemachine.supported" -delete || fatal "Failed to remove .com.apple.timemachine.supported"
#   find "$VOLUME" -name ".com.apple.timemachine.donotpresent" -delete || fatal "Failed to remove .com.apple.timemachine.donotpresent"
#   find "$VOLUME" -name ".AppleDB" -delete || fatal "Failed to remove .AppleDB"
#   find "$VOLUME" -name ".AppleDesktop" -delete || fatal "Failed to remove .AppleDesktop"
#   find "$VOLUME" -name ".apdisk" -delete || fatal "Failed to remove .apdisk"
#   find "$VOLUME" -name ".DocumentRevisions-V100" -delete || fatal "Failed to remove .DocumentRevisions-V100"
# }

function main {
  is_darwin
  parse_args "$@"
  banner
  check_root
  check_volume "$VOLUME"
  warning_message "$VOLUME"
  consent
  stop_stupidity "$VOLUME"
  remove_files_dry_run "$VOLUME"
  if [ "$DRY_RUN" = false ]; then
    echo "RUNNING FOR REALZ"
    exit 0
    # consent
    # disable_spotlight "$VOLUME"
    # disable_timemachine "$VOLUME"
    # create_noindex "$VOLUME"
    # remove_files "$VOLUME"
  fi
  exit 0
}

main "$@"
