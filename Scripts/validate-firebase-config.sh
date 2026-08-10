#!/bin/sh

set -eu

firebase_config_path="${SRCROOT}/Resources/Firebase/GoogleService-Info.plist"

if [ "${CONFIGURATION:-}" = "Release" ] && [ ! -f "${firebase_config_path}" ]; then
    echo "error: Release builds require Resources/Firebase/GoogleService-Info.plist"
    exit 1
fi

if [ ! -f "${firebase_config_path}" ]; then
    echo "warning: Firebase configuration is absent; collaboration features will stay disabled."
fi
