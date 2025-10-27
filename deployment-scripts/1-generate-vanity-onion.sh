#!/bin/bash

# =============================================================================
# STEP 1: Generate Vanity .onion Address
# =============================================================================
# This script ONLY generates the vanity .onion address.
# It can take hours, so run it separately from deployment.
#
# Usage:
#   bash 1-generate-vanity-onion.sh [prefix]
#
# Examples:
#   bash 1-generate-vanity-onion.sh oblivai      # Default
#   bash 1-generate-vanity-onion.sh obli         # Faster (4 chars)
#   bash 1-generate-vanity-onion.sh oblivai1     # Custom prefix
#
# After generation completes, run: 2-deploy-onion-site.sh
# =============================================================================

set -e  # Exit on error

# Configuration
PREFIX="${1:-oblivai}"  # Default to "oblivai"
MKPDIR="$HOME/mkp224o"
KEYSDIR="$HOME/oblivai-onion-keys"
THREADS=$(nproc)

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
# Check Environment
# =============================================================================

check_environment() {
    print_header "STEP 1: Vanity .onion Address Generator"

    if [ ! -f /usr/share/anon-gw-base-files/gateway ]; then
        print_info "Not detected as Whonix, but script works on any Debian/Ubuntu system"
    else
        print_success "Running on Whonix Workstation"
    fi

    echo ""
    print_info "This script will ONLY generate the vanity .onion address."
    print_info "After completion, run: ${CYAN}2-deploy-onion-site.sh${NC}"
    echo ""
}

# =============================================================================
# Install Dependencies
# =============================================================================

install_dependencies() {
    print_header "Installing Dependencies for mkp224o"

    print_info "Updating package list..."
    sudo apt update -qq

    print_info "Installing build dependencies..."
    sudo apt install -y \
        gcc \
        libc6-dev \
        libsodium-dev \
        make \
        autoconf \
        git \
        2>&1 | grep -v "^Reading" || true

    print_success "Dependencies installed"
}

# =============================================================================
# Build mkp224o
# =============================================================================

build_mkp224o() {
    print_header "Building mkp224o Vanity Generator"

    if [ -d "$MKPDIR" ]; then
        print_warning "mkp224o already exists, removing old version..."
        rm -rf "$MKPDIR"
    fi

    print_info "Cloning mkp224o repository..."
    git clone -q https://github.com/cathugger/mkp224o.git "$MKPDIR" 2>&1

    cd "$MKPDIR"

    print_info "Configuring build..."
    ./autogen.sh > /dev/null 2>&1
    ./configure > /dev/null 2>&1

    print_info "Compiling mkp224o (this may take a minute)..."
    make -j"$THREADS" > /dev/null 2>&1

    print_success "mkp224o compiled successfully"

    cd - > /dev/null
}

# =============================================================================
# Generate Vanity Address
# =============================================================================

