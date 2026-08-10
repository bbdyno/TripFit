#!/bin/sh

set -eu

java_major="$(java -version 2>&1 | awk -F '[\".]' '/version/ { print $2; exit }' || true)"
if { [ -z "${java_major}" ] || [ "${java_major}" -lt 21 ]; } && command -v mise >/dev/null 2>&1; then
    mise_java_root="$(mise where java@21 2>/dev/null || true)"
    if [ -n "${mise_java_root}" ]; then
        export JAVA_HOME="${mise_java_root}/Contents/Home"
        export PATH="${JAVA_HOME}/bin:${PATH}"
        java_major="$(java -version 2>&1 | awk -F '[\".]' '/version/ { print $2; exit }')"
    fi
fi
if [ -z "${java_major}" ] || [ "${java_major}" -lt 21 ]; then
    echo "error: Firebase emulator tests require Java 21 or newer."
    exit 1
fi

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "${script_dir}/../firebase-tests"
npm run test:emulator
