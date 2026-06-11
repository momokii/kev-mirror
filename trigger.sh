#!/bin/sh

# =============================================================================
# GitHub Actions Webhook Trigger
# -----------------------------------------------------------------------------
# Purpose:
#   Executes an authenticated POST request to the GitHub API to trigger 
#   a workflow_dispatch event.
# =============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# Define a logging function for consistent, readable output
log() {
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "[$timestamp] $1"
}

log "INFO: Starting GitHub Actions webhook trigger..."

# =============================================================================
# Validation: Ensure all required environment variables are present
# =============================================================================

if [ -z "$GITHUB_WEBHOOK_URL" ]; then
    log "ERROR: GITHUB_WEBHOOK_URL is missing."
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    log "ERROR: GITHUB_TOKEN is missing. Authentication is REQUIRED."
    exit 1
fi

if [ -z "$GITHUB_API_VERSION" ]; then
    log "ERROR: GITHUB_API_VERSION is missing (e.g., 2022-11-28). API versioning is REQUIRED."
    exit 1
fi

# Set target branch, default to 'main' if not explicitly defined
BRANCH=${TARGET_BRANCH:-"main"}

# =============================================================================
# Execution: Build payload and trigger the webhook
# =============================================================================

PAYLOAD="{\"ref\":\"$BRANCH\"}"

log "INFO: Preparing to dispatch workflow on branch: '$BRANCH'"
log "INFO: Target URL: $GITHUB_WEBHOOK_URL"
log "INFO: Using GitHub API Version: $GITHUB_API_VERSION"

# Execute curl and capture both the response body and the HTTP status code.
# -s : Silent mode (hides progress bar)
# -w : Write out format to append the HTTP status code at the very end
RESPONSE=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: $GITHUB_API_VERSION" \
  -d "$PAYLOAD" \
  "$GITHUB_WEBHOOK_URL")

# Extract the HTTP status code (from the last line) and the response body
HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1 | awk -F':' '{print $2}')
# Remove the last line (HTTP_STATUS) to get the clean response body
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

# =============================================================================
# Evaluation: Check if the API accepted the request
# =============================================================================

# GitHub workflow_dispatch endpoint returns HTTP 204 No Content on a successful trigger
if [ "$HTTP_STATUS" -eq 204 ]; then
    log "SUCCESS: Workflow successfully dispatched! (HTTP 204)"
else
    log "ERROR: Failed to dispatch workflow. HTTP Status Code: $HTTP_STATUS"
    
    # If there is an error message from GitHub, print it for easier debugging
    if [ -n "$RESPONSE_BODY" ]; then
        log "DEBUG: GitHub API Response: $RESPONSE_BODY"
    else
        log "DEBUG: No response body returned by GitHub API."
    fi
    
    # Exit with error status so Docker/Cron knows the job failed
    exit 1
fi

log "INFO: Trigger execution completed."
echo "-------------------------------------------------------------------"