#!/usr/bin/env bash
# Starts the local Android AVD reliably, then delegates to `flutter run`.
# Usage: ./tool/run_android.sh [flutter run arguments]

set -euo pipefail

readonly avd_name="${ITER_AVD_NAME:-iter_android}"
readonly sdk_dir="$(sed -n 's/^sdk\.dir=//p' android/local.properties | head -n 1)"
readonly emulator="$sdk_dir/emulator/emulator"
readonly adb="$sdk_dir/platform-tools/adb"
readonly emulator_log="/tmp/iter-android-emulator.log"

if [[ -z "$sdk_dir" || ! -x "$emulator" || ! -x "$adb" ]]; then
  echo "Android SDK non disponibile: controlla android/local.properties." >&2
  exit 1
fi

find_emulator() {
  "$adb" devices | awk '/^emulator-[0-9]+[[:space:]]+device$/ { print $1; exit }'
}

serial="$(find_emulator)"
if [[ -z "$serial" ]]; then
  echo "Avvio l'emulatore $avd_name (cold boot)…"
  "$emulator" -avd "$avd_name" -no-snapshot-load -no-boot-anim \
    >"$emulator_log" 2>&1 &
fi

for _ in {1..45}; do
  if [[ -n "$serial" ]] && [[ "$("$adb" -s "$serial" shell getprop sys.boot_completed)" == "1" ]]; then
    break
  fi
  sleep 2
  serial="$(find_emulator)"
done

if [[ -z "$serial" ]] || [[ "$("$adb" -s "$serial" shell getprop sys.boot_completed)" != "1" ]]; then
  echo "L'emulatore non ha completato l'avvio. Log: $emulator_log" >&2
  exit 1
fi

echo "Uso $serial."
exec flutter run -d "$serial" "$@"
