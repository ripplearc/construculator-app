#!/bin/bash
#
# Makes the perf-lab phone visible to adb inside this WSL2 VM before a run.
#
# The phone drops off the WSL VM between runs, and after the lab laptop wakes
# from standby Windows interop, usbipd and the USB stack may each still be
# coming back. This script waits for each of those instead of trying once.
#
# usbipd.exe is always started from its own Windows directory. WSL cannot start
# a Windows program whose working directory is under /home/ayana, which includes
# every runner workspace: it fails with "Invalid argument" and never runs.
#
# The phone is found by its serial number (the --device-id), not by bus id. A
# bus id is only a USB port slot: another phone of the same model, such as the
# lab's second Pixel, takes over the slot as soon as it is plugged in there.
#
# Usage:
#   scripts/perf/ensure_lab_device_attached.sh --device-id <adb serial>
#
# Environment (all optional):
#   USBIPD_BIN               usbipd.exe path (default: the Windows install under /mnt/c)
#   ADB_BIN                  adb binary (default: adb)
#   ATTACH_TIMEOUT_SECONDS   total time to keep retrying (default: 300)
#   ATTACH_POLL_SECONDS      pause between retries (default: 5)
#   ADB_SETTLE_SECONDS       how long a listed but not yet ready phone gets to become `device` (default: 30)
#   ADB_APPEAR_SECONDS       how long adb gets to list the phone at all after an attach (default: 10)
#
# Exits 0 when adb lists the device in the `device` state, and also when this
# machine has no usbipd (a native Linux or macOS lab host needs no attach).
# Every other outcome exits 1 with the reason and the current USB/adb state.
#
set -euo pipefail

USBIPD_BIN="${USBIPD_BIN:-/mnt/c/Program Files/usbipd-win/usbipd.exe}"
ADB_BIN="${ADB_BIN:-adb}"
TIMEOUT_SECONDS="${ATTACH_TIMEOUT_SECONDS:-300}"
POLL_SECONDS="${ATTACH_POLL_SECONDS:-5}"
ADB_SETTLE_SECONDS="${ADB_SETTLE_SECONDS:-30}"
ADB_APPEAR_SECONDS="${ADB_APPEAR_SECONDS:-10}"

DEVICE_ID=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --device-id) DEVICE_ID="$2"; shift 2 ;;
    *) echo "❌ Unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$DEVICE_ID" ]]; then
  echo "❌ --device-id is required" >&2
  exit 1
fi

if [[ ! -x "$USBIPD_BIN" ]]; then
  echo "No usbipd on this runner; skipping attach."
  exit 0
fi

command -v python3 >/dev/null || { echo "❌ python3 not found on PATH" >&2; exit 1; }

USBIPD_DIR="$(dirname "$USBIPD_BIN")"

SECONDS=0
LAST_PROBLEM="not tried yet"

run_usbipd() {
  (cd "$USBIPD_DIR" && "$USBIPD_BIN" "$@")
}

within_deadline() {
  [[ "$SECONDS" -lt "$TIMEOUT_SECONDS" ]]
}

fail() {
  echo "❌ Phone '$DEVICE_ID' is not usable after ${SECONDS}s: $1" >&2
  echo "--- usbipd list" >&2
  run_usbipd list >&2 || true
  echo "--- adb devices -l" >&2
  "$ADB_BIN" devices -l >&2 || true
  exit 1
}

# Prints "<busid> <client ip> <persisted guid>" for the connected device whose
# serial is DEVICE_ID, with "-" for an empty field, or nothing when it is not
# on the USB bus. usbipd names the serial only inside the InstanceId.
find_device() {
  run_usbipd state | python3 -c '
import json, sys
serial = sys.argv[1].upper()
for device in json.load(sys.stdin)["Devices"]:
    instance_id = (device.get("InstanceId") or "").upper()
    if device.get("BusId") and instance_id.rsplit("\\", 1)[-1] == serial:
        print(device["BusId"], device.get("ClientIPAddress") or "-", device.get("PersistedGuid") or "-")
        break
' "$DEVICE_ID"
}

