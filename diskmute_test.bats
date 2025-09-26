#!/usr/bin/env bats

setup() {
    export SCRIPT_PATH="./diskmute.sh"
    export TEST_VOLUME="/tmp/test_volume/diskmute_test.dmg"
    export VOLUME_NAME="diskmute"
    export MOUNT_PATH="/Volumes/$VOLUME_NAME"
    mkdir -p /tmp/test_volume
    hdiutil create -type UDIF -size 10m -fs ExFAT -volname "$VOLUME_NAME" "$TEST_VOLUME" &> /dev/null
    hdiutil attach "$TEST_VOLUME" &> /dev/null
    mkdir -p "$MOUNT_PATH/.fseventsd" "$MOUNT_PATH/.Trashes"
}

teardown() {
    hdiutil detach "$MOUNT_PATH" &> /dev/null || true
    rm -rf "$TEST_VOLUME" || true
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
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "shows version with --version flag" {
    run bash "$SCRIPT_PATH" --version
    [ "$status" -eq 0 ]
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+$ ]]
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