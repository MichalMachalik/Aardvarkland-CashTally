#!/usr/bin/env bash
set -Eeuo pipefail

# Run under reactivecircus/android-emulator-runner with a debug Android app.
# Each crash invocation must reach a durable checkpoint before the host sends
# an actual Android force-stop. Flutter drive failing after the stop is expected.
PACKAGE="cz.vycetka.vycetka"
MARKER="app_flutter/cash_tally_android_it_checkpoint.txt"
LOG_DIR="${RUNNER_TEMP:-/tmp}/cash-tally-android-recovery"
mkdir -p "$LOG_DIR"

DEVICE_ID="${CASH_TALLY_TEST_DEVICE:-$(adb devices | awk '$2 == "device" && $1 ~ /^emulator-/ { print $1; exit }')}"
if [[ "$DEVICE_ID" != emulator-* ]]; then
  echo "ERROR: No Android emulator connected" >&2
  exit 1
fi
ADB=(adb -s "$DEVICE_ID")
timeout 60s "${ADB[@]}" wait-for-device

collect_diagnostics() {
  local status="$?"
  trap - EXIT
  timeout 20s "${ADB[@]}" logcat -d -v threadtime >"$LOG_DIR/logcat.log" 2>&1 || true
  timeout 20s "${ADB[@]}" shell dumpsys activity activities >"$LOG_DIR/activities.log" 2>&1 || true
  timeout 20s "${ADB[@]}" shell run-as "$PACKAGE" ls -la app_flutter/ >"$LOG_DIR/sandbox-files.log" 2>&1 || true
  exit "$status"
}
trap collect_diagnostics EXIT

prepare_launch() {
  local label="$1"
  # A previous process and its debugger must not be mistaken for this launch.
  # Preserve the preceding log before clearing only this disposable emulator.
  timeout 20s "${ADB[@]}" shell am force-stop "$PACKAGE"
  timeout 20s "${ADB[@]}" logcat -d -v threadtime >"$LOG_DIR/before-$label.log" 2>&1 || true
  timeout 20s "${ADB[@]}" logcat -c
  timeout 20s "${ADB[@]}" forward --remove-all
}

drive_case() {
  local mode="$1"
  local checkpoint="${2:-}"
  prepare_launch "$mode${checkpoint:+-$checkpoint}"
  # This also bounds installation and VM-service connection, which are not
  # covered by Flutter's test timeout before the driver attaches.
  timeout --signal=TERM --kill-after=10s 600s \
    flutter drive -d "$DEVICE_ID" \
    --keep-app-running \
    --no-dds \
    --host-vmservice-port=8181 \
    --no-pub \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/android_backup_recovery_test.dart \
    "--dart-define=CASH_TALLY_IT_MODE=$mode" \
    "--dart-define=CASH_TALLY_IT_CHECKPOINT=$checkpoint" \
    2>&1 | tee "$LOG_DIR/$mode${checkpoint:+-$checkpoint}.log"
}

crash_at_checkpoint() {
  local checkpoint="$1"
  local log="$LOG_DIR/crash-$checkpoint.log"
  echo "==> Android forced termination after: $checkpoint"
  prepare_launch "crash-$checkpoint"

  # Only the app sandbox marker is needed for this phase. Starting the test APK
  # directly lets Dart reach the write even when a debugger cannot attach.
  timeout --signal=TERM --kill-after=10s 600s flutter build apk --debug --no-pub \
    --target=integration_test/android_backup_recovery_test.dart \
    --dart-define=CASH_TALLY_IT_MODE=crash \
    "--dart-define=CASH_TALLY_IT_CHECKPOINT=$checkpoint" 2>&1 | tee "$log"
  timeout 90s "${ADB[@]}" install -r -t build/app/outputs/flutter-apk/app-debug.apk
  timeout 20s "${ADB[@]}" shell run-as "$PACKAGE" rm -f "$MARKER"
  timeout 40s "${ADB[@]}" shell am start -W -n "$PACKAGE/.MainActivity"

  local observed
  local deadline=$((SECONDS + 120))
  while (( SECONDS < deadline )); do
    observed="$(timeout 10s "${ADB[@]}" shell run-as "$PACKAGE" cat "$MARKER" 2>/dev/null | tr -d '\r\n' || true)"
    if [[ "$observed" == "$checkpoint" ]]; then
      break
    fi
    sleep 1
  done
  if [[ "$observed" != "$checkpoint" ]]; then
    echo "ERROR: checkpoint '$checkpoint' was never reached" >&2
    return 1
  fi

  timeout 20s "${ADB[@]}" shell am force-stop "$PACKAGE"
  observed="$(timeout 10s "${ADB[@]}" shell run-as "$PACKAGE" cat "$MARKER" | tr -d '\r\n')"
  if [[ "$observed" != "$checkpoint" ]]; then
    echo "ERROR: checkpoint marker disappeared after force-stop" >&2
    return 1
  fi
  echo "Android stopped at the verified '$checkpoint' checkpoint"
}

echo "==> Baseline: encrypted backup, wrong password, and full reload"
drive_case roundtrip

for checkpoint in journal sessions templates custom hidden; do
  crash_at_checkpoint "$checkpoint"
  echo "==> Cold start: recover complete data after '$checkpoint'"
  drive_case verify "$checkpoint"
done

# Destructive corrupted-history checks must run last.
echo "==> History recovery from .bak and fail-closed on double corruption"
drive_case history

echo "Android recovery suite passed."
