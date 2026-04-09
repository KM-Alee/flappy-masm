#!/usr/bin/env bash
set -euo pipefail

"$(dirname "$0")/build.sh" debug
exec gdb -q --args "$(dirname "$0")/build/flappy-term"
