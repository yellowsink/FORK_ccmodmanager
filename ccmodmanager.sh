#!/bin/sh
# CCModManager launch script bundled with Linux and macOS builds.

# macOS doesn't have readlink -f and Linux can symlink this launch script.
realpath() {
    [ "." = "${1}" ] && n=${PWD} || n=${1}; while nn=$( readlink -n "$n" ); do n=$nn; done; echo "$n"
}

cd "$(dirname "$(realpath "$0")")" || exit 1

if [ -f "ccmodmanager.new.love" ]; then
    if [ -n "${OLYMPUS_RESTARTER_PID+x}" ]; then
        attempt=0
        while [ "$attempt" -lt 30 ] && kill -0 "$OLYMPUS_RESTARTER_PID"; do
            attempt=$((attempt + 1))
            sleep 0.1
        done
    fi

    mv "ccmodmanager.love" "ccmodmanager.old.love"
    mv "ccmodmanager.new.love" "ccmodmanager.love"
fi

if [ "$(uname)" = "Darwin" ]; then
    DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}:$(pwd)"
    export DYLD_LIBRARY_PATH
else
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:$(pwd)"
    export LD_LIBRARY_PATH
fi

if [ -f "love" ]; then
    ./love --fused ccmodmanager.love $@
elif command -v love >/dev/null 2>&1; then
    love --fused ccmodmanager.love $@
elif command -v love2d >/dev/null 2>&1; then
    love2d --fused ccmodmanager.love $@
else
    echo "love2d not found!"
fi
