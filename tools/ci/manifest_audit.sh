#!/usr/bin/env bash
# Manifest audit for T03. Fails on forbidden permissions.
# See PLAN.md 8.6 and 12.6 AC15.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST_DIR="$ROOT/app/android"

FORBIDDEN=(
  "android.permission.ACCESS_BACKGROUND_LOCATION"
  "android.permission.RECEIVE_BOOT_COMPLETED"
  "android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"
  "android.permission.WAKE_LOCK"
  "android.permission.SYSTEM_ALERT_WINDOW"
)

ALLOWED=(
  "android.permission.INTERNET"
  "android.permission.ACCESS_FINE_LOCATION"
  "android.permission.ACCESS_COARSE_LOCATION"
  "android.permission.FOREGROUND_SERVICE"
  "android.permission.FOREGROUND_SERVICE_LOCATION"
  "android.permission.POST_NOTIFICATIONS"
)

fail=0
for p in "${FORBIDDEN[@]}"; do
  if grep -rn --include="*.xml" --include="*.kts" --include="*.gradle" "$p" "$MANIFEST_DIR" >/dev/null 2>&1; then
    echo "FORBIDDEN permission found: $p"
    fail=1
  fi
done

echo "Declared permissions in source manifests:"
grep -rhn --include="*.xml" "uses-permission" "$MANIFEST_DIR" || echo "(none in main source set; INTERNET only in debug/profile is expected)"

if [ "$fail" -ne 0 ]; then
  echo "manifest audit: FAIL"
  exit 1
fi
echo "manifest audit: PASS (source audit; full merged-manifest check lands in T45)"
