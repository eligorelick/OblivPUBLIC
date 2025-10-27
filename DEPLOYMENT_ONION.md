# OBLIVAI Tor Hidden Service Deployment Guide

Complete guide for hosting OBLIVAI on a Tor hidden service (.onion) with automatic git updates.

## ⚠️ IMPORTANT: Tails is NOT Recommended for Hosting

**Tails is designed for:**
- Anonymous browsing (client use)
- Leaving no traces (amnesic OS)
- Maximum privacy for users

**Tails is NOT designed for:**
- ❌ Running servers
- ❌ Persistent services
- ❌ Long-running daemons
- ❌ Automatic updates

**Problems with hosting on Tails:**
1. **Amnesic by design** - Everything is wiped on reboot
2. **No persistent services** - Tor hidden service keys lost on reboot
3. **Limited persistence** - Only encrypted persistence volume available
4. **Network restrictions** - Outbound connections forced through Tor (slow git pulls)
5. **Not hardened for servers** - Security model designed for clients

## ✅ RECOMMENDED: Debian/Ubuntu Server Setup

For a reliable, secure .onion hosting:

### Prerequisites
- Dedicated server or VM (2GB+ RAM, 20GB+ storage)
- Debian 12 or Ubuntu 22.04 LTS
- Root or sudo access
- Static IP (optional but recommended)

---

## OPTION 1: Recommended Setup (Debian/Ubuntu)

### Step 1: Initial Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y tor nginx git nodejs npm curl

# Verify installations
tor --version
nginx -v
node --version
git --version
```

### Step 2: Clone OBLIVAI Repository

```bash
# Create app directory
sudo mkdir -p /var/www/oblivai
sudo chown -R $USER:$USER /var/www/oblivai

# Clone repository
cd /var/www/oblivai
git clone https://github.com/eligorelick/OblivPUBLIC.git .

# Ensure you're on the main branch
git checkout main
```

### Step 3: Build OBLIVAI

```bash
# Install dependencies
cd /var/www/oblivai
npm install

# Build for production
npm run build

# Verify build
ls -lh dist/
```

### Step 4: Configure Nginx

```bash
# Create nginx config
sudo nano /etc/nginx/sites-available/oblivai
```

Paste this configuration:

```nginx
server {
    listen 127.0.0.1:8080;
    server_name localhost;

    root /var/www/oblivai/dist;
    index index.html;

    # Security headers (Tor-compatible, no HTTPS enforcement)
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

    # Disable logging for privacy
    access_log /var/log/nginx/oblivai-access.log;
    error_log /var/log/nginx/oblivai-error.log;
}
```

Enable the site:

```bash
# Create symlink
sudo ln -s /etc/nginx/sites-available/oblivai /etc/nginx/sites-enabled/

# Remove default site (optional)
sudo rm /etc/nginx/sites-enabled/default

# Test nginx config
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

# Verify nginx is running
sudo systemctl status nginx
```

### Step 5: Configure Tor Hidden Service

```bash
# Edit Tor config
sudo nano /etc/tor/torrc
```

Add these lines at the end:

```
# OBLIVAI Hidden Service
HiddenServiceDir /var/lib/tor/oblivai/
HiddenServicePort 80 127.0.0.1:8080

# Optional: Version 3 onion addresses (recommended)
HiddenServiceVersion 3

# Optional: Improve performance
HiddenServiceNonAnonymousMode 0
HiddenServiceSingleHopMode 0
```

Apply configuration:

```bash
# Restart Tor
sudo systemctl restart tor
sudo systemctl enable tor

# Wait a few seconds for Tor to generate keys
sleep 5

# Get your .onion address
sudo cat /var/lib/tor/oblivai/hostname
```

**Save this .onion address!** This is your permanent hidden service address.

### Step 6: Set Up Auto-Update from Git

Create an auto-update script:

```bash
# Create update script
sudo nano /usr/local/bin/oblivai-update.sh
```

Paste this script:

```bash
#!/bin/bash

# OBLIVAI Auto-Update Script
# Pulls latest changes from git and rebuilds

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
    echo "[$(date)] Updates found! Updating..." >> "$LOG_FILE"

    # Pull latest changes
    git pull origin "$BRANCH" 2>&1 >> "$LOG_FILE"

    # Install dependencies (in case package.json changed)
    npm install 2>&1 >> "$LOG_FILE"

    # Build
    npm run build 2>&1 >> "$LOG_FILE"

    # Reload nginx (optional, not usually needed for static sites)
    sudo systemctl reload nginx 2>&1 >> "$LOG_FILE"

    echo "[$(date)] Update complete! New version deployed." >> "$LOG_FILE"
else
    echo "[$(date)] No updates available." >> "$LOG_FILE"
fi

echo "[$(date)] Update check finished." >> "$LOG_FILE"
echo "---" >> "$LOG_FILE"
```

Make it executable:

```bash
# Make script executable
sudo chmod +x /usr/local/bin/oblivai-update.sh

