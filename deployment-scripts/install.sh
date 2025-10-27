#!/bin/bash

# OBLIVAI Tor Hidden Service - Quick Install Script
# For Debian/Ubuntu servers
# Run with: sudo bash install.sh YOUR_USERNAME

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}OBLIVAI Tor Hidden Service Installer${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: Please run as root (sudo bash install.sh YOUR_USERNAME)${NC}"
    exit 1
fi

# Check if username provided
if [ -z "$1" ]; then
    echo -e "${RED}ERROR: Please provide username as argument${NC}"
    echo "Usage: sudo bash install.sh YOUR_USERNAME"
    exit 1
fi

USERNAME="$1"
APP_DIR="/var/www/oblivai"
BRANCH="main"
REPO_URL="https://github.com/eligorelick/OblivPUBLIC.git"

# Check if user exists
if ! id "$USERNAME" &>/dev/null; then
    echo -e "${RED}ERROR: User '$USERNAME' does not exist${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing for user: $USERNAME${NC}"
echo ""

# Step 1: Update system
echo -e "${GREEN}[1/10] Updating system packages...${NC}"
apt update && apt upgrade -y

# Step 2: Install dependencies
echo -e "${GREEN}[2/10] Installing dependencies (tor, nginx, nodejs, npm, git)...${NC}"
apt install -y tor nginx git curl

# Install Node.js 18.x if not already installed
if ! command -v node &> /dev/null || [ $(node -v | cut -d'.' -f1 | tr -d 'v') -lt 18 ]; then
    echo -e "${YELLOW}Installing Node.js 18.x...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
fi

# Verify installations
echo -e "${YELLOW}Installed versions:${NC}"
tor --version | head -1
nginx -v
node --version
npm --version
git --version
echo ""

# Step 3: Create app directory
echo -e "${GREEN}[3/10] Creating application directory...${NC}"
mkdir -p "$APP_DIR"
chown -R "$USERNAME:$USERNAME" "$APP_DIR"

# Step 4: Clone repository
echo -e "${GREEN}[4/10] Cloning OBLIVAI repository...${NC}"
if [ -d "$APP_DIR/.git" ]; then
    echo -e "${YELLOW}Repository already exists, pulling latest...${NC}"
    cd "$APP_DIR"
    sudo -u "$USERNAME" git pull origin "$BRANCH"
else
    sudo -u "$USERNAME" git clone "$REPO_URL" "$APP_DIR"
    cd "$APP_DIR"
    sudo -u "$USERNAME" git checkout "$BRANCH"
fi

# Step 5: Build application
echo -e "${GREEN}[5/10] Building OBLIVAI...${NC}"
sudo -u "$USERNAME" npm install
sudo -u "$USERNAME" npm run build

# Verify build
if [ ! -d "$APP_DIR/dist" ]; then
    echo -e "${RED}ERROR: Build failed - dist directory not found${NC}"
    exit 1
fi

echo -e "${YELLOW}Build successful! Files in: $APP_DIR/dist${NC}"
echo ""

# Step 6: Configure nginx
echo -e "${GREEN}[6/10] Configuring nginx...${NC}"
cp deployment-scripts/nginx-oblivai.conf /etc/nginx/sites-available/oblivai

# Enable site
ln -sf /etc/nginx/sites-available/oblivai /etc/nginx/sites-enabled/oblivai

# Remove default site (optional)
if [ -L /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi

# Test nginx config
nginx -t

# Restart nginx
systemctl restart nginx
systemctl enable nginx

echo -e "${YELLOW}Nginx configured and running${NC}"
echo ""

# Step 7: Configure Tor hidden service
echo -e "${GREEN}[7/10] Configuring Tor hidden service...${NC}"

# Backup existing torrc
cp /etc/tor/torrc /etc/tor/torrc.backup

# Add hidden service configuration if not already present
if ! grep -q "HiddenServiceDir /var/lib/tor/oblivai" /etc/tor/torrc; then
    cat >> /etc/tor/torrc << EOF

# OBLIVAI Hidden Service
HiddenServiceDir /var/lib/tor/oblivai/
HiddenServicePort 80 127.0.0.1:8080
HiddenServiceVersion 3
EOF
fi

# Restart Tor
systemctl restart tor
systemctl enable tor

# Wait for Tor to generate keys
echo -e "${YELLOW}Waiting for Tor to generate .onion address...${NC}"
sleep 5

# Get .onion address
ONION_ADDRESS=$(cat /var/lib/tor/oblivai/hostname 2>/dev/null || echo "Error reading hostname")

echo ""
echo -e "${GREEN}✅ Tor hidden service configured!${NC}"
echo -e "${GREEN}Your .onion address: ${YELLOW}$ONION_ADDRESS${NC}"
echo ""

# Step 8: Install auto-update script
echo -e "${GREEN}[8/10] Installing auto-update script...${NC}"
cp deployment-scripts/oblivai-update.sh /usr/local/bin/oblivai-update.sh

# Replace placeholder username
sed -i "s/YOUR_USERNAME/$USERNAME/g" /usr/local/bin/oblivai-update.sh

chmod +x /usr/local/bin/oblivai-update.sh

# Create log file
touch /var/log/oblivai-update.log
chown "$USERNAME:$USERNAME" /var/log/oblivai-update.log

echo -e "${YELLOW}Auto-update script installed${NC}"
echo ""

# Step 9: Install systemd service and timer
echo -e "${GREEN}[9/10] Installing systemd auto-update service...${NC}"

# Copy and modify service file
cp deployment-scripts/oblivai-update.service /etc/systemd/system/
sed -i "s/YOUR_USERNAME/$USERNAME/g" /etc/systemd/system/oblivai-update.service

# Copy timer file
cp deployment-scripts/oblivai-update.timer /etc/systemd/system/

# Reload systemd
systemctl daemon-reload

# Enable and start timer
systemctl enable oblivai-update.timer
systemctl start oblivai-update.timer

echo -e "${YELLOW}Auto-update timer enabled (runs every 15 minutes)${NC}"
echo ""

# Step 10: Security hardening
echo -e "${GREEN}[10/10] Applying security hardening...${NC}"

# Set up firewall if not already configured
if ! command -v ufw &> /dev/null; then
    echo -e "${YELLOW}Installing UFW firewall...${NC}"
    apt install -y ufw
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp  # SSH
    echo "y" | ufw enable
    echo -e "${YELLOW}Firewall enabled${NC}"
else
    echo -e "${YELLOW}Firewall already installed${NC}"
fi

# Set up log rotation
cat > /etc/logrotate.d/oblivai << EOF
/var/log/oblivai-update.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF

echo -e "${YELLOW}Log rotation configured${NC}"
echo ""

# Final summary
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}     INSTALLATION COMPLETE! ✅       ${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}Your OBLIVAI Tor Hidden Service Details:${NC}"
echo ""
echo -e "${GREEN}.onion Address:${NC} ${YELLOW}$ONION_ADDRESS${NC}"
echo ""
echo -e "${GREEN}Status:${NC}"
echo -e "  Tor:    $(systemctl is-active tor)"
echo -e "  Nginx:  $(systemctl is-active nginx)"
echo -e "  Timer:  $(systemctl is-active oblivai-update.timer)"
echo ""
echo -e "${GREEN}Auto-Update:${NC} Every 15 minutes from git"
echo -e "${GREEN}Branch:${NC} $BRANCH"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Test your site: Visit $ONION_ADDRESS in Tor Browser"
echo "2. Monitor auto-updates: tail -f /var/log/oblivai-update.log"
echo "3. Check status: systemctl status oblivai-update.timer"
echo "4. Manual update: systemctl start oblivai-update.service"
echo ""
echo -e "${GREEN}Monitoring Commands:${NC}"
echo "  sudo systemctl status tor"
echo "  sudo systemctl status nginx"
echo "  sudo systemctl status oblivai-update.timer"
echo "  sudo tail -f /var/log/oblivai-update.log"
echo "  sudo journalctl -u oblivai-update.service -f"
echo ""
echo -e "${RED}IMPORTANT:${NC} Save your .onion address in a secure location!"
echo ""
echo -e "${GREEN}=====================================${NC}"
