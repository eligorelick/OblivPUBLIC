# OBLIVAI Deployment Scripts

Complete set of scripts for deploying OBLIVAI on Tor hidden service.

## 🚀 Quick Start

### For New Setup (No Keys Yet)

```bash
# STEP 1: Generate vanity .onion address (takes 4-24 hours)
bash 1-generate-vanity-onion.sh oblivai

# STEP 2: Deploy the site (after generation completes)
bash 2-deploy-onion-site.sh
```

### For Complete Setup (One Command)

If you already have keys OR want everything automated:

```bash
# Does everything in one go
bash deploy-complete.sh
```

---

## 📜 Available Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `1-generate-vanity-onion.sh` | Generate vanity .onion address | First time setup, want custom address |
| `2-deploy-onion-site.sh` | Deploy site with existing keys | After generation completes |
| `deploy-complete.sh` | **Complete deployment** | **Recommended - does everything** |
| `generate-vanity-onion.sh` | Generate + deploy (all-in-one) | Legacy - use deploy-complete.sh instead |
| `verify-everything.sh` | Test all functionality | After deployment, troubleshooting |
| `status.sh` | Quick status dashboard | Check if everything is running |
| `fix-permissions.sh` | Fix permission issues | Troubleshooting |

---

## 🎯 Recommended Workflow

### First Time Setup

```bash
# 1. Generate vanity address (run overnight)
bash 1-generate-vanity-onion.sh oblivai

# 2. Deploy site (after keys are generated)
bash deploy-complete.sh

# 3. Verify everything works
bash verify-everything.sh

# 4. Check status anytime
bash status.sh
```

### Already Have Keys

```bash
# Just deploy
bash deploy-complete.sh

# Verify
bash verify-everything.sh
```

---

## 📋 Script Details

### `deploy-complete.sh` ⭐ RECOMMENDED

**Complete all-in-one deployment script**

**What it does:**
- ✅ Checks for existing vanity keys
- ✅ Installs all dependencies (Tor, nginx, Node.js)
- ✅ Creates custom Tor service (fixes multi-instance issues)
- ✅ Configures hidden service
- ✅ Builds OBLIVAI
- ✅ Configures nginx
- ✅ Starts all services
- ✅ Verifies everything works

**Usage:**
```bash
bash deploy-complete.sh
```

**Time:** ~5 minutes (if keys already exist)

---

### `1-generate-vanity-onion.sh`

**Generate vanity .onion address only**

**What it does:**
- Installs mkp224o vanity generator
- Generates .onion starting with your prefix
- Saves keys to `~/oblivai-onion-keys/`
- Can be stopped/restarted (Ctrl+C)

**Usage:**
```bash
# Generate address starting with "oblivai"
bash 1-generate-vanity-onion.sh oblivai

# Or use shorter prefix (faster)
bash 1-generate-vanity-onion.sh obliv
```

**Time:**
- 4 chars (obli): Seconds
- 5 chars (obliv): Minutes
- 6 chars (obliva): Hours
- 7 chars (oblivai): 4-24 hours
- 8+ chars: Days to weeks

**Tips:**
- Run overnight for 7+ character prefixes
- Press Ctrl+C to stop, run again to resume
- Uses all available CPU cores

---

### `2-deploy-onion-site.sh`

**Deploy site with existing keys**

**Prerequisites:**
- Keys must exist in `~/oblivai-onion-keys/`

**What it does:**
- Uses pre-generated keys
- Installs Tor and nginx
- Configures hidden service
- Builds OBLIVAI
- Starts services

**Usage:**
```bash
bash 2-deploy-onion-site.sh
```

**Time:** ~5 minutes

---

### `verify-everything.sh`

**Comprehensive functionality test**

**What it tests:**
- ✅ Service status (Tor, nginx)
- ✅ Hidden service configuration
- ✅ Nginx configuration
- ✅ Local site access (HTTP 200)
- ✅ Security headers (CSP, CORS)
- ✅ HuggingFace CDN allowed (AI models)
- ✅ WASM support (required for AI)
- ✅ Application files exist
- ✅ Auto-start on boot configured

**Usage:**
```bash
bash verify-everything.sh
```

**Output:**
```
✓ ALL TESTS PASSED!

Your OBLIVAI .onion site is fully functional!

What works:
  ✓ Hidden service hosting
  ✓ Automatic startup on boot
  ✓ AI model downloads from HuggingFace
  ✓ WebGPU/WASM support
  ✓ All 15 AI models available
  ✓ Security headers configured
  ✓ PWA support (offline mode)
```

---

### `status.sh`

**Quick status dashboard**

**What it shows:**
- Your .onion address
- Service status (running/stopped)
- Auto-start configuration
- Local site accessibility
- System uptime
- Recent activity

**Usage:**
```bash
bash status.sh
```

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  OBLIVAI Status Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Your .onion address:
  http://oblivaiXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.onion

Services:
  Tor:   ● Running
  Nginx: ● Running

Auto-start on boot:
  Tor:   ✓ Enabled
  Nginx: ✓ Enabled

Local site access:
  ✓ Site accessible (HTTP 200)
```

---

### `fix-permissions.sh`

**Fix common permission issues**

**What it fixes:**
- Tor directory permissions
- Hidden service key permissions
- Nginx file permissions
- Service ownership

**Usage:**
```bash
bash fix-permissions.sh
```

**When to use:**
- After manually copying files
- If Tor won't start
- If nginx can't read files
- Troubleshooting permission errors

---

## 🔧 Troubleshooting

### Issue: Tor won't start

```bash
# Check logs
sudo journalctl -u oblivai-tor -n 50

