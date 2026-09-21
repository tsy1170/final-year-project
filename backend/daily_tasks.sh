#!/bin/bash

# Stop immediately if a command fails
set -e

# Move to the backend directory
cd "$(dirname "$0")"

# Create logs directory if it doesn't exist
mkdir -p logs

# Start log
echo "================================" >> logs/daily_tasks.log
echo "Daily task started at $(date)" >> logs/daily_tasks.log

# --------------------------------
# Data ingestion
# --------------------------------

echo "Running data ingestion script..." >> logs/daily_tasks.log

if python data_ingestion.py >> logs/daily_tasks.log 2>&1; then
    echo "Data ingestion completed successfully at $(date)" >> logs/daily_tasks.log
else
    ERROR_CODE=$?
    echo "data_ingestion.py failed at $(date) with error code $ERROR_CODE" >> logs/daily_tasks.log
    exit $ERROR_CODE
fi

# --------------------------------
# Price notification service
# --------------------------------

echo "Running price notification service..." >> logs/daily_tasks.log

if python -m app.price_notification_service >> logs/daily_tasks.log 2>&1; then
    echo "Price notification service completed successfully at $(date)" >> logs/daily_tasks.log
else
    ERROR_CODE=$?
    echo "price_notification_service failed at $(date) with error code $ERROR_CODE" >> logs/daily_tasks.log
    exit $ERROR_CODE
fi

# --------------------------------
# Completed
# --------------------------------

echo "Daily task completed successfully at $(date)" >> logs/daily_tasks.log

exit 0