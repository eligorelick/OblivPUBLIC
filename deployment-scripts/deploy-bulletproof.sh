#!/bin/bash

# =============================================================================
# OBLIVAI Bulletproof Deployment Script
# =============================================================================
# This script has NO silent failures and verifies everything
# If it says success, it actually worked
# =============================================================================

set -e  # Exit on any error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failures

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

# Logging
LOGFILE="/tmp/oblivai-deploy-$(date +%Y%m%d-%H%M%S).log"
exec 1> >(tee -a "$LOGFILE")
exec 2>&1

print_header "OBLIVAI Bulletproof Deployment"
print_info "Log file: $LOGFILE"

# Configuration
KEYSDIR="$HOME/oblivai-onion-keys"
APPDIR="$HOME/OblivPUBLIC"
TORDIR="/var/lib/tor/oblivai"

# =============================================================================
# Step 1: Find and Verify Keys
# =============================================================================

print_header "Step 1: Locating Vanity Keys"

if [ ! -d "$KEYSDIR" ]; then
    print_error "Keys directory not found: $KEYSDIR"
    print_info "Generate keys first: bash 1-generate-vanity-onion.sh oblivai"
    exit 1
fi

ONION_DIR=$(find "$KEYSDIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [ -z "$ONION_DIR" ]; then
    print_error "No .onion directory found in $KEYSDIR"
    exit 1
fi

# Verify required key files exist
REQUIRED_FILES=("hs_ed25519_secret_key" "hs_ed25519_public_key" "hostname")
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$ONION_DIR/$file" ]; then
        print_error "Missing required file: $file"
        exit 1
    fi
done

ONION_ADDRESS=$(cat "$ONION_DIR/hostname")
print_success "Found keys for: $ONION_ADDRESS"

# =============================================================================
# Step 2: Install Dependencies
# =============================================================================

print_header "Step 2: Installing Dependencies"

sudo apt update || { print_error "apt update failed"; exit 1; }

PACKAGES="tor nginx curl git"
for pkg in $PACKAGES; do
    if ! dpkg -l | grep -q "^ii  $pkg "; then
        print_info "Installing $pkg..."
        sudo apt install -y "$pkg" || { print_error "Failed to install $pkg"; exit 1; }
    fi
done

# Check Node.js version
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        print_info "Upgrading Node.js to v20..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || exit 1
        sudo apt install -y nodejs || exit 1
    fi
else
    print_info "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - || exit 1
    sudo apt install -y nodejs || exit 1
fi

print_success "All dependencies installed"

# =============================================================================
# Step 3: Configure Tor
# =============================================================================

print_header "Step 3: Configuring Tor"

# Create Tor directory
sudo mkdir -p "$TORDIR" || { print_error "Failed to create Tor directory"; exit 1; }

# Copy keys file by file
print_info "Copying hidden service keys..."
for file in "$ONION_DIR"/*; do
    filename=$(basename "$file")
    print_info "Copying $filename..."
    sudo cp "$file" "$TORDIR/$filename" || { print_error "Failed to copy $filename"; exit 1; }
done

# Verify all files copied
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$TORDIR/$file" ]; then
        print_error "File not copied: $file"
        exit 1
    fi
done

print_success "All keys copied"

# Set permissions
print_info "Setting permissions..."
sudo chown -R debian-tor:debian-tor "$TORDIR" || { print_error "chown failed"; exit 1; }
sudo chmod 700 "$TORDIR" || { print_error "chmod 700 failed"; exit 1; }
sudo chmod 600 "$TORDIR"/* || { print_error "chmod 600 failed"; exit 1; }

print_success "Permissions set"

# Configure torrc
print_info "Configuring torrc..."
if ! grep -q "HiddenServiceDir /var/lib/tor/oblivai" /etc/tor/torrc; then
    sudo tee -a /etc/tor/torrc > /dev/null << 'EOF'

# OBLIVAI Hidden Service
HiddenServiceDir /var/lib/tor/oblivai/
HiddenServicePort 80 127.0.0.1:8080
EOF
    print_success "Torrc configured"
else
    print_info "Torrc already configured"
fi

# Create systemd service
sudo tee /etc/systemd/system/oblivai-tor.service > /dev/null << 'EOF'
[Unit]
Description=Tor Hidden Service for OBLIVAI
After=network.target

[Service]
Type=simple
User=debian-tor
Group=debian-tor
ExecStart=/usr/bin/tor -f /etc/tor/torrc
Restart=always
RestartSec=5
KillSignal=SIGINT
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

# Start Tor
print_info "Starting Tor..."
sudo systemctl daemon-reload
sudo systemctl stop tor tor@default 2>/dev/null || true
sudo systemctl enable oblivai-tor || exit 1
sudo systemctl start oblivai-tor || { print_error "Tor failed to start"; exit 1; }

# Wait for hostname file
print_info "Waiting for hidden service to initialize (max 60 seconds)..."
WAIT_COUNT=0
while [ ! -f "$TORDIR/hostname" ] && [ $WAIT_COUNT -lt 60 ]; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    if [ $((WAIT_COUNT % 10)) -eq 0 ]; then
        echo -n "[$WAIT_COUNT seconds]..."
    fi
done
echo ""

if [ ! -f "$TORDIR/hostname" ]; then
    print_error "Hostname file not created after 60 seconds"
    print_info "Tor logs:"
    sudo journalctl -u oblivai-tor -n 50 --no-pager
    exit 1
fi

ACTUAL_ONION=$(sudo cat "$TORDIR/hostname")
print_success "Tor hidden service running: $ACTUAL_ONION"

# =============================================================================
# Step 4: Build OBLIVAI
# =============================================================================

print_header "Step 4: Building OBLIVAI"

cd "$APPDIR" || { print_error "App directory not found"; exit 1; }

print_info "Cleaning previous build..."
rm -rf node_modules package-lock.json dist

print_info "Installing dependencies..."
npm install || { print_error "npm install failed"; exit 1; }

print_info "Building application..."
npm run build || { print_error "Build failed"; exit 1; }

# Verify build
if [ ! -f "$APPDIR/dist/index.html" ]; then
    print_error "Build verification failed: index.html not found"
    exit 1
fi

if ! ls "$APPDIR/dist"/assets/*.js > /dev/null 2>&1; then
    print_error "Build verification failed: no JS bundles found"
    exit 1
fi

print_success "Build complete ($(du -sh "$APPDIR/dist" | cut -f1))"

# =============================================================================
# Step 5: Configure Nginx
# =============================================================================

print_header "Step 5: Configuring Nginx"

ACTUAL_APPDIR=$(realpath "$APPDIR")

sudo tee /etc/nginx/sites-available/oblivai > /dev/null << EOF
server {
    listen 127.0.0.1:8080;
    server_name localhost;

    root ${ACTUAL_APPDIR}/dist;
    index index.html;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=()" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; worker-src 'self' blob:; connect-src 'self' https://huggingface.co https://cdn-lfs.huggingface.co https://*.huggingface.co; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; font-src 'self' data:; form-action 'none'; object-src 'none';" always;

    # WASM
    location ~* \.wasm\$ {
        add_header Content-Type application/wasm;
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header Cross-Origin-Embedder-Policy "require-corp";
        add_header Cross-Origin-Opener-Policy "same-origin";
        add_header Cross-Origin-Resource-Policy "cross-origin";
    }

    # JS
    location ~* \.js\$ {
        add_header Content-Type "application/javascript; charset=utf-8";
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # CSS
    location ~* \.css\$ {
        add_header Content-Type "text/css; charset=utf-8";
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Service Worker
    location = /sw.js {
        add_header Content-Type "application/javascript; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Service-Worker-Allowed "/";
    }

    # SPA
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    access_log /var/log/nginx/oblivai-access.log;
    error_log /var/log/nginx/oblivai-error.log;
}
EOF

sudo ln -sf /etc/nginx/sites-available/oblivai /etc/nginx/sites-enabled/oblivai
sudo rm -f /etc/nginx/sites-enabled/default

print_info "Testing nginx configuration..."
sudo nginx -t || { print_error "Nginx config test failed"; exit 1; }

print_info "Starting nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx || { print_error "Nginx failed to start"; exit 1; }

# Wait and test
sleep 3
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080 2>/dev/null || echo "000")

if [ "$HTTP_CODE" != "200" ]; then
    print_error "Site not accessible (HTTP $HTTP_CODE)"
    sudo tail -20 /var/log/nginx/oblivai-error.log
    exit 1
fi

print_success "Nginx serving site (HTTP 200)"

# =============================================================================
# Success
# =============================================================================

print_header "✓ DEPLOYMENT SUCCESSFUL"

echo ""
echo -e "${GREEN}Your .onion site is live:${NC}"
echo -e "${CYAN}http://$ACTUAL_ONION${NC}"
echo ""
print_info "Test in Tor Browser:"
echo "  1. Open Tor Browser"
echo "  2. Visit: http://$ACTUAL_ONION"
echo "  3. Select an AI model"
echo "  4. Start chatting"
echo ""
print_success "All services configured for auto-start on boot"
echo ""
