#!/bin/bash

# =============================================================================
# OBLIVAI Pre-Flight Check Script
# =============================================================================
# Comprehensive validation before deployment
# Ensures everything will work correctly on Qubes
# =============================================================================

set -e

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

ERRORS=0
WARNINGS=0

# =============================================================================
# Check 1: System Requirements
# =============================================================================

print_header "Check 1/12: System Requirements"

# Check OS
if [ -f /etc/debian_version ]; then
    DEBIAN_VERSION=$(cat /etc/debian_version)
    print_success "Debian-based system detected (version $DEBIAN_VERSION)"
elif [ -f /etc/redhat-release ]; then
    print_success "RedHat-based system detected"
else
    print_warning "Unknown OS - may have compatibility issues"
    WARNINGS=$((WARNINGS + 1))
fi

# Check if Qubes
if [ -d /usr/share/qubes ]; then
    print_success "Running on Qubes OS"
else
    print_info "Not running on Qubes (standalone system)"
fi

# Check RAM
TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
if [ "$TOTAL_RAM" -ge 2 ]; then
    print_success "RAM: ${TOTAL_RAM}GB (sufficient)"
else
    print_error "RAM: ${TOTAL_RAM}GB (minimum 2GB required)"
    ERRORS=$((ERRORS + 1))
fi

# Check disk space
FREE_SPACE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$FREE_SPACE" -ge 10 ]; then
    print_success "Disk space: ${FREE_SPACE}GB free (sufficient)"
else
    print_warning "Disk space: ${FREE_SPACE}GB free (10GB+ recommended)"
    WARNINGS=$((WARNINGS + 1))
fi

# Check CPU cores
CPU_CORES=$(nproc)
if [ "$CPU_CORES" -ge 2 ]; then
    print_success "CPU cores: $CPU_CORES (sufficient)"
else
    print_warning "CPU cores: $CPU_CORES (2+ recommended)"
    WARNINGS=$((WARNINGS + 1))
fi

# =============================================================================
# Check 2: Required Commands
# =============================================================================

print_header "Check 2/12: Required Commands"

REQUIRED_COMMANDS=("bash" "curl" "git" "find" "grep" "sudo" "systemctl")

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" &> /dev/null; then
        print_success "$cmd: Available"
    else
        print_error "$cmd: NOT FOUND"
        ERRORS=$((ERRORS + 1))
    fi
done

# =============================================================================
# Check 3: Network Connectivity
# =============================================================================

print_header "Check 3/12: Network Connectivity"

# Check if we have network
if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1; then
    print_success "Network connectivity: OK"
else
    print_error "No network connectivity (required for installation)"
    ERRORS=$((ERRORS + 1))
fi

# Check DNS
if nslookup github.com > /dev/null 2>&1; then
    print_success "DNS resolution: Working"
else
    print_error "DNS resolution: Failed"
    ERRORS=$((ERRORS + 1))
fi

# Check HTTPS access
if curl -s -I --max-time 5 https://github.com > /dev/null 2>&1; then
    print_success "HTTPS access: Working"
else
    print_warning "HTTPS access: Slow or blocked (may affect downloads)"
    WARNINGS=$((WARNINGS + 1))
fi

# =============================================================================
# Check 4: Repository Structure
# =============================================================================

print_header "Check 4/12: Repository Structure"

APPDIR="$HOME/OblivPUBLIC"

if [ ! -d "$APPDIR" ]; then
    print_error "Repository not found at $APPDIR"
    print_info "Clone it with: git clone https://github.com/eligorelick/OblivPUBLIC.git ~/OblivPUBLIC"
    ERRORS=$((ERRORS + 1))
else
    print_success "Repository found"

    # Check critical directories
    REQUIRED_DIRS=("src" "deployment-scripts" "public")
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [ -d "$APPDIR/$dir" ]; then
            print_success "$dir/: Present"
        else
            print_error "$dir/: Missing"
            ERRORS=$((ERRORS + 1))
        fi
    done

    # Check critical files
    REQUIRED_FILES=("package.json" "vite.config.ts" "index.html")
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$APPDIR/$file" ]; then
            print_success "$file: Present"
        else
            print_error "$file: Missing"
            ERRORS=$((ERRORS + 1))
        fi
    done
fi

# =============================================================================
# Check 5: Deployment Scripts
# =============================================================================

print_header "Check 5/12: Deployment Scripts"

