#!/bin/bash

# =============================================================================
# STEP 2: Deploy OBLIVAI on Tor Hidden Service
# =============================================================================
# This script sets up and runs your .onion site using keys from Step 1.
#
# Prerequisites:
#   - Run 1-generate-vanity-onion.sh first
#   - Generated keys should be in ~/oblivai-onion-keys/
#
# Usage:
#   bash 2-deploy-onion-site.sh
#
# What this does:
#   1. Installs Tor and nginx
#   2. Configures Tor hidden service with your vanity keys
#   3. Builds OBLIVAI
#   4. Configures nginx web server
#   5. Starts your .onion site
# =============================================================================

set -e  # Exit on error

# Configuration
KEYSDIR="$HOME/oblivai-onion-keys"
APPDIR="$HOME/oblivai-app"
TORDIR="/var/lib/tor/oblivai"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_tip() {
    echo -e "${MAGENTA}💡 TIP: $1${NC}"
}

# =============================================================================
# Check Prerequisites
# =============================================================================

check_prerequisites() {
    print_header "STEP 2: Deploy OBLIVAI on Tor"

    # Check if keys exist
    if [ ! -d "$KEYSDIR" ] || [ -z "$(ls -A "$KEYSDIR" 2>/dev/null)" ]; then
        print_error "No vanity .onion keys found!"
        echo ""
        print_info "You need to generate keys first:"
        echo "  ${CYAN}bash 1-generate-vanity-onion.sh oblivai${NC}"
        echo ""
        exit 1
    fi

    # Find generated keys
    ONION_DIR=$(find "$KEYSDIR" -type d -mindepth 1 -maxdepth 1 | head -n 1)

    if [ -z "$ONION_DIR" ]; then
        print_error "No .onion address directories found in $KEYSDIR"
        exit 1
    fi

    ONION_ADDRESS=$(basename "$ONION_DIR")

    echo ""
    print_success "Found vanity .onion keys!"
    echo ""
    echo -e "  Address: ${GREEN}${ONION_ADDRESS}.onion${NC}"
    echo -e "  Keys:    ${CYAN}${ONION_DIR}${NC}"
    echo ""

    print_info "This script will:"
    echo "  1. Install Tor and nginx"
    echo "  2. Configure hidden service with your vanity address"
    echo "  3. Build OBLIVAI"
    echo "  4. Deploy and start your site"
    echo ""

    read -p "Continue with deployment? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled by user"
        exit 0
    fi
}

# =============================================================================
# Install Dependencies
# =============================================================================

install_dependencies() {
    print_header "Step 1/4: Installing Dependencies"

    print_info "Updating package list..."
    sudo apt update -qq

    print_info "Installing Tor, nginx, and Node.js..."
    sudo apt install -y \
        tor \
        nginx \
        curl \
        git \
        2>&1 | grep -v "^Reading" || true

    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        print_info "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - > /dev/null 2>&1
        sudo apt install -y nodejs 2>&1 | grep -v "^Reading" || true
    else
        print_success "Node.js already installed ($(node --version))"
    fi

    print_success "Dependencies installed"
}

# =============================================================================
# Configure Tor
# =============================================================================

