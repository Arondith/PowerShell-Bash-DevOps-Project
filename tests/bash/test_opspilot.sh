#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/bash/opspilot.sh"
TMP="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "Expected file: $1"
}

printf 'Running Bash OpsPilot tests...\n'

report="$TMP/system-report.json"
bash "$SCRIPT" system-report --output "$report" >/dev/null
assert_file "$report"
grep -q '"hostname"' "$report" || fail "System report is missing hostname"
grep -q '"architecture"' "$report" || fail "System report is missing architecture"

findings="$TMP/findings.csv"
bash "$SCRIPT" log-scan --file "$ROOT/examples/sample.log" --output "$findings" >/dev/null
assert_file "$findings"
[[ "$(wc -l <"$findings")" -eq 5 ]] || fail "Expected four findings plus CSV header"
grep -q 'critical' "$findings" || fail "Critical finding was not detected"
grep -q 'warning' "$findings" || fail "Warning finding was not detected"

source_dir="$TMP/source"
mkdir -p "$source_dir"
printf 'alpha\n' >"$source_dir/alpha.txt"
printf 'beta\n' >"$source_dir/beta.txt"

manifest="$TMP/sha256.txt"
bash "$SCRIPT" checksum --path "$source_dir" --output "$manifest" >/dev/null
assert_file "$manifest"
grep -q 'alpha.txt' "$manifest" || fail "alpha.txt missing from manifest"
grep -Eq '^[a-f0-9]{64}  ' "$manifest" || fail "Manifest is missing SHA256 values"

backup_dir="$TMP/backups"
archive="$(bash "$SCRIPT" backup --source "$source_dir" --destination "$backup_dir")"
assert_file "$archive"
[[ "$archive" == *.tar.gz ]] || fail "Backup does not use tar.gz format"

if bash "$SCRIPT" unknown-command >/dev/null 2>&1; then
  fail "Unknown command should return a non-zero exit code"
fi

printf 'All Bash OpsPilot tests passed.\n'
