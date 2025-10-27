#!/bin/bash

# =============================================================================
# OBLIVAI Vanity .onion Address Generator
# =============================================================================
# Generates a Tor v3 hidden service address starting with "oblivai"
# Optimized for Qubes Whonix Workstation
#
# This script:
# 1. Installs dependencies (mkp224o vanity address generator)
# 2. Generates vanity .onion address starting with "oblivai"
# 3. Configures Tor hidden service with the generated keys
# 4. Sets up nginx web server
# 5. Builds and deploys OBLIVAI
#
# Usage:
#   bash generate-vanity-onion.sh [prefix]
#
# Examples:
#   bash generate-vanity-onion.sh oblivai      # Default
#   bash generate-vanity-onion.sh oblivai1     # Custom prefix
#
# =============================================================================

set -e  # Exit on error

# Configuration
PREFIX="${1:-oblivai}"  # Default to "oblivai" if no argument provided
MKPDIR="$HOME/mkp224o"
KEYSDIR="$HOME/onion-keys"
APPDIR="$HOME/oblivai-app"
THREADS=$(nproc)  # Use all available CPU cores

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
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

check_whonix() {
    if [ ! -f /usr/share/anon-gw-base-files/gateway ]; then
        print_warning "Not detected as Whonix Workstation, but continuing anyway..."
        print_info "This script works on any Debian/Ubuntu-based system"
    else
        print_success "Running on Whonix Workstation"
    fi
}

# =============================================================================
# Step 1: Install Dependencies
# =============================================================================

install_dependencies() {
    print_header "Step 1/6: Installing Dependencies"

    print_info "Updating package list..."
    sudo apt update

    print_info "Installing build dependencies for mkp224o..."
    sudo apt install -y \
        gcc \
        libc6-dev \
        libsodium-dev \
        make \
        autoconf \
        git \
        tor \
        nginx \
        curl

    print_success "Dependencies installed"
}

# =============================================================================
# Step 2: Build mkp224o (Vanity Address Generator)
# =============================================================================

build_mkp224o() {
    print_header "Step 2/6: Building mkp224o Vanity Address Generator"

    if [ -d "$MKPDIR" ]; then
        print_warning "mkp224o directory already exists, removing old version..."
        rm -rf "$MKPDIR"
    fi

    print_info "Cloning mkp224o repository..."
    git clone https://github.com/cathugger/mkp224o.git "$MKPDIR"

    cd "$MKPDIR"

    print_info "Configuring build..."
    ./autogen.sh
    ./configure

    print_info "Compiling mkp224o (this may take a few minutes)..."
    make -j"$THREADS"

    print_success "mkp224o built successfully"

    cd - > /dev/null
}

# =============================================================================
# Step 3: Generate Vanity .onion Address
# =============================================================================

