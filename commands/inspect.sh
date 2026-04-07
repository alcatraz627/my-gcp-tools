#!/usr/bin/env bash
# commands/inspect.sh — full resource survey for one or all GCP projects
#
# Usage:
#   gct inspect              Survey ALL accessible projects
#   gct inspect PROJECT_ID   Survey a single project
#
# What it checks (per project):
#   Enabled APIs, Cloud Run (services + jobs), Cloud Functions (gen1 + gen2),
#   GCS buckets, Cloud SQL, Pub/Sub, Firestore, BigQuery, Secret Manager,
#   Cloud Scheduler, Artifact Registry, Compute VMs, VPC networks, IAM service accounts

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/colors.sh"
source "$SCRIPT_DIR/../lib/common.sh"

CMD_HELP="Survey all provisioned resources in one or all GCP projects."
CMD_USAGE="gct inspect [PROJECT_ID]"
CMD_EXAMPLES=(
  "gct inspect                    # scan all accessible projects"
  "gct inspect my-project-id      # scan a single project"
)

_inspect_project() {
  local proj="$1"
  header "PROJECT: $proj"

  section "Enabled APIs (non-default)"
  dim "APIs beyond the baseline platform services"
  gcloud services list --enabled --project="$proj" \
    --filter="NOT name:servicemanagement AND NOT name:serviceusage AND NOT name:cloudapis \
              AND NOT name:cloudresourcemanager AND NOT name:iam AND NOT name:iamcredentials" \
    --format="table[box](name.basename():label=API, title:label=TITLE)" 2>/dev/null || none

  section "Cloud Run — Services"
  dim "Long-running HTTP services with auto-scaling"
  gcloud run services list --project="$proj" \
    --format="table[box](metadata.name:label=NAME,region:label=REGION,status.url:label=URL,status.conditions[0].status:label=READY)" 2>/dev/null || none

  section "Cloud Run — Jobs"
  dim "Batch/one-shot containers that run to completion"
  gcloud run jobs list --project="$proj" \
    --format="table[box](metadata.name:label=NAME,metadata.namespace:label=REGION)" 2>/dev/null || none

  section "Cloud Functions — Gen 1"
  dim "Event-driven functions (legacy runtime, per-function scaling)"
  gcloud functions list --project="$proj" \
    --format="table[box](name.basename():label=NAME,region:label=REGION,status:label=STATUS,entryPoint:label=ENTRY_POINT,runtime:label=RUNTIME)" 2>/dev/null || none

  section "Cloud Functions — Gen 2"
  dim "Event-driven functions (built on Cloud Run, more powerful)"
  gcloud functions list --project="$proj" --gen2 \
    --format="table[box](name.basename():label=NAME,region:label=REGION,state:label=STATE,runtime:label=RUNTIME)" 2>/dev/null || none

  section "GCS Buckets"
  dim "Object storage buckets in this project"
  gsutil ls -p "$proj" 2>/dev/null || none

  section "Cloud SQL Instances"
  dim "Managed relational databases (PostgreSQL, MySQL, SQL Server)"
  gcloud sql instances list --project="$proj" \
    --format="table[box](name:label=NAME,region:label=REGION,databaseVersion:label=ENGINE,state:label=STATE,settings.tier:label=TIER)" 2>/dev/null || none

  section "Pub/Sub — Topics"
  dim "Message queues (publishers write here)"
  gcloud pubsub topics list --project="$proj" \
    --format="table[box](name.basename():label=TOPIC)" 2>/dev/null || none

  section "Pub/Sub — Subscriptions"
  dim "Consumers that pull/push messages from topics"
  gcloud pubsub subscriptions list --project="$proj" \
    --format="table[box](name.basename():label=SUBSCRIPTION,topic.basename():label=TOPIC,pushConfig.pushEndpoint:label=PUSH_URL)" 2>/dev/null || none

  section "Firestore Databases"
  dim "NoSQL document databases"
  gcloud firestore databases list --project="$proj" \
    --format="table[box](name.basename():label=NAME,type:label=TYPE,locationId:label=LOCATION)" 2>/dev/null || none

  section "BigQuery Datasets"
  dim "Data warehouse datasets in this project"
  bq ls --project_id="$proj" 2>/dev/null || none

  section "Secret Manager"
  dim "Encrypted secrets (API keys, credentials, config)"
  gcloud secrets list --project="$proj" \
    --format="table[box](name.basename():label=SECRET,createTime:label=CREATED,replication.automatic:label=GLOBAL_REPL)" 2>/dev/null || none

  section "Cloud Scheduler Jobs"
  dim "Cron-triggered HTTP or Pub/Sub calls"
  gcloud scheduler jobs list --project="$proj" \
    --format="table[box](name.basename():label=NAME,schedule:label=CRON,state:label=STATE,lastAttemptTime:label=LAST_RUN)" 2>/dev/null || none

  section "Artifact Registry Repositories"
  dim "Container image and package registries (Docker, npm, Maven, etc.)"
  gcloud artifacts repositories list --project="$proj" \
    --format="table[box](name.basename():label=REPO,format:label=FORMAT,location:label=REGION)" 2>/dev/null || none

  section "Compute Engine — VM Instances"
  dim "Virtual machines (always-on, unmanaged compute)"
  gcloud compute instances list --project="$proj" \
    --format="table[box](name:label=NAME,zone.basename():label=ZONE,machineType.basename():label=TYPE,status:label=STATUS,networkInterfaces[0].accessConfigs[0].natIP:label=EXT_IP)" 2>/dev/null || none

  section "VPC Networks"
  dim "Virtual private networks and their routing mode"
  gcloud compute networks list --project="$proj" \
    --format="table[box](name:label=NAME,subnetMode:label=SUBNET_MODE,routingConfig.routingMode:label=ROUTING)" 2>/dev/null || none

  section "IAM — Service Accounts"
  dim "Machine identities used by apps and services"
  gcloud iam service-accounts list --project="$proj" \
    --format="table[box](displayName:label=NAME,email:label=EMAIL,disabled:label=DISABLED)" 2>/dev/null || none
}

main() {
  require_gcloud
  local target="${1:-}"

  if [[ -n "$target" ]]; then
    _inspect_project "$target"
  else
    echo -e "${BOLD}Fetching all accessible projects...${RESET}"
    for proj in $(all_projects); do
      _inspect_project "$proj"
    done
  fi

  echo -e "\n${GREEN}${BOLD}Done.${RESET}\n"
}

main "$@"
