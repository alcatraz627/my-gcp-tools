#!/usr/bin/env bash
# commands/report.sh — condensed single-page digest for one GCP project
#
# Unlike `gct inspect` (verbose, per-resource-type tables), `report` outputs
# a compact at-a-glance summary: what exists, what APIs are on, billing status.
#
# Usage:
#   gct report                 Report for the active project
#   gct report PROJECT_ID      Report for a specific project
#   gct report PROJECT --md    Output as Markdown (useful for piping/saving)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/common.sh"

CMD_HELP="Condensed at-a-glance digest for a single GCP project."
CMD_USAGE="gct report [PROJECT_ID] [--md]"
CMD_EXAMPLES=(
  "gct report                        # digest for active project"
  "gct report my-project-id          # digest for a specific project"
  "gct report my-project-id --md     # markdown output (pipe/save)"
  "gct report my-project-id --md > report.md   # save to file"
)

# ── helpers ───────────────────────────────────────────────────────────────────

count_or_none() {
  # count non-empty lines; print N or "—"
  local input="$1"
  if [[ -z "$input" ]]; then
    echo "—"
    return
  fi
  local n
  n=$(printf '%s\n' "$input" | grep -c '[^[:space:]]' || true)
  if [[ "$n" -eq 0 ]]; then
    echo "—"
  else
    echo "$n"
  fi
}

row() {
  # $1=label $2=value $3=detail(optional)
  if $MD_MODE; then
    printf "| %-30s | %-10s | %s |\n" "$1" "$2" "${3:-}"
  else
    if [[ "$2" == "—" ]]; then
      printf "  ${DIM}%-30s ${RESET}${DIM}%s${RESET}\n" "$1" "$2"
    else
      printf "  ${BOLD}%-30s ${RESET}${GREEN}%s${RESET}  ${DIM}%s${RESET}\n" "$1" "$2" "${3:-}"
    fi
  fi
}

# ── main ──────────────────────────────────────────────────────────────────────

