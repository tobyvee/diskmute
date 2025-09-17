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
DRY_RUN=true
VOLUME=""

# Display usage information and exit
function usage {
  echo ""
  echo "Usage: sudo $0 <volume>"
  echo ""
  echo "Options:"
  echo "  -h, --help      Show this help message and exit"
  echo "  -v, --version   Show version number and exit"
  echo "  -d, --dry-run   Show files to be modified and exit without making changes. Default true."
  echo ""
  echo "Example: sudo $0 /Volumes/MyDisk"
  echo ""
  exit 0
}

# Display version number and exit
function version {
  echo "$VERSION"
  exit 0
}

# Parse command line arguments
# Arguments: $@ - all command line arguments
function parse_args {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help) usage ;;
      -v|--version) version ;;
      -d|--dry-run) DRY_RUN=true || DRY_RUN=false ;;
      -*) fatal "Unknown option: $1" ;;
      *) VOLUME="$1" ;;
    esac
    shift
  done
  if [ -z "$VOLUME" ]; then
    fatal "No volume specified."
  fi
}

# Print error message and exit with status 1
# Arguments: $@ - error message(s) to display
function fatal {
  printf "ERROR: %s\n" "$@"
  exit 1
}

# Check if running on macOS
function is_darwin {
  if [ "$(uname)" != "Darwin" ]; then
    fatal "This script is only supported on macOS."
  fi
  return 0
}

# Prevent running on dangerous system volumes
# Arguments: $1 - volume path to check
function path_blacklist {
  if [[ "$1" == *"System"* ]]; then
    fatal "ERROR: Cannot run on a system volume. Exiting..."
  fi
  if [[ "$1" == *"Recovery"* ]]; then
    fatal "ERROR: Cannot run on a recovery volume. Exiting..."
  fi
  if [[ "$1" == *"Library"* ]]; then
    fatal "ERROR: Cannot run on a simulator volume. Exiting..."
  fi
  if [[ "$1" == "/" ]]; then
    fatal "ERROR: Cannot run on the root volume. Exiting..."
  fi
  if [[ "$1" == *"~"* ]]; then
    fatal "ERROR: Cannot run on a home volume. Exiting..."
  fi
  if [[ "$1" == "/Volumes" ]]; then
    fatal "ERROR: Cannot run on the volumes root. Exiting..."
  fi
}

# Display ASCII art banner
function banner {
  echo ""
  echo -e "\033[0;36m░█▀▄░▀█▀░█▀▀░█░█░█▄█░█░█░▀█▀░█▀▀\033[0m"
  echo -e "\033[0;36m░█░█░░█░░▀▀█░█▀▄░█░█░█░█░░█░░█▀▀\033[0m"
  echo -e "\033[0;36m░▀▀░░▀▀▀░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀\033[0m"
  echo -e ""
}

# Display warning message about destructive operations
# Arguments: $1 - volume path
function warning_message {
  echo -e "\033[0;31mWARNING:\033[0m"
  echo -e "This script will turn off all indexing and remove all metadata on drive $1"
  echo -e "This is destructive and if used on the wrong drive, it can cause data loss"
  echo -e ""
  echo -e "DO NOT USE THIS ON YOUR SYSTEM VOLUME."
  echo -e "Use at your own risk."
  echo -e ""
}

# Ask user for confirmation to continue
function consent {
  echo "Do you want to continue? (y/n)"
  read -r ANSWER
  if [ "$ANSWER" != "y" ]; then
    echo "Exiting..."
    exit 1
  fi
}

# Verify script is running as root
function check_root {
  if [ "$(id -u)" != "0" ]; then
    fatal "ERROR: This script must be run as root. Exiting..."
  fi
}

# Verify volume is mounted and change to it
# Arguments: $1 - volume path to check and change to
function check_volume {
  if mount | grep "$1" &> /dev/null; then
    cd "$1" || exit 1
  else
    fatal "Volume not mounted. Exiting..."
  fi
}

