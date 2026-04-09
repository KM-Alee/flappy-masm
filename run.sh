#!/usr/bin/env bash
set -euo pipefail

mode="${1:-release}"
"$(dirname "$0")/build.sh" "$mode"
exec "$(dirname "$0")/build/flappy-term"
