#!/usr/bin/env bash
# Builds and serves Iter's release Web bundle for local UI QA.
# Usage: ./tool/run_web.sh [flutter build arguments]

set -euo pipefail

flutter build web --release "$@"
exec python3 -m http.server 7357 \
  --directory build/web \
  --bind 127.0.0.1
