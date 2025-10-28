# Enable GPU Acceleration (RTX 4050, etc.)

Your browser needs **WebGPU** enabled to use your RTX 4050 GPU for AI inference.

---

## ✅ How to Enable WebGPU in Chrome/Edge

### Step 1: Open Chrome Flags
1. Type `chrome://flags` in the address bar
2. Press Enter

### Step 2: Enable WebGPU
1. Search for "**WebGPU**" in the search box
2. Find "**Unsafe WebGPU**" flag
3. Change from "**Default**" to "**Enabled**"
4. Find "**WebGPU Developer Features**" (optional but recommended)
5. Change from "**Default**" to "**Enabled**"

### Step 3: Restart Browser
1. Click the "**Relaunch**" button that appears at the bottom
2. Chrome will restart with WebGPU enabled

---

## ✅ Verify GPU is Working

After enabling WebGPU and restarting:

### 1. Check WebGPU Status
1. Go to `chrome://gpu`
2. Look for "**WebGPU**" section
3. Should show "**WebGPU: Hardware accelerated**"
4. Should show your GPU: "**NVIDIA GeForce RTX 4050**"

### 2. Check OBLIVAI Console
1. Open browser console (F12)
2. Load a model
3. Look for these messages:
   ```
   ✓ WebGPU available - will use GPU acceleration
   GPU detected: NVIDIA GeForce RTX 4050
   ✓ Desktop GPU detected - using WebGPU for maximum performance
   ```

---

## 🚫 If WebGPU Still Doesn't Work

### Try These:

1. **Update Graphics Drivers**
   - Go to NVIDIA website
   - Download latest RTX 4050 drivers
   - Restart computer

2. **Update Chrome/Edge**
   - Go to `chrome://settings/help`
   - Install any available updates
   - Restart browser

3. **Check Windows Graphics Settings**
   - Open "Graphics Settings" in Windows
   - Add Chrome to high performance apps
   - Set Chrome to use NVIDIA GPU (not integrated)

4. **Disable Hardware Scheduling (rare fix)**
   - Windows Settings → Display → Graphics Settings
   - Turn OFF "Hardware-accelerated GPU scheduling"
   - Restart computer

---

## 📊 Performance Comparison

With your **RTX 4050**, you should see:

| Backend | Speed | RAM Usage | GPU Usage |
|---------|-------|-----------|-----------|
| **WebGPU (RTX 4050)** | **10-50x faster** | **Low** | **90-100%** |
| WebGL (fallback) | 2-5x slower | Medium | 50-70% |
| CPU (no GPU) | Very slow | High | 0% |

---

## 💡 Tips

- **First model load** will be slower (downloading + compiling shaders)
- **Second load** will be instant (cached)
- **Larger models** (7B, 8B) will really benefit from RTX 4050
- **Monitor GPU usage** in Task Manager → Performance → GPU

---

## ❓ Still Having Issues?

Check browser console (F12) for error messages:
- `WebGPU not available` = WebGPU flag not enabled
- `adapter not available` = Driver issue
- `Access denied` = Browser security blocking GPU

---

**Your RTX 4050 should give you excellent performance once WebGPU is enabled!** 🚀
