# OBLIVAI Whonix Workstation Setup Guide

Complete guide for generating a vanity .onion address starting with "OblivAi" and deploying OBLIVAI on Qubes Whonix Workstation.

## 🎯 Quick Start

### Prerequisites
- Qubes OS with Whonix Workstation VM
- At least 2GB RAM allocated to Whonix Workstation
- 10GB free disk space
- Tor Browser for testing

### Two-Step Setup (Recommended)

The setup is split into two scripts because vanity generation can take hours:

**STEP 1: Generate vanity .onion address** (may take 4-24 hours for "oblivai")

```bash
# Clone repository
git clone https://github.com/eligorelick/OblivPUBLIC.git ~/oblivai
cd ~/oblivai

# Generate vanity address (can run overnight)
bash deployment-scripts/1-generate-vanity-onion.sh oblivai
```

**STEP 2: Deploy the site** (takes ~5 minutes)

```bash
# After generation completes, deploy the site
bash deployment-scripts/2-deploy-onion-site.sh
```

**That's it!** Your .onion site will be live.

### Alternative: All-in-One Setup

If you want everything automated in one script:

```bash
# This does BOTH generation and deployment
bash deployment-scripts/generate-vanity-onion.sh oblivai
```

Note: This will block for hours during generation.

---

## 📜 Understanding the Scripts

### Why Two Scripts?

**Script 1: `1-generate-vanity-onion.sh`**
- ONLY generates the vanity .onion address
- Can take **4-24 hours** for a 7-character prefix like "oblivai"
- You can run this overnight
- You can stop and restart it (press Ctrl+C to stop)
- Keys are saved to `~/oblivai-onion-keys/`

**Script 2: `2-deploy-onion-site.sh`**
- Takes the generated keys and deploys your site
- Only takes **~5 minutes**
- Installs Tor, nginx, builds OBLIVAI
- Configures everything automatically
- Your .onion site goes live

### What Each Script Does

#### Script 1: Generation
```
┌─────────────────────────────────────┐
│ 1-generate-vanity-onion.sh          │
├─────────────────────────────────────┤
│ 1. Install mkp224o dependencies     │
│ 2. Build mkp224o vanity generator   │
│ 3. Generate .onion starting with    │
│    your prefix (TAKES HOURS)        │
│ 4. Save keys to ~/oblivai-onion-keys/│
└─────────────────────────────────────┘
```

#### Script 2: Deployment
```
┌─────────────────────────────────────┐
│ 2-deploy-onion-site.sh              │
├─────────────────────────────────────┤
│ 1. Install Tor and nginx            │
│ 2. Copy keys to Tor directory       │
│ 3. Configure Tor hidden service     │
│ 4. Build OBLIVAI (npm run build)    │
│ 5. Configure nginx                  │
│ 6. Start services → Site goes live  │
└─────────────────────────────────────┘
```

### When to Use All-in-One Script

Use `generate-vanity-onion.sh` (all-in-one) if:
- You want to set it and forget it
- You're okay waiting hours without interaction
- You don't need to stop/restart generation

### Script Options Summary

| Script | Purpose | Time | Best For |
|--------|---------|------|----------|
| `1-generate-vanity-onion.sh` | Generate .onion only | 4-24 hours | Run overnight, then deploy later |
| `2-deploy-onion-site.sh` | Deploy with existing keys | ~5 mins | After generation completes |
| `generate-vanity-onion.sh` | Both generation + deployment | 4-24+ hours | Set and forget |

**Recommendation:** Use Scripts 1 & 2 for better control and flexibility.

---

## 📖 Detailed Setup Guide

### Step 1: Prepare Whonix Workstation

#### 1.1 Update System

```bash
# Update package list
sudo apt update

# Upgrade existing packages (optional but recommended)
sudo apt upgrade -y
```

#### 1.2 Clone OBLIVAI Repository

```bash
# Clone to home directory
cd ~
git clone https://github.com/eligorelick/OblivPUBLIC.git oblivai
cd oblivai
```

### Step 2: Generate Vanity .onion Address

The script uses **mkp224o**, a fast vanity address generator for Tor v3 hidden services.

