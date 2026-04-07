#!/usr/bin/env bash
# lib/common.sh — shared utility functions

# Resolve active project: use arg if given, else fall back to gcloud config
resolve_project() {
  local proj="${1:-}"
  if [[ -z "$proj" ]]; then
    proj=$(gcloud config get-value project 2>/dev/null)
    if [[ -z "$proj" ]]; then
      error "No project specified and no default project set."
      echo "  Set one with: gct use PROJECT_ID" >&2
      return 1
    fi
  fi
  echo "$proj"
}

# List all accessible project IDs
all_projects() {
  gcloud projects list --format="value(projectId)" 2>/dev/null
}

# Verify gcloud is on PATH and authenticated
require_gcloud() {
  if ! command -v gcloud &>/dev/null; then
    error "gcloud not found. Install the Google Cloud SDK:"
    echo "  https://cloud.google.com/sdk/docs/install" >&2
    exit 1
  fi
  if ! gcloud auth list --format="value(account)" 2>/dev/null | grep -q '@'; then
    error "No authenticated gcloud account found."
    echo "  Run: gcloud auth login" >&2
    exit 1
  fi
}