main() {
  require_gcloud

  local proj=""
  MD_MODE=false

  for arg in "$@"; do
    case "$arg" in
      --md) MD_MODE=true ;;
      *)    proj="$arg"  ;;
    esac
  done

  proj=$(resolve_project "$proj") || exit 1

  # Fetch all data (suppress errors — missing = empty)
  local run_svcs run_jobs fn1 fn2 buckets sql firestore secrets scheduler artifact vms networks sas enabled_apis billing

  run_svcs=$(gcloud run services list --project="$proj" --format="value(metadata.name)" 2>/dev/null)
  run_jobs=$(gcloud run jobs list --project="$proj" --format="value(metadata.name)" 2>/dev/null)
  fn1=$(gcloud functions list --project="$proj" --format="value(name.basename())" 2>/dev/null)
  fn2=$(gcloud functions list --project="$proj" --gen2 --format="value(name.basename())" 2>/dev/null)
  buckets=$(gsutil ls -p "$proj" 2>/dev/null)
  sql=$(gcloud sql instances list --project="$proj" --format="value(name,databaseVersion,state)" 2>/dev/null)
  firestore=$(gcloud firestore databases list --project="$proj" --format="value(name.basename())" 2>/dev/null)
  secrets=$(gcloud secrets list --project="$proj" --format="value(name.basename())" 2>/dev/null)
  scheduler=$(gcloud scheduler jobs list --project="$proj" --format="value(name.basename())" 2>/dev/null)
  artifact=$(gcloud artifacts repositories list --project="$proj" --format="value(name.basename())" 2>/dev/null)
  vms=$(gcloud compute instances list --project="$proj" --format="value(name,zone.basename(),status)" 2>/dev/null)
  networks=$(gcloud compute networks list --project="$proj" --format="value(name,subnetMode)" 2>/dev/null)
  sas=$(gcloud iam service-accounts list --project="$proj" --format="value(email)" 2>/dev/null)
  enabled_apis=$(gcloud services list --enabled --project="$proj" \
    --filter="NOT name:servicemanagement AND NOT name:serviceusage AND NOT name:cloudapis AND NOT name:cloudresourcemanager AND NOT name:iam AND NOT name:iamcredentials AND NOT name:monitoring AND NOT name:logging AND NOT name:storage-api AND NOT name:storage-component" \
    --format="value(name.basename())" 2>/dev/null | sort)
  billing=$(gcloud billing projects describe "$proj" \
    --format="value(billingAccountName.basename(),billingEnabled)" 2>/dev/null)
  billing_acct=$(echo "$billing" | cut -d$'\t' -f1)
  billing_on=$(echo "$billing" | cut -d$'\t' -f2)

  # ── Output ──────────────────────────────────────────────────────────────────

  if $MD_MODE; then
    echo "# GCP Project Report: \`$proj\`"
    echo ""
    echo "_Generated: $(date '+%Y-%m-%d %H:%M')_"
    echo ""
    echo "## Infrastructure"
    echo ""
    echo "| Resource | Count | Detail |"
    echo "|---|---|---|"
  else
    header "GCP Project Report: $proj"
    echo ""
    echo -e "  ${DIM}Generated: $(date '+%Y-%m-%d %H:%M')${RESET}"
    echo ""
    echo -e "  ${BOLD}INFRASTRUCTURE${RESET}"
    echo "  ──────────────────────────────────────────"
  fi

  row "Cloud Run Services"   "$(count_or_none "$run_svcs")"  "$(echo "$run_svcs" | tr '\n' ' ' | xargs)"
  row "Cloud Run Jobs"       "$(count_or_none "$run_jobs")"  "$(echo "$run_jobs" | tr '\n' ' ' | xargs)"
  row "Cloud Functions gen1" "$(count_or_none "$fn1")"       "$(echo "$fn1" | tr '\n' ' ' | xargs)"
  row "Cloud Functions gen2" "$(count_or_none "$fn2")"       "$(echo "$fn2" | tr '\n' ' ' | xargs)"
  row "GCS Buckets"          "$(count_or_none "$buckets")"   "$(echo "$buckets" | tr '\n' ' ' | xargs)"
  row "Cloud SQL Instances"  "$(count_or_none "$sql")"       "$(echo "$sql" | head -3 | tr '\n' ' ' | xargs)"
  row "Firestore Databases"  "$(count_or_none "$firestore")" "$(echo "$firestore" | tr '\n' ' ' | xargs)"
  row "Secrets"              "$(count_or_none "$secrets")"   "$(echo "$secrets" | tr '\n' ' ' | xargs)"
  row "Scheduler Jobs"       "$(count_or_none "$scheduler")" "$(echo "$scheduler" | tr '\n' ' ' | xargs)"
  row "Artifact Repos"       "$(count_or_none "$artifact")"  "$(echo "$artifact" | tr '\n' ' ' | xargs)"
  row "Compute VMs"          "$(count_or_none "$vms")"       "$(echo "$vms" | tr '\n' ' ' | xargs)"
  row "VPC Networks"         "$(count_or_none "$networks")"  "$(echo "$networks" | tr '\n' ' ' | xargs)"
  row "Service Accounts"     "$(count_or_none "$sas")"       ""

  if $MD_MODE; then
    echo ""
    echo "## Billing"
    echo ""
    echo "| Field | Value |"
    echo "|---|---|"
    echo "| Account | \`${billing_acct:-(none)}\` |"
    echo "| Billing Enabled | $billing_on |"
    echo ""
    echo "## Enabled APIs"
    echo ""
    echo "\`\`\`"
    echo "$enabled_apis"
    echo "\`\`\`"
  else
    echo ""
    echo -e "  ${BOLD}BILLING${RESET}"
    echo "  ──────────────────────────────────────────"
    kv "Account"          "${billing_acct:-(none)}"
    kv "Billing Enabled"  "${billing_on:-False}"
    echo ""
    echo -e "  ${BOLD}ENABLED APIs (${#enabled_apis} chars)${RESET}"
    echo "  ──────────────────────────────────────────"
    echo "$enabled_apis" | sed 's/^/  /' | column
  fi

  echo ""
}

main "$@"