#### 2.1 Run Generator Script

```bash
# Generate address starting with "oblivai" (default)
bash deployment-scripts/generate-vanity-onion.sh

# Or specify custom prefix
bash deployment-scripts/generate-vanity-onion.sh oblivai1
bash deployment-scripts/generate-vanity-onion.sh oblivprivacy
```

#### 2.2 Expected Generation Times

| Prefix Length | Characters | Estimated Time (4 cores) |
|---------------|------------|--------------------------|
| 4 characters  | obli       | Seconds                  |
| 5 characters  | obliv      | Minutes                  |
| 6 characters  | obliva     | Hours                    |
| 7 characters  | oblivai    | **Hours to Days**        |
| 8 characters  | oblivaix   | Days to Weeks            |

**Note:** The script uses all available CPU cores to maximize speed. On Whonix with 4 cores, "oblivai" (7 chars) typically takes **4-24 hours**.

#### 2.3 What the Script Does

1. **Installs dependencies:**
   - gcc, libc6-dev (C compiler)
   - libsodium-dev (cryptography library)
   - mkp224o (vanity address generator)
   - Tor, nginx (web server)

2. **Builds mkp224o:**
   - Clones from GitHub
   - Compiles optimized binary
   - Configures for maximum performance

3. **Generates vanity address:**
   - Searches for .onion starting with your prefix
   - Uses all CPU cores (parallel generation)
   - Stops automatically when found

4. **Configures Tor:**
   - Copies generated keys to `/var/lib/tor/oblivai/`
   - Updates `/etc/tor/torrc`
   - Restarts Tor service

5. **Builds OBLIVAI:**
   - Installs Node.js dependencies
   - Compiles production build
   - Outputs to `dist/` directory

6. **Configures nginx:**
   - Sets up reverse proxy on `127.0.0.1:8080`
   - Adds security headers
   - Enables Tor-compatible CSP

### Step 3: Access Your .onion Site

```bash
# Get your .onion address
sudo cat /var/lib/tor/oblivai/hostname
```

Example output:
```
oblivai7x3j2k4m5n6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2.onion
```

#### 3.1 Test in Tor Browser

1. Open **Tor Browser** (on Qubes host or another VM)
2. Visit your `.onion` address (e.g., `http://oblivai...onion`)
3. OBLIVAI should load
4. Select an AI model and test chat functionality

---

## 🔧 Manual Configuration (Advanced)

If you want to customize the setup or understand the process better:

### Manual Step 1: Install Dependencies

```bash
# Update system
sudo apt update

# Install build tools
sudo apt install -y gcc libc6-dev libsodium-dev make autoconf git

# Install Tor and nginx
sudo apt install -y tor nginx

# Install Node.js (if not already installed)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

### Manual Step 2: Build mkp224o

```bash
# Clone mkp224o repository
git clone https://github.com/cathugger/mkp224o.git ~/mkp224o
cd ~/mkp224o

# Build
./autogen.sh
./configure
make -j$(nproc)

# Verify build
./mkp224o -h
```

### Manual Step 3: Generate Vanity Address

```bash
# Create output directory
mkdir -p ~/onion-keys

# Generate address starting with "oblivai"
# -d: output directory
# -t: number of threads (use all cores)
# -v: verbose output
# oblivai: prefix to search for
~/mkp224o/mkp224o -d ~/onion-keys -t $(nproc) -v oblivai
```

**This will run until an address is found.** Press `Ctrl+C` to stop early.

When found, you'll see output like:
```
>oblivai7x3j2k4m5n6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2.onion
```

The keys are saved in `~/onion-keys/oblivai.../`

### Manual Step 4: Configure Tor

```bash
# Create Tor hidden service directory
sudo mkdir -p /var/lib/tor/oblivai

