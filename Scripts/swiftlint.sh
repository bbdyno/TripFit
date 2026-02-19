#!/bin/sh

if command -v swiftlint >/dev/null 2>&1; then
  swiftlint lint --no-cache --config "${SRCROOT}/.swiftlint.yml" || true
else
  echo "warning: SwiftLint not installed. Install with 'brew install swiftlint'."
fi
