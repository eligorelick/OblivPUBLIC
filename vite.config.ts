import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  optimizeDeps: {
    exclude: ['@mlc-ai/web-llm']
  },
  build: {
    target: 'esnext',
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true,
        pure_funcs: ['console.log', 'console.warn']
      }
    },
    rollupOptions: {
      output: {
        manualChunks: {
          'webllm': ['@mlc-ai/web-llm'],
          'react-vendor': ['react', 'react-dom'],
          'ui-vendor': ['lucide-react', 'clsx', 'tailwind-merge']
        }
      }
    },
    chunkSizeWarningLimit: 2000
  },
  server: {
    headers: {
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Resource-Policy': 'cross-origin',
      'Content-Security-Policy': "default-src 'self'; " +
        "base-uri 'self'; " +
        "script-src 'self' 'wasm-unsafe-eval' 'unsafe-inline'; " +
        "worker-src 'self' blob:; " +
        "connect-src 'self' https://huggingface.co https://cdn-lfs.huggingface.co https://*.huggingface.co https://*.xethub.hf.co https://raw.githubusercontent.com https://*.githubusercontent.com; " +
        "img-src 'self' data: blob:; " +
        "style-src 'self' 'unsafe-inline'; " +
        "font-src 'self' data:; " +
        "form-action 'none'; " +
        "object-src 'none'; " +
        "media-src 'self'; " +
        "manifest-src 'self';",
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Referrer-Policy': 'no-referrer',
      'Permissions-Policy': 'geolocation=(), microphone=(), camera=(), payment=(), usb=(), magnetometer=(), gyroscope=(), accelerometer=()',
      'Cache-Control': 'no-cache, no-store, must-revalidate, private, max-age=0',
      'Pragma': 'no-cache',
      'Expires': '0'
    }
  }
})