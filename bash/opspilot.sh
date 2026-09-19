#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
OpsPilot - cross-platform operations automation

Usage:
  opspilot.sh system-report [--output FILE]
  opspilot.sh health --url URL [--timeout SECONDS]
  opspilot.sh log-scan --file FILE [--output CSV]
  opspilot.sh checksum --path DIRECTORY --output FILE
  opspilot.sh backup --source DIRECTORY --destination DIRECTORY
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 2
}

option_value() {
  local name="$1"
  shift

  while (($#)); do
    if [[ "$1" == "$name" ]]; then
      (($# >= 2)) || die "Missing value for $name"
      printf '%s' "$2"
      return 0
    fi
    shift
  done

  return 1
}

json_escape() {
  local value="$1"
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  printf '%s' "$value"
}

system_report() {
  local output=""
  output="$(option_value --output "$@" || true)"

  local generated hostname_value user_value os_value arch processors shell_version working_dir
  generated="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  hostname_value="$(hostname)"
  user_value="$(id -un)"
  os_value="$(uname -srm)"
  arch="$(uname -m)"
  processors="$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf 'unknown')"
  shell_version="${BASH_VERSION}"
  working_dir="$(pwd)"

  local json
  printf -v json '{\n  "generatedAtUtc": "%s",\n  "hostname": "%s",\n  "user": "%s",\n  "os": "%s",\n  "architecture": "%s",\n  "processors": "%s",\n  "bash": "%s",\n  "workingDir": "%s"\n}' \
    "$(json_escape "$generated")" \
    "$(json_escape "$hostname_value")" \
    "$(json_escape "$user_value")" \
    "$(json_escape "$os_value")" \
    "$(json_escape "$arch")" \
    "$(json_escape "$processors")" \
    "$(json_escape "$shell_version")" \
    "$(json_escape "$working_dir")"

  if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    printf '%s\n' "$json" >"$output"
  fi

  printf '%s\n' "$json"
}

health_check() {
  command -v curl >/dev/null 2>&1 || die "curl is required"

  local url timeout result http_code total_time healthy
  url="$(option_value --url "$@" || true)"
  [[ -n "$url" ]] || die "Missing required option: --url"

  timeout="$(option_value --timeout "$@" || true)"
  timeout="${timeout:-10}"

  if result="$(curl --silent --show-error --location --output /dev/null \
      --max-time "$timeout" --write-out '%{http_code} %{time_total}' "$url" 2>/dev/null)"; then
    read -r http_code total_time <<<"$result"
    if [[ "$http_code" -ge 200 && "$http_code" -lt 400 ]]; then
      healthy=true
    else
      healthy=false
    fi

    printf '{"uri":"%s","healthy":%s,"statusCode":%s,"latencySeconds":%s}\n' \
      "$(json_escape "$url")" "$healthy" "$http_code" "$total_time"
  else
    printf '{"uri":"%s","healthy":false,"statusCode":null,"error":"request failed"}\n' \
      "$(json_escape "$url")"
    return 1
  fi
}

log_scan() {
  local file output
  file="$(option_value --file "$@" || true)"
  [[ -n "$file" ]] || die "Missing required option: --file"
  [[ -f "$file" ]] || die "Log file not found: $file"
  output="$(option_value --output "$@" || true)"

  local temp
  temp="$(mktemp)"

  awk '
    BEGIN {
      IGNORECASE = 1
      print "LineNumber,Severity,Message"
    }
    {
      severity = ""
      lower = tolower($0)
      if (lower ~ /(^|[^a-z])(fatal|critical)([^a-z]|$)/) {
        severity = "critical"
      } else if (lower ~ /(^|[^a-z])(error|failed|failure|exception)([^a-z]|$)/) {
        severity = "error"
      } else if (lower ~ /(^|[^a-z])(warn|warning)([^a-z]|$)/) {
        severity = "warning"
      }

      if (severity != "") {
        message = $0
        gsub(/"/, """", message)
        printf "%d,%s,\"%s\"\n", NR, severity, message
      }
    }
  ' "$file" >"$temp"

  local count
  count=$(( $(wc -l <"$temp") - 1 ))

  if [[ -n "$output" ]]; then
    mkdir -p "$(dirname "$output")"
    cp "$temp" "$output"
  fi

  cat "$temp"
  printf 'Findings: %d\n' "$count" >&2
  rm -f "$temp"
}

checksum_manifest() {
  command -v find >/dev/null 2>&1 || die "find is required"

  local path output
  path="$(option_value --path "$@" || true)"
  output="$(option_value --output "$@" || true)"
  [[ -n "$path" ]] || die "Missing required option: --path"
  [[ -n "$output" ]] || die "Missing required option: --output"
  [[ -d "$path" ]] || die "Directory not found: $path"

  mkdir -p "$(dirname "$output")"
  : >"$output"

  local root file relative hash
  root="$(cd "$path" && pwd)"

  while IFS= read -r -d '' file; do
    relative="${file#"$root"/}"

    if command -v sha256sum >/dev/null 2>&1; then
      hash="$(sha256sum "$file" | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
      hash="$(shasum -a 256 "$file" | awk '{print $1}')"
    else
      die "sha256sum or shasum is required"
    fi

    printf '%s  %s\n' "$hash" "$relative" >>"$output"
  done < <(find "$root" -type f -print0 | sort -z)

  printf '%s\n' "$output"
}

create_backup() {
  command -v tar >/dev/null 2>&1 || die "tar is required"

  local source destination source_name timestamp archive
  source="$(option_value --source "$@" || true)"
  destination="$(option_value --destination "$@" || true)"
  [[ -n "$source" ]] || die "Missing required option: --source"
  [[ -n "$destination" ]] || die "Missing required option: --destination"
  [[ -d "$source" ]] || die "Directory not found: $source"

  mkdir -p "$destination"
  source="$(cd "$source" && pwd)"
  destination="$(cd "$destination" && pwd)"
  source_name="$(basename "$source")"
  timestamp="$(date -u +"%Y%m%d-%H%M%S")"
  archive="$destination/$source_name-$timestamp.tar.gz"

  tar -C "$(dirname "$source")" -czf "$archive" "$source_name"
  printf '%s\n' "$archive"
}

main() {
  (($#)) || {
    usage
    exit 2
  }

  local command="$1"
  shift

  case "$command" in
    system-report) system_report "$@" ;;
    health) health_check "$@" ;;
    log-scan) log_scan "$@" ;;
    checksum) checksum_manifest "$@" ;;
    backup) create_backup "$@" ;;
    -h|--help|help) usage ;;
    *) die "Unknown command: $command" ;;
  esac
}

main "$@"
