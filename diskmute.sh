#!/bin/bash

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

VERSION=0.0.1

function usage {
  echo ""
  echo "Usage: sudo $0 <volume>"
  echo ""
  echo "Options:"
  echo "  -h, --help      Show this help message and exit"
  echo "  -v, --version   Show version number and exit"
  echo ""
  echo "Example: sudo $0 /Volumes/MyDisk"
  echo ""
  exit 0
}

function version {
  echo "$VERSION"
  exit 0
}

function check_args {
  if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    usage
  fi
  if [ "$1" == "-v" ] || [ "$1" == "--version" ]; then
    version
  fi
  if [ -n "$1" ]; then
    usage
  fi
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
  if echo "$1" | grep "System" >/dev/null; then
    fatal "ERROR: Cannot run on a system volume. Exiting..."
  fi
  if echo "$1" | grep "Recovery" >/dev/null; then
    fatal "ERROR: Cannot run on a recovery volume. Exiting..."
  fi
  if echo "$1" | grep "Library" >/dev/null; then
    fatal "ERROR: Cannot run on a simulator volume. Exiting..."
  fi
  if [ "$1" == "/" ]; then
    fatal "ERROR: Cannot run on the root volume. Exiting..."
  fi
  if echo "$1" | grep "~" >/dev/null; then
    fatal "ERROR: Cannot run on a home volume. Exiting..."
  fi
  if [ "$1" == "/Volumes" ]; then
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
  echo -e "This script will turn off all indexing and remove all metadata on drive $1"
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
    echo "ERROR: This script must be run as root. Exiting..."
    exit 1
  fi
}

function check_volume {
  if mount | grep "$1"; then
    cd "$1" || exit 1
  else
    echo "Volume not mounted. Exiting..."
    exit 1
  fi
}

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

function disable_timemachine {
  echo "Disabling Time Machine..."
  sudo tmutil addexclusion -v "$1" || fatal "Failed to disable Time Machine"
  sudo tmutil isexcluded "$1" || fatal "Failed to disable Time Machine"
}

function disable_spotlight {
  echo "Disabling Spotlight..."
  sudo mdutil -i off -dE -V "$1" || fatal "Failed to disable Spotlight"
  sudo mdutil -s || fatal "Failed to disable Spotlight"
}

function create_noindex {
  touch "$1"/.metadata_never_index || fatal "Failed to create .metadata_never_index"
  mkdir "$1"/.fseventsd || fatal "Failed to create .fseventsd"
  touch "$1"/.fseventsd/no_log || fatal "Failed to create .fseventsd/no_log"
  touch "$1"/.Trashes || fatal "Failed to create .Trashes"
}

# function remove_files {
#   find "$1" -name ".DS_Store" -delete || fatal "Failed to remove .DS_Store"
#   find "$1" -name "._*" -delete || fatal "Failed to remove ._"
#   find "$1" -name ".Spotlight-V100" -delete || fatal "Failed to remove .Spotlight-V100"
#   find "$1" -name ".Trashes" -delete || fatal "Failed to remove .Trashes"
#   find "$1" -name ".fseventsd" -delete || fatal "Failed to remove .fseventsd"
#   find "$1" -name ".TemporaryItems" -delete || fatal "Failed to remove .TemporaryItems"
#   find "$1" -name ".VolumeIcon.icns" -delete || fatal "Failed to remove .VolumeIcon.icns"
#   find "$1" -name ".com.apple.timemachine.supported" -delete || fatal "Failed to remove .com.apple.timemachine.supported"
#   find "$1" -name ".com.apple.timemachine.donotpresent" -delete || fatal "Failed to remove .com.apple.timemachine.donotpresent"
#   find "$1" -name ".AppleDB" -delete || fatal "Failed to remove .AppleDB"
#   find "$1" -name ".AppleDesktop" -delete || fatal "Failed to remove .AppleDesktop"
#   find "$1" -name ".apdisk" -delete || fatal "Failed to remove .apdisk"
#   find "$1" -name ".DocumentRevisions-V100" -delete || fatal "Failed to remove .DocumentRevisions-V100"
# }

function main {
  is_darwin
  if [ "$#" -eq 0 ]; then
    fatal "No arguments specified."
  fi
  check_args "$1"
  banner
  check_root
  check_volume "$1"
  warning_message "$1"
  consent
  stop_stupidity "$1"
  remove_files_dry_run "$1"
  consent
  disable_spotlight "$1"
  disable_timemachine "$1"
  create_noindex "$1"

  # turn_off_spotlight "$1"
  # remove_files "$1"
  # create_noindex "$1"
}

main "$@"
