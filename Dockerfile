FROM alpine:3.19

# Install required packages (curl for HTTP requests, tzdata for timezone management if needed)
RUN apk add --no-cache curl tzdata

WORKDIR /app

# Copy execution scripts
COPY trigger.sh /app/trigger.sh
COPY entrypoint.sh /app/entrypoint.sh

# Ensure scripts are executable
RUN chmod +x /app/trigger.sh /app/entrypoint.sh

# Use the entrypoint script to setup cron and environments
ENTRYPOINT ["/app/entrypoint.sh"]