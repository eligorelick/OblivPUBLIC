// Enhanced error handling for WebLLM with user-friendly messages

export class WebLLMError extends Error {
  code: string;
  userMessage: string;
  suggestions: string[];

  constructor(
    message: string,
    code: string,
    userMessage: string,
    suggestions: string[]
  ) {
    super(message);
    this.name = 'WebLLMError';
    this.code = code;
    this.userMessage = userMessage;
    this.suggestions = suggestions;
  }
}

export function handleWebLLMError(error: unknown, detectedMemory?: number, requiredMemory?: number): WebLLMError {
  const errorMessage = error instanceof Error ? error.message : String(error);
  const errorLower = errorMessage.toLowerCase();

  // GPU/WebGPU errors
  if (errorLower.includes('webgpu') || errorLower.includes('gpu') || errorLower.includes('adapter')) {
    return new WebLLMError(
      errorMessage,
      'GPU_ERROR',
      'Your browser or device does not support WebGPU, which is required for this model.',
      [
        'Try a smaller model (Qwen2 0.5B or Llama 3.2 1B)',
        'Update your browser to the latest version',
        'Enable hardware acceleration in browser settings',
        'Try Chrome, Edge, or Firefox (latest versions)',
        'On iOS/iPad: Safari 17+ has WebGPU support',
        'Check if your GPU drivers are up to date'
      ]
    );
  }

  // Memory/OOM errors
  if (errorLower.includes('memory') || errorLower.includes('oom') || errorLower.includes('allocation')) {
    const suggestions = [
      'Close other browser tabs and applications',
      'Select a smaller model from the list',
      'Try restarting your browser',
      'Clear your browser cache'
    ];

    if (detectedMemory && requiredMemory) {
      suggestions.push(`Your device has ${detectedMemory}GB RAM, but this model needs at least ${requiredMemory}GB`);
    }

    return new WebLLMError(
      errorMessage,
      'OUT_OF_MEMORY',
      'Not enough memory to load this model.',
      suggestions
    );
  }

  // Network/download errors
  if (errorLower.includes('fetch') || errorLower.includes('network') || errorLower.includes('download') || errorLower.includes('cors')) {
    return new WebLLMError(
      errorMessage,
      'NETWORK_ERROR',
      'Failed to download model files from HuggingFace.',
      [
        'Check your internet connection',
        'Try again in a few moments',
        'HuggingFace servers might be experiencing issues',
        'Check if your firewall is blocking the connection',
        'Try a different network (disable VPN if active)'
      ]
    );
  }

  // Browser compatibility errors
  if (errorLower.includes('wasm') || errorLower.includes('webassembly')) {
    return new WebLLMError(
      errorMessage,
      'WASM_ERROR',
      'Your browser does not support WebAssembly or has it disabled.',
      [
        'Update your browser to the latest version',
        'Enable WebAssembly in browser settings',
        'Try a different browser (Chrome, Firefox, Edge, Safari)',
        'Clear browser cache and cookies'
      ]
    );
  }

  // Model loading/initialization errors
  if (errorLower.includes('model') || errorLower.includes('load') || errorLower.includes('initialize')) {
    return new WebLLMError(
      errorMessage,
      'MODEL_LOAD_ERROR',
      'Failed to load the AI model.',
      [
        'Try selecting a different model',
        'Clear browser cache and try again',
        'Refresh the page and try again',
        'Check if you have enough disk space',
        'The model file might be corrupted - try re-downloading'
      ]
    );
  }

  // Timeout errors
  if (errorLower.includes('timeout') || errorLower.includes('timed out')) {
    return new WebLLMError(
      errorMessage,
      'TIMEOUT_ERROR',
      'Model loading timed out.',
      [
        'Your internet connection might be too slow',
        'Try a smaller model',
        'Try again with a better connection',
        'Large models can take 5-10 minutes to download'
      ]
    );
  }

  // Permission/security errors
  if (errorLower.includes('permission') || errorLower.includes('security') || errorLower.includes('blocked')) {
    return new WebLLMError(
      errorMessage,
      'PERMISSION_ERROR',
      'Browser security settings are blocking model loading.',
      [
        'Check browser security/privacy settings',
        'Disable strict tracking protection for this site',
        'Allow third-party cookies for HuggingFace CDN',
        'Check if Content Security Policy is blocking resources'
      ]
    );
  }

  // Generic fallback
  return new WebLLMError(
    errorMessage,
    'UNKNOWN_ERROR',
    'An unexpected error occurred while loading the model.',
    [
      'Try refreshing the page',
      'Try a different model',
      'Check the browser console for details',
      'Clear browser cache and cookies',
      'Try a different browser',
      'Report this issue on GitHub if it persists'
    ]
  );
}

// Get user-friendly loading status messages based on device
export function getLoadingMessage(
  progress: number,
  deviceType: 'mobile' | 'tablet' | 'desktop',
  os: string,
  _browser: string,
  backend: 'webgpu' | 'webgl' | 'wasm'
): string {
  if (progress < 5) {
    if (backend === 'webgl') {
      return 'Initializing WebGL backend...';
    } else if (backend === 'wasm') {
      return 'Initializing WebAssembly (CPU mode)...';
    }
    return 'Initializing WebGPU...';
  }

  if (progress < 15) {
    return 'Checking model cache...';
  }

  if (progress < 25) {
    if (deviceType === 'mobile') {
      return 'Downloading model (this may take a few minutes on mobile)...';
    }
    return 'Downloading model metadata...';
  }

  if (progress < 40) {
    return 'Downloading model weights from HuggingFace...';
  }

  if (progress < 55) {
    return 'Loading model into memory...';
  }

  if (progress < 70) {
    if (backend === 'webgl') {
      return 'Compiling WebGL shaders for your GPU...';
    } else if (backend === 'wasm') {
      return 'Compiling for CPU execution...';
    }
    return 'Compiling WebGPU shaders...';
  }

  if (progress < 85) {
    if (os === 'ios' || os === 'android') {
      return 'Optimizing for mobile device...';
    }
    return 'Optimizing for your device...';
  }

  if (progress < 95) {
    return 'Finalizing model initialization...';
  }

  return 'Model loaded successfully!';
}
