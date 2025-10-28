# OBLIVAI Qubes OS Setup Guide

**Complete guide for deploying OBLIVAI on Qubes OS with minimal manual input.**

## 🎯 Quick Start (Minimal Manual Steps)

### Step 1: Create Standalone Debian VM (in dom0)

```bash
# Open dom0 terminal (Qubes menu → System Tools → Xfce Terminal)

# Create standalone Debian VM for OBLIVAI
qvm-create oblivai-onion --class StandaloneVM --label purple

# Allocate resources (adjust for your hardware)
qvm-prefs oblivai-onion vcpus 4        # 4 CPU cores (use 6 if available)
qvm-prefs oblivai-onion memory 4000    # 4GB RAM
qvm-prefs oblivai-onion maxmem 4000    # Max 4GB
qvm-prefs oblivai-onion netvm sys-firewall  # Network access

# Optional: Increase disk if needed
qvm-volume resize oblivai-onion:private 20G

# Start the VM
qvm-start oblivai-onion
```

### Step 2: Inside the VM - ONE COMMAND SETUP

Open terminal in `oblivai-onion` VM and run:

```bash
# ONE COMMAND - Does everything!
curl -fsSL https://raw.githubusercontent.com/eligorelick/OblivPUBLIC/main/deployment-scripts/deploy-complete.sh | bash
```

**OR** if you want to review first:

```bash
# Clone repository
git clone https://github.com/eligorelick/OblivPUBLIC.git ~/OblivPUBLIC
cd ~/OblivPUBLIC

# Run pre-flight check
bash deployment-scripts/pre-flight-check.sh

# Generate vanity .onion (takes hours - optional)
bash deployment-scripts/1-generate-vanity-onion.sh oblivai

# Deploy everything
bash deployment-scripts/deploy-complete.sh

# Verify
bash deployment-scripts/verify-everything.sh
```

**That's it!** Your .onion site is live.

---

## 📋 What Gets Automatically Configured

### ✅ Services
- [x] Tor hidden service (oblivai-tor.service)
- [x] Nginx web server
- [x] Auto-start on boot
- [x] Automatic restart on failure

### ✅ AI Features
- [x] All 15 AI models available
- [x] HuggingFace CDN whitelisted
- [x] WebGPU/WASM support
- [x] Model downloads over Tor
- [x] 100% local inference

### ✅ Security
- [x] Content Security Policy headers
- [x] CORS headers for WebGPU
- [x] Hidden service encryption
- [x] No external tracking
- [x] No data collection

### ✅ Features
- [x] Dark/Light mode
- [x] Custom system instructions
- [x] Chat export
- [x] Auto-delete chats
- [x] PWA installation
- [x] Offline mode

---

## 🔧 Detailed Setup (Manual Control)

If you prefer step-by-step control:

### 1. VM Creation (dom0)

```bash
# Basic VM
qvm-create oblivai-onion --class StandaloneVM --label purple

# Minimum specs
qvm-prefs oblivai-onion vcpus 2
qvm-prefs oblivai-onion memory 2000
qvm-prefs oblivai-onion netvm sys-firewall

# Recommended specs (better performance)
qvm-prefs oblivai-onion vcpus 4        # More cores = faster vanity generation
qvm-prefs oblivai-onion memory 4000    # More RAM = smoother operation
qvm-prefs oblivai-onion maxmem 4000

# Start VM
qvm-start oblivai-onion
```

### 2. Inside VM - Clone Repository

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Clone repository
git clone https://github.com/eligorelick/OblivPUBLIC.git ~/OblivPUBLIC
cd ~/OblivPUBLIC
```

### 3. Pre-Flight Check

```bash
# Run comprehensive validation
bash deployment-scripts/pre-flight-check.sh
```

This checks:
- ✓ System requirements (RAM, disk, CPU)
- ✓ Network connectivity
- ✓ Repository structure
- ✓ All scripts present and valid
- ✓ Dependencies availability
- ✓ Configuration correctness

### 4. Generate Vanity Address (Optional)

```bash
# Generate .onion starting with "oblivai"
# WARNING: Takes 4-24 hours with 4 cores
bash deployment-scripts/1-generate-vanity-onion.sh oblivai

# Or use shorter prefix (faster)
bash deployment-scripts/1-generate-vanity-onion.sh obliv  # Minutes
bash deployment-scripts/1-generate-vanity-onion.sh obli   # Seconds
```

**Tips:**
- Run overnight for 7+ character prefixes
- Press Ctrl+C to stop, run again to resume
- Monitor: `watch -n 5 'ls -lh ~/oblivai-onion-keys/'`

### 5. Deploy Site

```bash
# Complete deployment (works with or without vanity keys)
bash deployment-scripts/deploy-complete.sh
```

This automatically:
- ✓ Installs all dependencies (Tor, nginx, Node.js)
- ✓ Configures Tor hidden service
- ✓ Builds OBLIVAI
- ✓ Configures nginx with security headers
- ✓ Starts all services
- ✓ Enables auto-start on boot

### 6. Verify Everything Works

```bash
# Run comprehensive tests
bash deployment-scripts/verify-everything.sh
```

Expected output:
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

## 💡 Qubes-Specific Tips

### VM Resources

**Minimum (works but slower):**
- 2 CPU cores
- 2GB RAM
- 10GB disk

**Recommended (smooth experience):**
- 4 CPU cores
- 4GB RAM
- 20GB disk

**Optimal (fast vanity generation):**
- 6 CPU cores (use your full CPU)
- 6GB RAM
- 20GB disk

### Adjusting Resources

**In dom0 (while VM is running):**
```bash
# Increase RAM
qvm-prefs oblivai-onion memory 6000
qvm-prefs oblivai-onion maxmem 6000

