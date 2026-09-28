#!/bin/sh
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CROWN_ROOT=$(CDPATH= cd -- "$project_root/../lang" && pwd)
export CROWN_ROOT
compiler=${CROWN_COMPILER:-"$CROWN_ROOT/bootstrap/crown"}
export CROWN_COMPILER="$compiler"
"$compiler" build "$project_root"
if [ "$#" -eq 0 ]; then
    set -- "$project_root/roms/circuit-breaker.gba"
fi
exec "$project_root/target/debug/gba_crown" "$@"
