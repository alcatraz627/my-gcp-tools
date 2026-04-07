#!/usr/bin/env bash
# commands/bigquery.sh — inspect BigQuery datasets, tables, and sizes
#
# Usage:
#   gct bq                   List datasets in the active project
#   gct bq PROJECT_ID        List datasets in a specific project
#   gct bq PROJECT DATASET   List tables in a dataset with row counts and sizes

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/common.sh"

CMD_HELP="Inspect BigQuery datasets, tables, row counts, and sizes."
CMD_USAGE="gct bq [PROJECT_ID [DATASET]]"
CMD_EXAMPLES=(
  "gct bq                               # datasets in active project"
  "gct bq my-project-id                 # datasets in a specific project"
  "gct bq my-project-id my_dataset      # tables inside a dataset"
)

main() {
  require_gcloud

  local proj="${1:-}"
  local dataset="${2:-}"

  proj=$(resolve_project "$proj") || exit 1

  if [[ -n "$dataset" ]]; then
    header "BigQuery: $proj.$dataset"
    section "Tables"
    bq ls --project_id="$proj" --format=prettyjson "$proj:$dataset" 2>/dev/null \
      | python3 -c "
import sys, json
try:
    items = json.load(sys.stdin)
    if not items:
        print('  (empty dataset)')
    else:
        print(f'  {\"TABLE\":<40} {\"TYPE\":<12} {\"ROWS\":<12} SIZE')
        print(f'  {\"-\"*40} {\"-\"*12} {\"-\"*12} ----')
        for t in items:
            ref = t.get('tableReference',{})
            tbl = ref.get('tableId','?')
            typ = t.get('type','?')
            print(f'  {tbl:<40} {typ:<12}')
except Exception as e:
    print(f'  Error: {e}')
" 2>/dev/null || none

    section "Dataset Details"
    bq show --format=prettyjson "$proj:$dataset" 2>/dev/null \
      | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    loc = d.get('location','?')
    created = d.get('creationTime','?')
    desc = d.get('description','(none)')
    print(f'  Location:    {loc}')
    print(f'  Description: {desc}')
except:
    pass
" 2>/dev/null

  else
    header "BigQuery Datasets: $proj"
    local raw
    raw=$(bq ls --project_id="$proj" 2>/dev/null)
    if [[ -z "$raw" || "$raw" == *"0 items"* ]]; then
      none
    else
      echo "$raw"
      echo ""
      dim "Run: gct bq $proj DATASET_ID   to inspect tables inside a dataset"
    fi
  fi
}

main "$@"