# Requires restart to apply
qvm-shutdown oblivai-onion
qvm-start oblivai-onion
```

### Network Configuration

**Default setup (recommended):**
- NetVM: sys-firewall
- Allows: HTTPS for npm/git/HuggingFace

**Optional: Restrict to Tor only (advanced):**
```bash
# In dom0
qvm-firewall oblivai-onion reset
qvm-firewall oblivai-onion add action=accept specialtarget=dns
qvm-firewall oblivai-onion add action=accept proto=tcp dstports=443
qvm-firewall oblivai-onion add action=drop
```

### File Transfer (if needed)

**Copy keys between VMs:**
```bash
# In source VM (where keys are)
qvm-copy ~/oblivai-onion-keys

# In dom0, move to destination
qvm-move-to-vm oblivai-onion ~/QubesIncoming/source-vm/oblivai-onion-keys
```

---

## 🔍 Troubleshooting

### Issue: "Cannot connect to network"

**Check in dom0:**
```bash
qvm-prefs oblivai-onion netvm
# Should show: sys-firewall

# If it shows "None":
qvm-prefs oblivai-onion netvm sys-firewall
```

### Issue: "Not enough RAM"

**In dom0:**
```bash
# Check current allocation
qvm-prefs oblivai-onion memory

# Increase it
qvm-prefs oblivai-onion memory 4000
qvm-prefs oblivai-onion maxmem 4000

# Restart VM
qvm-shutdown oblivai-onion
qvm-start oblivai-onion
```

### Issue: "Port 8080 already in use"

**Inside VM:**
```bash
# Find what's using it
sudo lsof -i :8080

# Kill the process
sudo kill -9 <PID>

# Or restart services
sudo systemctl restart nginx
```

### Issue: "Tor won't start"

**Inside VM:**
```bash
# Check logs
sudo journalctl -u oblivai-tor -n 50

# Fix permissions
bash deployment-scripts/fix-permissions.sh

# Restart
sudo systemctl restart oblivai-tor
```

### Issue: "AI models won't load"

**Inside VM:**
```bash
# Verify HuggingFace is allowed
bash deployment-scripts/verify-everything.sh

# Should show:
# ✓ HuggingFace CDN allowed in CSP
# ✓ WASM execution allowed

# If not, redeploy
bash deployment-scripts/deploy-complete.sh
```

---

## 🎓 Understanding Qubes Setup

### Why Standalone VM?

**Standalone VM vs AppVM:**

**Standalone (recommended for .onion hosting):**
- ✓ Persistent storage (keys survive)
- ✓ Full control over system
- ✓ Can customize packages
- ✓ Independent from template
- ✗ Takes more disk space

**AppVM (NOT recommended):**
- ✗ Changes lost on reboot
- ✗ Hidden service keys would be lost
- ✗ Needs persistent bind-dirs setup

### Security Considerations

**The hidden service itself provides anonymity:**
- Your real IP is hidden
- Server location is hidden
- Traffic is encrypted
- No exit nodes involved

**Qubes adds:**
- VM isolation
- Separate network stack
- Resource limitations
- Easy backup/restore

---

## 📊 Feature Matrix

| Feature | Automatic | Manual Steps Required |
|---------|-----------|----------------------|
| Tor installation | ✓ Automatic | None |
| Nginx configuration | ✓ Automatic | None |
| Hidden service setup | ✓ Automatic | None |
| AI model support | ✓ Automatic | None |
| Security headers | ✓ Automatic | None |
| Auto-start on boot | ✓ Automatic | None |
| Vanity address | Semi-auto | Run generation script |
| VM creation | Manual | dom0 commands |
| VM resources | Manual | Adjust qvm-prefs |

---

## 🚀 Production Checklist

Before going live:

- [ ] VM created with adequate resources
- [ ] Pre-flight check passed
- [ ] Vanity .onion generated (optional)
- [ ] Deployment completed successfully
- [ ] Verification tests passed
- [ ] Hidden service keys backed up
- [ ] Site accessible via Tor Browser
- [ ] AI model loads successfully
- [ ] Chat functionality works
- [ ] Services auto-start on reboot

**Backup your keys:**
```bash
# Inside VM
sudo cp -r /var/lib/tor/oblivai ~/oblivai-keys-backup
tar -czf oblivai-keys-$(date +%Y%m%d).tar.gz ~/oblivai-keys-backup/

# Copy to dom0 for safekeeping
qvm-copy oblivai-keys-*.tar.gz
```

---

## 📞 Support

**Scripts provided:**
- `pre-flight-check.sh` - Validate before deployment
- `deploy-complete.sh` - One-command deployment
- `verify-everything.sh` - Test all functionality
- `status.sh` - Quick status check
- `fix-permissions.sh` - Repair permission issues

**Common commands:**
```bash
# Check status
bash deployment-scripts/status.sh

# View logs
sudo journalctl -u oblivai-tor -f

# Restart services
sudo systemctl restart oblivai-tor nginx

# Get .onion address
sudo cat /var/lib/tor/oblivai/hostname
```

---

**All scripts are designed for minimal manual intervention on Qubes OS!**
