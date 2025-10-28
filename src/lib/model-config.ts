export interface ModelConfig {
  id: string;
  name: string;
  size: string;
  requirements: {
    ram: number;
    gpu: 'optional' | 'recommended' | 'required';
  };
  description: string;
  category: 'tiny' | 'small' | 'medium' | 'large' | 'xl' | 'xxl';
}

// 15 AI models organized by capability and size
export const MODELS: Record<string, ModelConfig> = {
  // TINY TIER (500MB-1GB) - Ultra-fast, all devices
  qwen2_0_5b: {
    id: 'Qwen2-0.5B-Instruct-q4f16_1-MLC',
    name: 'Qwen2 0.5B',
    size: '945MB',
    requirements: { ram: 2, gpu: 'optional' },
    description: 'Ultra-fast, works on all devices including old phones',
    category: 'tiny'
  },
  llama32_1b: {
    id: 'Llama-3.2-1B-Instruct-q4f16_1-MLC',
    name: 'Llama 3.2 1B',
    size: '879MB',
    requirements: { ram: 4, gpu: 'optional' },
    description: 'Flexible and fast, great for mobile devices',
    category: 'tiny'
  },

  // SMALL TIER (1-2GB) - Fast, most devices
  qwen2_1_5b: {
    id: 'Qwen2-1.5B-Instruct-q4f16_1-MLC',
    name: 'Qwen2 1.5B',
    size: '1.63GB',
    requirements: { ram: 4, gpu: 'recommended' },
    description: 'Recommended: Best balance of speed and quality',
    category: 'small'
  },
  gemma_2b: {
    id: 'gemma-2b-it-q4f16_1-MLC',
    name: 'Gemma 2B (Google)',
    size: '1.73GB',
    requirements: { ram: 4, gpu: 'recommended' },
    description: 'Google\'s efficient model, excellent for general tasks',
    category: 'small'
  },

  // MEDIUM TIER (2-4GB) - High quality, good devices
  llama32_3b: {
    id: 'Llama-3.2-3B-Instruct-q4f16_1-MLC',
    name: 'Llama 3.2 3B',
    size: '2.26GB',
    requirements: { ram: 8, gpu: 'recommended' },
    description: 'High quality responses, good for complex conversations',
    category: 'medium'
  },
  stablelm_3b: {
    id: 'stablelm-2-zephyr-1_6b-q4f16_1-MLC',
    name: 'StableLM 2 Zephyr 1.6B',
    size: '1.89GB',
    requirements: { ram: 6, gpu: 'recommended' },
    description: 'Stability AI\'s efficient model, great for creative tasks',
    category: 'medium'
  },
  redpajama_3b: {
    id: 'RedPajama-INCITE-Chat-3B-v1-q4f16_1-MLC',
    name: 'RedPajama 3B',
    size: '2.07GB',
    requirements: { ram: 6, gpu: 'recommended' },
    description: 'Open-source model trained on diverse data, versatile',
    category: 'medium'
  },

  // LARGE TIER (4-6GB) - Very capable, powerful devices
  hermes_7b: {
    id: 'Hermes-2-Pro-Mistral-7B-q4f16_1-MLC',
    name: 'Hermes 2 Pro 7B (Uncensored)',
    size: '4.03GB',
    requirements: { ram: 12, gpu: 'required' },
    description: 'Advanced uncensored model with excellent instruction following',
    category: 'large'
  },
  mistral_7b: {
    id: 'Mistral-7B-Instruct-v0.2-q4f16_1-MLC',
    name: 'Mistral 7B v0.2',
    size: '4.37GB',
    requirements: { ram: 12, gpu: 'required' },
    description: 'Popular powerful model, excellent for complex reasoning',
    category: 'large'
  },
  wizardlm_7b: {
    id: 'WizardLM-2-7B-q4f16_1-MLC',
    name: 'WizardLM 2 7B',
    size: '4.65GB',
    requirements: { ram: 12, gpu: 'required' },
    description: 'Advanced instruction-following with strong reasoning',
    category: 'large'
  },
  deepseek_7b: {
    id: 'DeepSeek-R1-Distill-Qwen-7B-q4f16_1-MLC',
    name: 'DeepSeek-R1 7B (Reasoning)',
    size: '5.11GB',
    requirements: { ram: 12, gpu: 'required' },
    description: 'Specialized reasoning model with chain-of-thought capabilities',
    category: 'large'
  },

  // XL TIER (5-8GB) - Extremely capable, high-end devices
  llama31_8b: {
    id: 'Llama-3.1-8B-Instruct-q4f16_1-MLC',
    name: 'Llama 3.1 8B',
    size: '4.60GB',
    requirements: { ram: 16, gpu: 'required' },
    description: 'Meta\'s flagship model, exceptional at all tasks',
    category: 'xl'
  },
  hermes_8b: {
    id: 'Hermes-2-Pro-Llama-3-8B-q4f16_1-MLC',
    name: 'Hermes 2 Pro Llama 8B (Uncensored)',
    size: '4.98GB',
    requirements: { ram: 16, gpu: 'required' },
    description: 'Most powerful uncensored model, no content restrictions',
    category: 'xl'
  },
  deepseek_8b: {
    id: 'DeepSeek-R1-Distill-Llama-8B-q4f16_1-MLC',
    name: 'DeepSeek-R1 8B (Advanced Reasoning)',
    size: '5.00GB',
    requirements: { ram: 16, gpu: 'required' },
    description: 'Top-tier reasoning model with exceptional problem-solving',
    category: 'xl'
  },

  // XXL TIER (4-8GB) - Maximum intelligence, enthusiast hardware only
  wizardmath_7b: {
    id: 'WizardMath-7B-V1.1-q4f16_1-MLC',
    name: 'WizardMath 7B',
    size: '4.57GB',
    requirements: { ram: 16, gpu: 'required' },
    description: 'Specialized in mathematics and complex problem-solving',
    category: 'xxl'
  }
};

