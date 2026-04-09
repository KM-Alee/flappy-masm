#!/usr/bin/env bash
set -euo pipefail

mode="${1:-release}"

case "$mode" in
  release|debug)
    ;;
  *)
    echo "usage: $0 [release|debug]" >&2
    exit 1
    ;;
esac

make "$mode"
