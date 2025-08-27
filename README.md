# DiskMute

```bash
░█▀▄░▀█▀░█▀▀░█░█░█▄█░█░█░▀█▀░█▀▀
░█░█░░█░░▀▀█░█▀▄░█░█░█░█░░█░░█▀▀
░▀▀░░▀▀▀░▀▀▀░▀░▀░▀░▀░▀▀▀░░▀░░▀▀▀
```

DiskMute is a command line tool to remove metadata stored about files and directories on a volume mounted in Mac OS X. This tool is useful for creating a clean disk volume for backup or sharing purposes.

## Usage

```
Usage: diskmute <volume>
Example: diskmute /Volumes/MyDisk
Options:
  -h, --help      Show this help message and exit
  -v, --version   Show version number and exit
```

## Information

This script will turn off all indexing and remove all metadata on a mounted volume. This is destructive and if used on the wrong drive, it can cause data loss. Some checks are performed to ensure that the script is not run on the system volume, but it is up to the user to ensure that the correct volume is selected.

**!!! DO NOT USE THIS ON YOUR SYSTEM VOLUME !!!**

This script will modify or remove the following files and directories:
```
  .DS_Store
  ._*
  .Spotlight-V100
  .Trashes
  .fseventsd
  .TemporaryItems
  .VolumeIcon.icns
  .com.apple.timemachine.supported
  .com.apple.timemachine.donotpresent
  .AppleDB
  .AppleDesktop
  .apdisk
  .DocumentRevisions-V100
```

This script will create the following files and directories:
```
  .metadata_never_index
  .fseventsd/no_log
  .Trashes
```

Use this script at your own risk.

The author is not responsible for any loss of data, financial loss or damage to your system.

## Installation

### Homebrew

```bash
brew install diskmute
```

### From source

1. Clone this repo.
2. Run the following command:

```bash
make install
```

## Tests

Tests are written using the [bats testing framework](https://github.com/bats-core/bats-core). To test, run the following command:

```bash
make test
```