// Get models by category for easier filtering
export function getModelsByCategory(category: ModelConfig['category']): ModelConfig[] {
  return Object.values(MODELS).filter(model => model.category === category);
}

// Get all models as array sorted by size
export function getAllModelsSorted(): ModelConfig[] {
  return Object.values(MODELS).sort((a, b) => {
    const sizeA = parseFloat(a.size);
    const sizeB = parseFloat(b.size);
    return sizeA - sizeB;
  });
}

// Filter models based on device capabilities
export function getModelsForDevice(deviceMemory: number, isMobile: boolean): ModelConfig[] {
  return Object.values(MODELS).filter(model => {
    // Mobile devices (iOS/Android) - be conservative
    if (isMobile) {
      // iOS Safari and mobile browsers have strict memory limits (~2-3GB for web apps)
      // Even if device has 8GB, we can't use it all
      if (deviceMemory <= 4) {
        // Low-end phones: Only tiny models
        return model.category === 'tiny';
      } else if (deviceMemory <= 8) {
        // Mid to high-end phones (iPhone 15 Pro Max, Galaxy S24): Tiny + Small
        return model.category === 'tiny' || model.category === 'small';
      } else {
        // Tablets with lots of RAM: Tiny + Small + some Medium
        return model.category === 'tiny' || model.category === 'small' ||
               (model.category === 'medium' && model.requirements.ram <= 6);
      }
    }

    // Desktop - show all models that fit in available RAM
    return model.requirements.ram <= deviceMemory;
  });
}

// Check if a specific model is compatible with device
export function isModelCompatible(model: ModelConfig, deviceMemory: number, isMobile: boolean): boolean {
  if (isMobile) {
    // Mobile-specific limits
    if (deviceMemory <= 4) {
      return model.category === 'tiny';
    } else if (deviceMemory <= 8) {
      return model.category === 'tiny' || model.category === 'small';
    } else {
      return model.category === 'tiny' || model.category === 'small' ||
             (model.category === 'medium' && model.requirements.ram <= 6);
    }
  }

  // Desktop compatibility
  return model.requirements.ram <= deviceMemory;
}

// Legacy compatibility - map old keys to new models
export const MODEL_ALIASES: Record<string, string> = {
  'tiny': 'qwen2_0_5b',
  'medium': 'qwen2_1_5b',
  'large': 'llama32_3b',
  'xl': 'llama31_8b',
  'uncensored': 'hermes_8b'
};