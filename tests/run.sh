#!/bin/sh
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CROWN_ROOT=$(CDPATH= cd -- "$project_root/../lang" && pwd)
export CROWN_ROOT
compiler=${CROWN_COMPILER:-"$CROWN_ROOT/bootstrap/crown"}
export CROWN_COMPILER="$compiler"
binary="$project_root/target/debug/gba_crown"
rom="$project_root/tests/fixtures/deterministic_game.gba"
host_os=$(uname -s)
run_native_memory=false
headless_checks=21
if [ "$host_os" = Darwin ]; then
    run_native_memory=true
    headless_checks=23
fi

if [ "$#" -gt 1 ]; then
    printf '%s\n' 'usage: ./tests/run.sh [--headless-only]' >&2
    exit 2
fi
if [ "$#" -eq 1 ]; then
    if [ "$1" != "--headless-only" ]; then
        printf '%s\n' 'usage: ./tests/run.sh [--headless-only]' >&2
        exit 2
    fi
    run_native_memory=false
fi

expect_exit() {
    expected=$1
    shift
    if "$@"; then
        exit 1
    else
        actual=$?
        if [ "$actual" -ne "$expected" ]; then exit "$actual"; fi
    fi
}

expect_bmp() {
    expected=$1
    path=$2
    if [ "$(wc -c < "$path")" -ne 115254 ]; then exit 1; fi
    actual=$(shasum -a 256 "$path" | awk '{ print $1 }')
    if [ "$actual" != "$expected" ]; then exit 1; fi
}

"$compiler" build "$project_root"
if [ "$host_os" = Darwin ]; then
    dyld_info -opcodes "$binary" | grep -q '_mach_absolute_time'
    if dyld_info -opcodes "$binary" | grep -q '_mach_continuous_time'; then exit 1; fi
fi
"$project_root/run.sh" "$rom" --headless 0
"$compiler" build "$project_root/tests/validation"
validation="$project_root/tests/validation/target/debug/gba_validation"
"$validation" "$project_root/tests/fixtures/cpu_self_test.gba" cpu
"$validation" "$rom" frames
"$binary" "$rom" screenshot /private/tmp/gba_crown_test.bmp
"$binary" "$rom" --headless 0
"$binary" "$rom" --steps 0
"$binary" "$rom" "$rom" --steps 0
"$binary" "$rom" --steps 0 "$rom"
"$binary" "$rom" --headless 0 --screenshot /private/tmp/gba_crown_option_test.bmp
expect_bmp 0ad97684bb9e6098a5b6d71e4840931fb28278b47e82f8f91ee0792a96a0d779 /private/tmp/gba_crown_test.bmp
expect_bmp 836b26454702a2499f3c4b4bba3c564fb910a3c653f27d7276bc1a3639be73d1 /private/tmp/gba_crown_option_test.bmp
"$compiler" build "$project_root/tests/core"
"$project_root/tests/core/target/debug/gba_crown_core_tests" "$project_root/tests/fixtures/cpu_self_test.gba" /private/tmp/gba_crown_save_test.gba
expect_exit 2 "$binary"
expect_exit 3 "$binary" "$rom" --headless
expect_exit 5 "$binary" "$rom" --headless invalid
expect_exit 5 "$binary" "$rom" --steps 18446744073709551616
expect_exit 4 "$binary" "$rom" --unknown
expect_exit 4 "$binary" "$rom" --steps 0 --headless 0
expect_exit 3 "$binary" "$rom" --screenshot
expect_exit 4 "$binary" "$rom" --screenshot first.bmp --screenshot second.bmp
expect_exit 20 "$binary" "$rom" /private/tmp/gba_crown_missing_bios.bin --steps 0
if "$run_native_memory"; then
    "$project_root/tests/native_memory.sh" "$binary" "$rom"
    printf '%s\n' '24 checks passed'
else
    printf '%s headless checks passed\n' "$headless_checks"
fi
