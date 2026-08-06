#!/usr/bin/env bash
# Starts Iter in the local browser through Flutter's web-server device.
# Usage: ./tool/run_web.sh [flutter run arguments]

set -euo pipefail

exec flutter run \
  -d web-server \
  --web-hostname=127.0.0.1 \
  --web-port=7357 \
  --dart-define=ITER_NEW_TRIP_LAB=true \
  "$@"
