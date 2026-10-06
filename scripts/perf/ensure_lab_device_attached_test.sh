#!/bin/bash
#
# Manual test harness for scripts/perf/ensure_lab_device_attached.sh.
#
# Drives the script against a fake usbipd.exe and a fake adb that keep their
# state in a temp directory, so the wake-from-standby races (interop not ready,
# phone not yet on the bus, stale attachment) can be replayed without hardware.
#
# Usage:
#   scripts/perf/ensure_lab_device_attached_test.sh
#
# Exits 0 if every case behaves as expected, non-zero otherwise.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SCRIPT_DIR}/ensure_lab_device_attached.sh"
SERIAL="3A091FDJG005FU"
OTHER_PIXEL_SERIAL="43121FDAP0003L"

FAILURES=0
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

# The fake usbipd refuses to start unless it is run from its own directory,
# like the real usbipd.exe, which WSL cannot start from a working directory
# under /home/ayana (every runner workspace).
#
# Fake state lives in files so each scenario is plain data:
#   interop_failures   usbipd.exe calls that still fail with "Invalid argument"
#   state_failures     `usbipd state` calls that still fail
#   absent_polls       `usbipd state` calls that still omit the phone
#   attach_failures    attach calls that still fail
#   bound              "yes" when usbipd has the phone shared
#   attached           "yes" when usbipd lists a client for the phone
#   busid              the phone's bus id
#   phone_visible      "yes" once adb can see it
#   adb_state          what adb reports for it (device, offline, unauthorized)
#   unauthorized_polls `adb devices` calls that still report it unauthorized
#   attach_reveals     "yes" if a fresh attach makes the phone visible to adb
#   other_busid        bus id taken by a second phone of the same model, or ""
#   calls              log of every usbipd/adb call, one per line
write_fakes() {
  cat >"${WORK_DIR}/usbipd" <<'EOF'
#!/bin/bash
D="$FAKE_DIR"
echo "usbipd $*" >>"$D/calls"
if [[ "$PWD" != "$(dirname "$0")" ]]; then
  echo "$0: Invalid argument" >&2; exit 126
fi
countdown() {
  local n; n="$(cat "$D/$1")"
  if [[ "$n" -gt 0 ]]; then echo $((n - 1)) >"$D/$1"; return 0; fi
  return 1
}
if countdown interop_failures; then
  echo "$0: Invalid argument" >&2; exit 126
fi
case "$1" in
  --version) echo "5.3.0" ;;
  state)
    if countdown state_failures; then echo "service not running" >&2; exit 1; fi
    other=""
    if [[ -n "$(cat "$D/other_busid")" ]]; then
      other=",{\"BusId\":\"$(cat "$D/other_busid")\",\"ClientIPAddress\":null,\"InstanceId\":\"USB\\\\VID_18D1&PID_4EE7\\\\${FAKE_OTHER_SERIAL}\",\"PersistedGuid\":\"g2\"}"
    fi
    if countdown absent_polls; then
      echo "{\"Devices\":[{\"BusId\":\"1-3\",\"InstanceId\":\"USB\\\\VID_04F2&PID_B7BA\\\\0001\",\"ClientIPAddress\":null,\"PersistedGuid\":null}${other}]}"
    else
      ip=null; [[ "$(cat "$D/attached")" == yes ]] && ip='"172.29.254.250"'
      guid=null; [[ "$(cat "$D/bound")" == yes ]] && guid='"g1"'
      echo "{\"Devices\":[{\"BusId\":\"$(cat "$D/busid")\",\"ClientIPAddress\":${ip},\"InstanceId\":\"USB\\\\VID_18D1&PID_4EE7\\\\${FAKE_SERIAL}\",\"PersistedGuid\":${guid}}${other}]}"
    fi ;;
  attach)
    if countdown attach_failures; then echo "attach refused" >&2; exit 1; fi
    echo yes >"$D/attached"
    [[ "$(cat "$D/attach_reveals")" == yes ]] && echo yes >"$D/phone_visible" ;;
  detach) echo no >"$D/attached"; echo yes >"$D/attach_reveals"; echo no >"$D/phone_visible" ;;
  list) echo "BUSID  DEVICE  STATE (fake list)" ;;
esac
EOF
  cat >"${WORK_DIR}/adb" <<'EOF'
