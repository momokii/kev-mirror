#!/bin/sh

# =============================================================================
# Cron Entrypoint Script
# -----------------------------------------------------------------------------
# Purpose:
#   Prepares the environment and starts the cron daemon. Cron jobs run in an 
#   isolated shell, so we must explicitly pass Docker environment variables 
#   to them before execution.
# =============================================================================

# Clear the environment file to prevent duplicate entries on restarts
> /etc/environment

# Safely export Docker environment variables by wrapping values in double quotes.
# This prevents shell parsing errors (like 'not found') when dealing with 
# spaces or wildcards, especially in variables like CRON_SCHEDULE.
env | while IFS='=' read -r key value; do
  echo "export $key=\"$value\"" >> /etc/environment
done

# Dynamically generate the crontab file for the root user.
# It sources the environment file first, executes the trigger script, 
# and redirects standard output and error to the container's main logs.
echo "$CRON_SCHEDULE . /etc/environment && /app/trigger.sh > /proc/1/fd/1 2>/proc/1/fd/2" > /etc/crontabs/root

echo "Starting cron daemon with schedule: $CRON_SCHEDULE"

# Start the cron daemon in the foreground (-f) and redirect logs to stderr (-l 2)
exec crond -f -l 2