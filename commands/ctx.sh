#!/usr/bin/env bash
# commands/ctx.sh — show current gcloud auth and configuration context
#
# Usage:
#   gct ctx          Show active account, project, and region
#   gct ctx --full   Show full gcloud config (all properties)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/common.sh"

CMD_HELP="Show the active gcloud account, project, and configuration."
CMD_USAGE="gct ctx [--full]"
CMD_EXAMPLES=(
  "gct ctx           # show active account + project at a glance"
  "gct ctx --full    # dump the full gcloud config"
)

main() {
  require_gcloud

  local full=false
  [[ "${1:-}" == "--full" ]] && full=true

  if $full; then
    gcloud config list
    return
  fi

  header "Active GCP Context"

  local account project region
  account=$(gcloud config get-value account 2>/dev/null)
  project=$(gcloud config get-value project 2>/dev/null)
  region=$(gcloud config get-value compute/region 2>/dev/null)
  zone=$(gcloud config get-value compute/zone 2>/dev/null)

  kv "Account"  "${account:-(not set)}"
  kv "Project"  "${project:-(not set)}"
  kv "Region"   "${region:-(not set)}"
  kv "Zone"     "${zone:-(not set)}"
  echo ""

  section "Credentialed Accounts"
  gcloud auth list --format="table[box](account,status)" 2>/dev/null

  if [[ -n "$project" ]]; then
    echo ""
    section "Recent Configs"
    gcloud config configurations list --format="table[box](name,is_active,properties.core.account,properties.core.project)" 2>/dev/null
  fi
}

main "$@"