#!/bin/bash
D="$FAKE_DIR"
echo "adb $*" >>"$D/calls"
case "$1" in
  devices)
    echo "List of devices attached"
    if [[ "$(cat "$D/phone_visible")" == yes ]]; then
      state="$(cat "$D/adb_state")"
      n="$(cat "$D/unauthorized_polls")"
      if [[ "$n" -gt 0 ]]; then echo $((n - 1)) >"$D/unauthorized_polls"; state=unauthorized; fi
      printf '%s\t%s\n' "$FAKE_SERIAL" "$state"
    fi ;;
  kill-server) [[ "$(cat "$D/adb_state")" == offline ]] && echo device >"$D/adb_state" ;;
esac
exit 0
EOF
  chmod +x "${WORK_DIR}/usbipd" "${WORK_DIR}/adb"
}

# reset_state: a phone that has dropped off WSL but is bound and on the bus.
reset_state() {
  local d="${WORK_DIR}/state"
  rm -rf "$d"; mkdir -p "$d"
  echo 0 >"$d/interop_failures"; echo 0 >"$d/state_failures"
  echo 0 >"$d/absent_polls"; echo 0 >"$d/attach_failures"
  echo yes >"$d/bound"; echo no >"$d/attached"; echo 1-1 >"$d/busid"
  echo no >"$d/phone_visible"; echo device >"$d/adb_state"; echo 0 >"$d/unauthorized_polls"
  echo yes >"$d/attach_reveals"; echo "" >"$d/other_busid"
  : >"$d/calls"
}

set_state() { echo "$2" >"${WORK_DIR}/state/$1"; }

# run_target: runs the script and fills OUTPUT / STATUS.
run_target() {
  OUTPUT="$(FAKE_DIR="${WORK_DIR}/state" FAKE_SERIAL="$SERIAL" \
    FAKE_OTHER_SERIAL="$OTHER_PIXEL_SERIAL" \
    USBIPD_BIN="${USBIPD_OVERRIDE:-${WORK_DIR}/usbipd}" ADB_BIN="${ADB_OVERRIDE:-${WORK_DIR}/adb}" \
    ATTACH_TIMEOUT_SECONDS="${TIMEOUT:-4}" ATTACH_POLL_SECONDS=1 ADB_SETTLE_SECONDS="${SETTLE:-2}" ADB_APPEAR_SECONDS=1 \
    "$TARGET" --device-id "$SERIAL" 2>&1)"
  STATUS=$?
}

calls() { cat "${WORK_DIR}/state/calls"; }

check() {
  local description="$1" ok="$2"
  if [[ "$ok" == yes ]]; then
    echo "✅ PASS: ${description}"
  else
    echo "❌ FAIL: ${description}"
    echo "   exit=${STATUS} output: ${OUTPUT}"
    echo "   calls: $(calls | tr '\n' ';')"
    FAILURES=$((FAILURES + 1))
  fi
}

has() { [[ "$1" == *"$2"* ]] && echo yes || echo no; }
lacks() { [[ "$1" == *"$2"* ]] && echo no || echo yes; }
exit_is() { [[ "$STATUS" -eq "$1" ]] && echo yes || echo no; }

write_fakes

reset_state
mkdir -p "${WORK_DIR}/workspace"
cd "${WORK_DIR}/workspace" || exit 1
run_target
check "started from a runner workspace directory: usbipd still runs from its own directory" \
  "$([[ "$STATUS" -eq 0 && "$(has "$(calls)" "usbipd --version")" == yes ]] && echo yes || echo no)"

reset_state
set_state attached yes; set_state phone_visible yes
run_target
check "already attached and visible: succeeds without attaching" \
  "$([[ "$STATUS" -eq 0 && "$(lacks "$(calls)" "usbipd attach")" == yes ]] && echo yes || echo no)"

reset_state
run_target
check "dropped phone is attached on the phone's own bus id and adb sees it" \
  "$([[ "$STATUS" -eq 0 && "$(has "$(calls)" "usbipd attach --wsl --busid 1-1")" == yes ]] && echo yes || echo no)"

reset_state
set_state interop_failures 2
run_target
check "Windows interop failing right after wake: retries until it works" \
  "$([[ "$STATUS" -eq 0 ]] && echo yes || echo no)"

reset_state
set_state absent_polls 2
run_target
check "phone not yet enumerated after wake: waits for it to appear" \
  "$([[ "$STATUS" -eq 0 ]] && echo yes || echo no)"

reset_state
set_state state_failures 2
run_target
check "usbipd service still starting: retries the device list" \
  "$([[ "$STATUS" -eq 0 ]] && echo yes || echo no)"