# Show files that would be removed without actually removing them
# Arguments: $1 - volume path to search
function remove_files_dry_run {
  echo ""
  echo "The following files will be removed:"
  find "$1" -name ".DS_Store" || true
  find "$1" -name '._*' || true
  find "$1" -name ".Spotlight-V100" || true
  find "$1" -name ".Trashes" || true
  find "$1" -name ".fseventsd" || true
  find "$1" -name ".TemporaryItems" || true
  find "$1" -name ".VolumeIcon.icns" || true
  find "$1" -name ".com.apple.timemachine.supported" || true
  find "$1" -name ".com.apple.timemachine.donotpresent" || true
  find "$1" -name ".AppleDB" || true
  find "$1" -name ".AppleDesktop" || true
  find "$1" -name ".apdisk" || true
  find "$1" -name ".DocumentRevisions-V100" || true
  echo ""
}

# Disable Time Machine for the specified volume
function disable_timemachine {
  echo "Disabling Time Machine..."
  sudo tmutil addexclusion -v "$VOLUME" || fatal "Failed to disable Time Machine"
  sudo tmutil isexcluded "$VOLUME" || fatal "Failed to disable Time Machine"
}

# Disable Spotlight indexing for the specified volume
function disable_spotlight {
  echo "Disabling Spotlight..."
  sudo mdutil -i off -dE -V "$VOLUME" || fatal "Failed to disable Spotlight"
  sudo mdutil -s || fatal "Failed to disable Spotlight"
}

# Create files to prevent indexing and metadata creation
function create_noindex {
  touch "$VOLUME"/.metadata_never_index || fatal "Failed to create .metadata_never_index"
  mkdir "$VOLUME"/.fseventsd || fatal "Failed to create .fseventsd"
  touch "$VOLUME"/.fseventsd/no_log || fatal "Failed to create .fseventsd/no_log"
  touch "$VOLUME"/.Trashes || fatal "Failed to create .Trashes"
}

function remove_files {
  find "$VOLUME" -name ".DS_Store" -delete || fatal "Failed to remove .DS_Store"
  find "$VOLUME" -name "._*" -delete || fatal "Failed to remove ._"
  find "$VOLUME" -name ".Spotlight-V100" -delete || fatal "Failed to remove .Spotlight-V100"
  find "$VOLUME" -name ".Trashes" -delete || fatal "Failed to remove .Trashes"
  find "$VOLUME" -name ".fseventsd" -delete || fatal "Failed to remove .fseventsd"
  find "$VOLUME" -name ".TemporaryItems" -delete || fatal "Failed to remove .TemporaryItems"
  find "$VOLUME" -name ".VolumeIcon.icns" -delete || fatal "Failed to remove .VolumeIcon.icns"
  find "$VOLUME" -name ".com.apple.timemachine.supported" -delete || fatal "Failed to remove .com.apple.timemachine.supported"
  find "$VOLUME" -name ".com.apple.timemachine.donotpresent" -delete || fatal "Failed to remove .com.apple.timemachine.donotpresent"
  find "$VOLUME" -name ".AppleDB" -delete || fatal "Failed to remove .AppleDB"
  find "$VOLUME" -name ".AppleDesktop" -delete || fatal "Failed to remove .AppleDesktop"
  find "$VOLUME" -name ".apdisk" -delete || fatal "Failed to remove .apdisk"
  find "$VOLUME" -name ".DocumentRevisions-V100" -delete || fatal "Failed to remove .DocumentRevisions-V100"
}

# Main function that orchestrates the entire process
# Arguments: $@ - all command line arguments
function main {
  is_darwin
  banner
  check_root
  parse_args "$@"
  check_volume "$VOLUME"
  warning_message "$VOLUME"
  consent
  path_blacklist "$VOLUME"
  remove_files_dry_run "$VOLUME"
  if [ "$DRY_RUN" = false ]; then
    consent
    disable_spotlight "$VOLUME"
    disable_timemachine "$VOLUME"
    create_noindex "$VOLUME"
    remove_files "$VOLUME"
  fi
  exit 0
}

main "$@"