SCRIPTS_DIR="$APPDIR/deployment-scripts"
REQUIRED_SCRIPTS=(
    "deploy-complete.sh"
    "verify-everything.sh"
    "1-generate-vanity-onion.sh"
    "2-deploy-onion-site.sh"
    "status.sh"
    "fix-permissions.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$SCRIPTS_DIR/$script" ]; then
        if [ -x "$SCRIPTS_DIR/$script" ]; then
            # Check syntax
            if bash -n "$SCRIPTS_DIR/$script" 2>/dev/null; then
                print_success "$script: Valid and executable"
            else
                print_error "$script: Syntax errors"
                ERRORS=$((ERRORS + 1))
            fi
        else
            print_warning "$script: Not executable (will be fixed)"
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        print_error "$script: Missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# =============================================================================
# Check 6: Vanity Keys
# =============================================================================

print_header "Check 6/12: Vanity .onion Keys"

KEYSDIR="$HOME/oblivai-onion-keys"

if [ -d "$KEYSDIR" ] && [ -n "$(ls -A "$KEYSDIR" 2>/dev/null)" ]; then
    ONION_DIR=$(find "$KEYSDIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
    if [ -n "$ONION_DIR" ]; then
        ONION_NAME=$(basename "$ONION_DIR")
        print_success "Vanity keys found: ${GREEN}${ONION_NAME}${NC}"

        # Check for required key files
        if [ -f "$ONION_DIR/hostname" ]; then
            print_success "hostname file: Present"
        else
            print_error "hostname file: Missing"
            ERRORS=$((ERRORS + 1))
        fi

        if [ -f "$ONION_DIR/hs_ed25519_secret_key" ]; then
            print_success "Secret key: Present"
        else
            print_error "Secret key: Missing"
            ERRORS=$((ERRORS + 1))
        fi
    else
        print_warning "Keys directory exists but is empty"
        print_info "Run: bash deployment-scripts/1-generate-vanity-onion.sh oblivai"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    print_warning "No vanity keys found (will need to generate)"
    print_info "Run: bash deployment-scripts/1-generate-vanity-onion.sh oblivai"
    WARNINGS=$((WARNINGS + 1))
fi

# =============================================================================
# Check 7: Node.js and npm
# =============================================================================

print_header "Check 7/12: Node.js and npm"

if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -ge 16 ]; then
        print_success "Node.js: v$(node -v) (compatible)"
    else
        print_error "Node.js: v$(node -v) (requires v16+)"
        ERRORS=$((ERRORS + 1))
    fi
else
    print_warning "Node.js: Not installed (will be installed)"
    WARNINGS=$((WARNINGS + 1))
fi

if command -v npm &> /dev/null; then
    print_success "npm: $(npm -v) (available)"
else
    print_warning "npm: Not installed (will be installed)"
    WARNINGS=$((WARNINGS + 1))
fi

# =============================================================================
# Check 8: Package Dependencies
# =============================================================================

print_header "Check 8/12: Package Dependencies"

if [ -f "$APPDIR/package.json" ]; then
    print_success "package.json: Present"

    # Check if node_modules exists
    if [ -d "$APPDIR/node_modules" ]; then
        print_success "node_modules: Present"

        # Check for critical dependencies
        CRITICAL_DEPS=("react" "vite" "@mlc-ai/web-llm")
        for dep in "${CRITICAL_DEPS[@]}"; do
            if [ -d "$APPDIR/node_modules/$dep" ] || [ -d "$APPDIR/node_modules/@types/$dep" ]; then
                print_success "$dep: Installed"
            else
                print_warning "$dep: Not installed (will run npm install)"
                WARNINGS=$((WARNINGS + 1))
            fi
        done
    else
        print_warning "node_modules: Not present (will run npm install)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    print_error "package.json: Missing"
    ERRORS=$((ERRORS + 1))
fi

# =============================================================================
# Check 9: Application Configuration
# =============================================================================

print_header "Check 9/12: Application Configuration"

# Check model config
if [ -f "$APPDIR/src/lib/model-config.ts" ]; then
    print_success "model-config.ts: Present"

    # Check if all 15 models are defined
    MODEL_COUNT=$(grep -c "id:.*MLC" "$APPDIR/src/lib/model-config.ts" || echo "0")
    if [ "$MODEL_COUNT" -ge 15 ]; then
        print_success "AI models: $MODEL_COUNT models configured"
    else
        print_warning "AI models: Only $MODEL_COUNT models found (expected 15)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    print_error "model-config.ts: Missing"
    ERRORS=$((ERRORS + 1))
fi

# Check security config
if [ -f "$APPDIR/src/lib/security-init.ts" ]; then
    print_success "security-init.ts: Present"

    # Check HuggingFace whitelist
    if grep -q "huggingface.co" "$APPDIR/src/lib/security-init.ts"; then
        print_success "HuggingFace CDN: Whitelisted in security config"
    else
        print_error "HuggingFace CDN: NOT whitelisted (models won't load)"
        ERRORS=$((ERRORS + 1))
    fi