# Create log file
sudo touch /var/log/oblivai-update.log
sudo chown $USER:$USER /var/log/oblivai-update.log

# Test the script
sudo -u $USER /usr/local/bin/oblivai-update.sh

# Check log
tail -f /var/log/oblivai-update.log
```

### Step 7: Set Up Automatic Updates with Systemd Timer

Create a systemd service:

```bash
# Create service file
sudo nano /etc/systemd/system/oblivai-update.service
```

Paste this:

```ini
[Unit]
Description=OBLIVAI Auto-Update Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=YOUR_USERNAME_HERE
WorkingDirectory=/var/www/oblivai
ExecStart=/usr/local/bin/oblivai-update.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Replace `YOUR_USERNAME_HERE` with your actual username!**

Create a timer:

```bash
# Create timer file
sudo nano /etc/systemd/system/oblivai-update.timer
```

Paste this:

```ini
[Unit]
Description=OBLIVAI Auto-Update Timer
Requires=oblivai-update.service

[Timer]
# Run every 15 minutes
OnCalendar=*:0/15
# Run 1 minute after boot
OnBootSec=1min
# Randomize start time by up to 2 minutes (reduces predictability)
RandomizedDelaySec=2min
# Persist missed runs
Persistent=true

[Install]
WantedBy=timers.target
```

Enable the timer:

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable and start the timer
sudo systemctl enable oblivai-update.timer
sudo systemctl start oblivai-update.timer

# Check timer status
sudo systemctl status oblivai-update.timer

# List all timers
sudo systemctl list-timers --all | grep oblivai

# Manually trigger an update (for testing)
sudo systemctl start oblivai-update.service

# Check logs
sudo journalctl -u oblivai-update.service -f
```

### Step 8: Security Hardening

```bash
# 1. Set up firewall (allow only local nginx, block external)
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp  # SSH (if needed)
sudo ufw enable

# 2. Disable nginx access logs for privacy (optional)
sudo sed -i 's/access_log.*/access_log off;/' /etc/nginx/sites-available/oblivai
sudo systemctl reload nginx

# 3. Set up log rotation
sudo nano /etc/logrotate.d/oblivai
```

Paste this:

```
/var/log/oblivai-update.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

Apply:

```bash
sudo logrotate -f /etc/logrotate.d/oblivai
```

### Step 9: Monitoring & Maintenance

```bash
# Check Tor hidden service status
sudo systemctl status tor
sudo cat /var/lib/tor/oblivai/hostname

# Check nginx status
sudo systemctl status nginx
curl http://127.0.0.1:8080

# Check auto-update logs
tail -f /var/log/oblivai-update.log
sudo journalctl -u oblivai-update.service -f

# Check timer status
sudo systemctl list-timers | grep oblivai

# Manually trigger update
sudo systemctl start oblivai-update.service

# View nginx logs
sudo tail -f /var/log/nginx/oblivai-access.log
sudo tail -f /var/log/nginx/oblivai-error.log
```

### Step 10: Test Your .onion Site

```bash
# Get your .onion address
sudo cat /var/lib/tor/oblivai/hostname

# Test locally with Tor Browser
# 1. Install Tor Browser on another machine
# 2. Visit your .onion address
# 3. Verify the site loads
# 4. Test AI functionality (select model, send message)
```

---

## OPTION 2: Tails Workaround (Not Recommended)

If you absolutely must use Tails, here's how to make it work:

### Tails Limitations
- .onion keys will be lost on reboot unless stored on persistent volume
- Auto-updates won't work reliably (Tails blocks most background services)
- Git pulls will be very slow (forced through Tor)
- Not suitable for production use

### Tails Setup (Manual Process)

1. **Enable Persistent Storage** (required)
   - Boot Tails
   - Configure Persistent Volume
   - Enable "Persistent Folder" option
   - Restart Tails

2. **Install Dependencies** (each boot)
   ```bash
   # Tails uses Debian, but packages reset on reboot
   sudo apt update
   sudo apt install -y nginx nodejs npm git
   ```

3. **Clone Repository to Persistent Storage**
   ```bash
   cd ~/Persistent
   git clone https://github.com/eligorelick/OblivPUBLIC.git oblivai
   cd oblivai
   npm install
   npm run build
   ```

4. **Configure Tor Hidden Service**
   ```bash
   # Edit torrc
   sudo nano /etc/tor/torrc

   # Add:
   HiddenServiceDir /home/amnesia/Persistent/tor-hidden-service/
   HiddenServicePort 80 127.0.0.1:8080

   # Create directory
   mkdir -p ~/Persistent/tor-hidden-service
   chmod 700 ~/Persistent/tor-hidden-service

   # Restart Tor
   sudo systemctl restart tor@default.service

   # Get .onion address
   cat ~/Persistent/tor-hidden-service/hostname
   ```

5. **Configure Nginx** (manually each boot)
   ```bash
   # Create nginx config
   sudo nano /etc/nginx/sites-available/oblivai
   # (paste config from Option 1)

   sudo ln -s /etc/nginx/sites-available/oblivai /etc/nginx/sites-enabled/
   sudo nginx -t
   sudo systemctl restart nginx
   ```

