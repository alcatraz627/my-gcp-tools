# gct Cheatsheet

> **gct** — Google Cloud Tools. One CLI for all GCP inspection and management.
> Repo: https://github.com/alcatraz627/my-gcp-tools

---

## Quick Reference

```
gct <command> [args]
```

---

## Context & Navigation

| Command | What it does |
|---|---|
| `gct ctx` | Active account, project, region at a glance |
| `gct ctx --full` | Full `gcloud config` dump |
| `gct projects` | List all accessible projects with state |
| `gct use PROJECT_ID` | Switch active (default) project |
| `gct pick` | Fuzzy project picker (requires `fzf`) |

```bash
gct ctx                              # who am I, what project?
gct use ambient-future-482717-r2     # switch project
gct pick                             # interactive picker
```

---

## Resource Survey

| Command | What it does |
|---|---|
| `gct inspect` | Full resource survey — ALL projects |
| `gct inspect PROJECT_ID` | Full survey — one project |
| `gct report` | Condensed digest — active project |
| `gct report PROJECT_ID` | Condensed digest — one project |
| `gct report PROJECT_ID --md` | Markdown output (pipeable) |

```bash
gct inspect                              # everything, all projects (slow)
gct inspect ambient-future-482717-r2    # one project deep-dive
gct report ambient-future-482717-r2     # fast summary: counts + billing + APIs
gct report ambient-future-482717-r2 --md > report.md   # save to file
```

**inspect covers:** Cloud Run (services + jobs), Cloud Functions (gen1 + gen2),
GCS buckets, Cloud SQL, Pub/Sub, Firestore, BigQuery, Secret Manager,
Cloud Scheduler, Artifact Registry, Compute VMs, VPC networks, IAM service accounts.

---

## APIs / Enabled Services

| Command | What it does |
|---|---|
| `gct services` | Enabled APIs — active project |
| `gct services PROJECT_ID` | Enabled APIs — specific project |
| `gct services --all` | Enabled APIs — all projects |
| `gct services --filter KEYWORD` | Filter by keyword |

```bash
gct services                          # what's on in my current project?
gct services --all                    # compare across all projects
gct services --filter ai              # AI/Vertex APIs only
gct services --all --filter bigquery  # BQ APIs across all projects
```

---

## BigQuery

| Command | What it does |
|---|---|
| `gct bq` | Datasets in active project |
| `gct bq PROJECT_ID` | Datasets in a specific project |
| `gct bq PROJECT_ID DATASET` | Tables inside a dataset |

```bash
gct bq                                         # my datasets
gct bq ambient-future-482717-r2               # specific project
gct bq ambient-future-482717-r2 my_dataset    # tables in a dataset
```

---

## Billing

| Command | What it does |
|---|---|
| `gct billing` | All accounts + per-project billing links |
| `gct billing budgets` | Configured budget alerts |
| `gct billing PROJECT_ID` | Billing status for one project |

```bash
gct billing                              # who's paying for what?
gct billing budgets                      # any spend alerts configured?
gct billing ambient-future-482717-r2    # is this project billed?
```

**Your accounts:**
| ID | Name | Status |
|---|---|---|
| `01E937-FD3716-10F6BD` | Versable Billing | Active |
| `018FA9-C02F0B-5376C4` | My Billing Account | Active |
| `01F1D8-91FD5F-181011` | My Billing Account | Closed |

**Projects on Versable Billing:** `ambient-future-482717-r2`, `gen-lang-client-0060614394`

---

## Cloud Run Logs

| Command | What it does |
|---|---|
| `gct logs SERVICE` | Last 100 log lines (active project) |
| `gct logs SERVICE PROJECT_ID` | Logs from a specific project |
| `gct logs SERVICE --severity ERROR` | Filter by severity |
| `gct logs SERVICE --follow` | Live polling every 10s |
| `gct logs SERVICE --limit N` | More/fewer lines |

```bash
gct logs my-api                         # recent logs
gct logs my-api --severity ERROR        # errors only
gct logs my-api --follow                # watch live (Ctrl+C to stop)
gct logs my-api --limit 500             # last 500 lines
gct logs my-api --severity WARNING --limit 200
```

**Severity levels:** `DEBUG` `INFO` `WARNING` `ERROR` `CRITICAL`

---

## Your Projects

| Project ID | Name | Billing |
|---|---|---|
| `ambient-future-482717-r2` | My First Project | Versable Billing ✓ |
| `gen-lang-client-0060614394` | versable-infra | Versable Billing ✓ |
| `carbon-web-455520-c1` | My First Project | — (disabled) |
| `excellent-math-452323-m9` | My First Project | — (disabled) |
| `gen-lang-client-0266094911` | Gemini API | — (disabled) |
| `custom-search-1724431614665` | Custom Search | — (disabled) |
| `gen-lang-client-0640048131` | Generative Language Client | Closed account |

---

## Common Workflows

**"What's running in my main project?"**
```bash
gct report ambient-future-482717-r2
```

**"Show me all resources across everything"**
```bash
gct inspect
```

**"Is this project billed? What account?"**
```bash
gct billing ambient-future-482717-r2
```

**"What GCP services/APIs does my project use?"**
```bash
gct services ambient-future-482717-r2
```

**"Tail errors from a Cloud Run service"**
```bash
gct logs my-service --severity ERROR --follow
```

**"Switch to a different project"**
```bash
gct pick          # interactive
gct use PROJECT   # direct
```

---

## Installation

```bash
git clone https://github.com/alcatraz627/my-gcp-tools.git ~/Code/my-gcp-tools
bash ~/Code/my-gcp-tools/install.sh   # symlinks to /usr/local/bin/gct
```

Or via PATH (already in `~/.zshrc`):
```bash
export PATH="$HOME/Code/my-gcp-tools:$PATH"
```

**Update:**
```bash
cd ~/Code/my-gcp-tools && git pull
```

---

## Requires

- `gcloud` SDK — [cloud.google.com/sdk](https://cloud.google.com/sdk/docs/install)
- `gsutil`, `bq` — bundled with gcloud
- `fzf` — only for `gct pick` (`brew install fzf`)
