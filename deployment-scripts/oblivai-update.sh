#!/bin/bash

# OBLIVAI Auto-Update Script
# Pulls latest changes from git and rebuilds
# Usage: sudo -u YOUR_USERNAME /usr/local/bin/oblivai-update.sh

set -e  # Exit on error

LOG_FILE="/var/log/oblivai-update.log"
APP_DIR="/var/www/oblivai"
BRANCH="main"

echo "[$(date)] Starting OBLIVAI update check..." >> "$LOG_FILE"

cd "$APP_DIR"

# Fetch latest changes
git fetch origin "$BRANCH" 2>&1 >> "$LOG_FILE"

# Check if updates are available
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/"$BRANCH")

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "[$(date)] Updates found! Local: $LOCAL, Remote: $REMOTE" >> "$LOG_FILE"
    echo "[$(date)] Pulling latest changes..." >> "$LOG_FILE"

    # Pull latest changes
    git pull origin "$BRANCH" 2>&1 >> "$LOG_FILE"

    # Install dependencies (in case package.json changed)
    echo "[$(date)] Installing dependencies..." >> "$LOG_FILE"
    npm install 2>&1 >> "$LOG_FILE"

    # Build
    echo "[$(date)] Building production bundle..." >> "$LOG_FILE"
    npm run build 2>&1 >> "$LOG_FILE"

    # Reload nginx (optional, not usually needed for static sites)
    echo "[$(date)] Reloading nginx..." >> "$LOG_FILE"
    sudo systemctl reload nginx 2>&1 >> "$LOG_FILE"

    echo "[$(date)] ✅ Update complete! New version deployed." >> "$LOG_FILE"

    # Log new commit hash
    NEW_COMMIT=$(git rev-parse --short HEAD)
    echo "[$(date)] New commit: $NEW_COMMIT" >> "$LOG_FILE"
else
    echo "[$(date)] No updates available. Current: $LOCAL" >> "$LOG_FILE"
fi

echo "[$(date)] Update check finished." >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"

exit 0