else
    print_error "security-init.ts: Missing"
    ERRORS=$((ERRORS + 1))
fi

# Check chat store
if [ -f "$APPDIR/src/store/chat-store.ts" ]; then
    print_success "chat-store.ts: Present (chat functionality available)"
else
    print_error "chat-store.ts: Missing (chat won't work)"
    ERRORS=$((ERRORS + 1))
fi

# =============================================================================
# Check 10: Service Configuration Files
# =============================================================================

print_header "Check 10/12: Service Configuration Templates"

# Check if Tor config will be created correctly
if grep -q "oblivai-tor.service" "$SCRIPTS_DIR/deploy-complete.sh" 2>/dev/null; then
    print_success "Tor service template: Present in deployment script"
else
    print_error "Tor service template: Missing"
    ERRORS=$((ERRORS + 1))
fi

# Check nginx config template
if grep -q "Content-Security-Policy" "$SCRIPTS_DIR/deploy-complete.sh" 2>/dev/null; then
    print_success "Nginx CSP template: Present"

    # Verify HuggingFace is in CSP
    if grep -q "huggingface.co" "$SCRIPTS_DIR/deploy-complete.sh"; then
        print_success "HuggingFace CDN: Allowed in nginx CSP"
    else
        print_error "HuggingFace CDN: NOT in nginx CSP (critical!)"
        ERRORS=$((ERRORS + 1))
    fi

    # Verify WASM is allowed
    if grep -q "wasm-unsafe-eval" "$SCRIPTS_DIR/deploy-complete.sh"; then
        print_success "WASM execution: Allowed in CSP"
    else
        print_error "WASM execution: NOT allowed (AI won't work!)"
        ERRORS=$((ERRORS + 1))
    fi
else
    print_error "Nginx configuration: Missing CSP headers"
    ERRORS=$((ERRORS + 1))
fi

# =============================================================================
# Check 11: Sudo Permissions
# =============================================================================

print_header "Check 11/12: Sudo Permissions"

if sudo -n true 2>/dev/null; then
    print_success "Sudo: Passwordless access configured"
else
    if sudo -v 2>/dev/null; then
        print_success "Sudo: Available (may require password)"
    else
        print_error "Sudo: Not available or configured"
        ERRORS=$((ERRORS + 1))
    fi
fi

# =============================================================================
# Check 12: Port Availability
# =============================================================================

print_header "Check 12/12: Port Availability"

# Check if port 8080 is available
if command -v netstat &> /dev/null; then
    if netstat -tuln 2>/dev/null | grep -q ":8080"; then
        print_warning "Port 8080: Already in use (nginx may fail to start)"
        WARNINGS=$((WARNINGS + 1))
    else
        print_success "Port 8080: Available"
    fi
elif command -v ss &> /dev/null; then
    if ss -tuln 2>/dev/null | grep -q ":8080"; then
        print_warning "Port 8080: Already in use (nginx may fail to start)"
        WARNINGS=$((WARNINGS + 1))
    else
        print_success "Port 8080: Available"
    fi
else
    print_info "Port check: Cannot verify (netstat/ss not available)"
fi

# =============================================================================
# Summary
# =============================================================================

print_header "Pre-Flight Check Summary"

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  ✓ ALL CHECKS PASSED!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    print_success "System is ready for deployment!"
    echo ""
    print_info "Next steps:"
    echo "  1. If you don't have vanity keys:"
    echo "     ${CYAN}bash deployment-scripts/1-generate-vanity-onion.sh oblivai${NC}"
    echo ""
    echo "  2. Deploy everything:"
    echo "     ${CYAN}bash deployment-scripts/deploy-complete.sh${NC}"
    echo ""
    echo "  3. Verify deployment:"
    echo "     ${CYAN}bash deployment-scripts/verify-everything.sh${NC}"
    echo ""
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  ⚠ PASSED WITH $WARNINGS WARNING(S)${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    print_info "System can proceed but has warnings"
    print_info "Warnings will be automatically resolved during deployment"
    echo ""
    print_info "Proceed with:"
    echo "  ${CYAN}bash deployment-scripts/deploy-complete.sh${NC}"
    echo ""
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  ✗ FOUND $ERRORS ERROR(S) AND $WARNINGS WARNING(S)${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    print_error "System is NOT ready for deployment"
    echo ""
    print_info "Fix the errors above before proceeding"
    echo ""
fi

exit $ERRORS