configure_tor() {
    print_header "Step 2/4: Configuring Tor Hidden Service"

    print_info "Creating Tor hidden service directory..."
    sudo mkdir -p "$TORDIR"

    print_info "Copying your vanity .onion keys..."
    sudo cp -r "$ONION_DIR"/* "$TORDIR/"
    sudo chown -R debian-tor:debian-tor "$TORDIR"
    sudo chmod 700 "$TORDIR"
    sudo chmod 600 "$TORDIR"/*

    print_info "Configuring torrc..."

    # Backup existing torrc
    if [ -f /etc/tor/torrc ]; then
        sudo cp /etc/tor/torrc /etc/tor/torrc.backup.$(date +%s)
    fi

    # Check if already configured
    if grep -q "# OBLIVAI Hidden Service" /etc/tor/torrc 2>/dev/null; then
        print_warning "OBLIVAI already configured in torrc, updating..."
        # Remove old config
        sudo sed -i '/# OBLIVAI Hidden Service/,/HiddenServicePort/d' /etc/tor/torrc
    fi

    # Add hidden service configuration
    sudo tee -a /etc/tor/torrc > /dev/null << 'EOF'

# OBLIVAI Hidden Service
HiddenServiceDir /var/lib/tor/oblivai/
HiddenServicePort 80 127.0.0.1:8080
EOF

    print_info "Restarting Tor..."
    sudo systemctl restart tor
    sudo systemctl enable tor > /dev/null 2>&1

    # Wait for Tor to start
    sleep 3

    # Verify hostname
    if [ -f "$TORDIR/hostname" ]; then
        ACTUAL_ONION=$(sudo cat "$TORDIR/hostname")
        print_success "Tor hidden service running!"
        echo ""
        echo -e "  ${GREEN}${ACTUAL_ONION}${NC}"
        echo ""
    else
        print_error "Failed to start Tor hidden service"
        print_info "Check logs: sudo journalctl -u tor -n 50"
        exit 1
    fi
}

# =============================================================================
# Build OBLIVAI
# =============================================================================

build_oblivai() {
    print_header "Step 3/4: Building OBLIVAI"

    if [ -d "$APPDIR" ]; then
        print_info "App directory exists, pulling latest changes..."
        cd "$APPDIR"
        git pull origin main 2>&1 | grep -v "^Already up to date" || print_success "Already up to date"
    else
        print_info "Cloning OBLIVAI repository..."
        git clone https://github.com/eligorelick/OblivPUBLIC.git "$APPDIR" 2>&1
        cd "$APPDIR"
    fi

    print_info "Installing Node.js dependencies (this may take a minute)..."
    npm install --quiet

    print_info "Building OBLIVAI for production..."
    npm run build

    # Verify build
    if [ ! -d "$APPDIR/dist" ] || [ -z "$(ls -A "$APPDIR/dist" 2>/dev/null)" ]; then
        print_error "Build failed - dist/ directory is empty"
        exit 1
    fi

    print_success "OBLIVAI built successfully"

    cd - > /dev/null
}

# =============================================================================
# Configure Nginx
# =============================================================================

configure_nginx() {
    print_header "Step 4/4: Configuring Nginx Web Server"

    print_info "Creating nginx configuration..."

    # Get actual app directory path
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
    location ~* \.wasm$ {
        add_header Content-Type application/wasm;
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header Cross-Origin-Embedder-Policy "require-corp";
        add_header Cross-Origin-Opener-Policy "same-origin";
        add_header Cross-Origin-Resource-Policy "cross-origin";
    }

    # JavaScript bundles
    location ~* \.js$ {
        add_header Content-Type "application/javascript; charset=utf-8";
        add_header Cache-Control "public, max-age=31536000, immutable";
    }

    # CSS files
    location ~* \.css$ {
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

    # Remove default site
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

    # Wait for nginx to start
    sleep 2

    # Test local access
    if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080 | grep -q "200"; then
        print_success "Nginx running and serving site"
    else
        print_warning "Nginx started but site may not be accessible"
        print_info "Check logs: sudo tail -f /var/log/nginx/oblivai-error.log"
    fi
}

# =============================================================================
# Final Summary
# =============================================================================

print_summary() {
    print_header "✓ DEPLOYMENT COMPLETE!"

    FINAL_ONION=$(sudo cat "$TORDIR/hostname")

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

    print_warning "CRITICAL: Backup your keys!"
    echo ""
    echo "  Your hidden service keys are in:"
    echo "  ${CYAN}${TORDIR}${NC}"
    echo ""
    echo "  To backup:"
    echo "  ${YELLOW}sudo cp -r ${TORDIR} ~/oblivai-tor-keys-backup/${NC}"
    echo ""

    print_header "Next Steps"
    echo ""
    print_info "1. Test your site in Tor Browser:"
    echo "     ${CYAN}http://${FINAL_ONION}${NC}"
    echo ""
    print_info "2. Select an AI model and test chat"
    echo ""
    print_info "3. Share your .onion address (optional)"
    echo ""

    print_tip "Model downloads over Tor will be slower than clearnet"
    print_tip "Start with small models (Qwen2 1.5B) for faster download"
    echo ""

    print_header "Service Management"
    echo ""
    echo "  Get .onion address:  ${CYAN}sudo cat ${TORDIR}/hostname${NC}"
    echo "  Check Tor status:    ${CYAN}sudo systemctl status tor${NC}"
    echo "  Check nginx status:  ${CYAN}sudo systemctl status nginx${NC}"
    echo "  View nginx logs:     ${CYAN}sudo tail -f /var/log/nginx/oblivai-access.log${NC}"
    echo "  Restart services:    ${CYAN}sudo systemctl restart tor nginx${NC}"
    echo ""

    print_header "Update OBLIVAI"
    echo ""
    echo "  ${CYAN}cd ${APPDIR} && git pull && npm install && npm run build${NC}"
    echo "  ${CYAN}sudo systemctl reload nginx${NC}"
    echo ""

    print_success "Enjoy your privacy-focused AI chat on Tor! 🎊"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    check_prerequisites
    install_dependencies
    configure_tor
    build_oblivai
    configure_nginx
    print_summary
}

main