adb_state() {
  "$ADB_BIN" devices | awk -v id="$DEVICE_ID" '$1 == id { print $2 }'
}

restart_adb_server() {
  "$ADB_BIN" kill-server >/dev/null 2>&1 || true
  "$ADB_BIN" start-server >/dev/null || fail "the adb server would not start"
}

# Waits briefly for adb to list the device. Returns 0 once it is `device`,
# 1 if it never showed up. usbipd can report a successful attach while the
# phone never appears in WSL at all, so a phone adb does not list within
# ADB_APPEAR_SECONDS returns 1 early and the caller attaches it again. A
# freshly attached phone also reads `unauthorized` for a few seconds while it
# finishes the USB debugging handshake, so a listed phone gets the full settle
# time. Only a phone still unauthorized when that ends fails the run, since
# retrying cannot fix a missing USB-debugging approval.
wait_for_adb() {
  local waited=0 state=""
  while [[ "$waited" -lt "$ADB_SETTLE_SECONDS" ]]; do
    state="$(adb_state)"
    case "$state" in
      device) return 0 ;;
      offline) restart_adb_server ;;
      "") [[ "$waited" -ge "$ADB_APPEAR_SECONDS" ]] && return 1 ;;
    esac
    sleep "$POLL_SECONDS"
    waited=$((waited + POLL_SECONDS + 1))
  done
  if [[ "$state" == "unauthorized" ]]; then
    fail "adb still reports it unauthorized. Unlock the phone and accept the USB debugging prompt, or re-authorize this host's adb key."
  fi
  return 1
}

attach_to_wsl() {
  local busid="$1" output
  if output="$(run_usbipd attach --wsl --busid "$busid" 2>&1)"; then
    return 0
  fi
  LAST_PROBLEM="usbipd attach --busid $busid failed: $output"
  return 1
}

while within_deadline; do
  if ! version_output="$(run_usbipd --version 2>&1)"; then
    LAST_PROBLEM="usbipd.exe cannot be run from WSL (Windows interop is not ready): $version_output"
    echo "⚠️  $LAST_PROBLEM; retrying..." >&2
    sleep "$POLL_SECONDS"
    continue
  fi

  if ! device="$(find_device)"; then
    LAST_PROBLEM="usbipd is running but its device list could not be read (the Windows service may still be starting)"
    echo "⚠️  $LAST_PROBLEM; retrying..." >&2
    sleep "$POLL_SECONDS"
    continue
  fi
  if [[ -z "$device" ]]; then
    LAST_PROBLEM="the phone is not on the Windows USB bus (still waking, unplugged, or on a dead cable)"
    echo "⚠️  $LAST_PROBLEM; retrying..." >&2
    sleep "$POLL_SECONDS"
    continue
  fi

  read -r busid client_ip persisted_guid <<<"$device"
  if [[ "$persisted_guid" == "-" ]]; then
    fail "usbipd has not shared it. Run 'usbipd bind --busid $busid' once from an elevated Windows shell."
  fi

  if [[ "$client_ip" == "-" ]]; then
    echo "Attaching busid $busid to WSL..."
    if ! attach_to_wsl "$busid"; then
      echo "⚠️  $LAST_PROBLEM; retrying..." >&2
      sleep "$POLL_SECONDS"
      continue
    fi
  fi

  restart_adb_server
  if wait_for_adb; then
    echo "✅ Phone '$DEVICE_ID' is attached (busid $busid) and adb lists it."
    exit 0
  fi

  # Windows believes the phone is attached, but adb cannot see it: the
  # attachment never took or went stale. Drop it so the next pass attaches
  # it afresh.
  LAST_PROBLEM="busid $busid is marked attached but adb cannot see the phone"
  echo "⚠️  $LAST_PROBLEM; detaching so it can be re-attached..." >&2
  run_usbipd detach --busid "$busid" >/dev/null 2>&1 || true
done

fail "$LAST_PROBLEM"
