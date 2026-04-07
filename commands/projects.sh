#!/usr/bin/env bash
# commands/projects.sh — list, switch, and pick GCP projects
#
# Usage:
#   gct projects             List all accessible projects
#   gct use PROJECT_ID       Switch the active (default) project
#   gct pick                 Interactive fuzzy-search project picker (requires fzf)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/common.sh"

CMD_HELP="List, switch, and interactively pick GCP projects."
CMD_USAGE="gct projects | gct use PROJECT_ID | gct pick"
CMD_EXAMPLES=(
  "gct projects                    # list all accessible projects"
  "gct use my-project-id           # switch active project"
  "gct pick                        # fuzzy project picker (needs fzf)"
)

cmd_projects() {
  require_gcloud
  echo -e "${BOLD}Accessible projects:${RESET}\n"
  gcloud projects list \
    --format="table[box](projectId:label=PROJECT_ID,name:label=NAME,projectNumber:label=NUMBER,lifecycleState:label=STATE)" 2>/dev/null
  echo ""
  local active
  active=$(gcloud config get-value project 2>/dev/null)
  [[ -n "$active" ]] && success "Active project: $active"
}

cmd_use() {
  local proj="${1:?}"
  require_gcloud
  gcloud config set project "$proj"
  success "Active project set to: $proj"
}

cmd_pick() {
  require_gcloud
  if ! command -v fzf &>/dev/null; then
    error "fzf not found. Install with: brew install fzf"
    exit 1
  fi
  local chosen
  chosen=$(gcloud projects list --format="value(projectId)" 2>/dev/null | fzf --prompt="Select project: " --height=15 --reverse)
  if [[ -n "$chosen" ]]; then
    gcloud config set project "$chosen"
    success "Active project set to: $chosen"
  else
    dim "No project selected."
  fi
}
