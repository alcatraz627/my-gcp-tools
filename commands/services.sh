#!/usr/bin/env bash
# commands/services.sh — list enabled GCP APIs/services across projects
#
# Usage:
#   gct services                   Show enabled APIs for the active project
#   gct services PROJECT_ID        Show enabled APIs for a specific project
#   gct services --all             Show enabled APIs across ALL projects
#   gct services --filter KEYWORD  Filter by keyword (e.g. "run", "bigquery")

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/common.sh"

CMD_HELP="List enabled GCP APIs/services for one or all projects."
CMD_USAGE="gct services [PROJECT_ID] [--all] [--filter KEYWORD]"
CMD_EXAMPLES=(
  "gct services                    # enabled APIs in active project"
  "gct services my-project-id      # enabled APIs in a specific project"
  "gct services --all              # enabled APIs across all projects"
  "gct services --filter run       # filter by keyword (e.g. 'run', 'sql')"
  "gct services --all --filter ai  # AI-related APIs across all projects"
)

_show_services() {
  local proj="$1"
  local kw="$2"

  header "PROJECT: $proj"

  local filter_expr="NOT name:servicemanagement AND NOT name:serviceusage AND NOT name:cloudapis \
    AND NOT name:cloudresourcemanager"
  [[ -n "$kw" ]] && filter_expr+=" AND name:$kw"

  gcloud services list --enabled --project="$proj" \
    --filter="$filter_expr" \
    --format="table[box](name.basename():label=API,title:label=TITLE)" 2>/dev/null || none
}

main() {
  require_gcloud

  local target=""
  local scan_all=false
  local keyword=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)    scan_all=true; shift ;;
      --filter) keyword="$2"; shift 2 ;;
      -*)
        error "Unknown flag: $1"
        echo "Usage: $CMD_USAGE" >&2
        exit 1
        ;;
      *) target="$1"; shift ;;
    esac
  done

  if $scan_all; then
    echo -e "${BOLD}Scanning all accessible projects...${RESET}"
    for proj in $(all_projects); do
      _show_services "$proj" "$keyword"
    done
  else
    local proj
    proj=$(resolve_project "$target") || exit 1
    _show_services "$proj" "$keyword"
  fi
}

main "$@"