reset_state
set_state attach_failures 2
run_target
check "attach refused twice then accepted: retries" \
  "$([[ "$STATUS" -eq 0 ]] && echo yes || echo no)"

reset_state
set_state attach_failures 99
run_target
check "attach that never works fails and shows usbipd's own error" \
  "$([[ "$STATUS" -eq 1 && "$(has "$OUTPUT" "attach refused")" == yes ]] && echo yes || echo no)"

reset_state
set_state absent_polls 99
run_target
check "phone that never appears fails with the reason and USB state" \
  "$([[ "$STATUS" -eq 1 && "$(has "$OUTPUT" "not on the Windows USB bus")" == yes && "$(has "$OUTPUT" "usbipd list")" == yes ]] && echo yes || echo no)"

reset_state
set_state interop_failures 99
run_target
check "interop that never recovers fails naming Windows interop and usbipd's own error" \
  "$([[ "$STATUS" -eq 1 && "$(has "$OUTPUT" "Windows interop")" == yes && "$(has "$OUTPUT" "Invalid argument")" == yes ]] && echo yes || echo no)"

reset_state
set_state bound no
run_target
check "phone not shared fails fast with the bind command" \
  "$([[ "$STATUS" -eq 1 && "$(has "$OUTPUT" "usbipd bind --busid 1-1")" == yes && "$(lacks "$(calls)" "usbipd attach")" == yes ]] && echo yes || echo no)"

reset_state
set_state busid 1-2; set_state other_busid 1-1
run_target
check "second phone of the same model in port 1-1: attaches this phone on 1-2 only" \
  "$([[ "$STATUS" -eq 0 && "$(has "$(calls)" "attach --wsl --busid 1-2")" == yes && "$(lacks "$(calls)" "busid 1-1")" == yes ]] && echo yes || echo no)"

reset_state
set_state adb_state unauthorized
run_target
check "phone that stays unauthorized fails and says to accept the prompt" \
  "$([[ "$STATUS" -eq 1 && "$(has "$OUTPUT" "unauthorized")" == yes ]] && echo yes || echo no)"

reset_state
set_state unauthorized_polls 2
SETTLE=8 run_target
check "freshly attached phone reads unauthorized briefly: waits it out" \
  "$([[ "$STATUS" -eq 0 ]] && echo yes || echo no)"

reset_state
set_state adb_state offline
run_target
check "offline phone recovers after an adb server restart" \
  "$([[ "$STATUS" -eq 0 ]] && echo yes || echo no)"

reset_state
set_state attached yes; set_state attach_reveals no
TIMEOUT=12 run_target
check "stale attachment (marked attached, adb blind): detaches then re-attaches" \
  "$([[ "$STATUS" -eq 0 && "$(has "$(calls)" "usbipd detach --busid 1-1")" == yes && "$(has "$(calls)" "usbipd attach --wsl --busid 1-1")" == yes ]] && echo yes || echo no)"

reset_state
USBIPD_OVERRIDE="${WORK_DIR}/does-not-exist.exe" run_target
check "no usbipd on the host: skips and succeeds" \
  "$([[ "$STATUS" -eq 0 && "$(has "$OUTPUT" "skipping attach")" == yes ]] && echo yes || echo no)"

reset_state
STATUS=0
OUTPUT="$("$TARGET" 2>&1)"; STATUS=$?
check "missing --device-id is rejected" \
  "$([[ "$STATUS" -eq 1 && "$(has "$OUTPUT" "--device-id is required")" == yes ]] && echo yes || echo no)"

reset_state
STATUS=0
OUTPUT="$("$TARGET" --device-id 2>&1)"; STATUS=$?
check "--device-id without a value is rejected with a clear message" \
  "$([[ "$STATUS" -eq 1 && "$(has "$OUTPUT" "--device-id needs a value")" == yes ]] && echo yes || echo no)"

reset_state
ADB_OVERRIDE="${WORK_DIR}/no-such-adb" run_target
check "missing adb is reported by name" \
  "$([[ "$STATUS" -eq 1 && "$(has "$OUTPUT" "adb not found")" == yes ]] && echo yes || echo no)"

echo
if [[ "$FAILURES" -eq 0 ]]; then
  echo "✅ All ensure_lab_device_attached cases passed."
else
  echo "❌ ${FAILURES} case(s) failed."
  exit 1
fi