6. **Manual Update Process** (no auto-update on Tails)
   ```bash
   cd ~/Persistent/oblivai
   git pull origin main
   npm install
   npm run build
   sudo systemctl reload nginx
   ```

**Tails Conclusion:** This requires manual intervention after every reboot. Not suitable for reliable hosting.

---

## Security Best Practices

### 1. Monitor for Unauthorized Access
```bash
# Check nginx access logs regularly
sudo tail -f /var/log/nginx/oblivai-access.log

# Set up fail2ban (optional)
sudo apt install -y fail2ban
```

### 2. Keep .onion Keys Secure
```bash
# Backup hidden service keys
sudo cp -r /var/lib/tor/oblivai/ ~/oblivai-tor-backup/
sudo chmod 600 ~/oblivai-tor-backup/*

# Store backup securely (encrypted USB, password manager, etc.)
```

### 3. Monitor Tor Service
```bash
# Check Tor status
sudo systemctl status tor

# View Tor logs
sudo journalctl -u tor -f
```

### 4. Update System Regularly
```bash
# Weekly system updates
sudo apt update && sudo apt upgrade -y

# Restart services after updates
sudo systemctl restart tor nginx
```

### 5. Test Auto-Updates
```bash
# Make a test commit to your repo
# Wait 15 minutes (or trigger manually)
sudo systemctl start oblivai-update.service

# Check if site updated
curl http://127.0.0.1:8080 | grep "version"
```

---

## Troubleshooting

### Issue: .onion address not accessible
```bash
# Check Tor is running
sudo systemctl status tor

# Check nginx is running
sudo systemctl status nginx

# Check nginx can connect to localhost:8080
curl http://127.0.0.1:8080

# Check Tor logs
sudo journalctl -u tor -n 50
```

### Issue: Auto-updates not working
```bash
# Check timer is running
sudo systemctl status oblivai-update.timer

# Check service logs
sudo journalctl -u oblivai-update.service -n 50

# Manually trigger update
sudo systemctl start oblivai-update.service
```

### Issue: Build fails
```bash
# Check Node.js version (need 18+)
node --version

# Clear node_modules and rebuild
cd /var/www/oblivai
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Issue: Git pull fails
```bash
# Check git remote
cd /var/www/oblivai
git remote -v

# Check branch
git branch -a

# Force reset to remote (WARNING: loses local changes)
git fetch origin
git reset --hard origin/main
```

---

## Performance Optimization

### 1. Enable Nginx Gzip Compression
```bash
sudo nano /etc/nginx/nginx.conf
```

Uncomment/add:
```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;
```

Restart nginx:
```bash
sudo systemctl restart nginx
```

### 2. Tune Tor Performance
```bash
sudo nano /etc/tor/torrc
```

Add:
```
# Increase circuits for better performance
NumEntryGuards 8
MaxCircuitDirtiness 600
```

Restart Tor:
```bash
sudo systemctl restart tor
```

---

## Monitoring Dashboard (Optional)

Create a simple status script:

```bash
sudo nano /usr/local/bin/oblivai-status.sh
```

Paste:

```bash
#!/bin/bash

echo "====== OBLIVAI STATUS ======"
echo ""
echo "Tor Hidden Service:"
sudo cat /var/lib/tor/oblivai/hostname
echo ""
echo "Tor Status:"
sudo systemctl is-active tor
echo ""
echo "Nginx Status:"
sudo systemctl is-active nginx
echo ""
echo "Auto-Update Timer:"
sudo systemctl is-active oblivai-update.timer
echo ""
echo "Last Update:"
tail -n 1 /var/log/oblivai-update.log
echo ""
echo "Next Update:"
sudo systemctl list-timers | grep oblivai
echo ""
echo "Current Git Commit:"
cd /var/www/oblivai && git rev-parse --short HEAD
echo "==========================="
```

Make executable:
```bash
sudo chmod +x /usr/local/bin/oblivai-status.sh

# Run it
oblivai-status.sh
```

---

## Summary

**Recommended Setup (Debian/Ubuntu):**
- ✅ Persistent .onion address
- ✅ Auto-updates every 15 minutes
- ✅ Reliable uptime
- ✅ Professional hosting
- ✅ Easy monitoring

**Tails Setup:**
- ⚠️ Manual intervention required after each boot
- ⚠️ No reliable auto-updates
- ⚠️ Not suitable for production
- ⚠️ Only use for testing/development

**Next Steps:**
1. Follow Option 1 (Debian/Ubuntu) setup
2. Save your .onion address
3. Test the site in Tor Browser
4. Verify auto-updates work (check logs after 15 minutes)
5. Share your .onion address (if desired)

**Your OBLIVAI .onion site will now:**
- Auto-update from git every 15 minutes
- Maintain privacy (no logs, no tracking)
- Run reliably 24/7
- Preserve your .onion address permanently
