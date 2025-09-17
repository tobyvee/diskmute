#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="./diskmute.sh"
    export TEST_VOLUME="/tmp/test_volume"
    mkdir -p "$TEST_VOLUME"
}

teardown() {
    rm -rf "$TEST_VOLUME"
}

@test "shows help message with -h flag" {
    run bash "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"Options:"* ]]
}

@test "shows help message with --help flag" {
    run bash "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
}

@test "shows version with -v flag" {
    run bash "$SCRIPT_PATH" -v
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "shows version with --version flag" {
    run bash "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "fails when no volume specified" {
    run bash "$SCRIPT_PATH"
    [ "$status" -eq 1 ]
    [[ "$output" == *"No volume specified"* ]]
}

@test "fails with unknown option" {
    run bash "$SCRIPT_PATH" --invalid
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option"* ]]
}

@test "fails on non-Darwin system" {
    run bash -c "uname() { echo 'Linux'; }; export -f uname; source $SCRIPT_PATH; is_darwin"
    [ "$status" -eq 1 ]
    [[ "$output" == *"only supported on macOS"* ]]
}

@test "prevents running on system volume" {
    run bash -c "set -euo pipefail; source $SCRIPT_PATH; path_blacklist '/System/Library'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cannot run on a system volume"* ]]
}

@test "prevents running on recovery volume" {
    run bash -c "source $SCRIPT_PATH; path_blacklist '/Volumes/Recovery'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cannot run on a recovery volume"* ]]
}

@test "prevents running on root volume" {
    run bash -c "source $SCRIPT_PATH; path_blacklist '/'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cannot run on the root volume"* ]]
}

@test "prevents running on home volume" {
    run bash -c "source $SCRIPT_PATH; path_blacklist '~/Documents'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cannot run on a home volume"* ]]
}

@test "prevents running on volumes root" {
    run bash -c "source $SCRIPT_PATH; path_blacklist '/Volumes'"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Cannot run on the volumes root"* ]]
}

@test "dry run flag works" {
    run bash "$SCRIPT_PATH" --dry-run "$TEST_VOLUME"
    [ "$status" -eq 1 ]
    [[ "$output" == *"This script must be run as root"* ]]
}

@test "requires root privileges" {
    run bash "$SCRIPT_PATH" "$TEST_VOLUME"
    [ "$status" -eq 1 ]
    [[ "$output" == *"This script must be run as root"* ]]
}