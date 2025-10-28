#!/bin/bash

# =============================================================================
# OBLIVAI Permission Fix Script
# =============================================================================
# Fixes common permission issues
# =============================================================================

set -e

echo "Fixing permissions..."

# Fix Tor directory permissions
sudo chown -R debian-tor:debian-tor /var/lib/tor/oblivai
sudo chmod 700 /var/lib/tor/oblivai
sudo find /var/lib/tor/oblivai -type f -exec chmod 600 {} \;

echo "✓ Tor permissions fixed"

# Fix nginx permissions
APPDIR="$HOME/OblivPUBLIC"
if [ -d "$APPDIR/dist" ]; then
    chmod -R 755 "$APPDIR/dist"
    find "$APPDIR/dist" -type f -exec chmod 644 {} \;
    echo "✓ Nginx file permissions fixed"
fi

# Restart services
sudo systemctl restart oblivai-tor
sudo systemctl restart nginx

echo "✓ Services restarted"
echo ""
echo "Permissions fixed!"
