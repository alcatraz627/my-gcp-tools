#!/usr/bin/env bash
# commands/logs.sh — tail structured logs for a Cloud Run service
#
# Usage:
#   gct logs SERVICE                Tail last 100 log entries (active project)
#   gct logs SERVICE PROJECT_ID     Tail from a specific project
#   gct logs SERVICE --limit N      Override the default 100-line limit
#   gct logs SERVICE --follow       Stream new logs as they arrive (10s poll)
#   gct logs SERVICE --severity LVL Filter by severity: DEBUG INFO WARNING ERROR CRITICAL

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/common.sh"

CMD_HELP="Tail recent logs for a Cloud Run service."
CMD_USAGE="gct logs SERVICE [PROJECT_ID] [--limit N] [--severity LEVEL] [--follow]"
CMD_EXAMPLES=(
  "gct logs my-api                     # last 100 lines, active project"
  "gct logs my-api my-project-id       # logs from a specific project"
  "gct logs my-api --limit 500         # fetch more log lines"
  "gct logs my-api --severity ERROR    # errors only"
  "gct logs my-api --follow            # poll every 10s for new entries"
)

main() {
  require_gcloud

  local svc=""
  local proj=""
  local limit=100
  local severity=""
  local follow=false

  # Parse args
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --limit)    limit="$2";    shift 2 ;;
      --severity) severity="$2"; shift 2 ;;
      --follow)   follow=true;   shift   ;;
      -*)
        error "Unknown flag: $1"
        echo "Usage: $CMD_USAGE" >&2
        exit 1
        ;;
      *)
        if [[ -z "$svc" ]]; then svc="$1"
        elif [[ -z "$proj" ]]; then proj="$1"
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$svc" ]]; then
    error "Service name required."
    echo "Usage: $CMD_USAGE" >&2
    exit 1
  fi

  proj=$(resolve_project "$proj") || exit 1

  local filter="resource.type=cloud_run_revision AND resource.labels.service_name=\"$svc\""
  [[ -n "$severity" ]] && filter+=" AND severity=$severity"

  kv "Service"  "$svc"
  kv "Project"  "$proj"
  kv "Limit"    "$limit"
  [[ -n "$severity" ]] && kv "Severity" "$severity"
  echo ""

  if $follow; then
    echo -e "${DIM}Polling every 10s — Ctrl+C to stop${RESET}\n"
    while true; do
      gcloud logging read "$filter" \
        --project="$proj" --limit="$limit" \
        --format="table(timestamp,severity,textPayload,jsonPayload.message)" \
        --order=asc 2>/dev/null
      sleep 10
    done
  else
    gcloud logging read "$filter" \
      --project="$proj" --limit="$limit" \
      --format="table(timestamp,severity,textPayload,jsonPayload.message)" \
      --order=asc 2>/dev/null
  fi
}

main "$@"
