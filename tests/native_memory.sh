#!/bin/sh
set -eu

binary=$1
rom=$2

"$binary" "$rom" &
native_pid=$!

cleanup() {
    if kill -0 "$native_pid" 2>/dev/null; then
        kill "$native_pid"
        wait "$native_pid" 2>/dev/null || :
    fi
}

trap cleanup EXIT INT TERM
sleep 3
if ! kill -0 "$native_pid" 2>/dev/null; then
    wait "$native_pid"
    exit 1
fi

drawables=$(/usr/bin/heap "$native_pid" | awk '
    $4 == "CAMetalDrawable" { print $1; found = 1 }
    END { if (!found) print 0 }
')

if [ "$drawables" -gt 8 ]; then
    exit 1
fi

cleanup
trap - EXIT INT TERM
printf '%s\n' '1 native memory check passed'