generate_vanity_address() {
    print_header "Generating Vanity .onion Address"

    print_info "Target prefix: ${CYAN}${PREFIX}${NC}"
    print_info "Using ${CYAN}$THREADS${NC} CPU threads for maximum speed"
    echo ""

    # Estimate time
    local prefix_len=${#PREFIX}
    print_warning "TIME ESTIMATES (approximate, varies by CPU):"
    echo ""
    if [ $prefix_len -le 4 ]; then
        echo "  4 chars (obli):    ${GREEN}Seconds${NC}"
        echo "  5 chars (obliv):   Minutes"
        echo "  6 chars (obliva):  Hours"
        echo "  7 chars (oblivai): Hours to Days"
    elif [ $prefix_len -le 5 ]; then
        echo "  5 chars (obliv):   ${GREEN}Minutes${NC}"
        echo "  6 chars (obliva):  Hours"
        echo "  7 chars (oblivai): Hours to Days"
    elif [ $prefix_len -le 6 ]; then
        echo "  6 chars (obliva):  ${YELLOW}Hours${NC}"
        echo "  7 chars (oblivai): Hours to Days"
    else
        echo "  7+ chars:          ${RED}Hours to Days (or longer!)${NC}"
        echo ""
        print_warning "Consider using a shorter prefix for faster results"
    fi
    echo ""

    print_tip "You can stop generation anytime with Ctrl+C"
    print_tip "Run this script overnight for 7+ character prefixes"
    print_tip "Generated keys are saved to: ${CYAN}${KEYSDIR}${NC}"
    echo ""

    read -p "Start generation? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cancelled by user"
        exit 0
    fi

    # Create output directory
    mkdir -p "$KEYSDIR"

    # Check if already generated
    EXISTING=$(find "$KEYSDIR" -type d -name "${PREFIX}*" 2>/dev/null | head -n 1)
    if [ -n "$EXISTING" ]; then
        print_warning "Found existing address starting with '$PREFIX'!"
        EXISTING_NAME=$(basename "$EXISTING")
        echo ""
        echo -e "  ${GREEN}${EXISTING_NAME}.onion${NC}"
        echo ""
        read -p "Use this address? (y) or generate new one? (n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ONION_ADDRESS="$EXISTING_NAME"
            ONION_DIR="$EXISTING"
            print_success "Using existing address"
            display_summary
            return
        else
            print_info "Generating new address..."
        fi
    fi

    # Run mkp224o
    print_header "GENERATION IN PROGRESS"
    echo ""
    print_info "Using ${GREEN}$THREADS threads${NC} for generation"
    print_info "This may take a while... Press Ctrl+C to stop."
    echo ""
    print_warning "NOTE: Output only appears when addresses are found!"
    print_tip "For 7+ char prefixes, this could take hours before first output"
    print_tip "In another terminal, run: ${CYAN}watch -n 5 'ls -l ~/oblivai-onion-keys/'${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Searching for .onion addresses starting with: ${GREEN}${PREFIX}${NC}"
    echo -e "${YELLOW}When found, addresses will appear below:${NC}"
    echo ""

    # Run mkp224o (output goes directly to terminal)
    "$MKPDIR/mkp224o" -d "$KEYSDIR" -t "$THREADS" -v "$PREFIX"

    # Find generated address
    ONION_DIR=$(find "$KEYSDIR" -type d -name "${PREFIX}*" | head -n 1)

    if [ -z "$ONION_DIR" ]; then
        echo ""
        print_error "No .onion address found (generation stopped or failed)"
        echo ""
        print_info "To resume, run this script again:"
        echo "  ${CYAN}bash 1-generate-vanity-onion.sh $PREFIX${NC}"
        exit 1
    fi

    ONION_ADDRESS=$(basename "$ONION_DIR")

    display_summary
}

# =============================================================================
# Display Summary
# =============================================================================

display_summary() {
    echo ""
    print_header "✓ VANITY ADDRESS GENERATED!"

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Your vanity .onion address:${NC}"
    echo ""
    echo -e "  ${CYAN}http://${ONION_ADDRESS}.onion${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    print_success "Keys saved to: ${CYAN}${ONION_DIR}${NC}"
    echo ""

    print_warning "IMPORTANT: Backup your keys!"
    echo ""
    echo "  To backup:"
    echo "  ${CYAN}cp -r \"$ONION_DIR\" ~/oblivai-keys-backup/${NC}"
    echo ""

    print_header "NEXT STEP: Deploy Your Site"
    echo ""
    print_info "Now run the deployment script:"
    echo ""
    echo "  ${GREEN}bash 2-deploy-onion-site.sh${NC}"
    echo ""
    print_info "This will:"
    echo "  ✓ Install Tor and nginx"
    echo "  ✓ Configure hidden service with your vanity address"
    echo "  ✓ Build and deploy OBLIVAI"
    echo "  ✓ Start your .onion site"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    check_environment
    install_dependencies
    build_mkp224o
    generate_vanity_address
}

main