generate_vanity_address() {
    print_header "Step 3/6: Generating Vanity .onion Address"

    print_info "Target prefix: ${PREFIX}"
    print_info "Using $THREADS CPU threads"
    print_warning "This may take a while depending on prefix length..."
    echo ""

    # Estimate time
    local prefix_len=${#PREFIX}
    if [ $prefix_len -le 4 ]; then
        print_info "Estimated time: seconds to minutes"
    elif [ $prefix_len -le 5 ]; then
        print_info "Estimated time: minutes to hours"
    elif [ $prefix_len -le 6 ]; then
        print_info "Estimated time: hours to days"
    else
        print_warning "Estimated time: days to weeks (consider shorter prefix)"
    fi
    echo ""

    # Create output directory
    mkdir -p "$KEYSDIR"

    # Run mkp224o
    print_info "Starting generation (press Ctrl+C to stop)..."
    echo ""

    "$MKPDIR/mkp224o" -d "$KEYSDIR" -t "$THREADS" -v "$PREFIX"

    # Find the generated directory
    ONION_DIR=$(find "$KEYSDIR" -type d -name "${PREFIX}*" | head -n 1)

    if [ -z "$ONION_DIR" ]; then
        print_error "No .onion address found!"
        exit 1
    fi

    ONION_ADDRESS=$(basename "$ONION_DIR")

    echo ""
    print_success "Vanity address generated!"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Your .onion address: ${YELLOW}${ONION_ADDRESS}.onion${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# =============================================================================
# Step 4: Configure Tor Hidden Service
# =============================================================================

configure_tor() {
    print_header "Step 4/6: Configuring Tor Hidden Service"

    print_info "Creating Tor hidden service directory..."
    sudo mkdir -p /var/lib/tor/oblivai

    print_info "Copying generated keys..."
    sudo cp -r "$ONION_DIR"/* /var/lib/tor/oblivai/
    sudo chown -R debian-tor:debian-tor /var/lib/tor/oblivai
    sudo chmod 700 /var/lib/tor/oblivai
    sudo chmod 600 /var/lib/tor/oblivai/*

    print_info "Configuring torrc..."

    # Backup existing torrc
    if [ -f /etc/tor/torrc ]; then
        sudo cp /etc/tor/torrc /etc/tor/torrc.backup.$(date +%s)
    fi

    # Check if OBLIVAI hidden service already configured
    if grep -q "# OBLIVAI Hidden Service" /etc/tor/torrc; then
        print_warning "OBLIVAI hidden service already configured in torrc, skipping..."
    else
        # Add hidden service configuration
        sudo tee -a /etc/tor/torrc > /dev/null << EOF

# OBLIVAI Hidden Service
HiddenServiceDir /var/lib/tor/oblivai/
HiddenServicePort 80 127.0.0.1:8080
EOF
        print_success "Tor configuration updated"
    fi

    print_info "Restarting Tor..."
    sudo systemctl restart tor

    # Wait for Tor to start
    sleep 3

    print_success "Tor hidden service configured"

    # Verify hostname
    ACTUAL_ONION=$(sudo cat /var/lib/tor/oblivai/hostname)
    echo ""
    print_success "Hidden service running at: ${YELLOW}${ACTUAL_ONION}${NC}"
    echo ""
}

# =============================================================================
# Step 5: Setup OBLIVAI Application
# =============================================================================

setup_app() {
    print_header "Step 5/6: Setting Up OBLIVAI Application"

    if [ -d "$APPDIR" ]; then
        print_warning "Application directory exists, pulling latest changes..."
        cd "$APPDIR"
        git pull origin main || print_warning "Git pull failed, using existing code"
    else
        print_info "Cloning OBLIVAI repository..."
        git clone https://github.com/eligorelick/OblivPUBLIC.git "$APPDIR"
        cd "$APPDIR"
    fi

    print_info "Installing Node.js dependencies..."
    npm install

    print_info "Building OBLIVAI for production..."
    npm run build

    print_success "Application built successfully"

    cd - > /dev/null
}

# =============================================================================
# Step 6: Configure Nginx
# =============================================================================

configure_nginx() {
    print_header "Step 6/6: Configuring Nginx Web Server"

    print_info "Creating nginx configuration..."

    sudo tee /etc/nginx/sites-available/oblivai > /dev/null << 'EOF'
server {
    listen 127.0.0.1:8080;
    server_name localhost;

    root /home/user/oblivai-app/dist;
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
        try_files $uri $uri/ /index.html;
    }

    # Minimal logging for privacy
    access_log /var/log/nginx/oblivai-access.log;
    error_log /var/log/nginx/oblivai-error.log;
}
EOF

    # Update the root path to actual user home
    ACTUAL_APPDIR=$(realpath "$APPDIR")
    sudo sed -i "s|/home/user/oblivai-app|$ACTUAL_APPDIR|g" /etc/nginx/sites-available/oblivai

    print_info "Enabling site..."
    sudo ln -sf /etc/nginx/sites-available/oblivai /etc/nginx/sites-enabled/oblivai

    # Remove default site if exists
    sudo rm -f /etc/nginx/sites-enabled/default

    print_info "Testing nginx configuration..."
    sudo nginx -t

    print_info "Restarting nginx..."
    sudo systemctl restart nginx
    sudo systemctl enable nginx

    print_success "Nginx configured and running"
}

# =============================================================================
# Final Summary
# =============================================================================

print_summary() {
    print_header "✓ Installation Complete!"

    FINAL_ONION=$(sudo cat /var/lib/tor/oblivai/hostname)

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  OBLIVAI is now running on Tor Hidden Service!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${YELLOW}Your .onion address:${NC}"
    echo -e "  ${BLUE}http://${FINAL_ONION}${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    print_info "Next steps:"
    echo ""
    echo "  1. Visit your .onion address in Tor Browser"
    echo "  2. Test the AI chat functionality"
    echo "  3. Share your .onion address (if desired)"
    echo ""

    print_warning "IMPORTANT: Backup your keys!"
    echo ""
    echo "  Your hidden service keys are stored in:"
    echo "  /var/lib/tor/oblivai/"
    echo ""
    echo "  To backup:"
    echo "  sudo cp -r /var/lib/tor/oblivai/ ~/oblivai-backup/"
    echo ""

    print_info "Service management:"
    echo ""
    echo "  Check Tor status:   sudo systemctl status tor"
    echo "  Check nginx status: sudo systemctl status nginx"
    echo "  View nginx logs:    sudo tail -f /var/log/nginx/oblivai-access.log"
    echo "  Get .onion address: sudo cat /var/lib/tor/oblivai/hostname"
    echo ""

    print_success "Setup complete! Enjoy your privacy-focused AI chat."
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    print_header "OBLIVAI Vanity .onion Address Generator"

    print_info "This script will:"
    echo "  1. Install dependencies (mkp224o, Tor, nginx)"
    echo "  2. Generate vanity .onion address starting with '$PREFIX'"
    echo "  3. Configure Tor hidden service"
    echo "  4. Build and deploy OBLIVAI"
    echo "  5. Configure nginx web server"
    echo ""

    check_whonix

    print_warning "This process may take a while, especially address generation."
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled by user"
        exit 0
    fi

    install_dependencies
    build_mkp224o
    generate_vanity_address
    configure_tor
    setup_app
    configure_nginx
    print_summary
}

# Run main function
main