# Fix permissions
bash fix-permissions.sh

# Restart
sudo systemctl restart oblivai-tor
```

### Issue: Site not accessible

```bash
# Check status
bash status.sh

# Verify everything
bash verify-everything.sh

# Check nginx logs
sudo tail -f /var/log/nginx/oblivai-error.log
```

### Issue: AI models won't load

```bash
# Verify HuggingFace is allowed
bash verify-everything.sh

# Should show:
# ✓ HuggingFace CDN allowed in CSP
# ✓ WASM execution allowed
```

### Issue: Services won't auto-start on boot

```bash
# Enable auto-start
sudo systemctl enable oblivai-tor
sudo systemctl enable nginx

# Verify
bash status.sh
```

---

## 📊 What Each Feature Needs

### ✅ Hidden Service Hosting
- **Required:** Tor service, hidden service keys
- **Script:** `deploy-complete.sh`
- **Verify:** `bash status.sh`

### ✅ AI Model Downloads
- **Required:** CSP header allowing HuggingFace
- **Script:** `deploy-complete.sh` (configures nginx with correct headers)
- **Verify:** `bash verify-everything.sh` → Check "HuggingFace CDN allowed"

### ✅ WebGPU/WASM Support
- **Required:** CSP with `wasm-unsafe-eval`, CORS headers
- **Script:** `deploy-complete.sh` (nginx configured correctly)
- **Verify:** `bash verify-everything.sh` → Check "WASM execution allowed"

### ✅ All 15 AI Models
- **Required:** HuggingFace CDN access, WASM support
- **Script:** `deploy-complete.sh`
- **Verify:** Visit site, check model selector

### ✅ PWA (Offline Mode)
- **Required:** Service worker, manifest.json
- **Script:** `deploy-complete.sh` (builds from source)
- **Verify:** Visit site, check for "Install App" prompt

### ✅ Auto-Start on Boot
- **Required:** Systemd services enabled
- **Script:** `deploy-complete.sh` (auto-enables services)
- **Verify:** `bash status.sh` → Check "Auto-start on boot"

---

## 🎓 Understanding the Setup

### Services Created

**`oblivai-tor.service`**
- Custom Tor systemd service
- Runs as `debian-tor` user
- Loads config from `/etc/tor/torrc`
- Auto-restarts on failure
- Enabled for auto-start

**`nginx.service`**
- Standard nginx service
- Serves site on `127.0.0.1:8080`
- Security headers configured
- Auto-starts on boot

### File Locations

| Item | Location |
|------|----------|
| Tor keys | `/var/lib/tor/oblivai/` |
| .onion address | `/var/lib/tor/oblivai/hostname` |
| Tor config | `/etc/tor/torrc` |
| Nginx config | `/etc/nginx/sites-available/oblivai` |
| Nginx enabled | `/etc/nginx/sites-enabled/oblivai` |
| Built site | `~/OblivPUBLIC/dist/` |
| Source code | `~/OblivPUBLIC/` |
| Generated keys | `~/oblivai-onion-keys/` |
| Tor logs | `sudo journalctl -u oblivai-tor` |
| Nginx logs | `/var/log/nginx/oblivai-*.log` |

### Ports

| Port | Service | Access |
|------|---------|--------|
| 8080 | Nginx | Localhost only |
| 80 (Tor) | Hidden service | Via .onion address |
| 9050 | Tor SOCKS | Localhost (for Tor clients) |

---

## 🎯 Feature Checklist

After running `deploy-complete.sh` and `verify-everything.sh`, you should have:

- [x] Tor hidden service running
- [x] Vanity .onion address (oblivai...)
- [x] Nginx serving site
- [x] Auto-start on boot configured
- [x] Security headers (CSP, CORS, etc.)
- [x] HuggingFace CDN allowed (AI models)
- [x] WASM execution enabled (AI inference)
- [x] All 15 AI models available
- [x] WebGPU/WebGL support
- [x] PWA support (offline mode)
- [x] Service worker caching
- [x] Local-only AI inference
- [x] No data collection
- [x] No external tracking

---

## 💡 Tips

### Faster Vanity Generation
- Use more CPU cores (allocate 4-6 in Qubes)
- Use shorter prefixes (5-6 chars instead of 7)
- Run overnight for 7+ character prefixes

### Monitoring
- Use `bash status.sh` for quick checks
- Use `watch -n 5 'bash status.sh'` for live monitoring
- Check logs: `sudo journalctl -u oblivai-tor -f`

### Updates
```bash
cd ~/OblivPUBLIC
git pull
npm install
npm run build
sudo systemctl reload nginx
```

### Backup Keys
```bash
# Backup your .onion address keys (CRITICAL!)
sudo cp -r /var/lib/tor/oblivai ~/oblivai-keys-backup
sudo chown -R $USER:$USER ~/oblivai-keys-backup

# Backup to archive
tar -czf oblivai-keys-$(date +%Y%m%d).tar.gz ~/oblivai-keys-backup/
```

### Performance
- Models download slower over Tor (this is normal)
- Start with small models (Qwen2 1.5B, Llama 3.2 1B)
- Larger models work but take longer to download
- Once downloaded, models are cached locally

---

## 🆘 Need Help?

1. **Run verification:** `bash verify-everything.sh`
2. **Check status:** `bash status.sh`
3. **View logs:** `sudo journalctl -u oblivai-tor -n 50`
4. **Check issues:** [GitHub Issues](https://github.com/eligorelick/OblivPUBLIC/issues)

---

**All scripts are designed to be idempotent** - safe to run multiple times!
