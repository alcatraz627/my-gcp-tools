#!/usr/bin/env bash
# commands/billing.sh — show billing accounts, project links, and budgets
#
# Usage:
#   gct billing               List billing accounts and which projects are linked
#   gct billing budgets       List configured budgets on all active billing accounts
#   gct billing PROJECT_ID    Show billing status for a specific project

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/common.sh"

CMD_HELP="Show billing accounts, project billing links, and configured budgets."
CMD_USAGE="gct billing [PROJECT_ID | budgets]"
CMD_EXAMPLES=(
  "gct billing                         # all accounts + project links"
  "gct billing budgets                 # configured budget alerts"
  "gct billing my-project-id           # billing status for one project"
)

cmd_accounts_and_links() {
  section "Billing Accounts"
  gcloud billing accounts list \
    --format="table[box](name.basename():label=ACCOUNT_ID,displayName:label=NAME,open:label=ACTIVE,masterBillingAccount:label=MASTER)" 2>/dev/null || none

  section "Project → Billing Links"
  echo ""
  printf "  ${BOLD}%-36s %-26s %s${RESET}\n" "PROJECT" "BILLING_ACCOUNT" "ENABLED"
  printf "  %-36s %-26s %s\n" "──────────────────────────────────" "──────────────────────────" "───────"
  for proj in $(all_projects); do
    result=$(gcloud billing projects describe "$proj" \
      --format="csv[no-heading](billingAccountName.basename(),billingEnabled)" 2>/dev/null)
    acct=$(echo "$result" | cut -d',' -f1)
    enabled=$(echo "$result" | cut -d',' -f2)
    if [[ "$enabled" == "True" ]]; then
      printf "  ${GREEN}%-36s %-26s %s${RESET}\n" "$proj" "${acct:-(none)}" "$enabled"
    else
      printf "  ${DIM}%-36s %-26s %s${RESET}\n" "$proj" "${acct:-(none)}" "${enabled:-False}"
    fi
  done
  echo ""
}

cmd_budgets() {
  section "Configured Budgets"
  local found=false
  while IFS= read -r acct_id; do
    local budgets
    budgets=$(gcloud billing budgets list --billing-account="$acct_id" \
      --format="table[box](displayName:label=NAME,amount.specifiedAmount.units:label=LIMIT_USD,thresholdRules[0].thresholdPercent:label=ALERT_AT)" 2>/dev/null)
    if [[ -n "$budgets" && "$budgets" != *"Listed 0 items"* ]]; then
      echo -e "\n  Account: ${BOLD}$acct_id${RESET}"
      echo "$budgets"
      found=true
    fi
  done < <(gcloud billing accounts list --filter="open=true" --format="value(name.basename())" 2>/dev/null)
  $found || echo -e "  ${DIM}No budgets configured on any active billing account.${RESET}"
  echo ""
  echo -e "  ${DIM}Add budgets at: console.cloud.google.com/billing → Budgets & alerts${RESET}"
}

cmd_project() {
  local proj="$1"
  header "Billing: $proj"
  gcloud billing projects describe "$proj" \
    --format="table[box](name,billingAccountName.basename():label=BILLING_ACCOUNT,billingEnabled:label=ENABLED)" 2>/dev/null || none
}

main() {
  require_gcloud
  local subcmd="${1:-}"

  case "$subcmd" in
    budgets) cmd_budgets ;;
    "")      cmd_accounts_and_links ;;
    *)       cmd_project "$subcmd" ;;
  esac
}

main "$@"
