# kev-mirror

A self-updating mirror of the [CISA Known Exploited Vulnerabilities (KEV) Catalog](https://www.cisa.gov/known-exploited-vulnerabilities-catalog), synchronized daily via GitHub Actions.

## Why This Exists

The KEV feed at `www.cisa.gov` sits behind Akamai edge protection, which returns **HTTP 403** to requests from cloud/datacenter IP ranges. GitHub-hosted runners use IP ranges that bypass this block, so this repo fetches the feed there and serves the committed copy via `raw.githubusercontent.com` — which is accessible from anywhere.

## Consuming the Data

The mirrored catalog is available as raw JSON:

```
https://raw.githubusercontent.com/momokii/kev-mirror/main/known_exploited_vulnerabilities.json
```

Example structure:

```json
{
  "title": "CISA Catalog of Known Exploited Vulnerabilities",
  "catalogVersion": "2026.06.11",
  "dateReleased": "2026-06-11T19:02:08.0715Z",
  "count": 1618,
  "vulnerabilities": [
    {
      "cveID": "CVE-2026-10520",
      "vendorProject": "Ivanti",
      "product": "Sentry",
      "vulnerabilityName": "Ivanti Sentry ...",
      "dateAdded": "2026-06-11",
      "shortDescription": "...",
      "requiredAction": "...",
      "dueDate": "2026-06-14",
      "knownRansomwareCampaignUse": "Unknown",
      "notes": "",
      "cwes": ["CWE-78"]
    }
  ]
}
```

## How It Works

There are two components that work together:

### 1. GitHub Actions Sync (`sync-kev.yml`)

Runs on GitHub's infrastructure daily at **00:13 UTC** (also triggerable manually):

1. Fetches the KEV JSON from `cisa.gov` with retry logic
2. Validates the payload structure and checks freshness (warns if older than 5 days)
3. Commits the file **only when content actually changed** (idempotent)
4. Pushes with an automated commit message: `chore(kev): update catalog to {version} ({count} CVEs)`

### 2. Docker Cron Trigger (optional)

An Alpine-based container that triggers the GitHub Actions workflow on a configurable schedule. Useful if you want syncs more frequent than the daily GitHub cron.

**Flow:** Docker cron → `trigger.sh` → GitHub API `workflow_dispatch` → sync workflow runs

## Setup

### Using the GitHub Actions Workflow Only

The workflow runs automatically on schedule. You can also trigger it manually from the **Actions** tab in GitHub.

### Running the Docker Cron Trigger

**Prerequisites:** Docker and Docker Compose.

1. Copy the environment template:

   ```sh
   cp .env.example .env
   ```

2. Edit `.env` with your values:

   | Variable | Required | Description |
   |---|---|---|
   | `GITHUB_WEBHOOK_URL` | Yes | GitHub API endpoint for `workflow_dispatch` |
   | `GITHUB_TOKEN` | Yes | PAT with `repo` or `actions:write` scope |
   | `GITHUB_API_VERSION` | Yes | GitHub API version (use `2022-11-28`) |
   | `TARGET_BRANCH` | No | Branch to target (default: `main`) |
   | `CRON_SCHEDULE` | No | Cron expression (default: `*/5 * * * *`) |

3. Start the container:

   ```sh
   docker compose up -d
   ```

4. Check logs:

   ```sh
   docker logs -f kev-sync-trigger
   ```

## Project Structure

```
.github/workflows/sync-kev.yml    # GitHub Actions workflow — fetch, validate, commit
known_exploited_vulnerabilities.json  # Mirrored KEV catalog data
Dockerfile                         # Alpine 3.19 image with curl + cron
compose.yaml                       # Docker Compose service definition
entrypoint.sh                      # Sets up cron daemon and environment passthrough
trigger.sh                         # Authenticated GitHub API webhook trigger
.env.example                       # Environment variable template
.env                               # Local config (gitignored)
```

## License

This project mirrors publicly available data from [CISA](https://www.cisa.gov). The code is provided as-is.
