#!/bin/bash

# =============================================================================
# OBLIVAI Complete Deployment Script
# =============================================================================
# This script does EVERYTHING to get your .onion site running
# Run this if you already have generated vanity keys
#
# Usage: bash deploy-complete.sh
# =============================================================================

set -e  # Exit on error

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
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Configuration
KEYSDIR="$HOME/oblivai-onion-keys"
APPDIR="$HOME/OblivPUBLIC"
TORDIR="/var/lib/tor/oblivai"

# =============================================================================
# Step 1: Check Prerequisites
# =============================================================================

print_header "OBLIVAI Complete Deployment"

print_info "Checking for generated .onion keys..."

if [ ! -d "$KEYSDIR" ] || [ -z "$(ls -A "$KEYSDIR" 2>/dev/null)" ]; then
    print_error "No vanity .onion keys found in $KEYSDIR"
    echo ""
    print_info "Run this first to generate keys:"
    echo "  bash deployment-scripts/1-generate-vanity-onion.sh oblivai"
    exit 1
fi

ONION_DIR=$(find "$KEYSDIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [ -z "$ONION_DIR" ]; then
    print_error "No .onion address found in $KEYSDIR"
    exit 1
fi

ONION_ADDRESS=$(basename "$ONION_DIR")

print_success "Found vanity .onion keys!"
echo ""
echo -e "  ${GREEN}${ONION_ADDRESS}${NC}"
echo ""

# =============================================================================
# Step 2: Install Dependencies
# =============================================================================

print_header "Step 1/5: Installing Dependencies"

print_info "Updating package list..."
sudo apt update -qq

print_info "Installing required packages..."
sudo apt install -y tor nginx curl git npm 2>&1 | grep -v "^Reading" | grep -v "^Building" || true

# Check Node.js version
if ! command -v node &> /dev/null || [ "$(node -v | cut -d'v' -f2 | cut -d'.' -f1)" -lt 16 ]; then
    print_info "Installing Node.js 18..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - > /dev/null 2>&1
    sudo apt install -y nodejs 2>&1 | grep -v "^Reading" || true
fi

print_success "Dependencies installed"

# =============================================================================
# Step 3: Configure Tor Hidden Service
# =============================================================================

print_header "Step 2/5: Configuring Tor Hidden Service"

print_info "Creating Tor hidden service directory..."
sudo mkdir -p "$TORDIR"

print_info "Copying vanity .onion keys..."
# Copy files one by one to ensure success
if ! sudo cp "$ONION_DIR"/* "$TORDIR/" 2>/dev/null; then
    # Try individual files
    for file in "$ONION_DIR"/*; do
        if [ -f "$file" ]; then
            sudo cp "$file" "$TORDIR/" || {
                print_error "Failed to copy $(basename "$file")"
                exit 1
            }
        fi
    done
fi

# Verify critical files were copied
if [ ! -f "$TORDIR/hs_ed25519_secret_key" ]; then
    print_error "Secret key not copied! Keys are missing."
    exit 1
fi

if [ ! -f "$TORDIR/hs_ed25519_public_key" ]; then
    print_error "Public key not copied! Keys are missing."
    exit 1
fi

print_success "Keys copied successfully"

print_info "Setting permissions..."
sudo chown -R debian-tor:debian-tor "$TORDIR" || {
    print_error "Failed to set ownership"
    exit 1
}
sudo chmod 700 "$TORDIR" || {
    print_error "Failed to set directory permissions"
    exit 1
}
sudo find "$TORDIR" -type f -exec chmod 600 {} \; || {
    print_error "Failed to set file permissions"
    exit 1
}

print_info "Configuring torrc..."

# Backup existing torrc
if [ -f /etc/tor/torrc ]; then
    sudo cp /etc/tor/torrc /etc/tor/torrc.backup.$(date +%s)
fi

# Remove old OBLIVAI configs if they exist
sudo sed -i '/# OBLIVAI Hidden Service/,/HiddenServicePort/d' /etc/tor/torrc 2>/dev/null || true

# Add hidden service configuration
sudo tee -a /etc/tor/torrc > /dev/null << 'EOF'

# OBLIVAI Hidden Service
HiddenServiceDir /var/lib/tor/oblivai/
HiddenServicePort 80 127.0.0.1:8080
EOF

print_info "Creating dedicated Tor service..."

# Create custom systemd service (avoids multi-instance issues)
sudo tee /etc/systemd/system/oblivai-tor.service > /dev/null << 'EOF'
[Unit]
Description=Tor Hidden Service for OBLIVAI
After=network.target

[Service]
Type=simple
User=debian-tor
Group=debian-tor
ExecStart=/usr/bin/tor -f /etc/tor/torrc
Restart=on-failure
RestartSec=5
KillSignal=SIGINT
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF

print_info "Starting Tor service..."
sudo systemctl daemon-reload
sudo systemctl stop tor tor@default 2>/dev/null || true
sudo systemctl enable oblivai-tor
sudo systemctl start oblivai-tor

# Wait for Tor to initialize and bootstrap
print_info "Waiting for Tor to bootstrap..."
sleep 3

# Verify Tor is running
if ! sudo systemctl is-active oblivai-tor > /dev/null 2>&1; then
    print_error "Tor service failed to start"
    print_info "Checking logs..."
    sudo journalctl -u oblivai-tor -n 30 --no-pager
    exit 1
fi

print_success "Tor service started"

# Wait for Tor to create hostname file (can take 10-30 seconds)
print_info "Waiting for hidden service to initialize..."
WAIT_COUNT=0
while [ ! -f "$TORDIR/hostname" ] && [ $WAIT_COUNT -lt 30 ]; do
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
    echo -n "."
done
echo ""

# Verify hostname file exists
if [ ! -f "$TORDIR/hostname" ]; then
    print_error "Hidden service hostname file not created after 30 seconds"
    print_info "This usually means Tor failed to load the hidden service"
    print_info "Checking Tor logs..."
    sudo journalctl -u oblivai-tor -n 50 --no-pager
    print_info "Checking directory permissions..."
    sudo ls -la "$TORDIR/"
    exit 1
fi

# Verify Tor bootstrapped successfully
print_info "Checking Tor bootstrap status..."
if sudo journalctl -u oblivai-tor --no-pager | grep -q "Bootstrapped 100%"; then
    print_success "Tor bootstrapped successfully"
else
    print_warning "Tor may not have fully bootstrapped yet"
    print_info "Recent Tor logs:"
    sudo journalctl -u oblivai-tor -n 10 --no-pager | tail -5
fi

ACTUAL_ONION=$(sudo cat "$TORDIR/hostname" 2>/dev/null || echo "")
if [ -n "$ACTUAL_ONION" ]; then
    print_success "Tor hidden service running!"
    echo ""
    echo -e "  ${GREEN}${ACTUAL_ONION}${NC}"
    echo ""
else
    print_error "Hostname file exists but is empty"
    exit 1
fi

# =============================================================================
# Step 4: Build OBLIVAI
# =============================================================================

print_header "Step 3/5: Building OBLIVAI"

if [ ! -d "$APPDIR" ]; then
    print_error "Application directory not found: $APPDIR"
    print_info "Expected to find OblivPUBLIC in your home directory"
    exit 1
fi

cd "$APPDIR"

print_info "Installing Node.js dependencies..."
if ! npm install 2>&1 | tee /tmp/npm-install.log | grep -v "^npm WARN EBADENGINE" | grep -v "^npm WARN"; then
    print_error "npm install failed"
    cat /tmp/npm-install.log
    exit 1
fi

print_success "Dependencies installed"

print_info "Building OBLIVAI for production..."
if ! npm run build 2>&1 | tee /tmp/npm-build.log; then
    print_error "Build failed"
    cat /tmp/npm-build.log
    exit 1
fi

# Verify build exists and has files
if [ ! -d "$APPDIR/dist" ]; then
    print_error "Build failed - dist/ directory not created"
    exit 1
fi

if [ -z "$(ls -A "$APPDIR/dist" 2>/dev/null)" ]; then
    print_error "Build failed - dist/ directory is empty"
    exit 1
fi

# Verify critical files
if [ ! -f "$APPDIR/dist/index.html" ]; then
    print_error "Build failed - index.html not found"
    exit 1
fi

# Check for JS bundles
if ! ls "$APPDIR/dist"/assets/*.js > /dev/null 2>&1 && ! ls "$APPDIR/dist"/*.js > /dev/null 2>&1; then
    print_error "Build failed - no JavaScript bundles found"
    exit 1
fi

print_success "OBLIVAI built successfully"
print_info "Build contains: $(du -sh "$APPDIR/dist" | cut -f1) of files"

# =============================================================================
# Step 5: Configure Nginx
# =============================================================================

print_header "Step 4/5: Configuring Nginx Web Server"

print_info "Creating nginx configuration..."

ACTUAL_APPDIR=$(realpath "$APPDIR")

sudo tee /etc/nginx/sites-available/oblivai > /dev/null << EOF
server {
    listen 127.0.0.1:8080;
    server_name localhost;

    root ${ACTUAL_APPDIR}/dist;
    index index.html;

    # Security headers (Tor-compatible)
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=(), payment=()" always;

    # CSP header (Tor-compatible)
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; worker-src 'self' blob:; connect-src 'self' https://huggingface.co https://cdn-lfs.huggingface.co https://*.huggingface.co; img-src 'self' data: blob:; style-src 'self' 'unsafe-inline'; font-src 'self' data:; form-action 'none'; object-src 'none';" always;

    # WASM MIME type
    location ~* \.wasm\$ {
        add_header Content-Type application/wasm;
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header Cross-Origin-Embedder-Policy "require-corp";
        add_header Cross-Origin-Opener-Policy "same-origin";
        add_header Cross-Origin-Resource-Policy "cross-origin";
    }

    # JavaScript bundles
    location ~* \.js\$ {
        add_header Content-Type "application/javascript; charset=utf-8";
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # CSS files
    location ~* \.css\$ {
        add_header Content-Type "text/css; charset=utf-8";
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # Service Worker - no cache
    location = /sw.js {
        add_header Content-Type "application/javascript; charset=utf-8";
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        add_header Service-Worker-Allowed "/";
    }

    # SPA fallback
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Minimal logging for privacy
    access_log /var/log/nginx/oblivai-access.log;
    error_log /var/log/nginx/oblivai-error.log;
}
EOF

print_info "Enabling site..."
sudo ln -sf /etc/nginx/sites-available/oblivai /etc/nginx/sites-enabled/oblivai
sudo rm -f /etc/nginx/sites-enabled/default

print_info "Testing nginx configuration..."
if ! sudo nginx -t > /dev/null 2>&1; then
    print_error "Nginx configuration test failed"
    sudo nginx -t
    exit 1
fi

print_info "Starting nginx..."
sudo systemctl restart nginx
sudo systemctl enable nginx > /dev/null 2>&1

sleep 2

# Test local access with retries
print_info "Testing local site access..."
RETRY_COUNT=0
HTTP_CODE="000"
while [ "$HTTP_CODE" != "200" ] && [ $RETRY_COUNT -lt 5 ]; do
    sleep 1
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080 2>/dev/null || echo "000")
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ "$HTTP_CODE" = "200" ]; then
    print_success "Nginx running and serving site (HTTP 200)"

    # Verify HTML content
    if curl -s http://127.0.0.1:8080 2>/dev/null | grep -q "<!DOCTYPE html>"; then
        print_success "HTML content verified"
    else
        print_warning "Site responds but may not be serving correct content"
    fi
else
    print_error "Site not accessible (HTTP $HTTP_CODE)"
    print_info "Checking nginx error log..."
    sudo tail -20 /var/log/nginx/oblivai-error.log 2>/dev/null || echo "No error log"
    print_info "Checking nginx status..."
    sudo systemctl status nginx --no-pager -l | head -10
    exit 1
fi

# =============================================================================
# Step 6: Final Verification
# =============================================================================

print_header "Step 5/5: Final Verification"

print_info "Running system checks..."

# Check Tor
if sudo systemctl is-active oblivai-tor > /dev/null 2>&1; then
    print_success "Tor service: Running"
else
    print_error "Tor service: Not running"
fi

# Check Nginx
if sudo systemctl is-active nginx > /dev/null 2>&1; then
    print_success "Nginx service: Running"
else
    print_error "Nginx service: Not running"
fi

# Check local site access
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    print_success "Local site access: Working (HTTP 200)"
else
    print_error "Local site access: HTTP $HTTP_CODE"
    print_info "Site is not accessible locally"
    print_info "Check nginx logs: sudo tail -f /var/log/nginx/oblivai-error.log"
fi

# Verify hidden service is actually reachable
print_info "Verifying hidden service configuration..."
if [ -f "$TORDIR/hostname" ] && [ -f "$TORDIR/hs_ed25519_secret_key" ]; then
    print_success "Hidden service files: Present"
else
    print_error "Hidden service files: Missing"
fi

# =============================================================================
# Success Summary
# =============================================================================

print_header "✓ DEPLOYMENT COMPLETE!"

FINAL_ONION=$(sudo cat "$TORDIR/hostname" 2>/dev/null || echo "Unknown")

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  🎉 OBLIVAI is now live on Tor!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${CYAN}Your .onion address:${NC}"
echo ""
echo -e "  ${GREEN}http://${FINAL_ONION}${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

print_header "Next Steps"
echo ""
print_info "1. Test your site in Tor Browser:"
echo "     ${CYAN}http://${FINAL_ONION}${NC}"
echo ""
print_info "2. Select an AI model and test chat functionality"
echo ""
print_info "3. Bookmark or share your .onion address"
echo ""

print_header "Service Management"
echo ""
echo "  Check Tor status:    ${CYAN}sudo systemctl status oblivai-tor${NC}"
echo "  Check nginx status:  ${CYAN}sudo systemctl status nginx${NC}"
echo "  View Tor logs:       ${CYAN}sudo journalctl -u oblivai-tor -f${NC}"
echo "  View nginx logs:     ${CYAN}sudo tail -f /var/log/nginx/oblivai-access.log${NC}"
echo "  Get .onion address:  ${CYAN}sudo cat /var/lib/tor/oblivai/hostname${NC}"
echo "  Restart services:    ${CYAN}sudo systemctl restart oblivai-tor nginx${NC}"
echo ""

print_header "Update OBLIVAI"
echo ""
echo "  ${CYAN}cd ~/OblivPUBLIC${NC}"
echo "  ${CYAN}git pull${NC}"
echo "  ${CYAN}npm install && npm run build${NC}"
echo "  ${CYAN}sudo systemctl reload nginx${NC}"
echo ""

print_warning "IMPORTANT: Backup your keys!"
echo ""
echo "  Keys location: ${CYAN}/var/lib/tor/oblivai/${NC}"
echo "  Backup command: ${CYAN}sudo cp -r /var/lib/tor/oblivai ~/oblivai-backup${NC}"
echo ""

print_success "Setup complete! Enjoy your privacy-focused AI chat on Tor! 🎊"
echo ""