# Copy generated keys (replace with your actual directory name)
ONION_DIR=$(find ~/onion-keys -type d -name "oblivai*" | head -n 1)
sudo cp -r "$ONION_DIR"/* /var/lib/tor/oblivai/

# Set correct permissions
sudo chown -R debian-tor:debian-tor /var/lib/tor/oblivai
sudo chmod 700 /var/lib/tor/oblivai
sudo chmod 600 /var/lib/tor/oblivai/*

# Edit Tor configuration
sudo nano /etc/tor/torrc
```

Add these lines to `/etc/tor/torrc`:
```
# OBLIVAI Hidden Service
HiddenServiceDir /var/lib/tor/oblivai/
HiddenServicePort 80 127.0.0.1:8080
```

Save and exit (`Ctrl+O`, `Enter`, `Ctrl+X`).

```bash
# Restart Tor
sudo systemctl restart tor

# Wait a few seconds
sleep 5

# Get your .onion address
sudo cat /var/lib/tor/oblivai/hostname
```

### Manual Step 5: Build OBLIVAI

```bash
# Clone repository (if not already done)
git clone https://github.com/eligorelick/OblivPUBLIC.git ~/oblivai
cd ~/oblivai

# Install dependencies
npm install

# Build for production
npm run build

# Verify build
ls -lh dist/
```

### Manual Step 6: Configure Nginx

```bash
# Create nginx configuration
sudo nano /etc/nginx/sites-available/oblivai
```

Paste this configuration:
```nginx
server {
    listen 127.0.0.1:8080;
    server_name localhost;

    # IMPORTANT: Update this path to your actual home directory
    root /home/user/oblivai/dist;
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
```

**Replace `/home/user/oblivai/dist` with your actual path!**

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/oblivai /etc/nginx/sites-enabled/oblivai

# Remove default site (optional)
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Restart nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

# Check status
sudo systemctl status nginx
```

---

## 🧪 Testing & Verification

### Test 1: Check Services Running

```bash
# Check Tor
sudo systemctl status tor
# Should show "active (running)"

# Check nginx
sudo systemctl status nginx
# Should show "active (running)"

# Check nginx can access site
curl -I http://127.0.0.1:8080
# Should return "200 OK"
```

### Test 2: Verify .onion Address

```bash
# Get your .onion address
ONION=$(sudo cat /var/lib/tor/oblivai/hostname)
echo "Your .onion address: http://$ONION"
```

### Test 3: Access from Tor Browser

1. Open Tor Browser
2. Visit your `.onion` address
3. OBLIVAI should load (may take 10-30 seconds first time)
4. Click "Start Chat"
5. Select a model (recommend: Qwen2 1.5B for testing)
6. Wait for model download (over Tor, may be slow)
7. Send a test message

**Expected behavior:**
- Site loads correctly
- Model downloads (slowly over Tor)
- AI responds to messages
- All inference happens in browser

---

## 🔒 Security & Privacy

### Backup Your Keys

**CRITICAL:** Your .onion address is tied to cryptographic keys. If you lose them, you lose your address.

```bash
# Backup keys
sudo cp -r /var/lib/tor/oblivai/ ~/oblivai-keys-backup/
sudo chown -R $USER:$USER ~/oblivai-keys-backup/
chmod 700 ~/oblivai-keys-backup/

# Compress for storage
tar -czf oblivai-keys-$(date +%Y%m%d).tar.gz ~/oblivai-keys-backup/

# Copy to another VM or secure storage
# Example: Transfer to dom0 vault
qvm-copy oblivai-keys-*.tar.gz
```

### Restore Keys

If you need to restore your .onion address:

```bash
# Stop Tor
sudo systemctl stop tor

# Remove existing keys
sudo rm -rf /var/lib/tor/oblivai/

# Restore from backup
sudo cp -r ~/oblivai-keys-backup/ /var/lib/tor/oblivai/

# Fix permissions
sudo chown -R debian-tor:debian-tor /var/lib/tor/oblivai
sudo chmod 700 /var/lib/tor/oblivai
sudo chmod 600 /var/lib/tor/oblivai/*

# Restart Tor
sudo systemctl restart tor

# Verify address
sudo cat /var/lib/tor/oblivai/hostname
```

### Monitor Access Logs

```bash
# Watch nginx access logs (see who's visiting)
sudo tail -f /var/log/nginx/oblivai-access.log

# Watch nginx error logs (troubleshooting)
sudo tail -f /var/log/nginx/oblivai-error.log

# Watch Tor logs
sudo journalctl -u tor -f
```

### Disable Access Logs (Max Privacy)

If you don't want any access logs:

```bash
# Edit nginx config
sudo nano /etc/nginx/sites-available/oblivai

# Change these lines:
# access_log /var/log/nginx/oblivai-access.log;
# error_log /var/log/nginx/oblivai-error.log;

# To:
access_log off;
error_log /var/log/nginx/oblivai-error.log;

# Restart nginx
sudo systemctl restart nginx
```

---

## 🚀 Updating OBLIVAI

### Manual Update

```bash
# Navigate to app directory
cd ~/oblivai

# Pull latest changes
git pull origin main

# Rebuild
npm install
npm run build

# Restart nginx (optional, usually not needed for static sites)
sudo systemctl reload nginx

# Verify update
curl -I http://127.0.0.1:8080
```

### Automatic Updates (Optional)

If you want automatic updates like the Debian setup:

```bash
# Create update script
nano ~/update-oblivai.sh
```

Paste:
```bash
#!/bin/bash
cd ~/oblivai
git pull origin main
npm install
npm run build
```

Make executable:
```bash
chmod +x ~/update-oblivai.sh

# Run manually
~/update-oblivai.sh
```

---

## 🛠️ Troubleshooting

### Problem: mkp224o compilation fails

```bash
# Install missing dependencies
sudo apt install -y build-essential autoconf libsodium-dev

# Try again
cd ~/mkp224o
make clean
./autogen.sh
./configure
make -j$(nproc)
```

### Problem: "address already in use" (nginx)

```bash
# Check what's using port 8080
sudo lsof -i :8080

# Kill the process (replace PID)
sudo kill -9 PID

# Or change nginx to different port
sudo nano /etc/nginx/sites-available/oblivai
# Change: listen 127.0.0.1:8080; to listen 127.0.0.1:8081;
# Also update torrc:
sudo nano /etc/tor/torrc
# Change: HiddenServicePort 80 127.0.0.1:8080 to 127.0.0.1:8081

sudo systemctl restart tor nginx
```

### Problem: .onion address not accessible

```bash
# Check Tor is running
sudo systemctl status tor

# Check nginx is running
sudo systemctl status nginx

# Check local access works
curl http://127.0.0.1:8080

# Check Tor logs for errors
sudo journalctl -u tor -n 50

# Restart both services
sudo systemctl restart tor nginx

# Wait 30 seconds and try again
```

### Problem: Model won't load over Tor

**This is normal!** Model downloads over Tor are very slow (10-100x slower than clearnet).

**Solutions:**
1. **Use smaller models:** Qwen2 0.5B (945MB) or Llama 3.2 1B (879MB)
2. **Be patient:** Large models may take 30-60 minutes to download
3. **Test locally first:** Use `http://127.0.0.1:8080` in Firefox to verify models work
4. **Pre-download models:** Visit clearnet OBLIVAI first, download models, then export/import browser cache

### Problem: Site loads but shows blank page

```bash
# Check nginx error logs
sudo tail -f /var/log/nginx/oblivai-error.log

# Check if dist/ directory exists and has files
ls -lh ~/oblivai/dist/

# Rebuild if empty
cd ~/oblivai
npm run build
sudo systemctl reload nginx
```

### Problem: vanity generation taking too long

**Options:**
1. **Use shorter prefix:** `obli` (4 chars) instead of `oblivai` (7 chars)
2. **Add more CPU cores:** Increase Whonix VM CPU allocation in Qubes settings
3. **Run overnight:** 7-character prefixes can take 4-24 hours on average hardware
4. **Accept partial match:** Stop mkp224o early if you get `oblivaiX...` where X is different

---

## 📊 Performance Tips

### Optimize Whonix for Faster Generation

```bash
# Allocate more RAM to Whonix Workstation (in Qubes settings)
# Recommended: 4GB+ for vanity generation

# Allocate more CPU cores (in Qubes settings)
# Recommended: 4+ cores for faster generation
```

### Speed Up Model Downloads

**Option 1: Pre-download on clearnet**
1. Visit `https://oblivai.netlify.app` (or your clearnet instance)
2. Download desired models
3. Export browser storage (IndexedDB)
4. Import to Tor Browser

**Option 2: Use smaller models**
- Tiny tier: 500MB-1GB (fast download even over Tor)
- Small tier: 1-2GB (acceptable download time)
- Avoid: 4GB+ models over Tor

---

## 📋 Quick Reference

### Common Commands

```bash
# Get .onion address
sudo cat /var/lib/tor/oblivai/hostname

# Restart Tor
sudo systemctl restart tor

# Restart nginx
sudo systemctl restart nginx

# Check service status
sudo systemctl status tor nginx

# View logs
sudo tail -f /var/log/nginx/oblivai-access.log
sudo journalctl -u tor -f

# Update OBLIVAI
cd ~/oblivai && git pull && npm install && npm run build

# Test local access
curl http://127.0.0.1:8080
```

### File Locations

| Item | Location |
|------|----------|
| Tor keys | `/var/lib/tor/oblivai/` |
| .onion address | `/var/lib/tor/oblivai/hostname` |
| OBLIVAI source | `~/oblivai/` |
| Built files | `~/oblivai/dist/` |
| Nginx config | `/etc/nginx/sites-available/oblivai` |
| Tor config | `/etc/tor/torrc` |
| nginx logs | `/var/log/nginx/oblivai-*.log` |
| mkp224o | `~/mkp224o/` |
| Generated keys | `~/onion-keys/` |

---

## 🎓 Understanding Vanity Addresses

### What is a vanity .onion address?

A vanity address is a .onion address that starts with specific characters you choose, like `oblivai...`.

**Normal .onion (random):**
```
7x3j2k4m5n6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2.onion
```

**Vanity .onion (custom prefix):**
```
oblivai2k4m5n6p7q8r9s0t1u2v3w4x5y6z7a8b9c0d1e2.onion
```

### How does vanity generation work?

1. **Generate random key pair** → Check if resulting .onion starts with "oblivai"
2. **If no:** Generate another key pair → Check again
3. **If yes:** Save keys and stop
4. **Repeat** millions/billions of times until found

**Why it takes time:**
- 4 chars: ~32 possibilities (instant)
- 5 chars: ~1,024 possibilities (seconds)
- 6 chars: ~32,768 possibilities (minutes)
- 7 chars: ~1 million possibilities (hours)
- 8 chars: ~33 million possibilities (days)

### Is it secure?

**Yes!** Vanity generation only affects the *public* part of the address. The cryptographic security is identical to a random .onion address.

**The keys are generated using:**
- Ed25519 elliptic curve cryptography
- SHA3-256 hashing
- Same security as regular Tor hidden services

---

## 🤝 Support

### Need help?

1. **Check logs first:**
   ```bash
   sudo tail -f /var/log/nginx/oblivai-error.log
   sudo journalctl -u tor -n 50
   ```

2. **Verify services running:**
   ```bash
   sudo systemctl status tor nginx
   ```

3. **Test local access:**
   ```bash
   curl http://127.0.0.1:8080
   ```

4. **GitHub Issues:**
   - [OblivPUBLIC Issues](https://github.com/eligorelick/OblivPUBLIC/issues)

### Common Error Messages

| Error | Solution |
|-------|----------|
| "bind: address already in use" | Port 8080 taken, change nginx port or kill process |
| "permission denied" | Missing sudo, check file permissions |
| "connection refused" | Service not running, check `systemctl status` |
| "hostname not found" | Tor not configured, check `/etc/tor/torrc` |
| "WASM compilation failed" | Browser too old, update Tor Browser |

---

## 🎉 Conclusion

You now have:
- ✅ Vanity .onion address starting with "oblivai"
- ✅ Tor hidden service running 24/7
- ✅ OBLIVAI AI chat with 100% browser-based privacy
- ✅ Accessible via Tor Browser
- ✅ No clearnet exposure

**Your setup provides:**
- **Anonymity:** Hidden service conceals server location
- **Privacy:** All AI inference runs in user's browser
- **Security:** No user data sent to servers (none exist!)
- **Accessibility:** Anyone with Tor Browser can access

**Enjoy your privacy-focused AI chat on the Tor network!** 🎊
