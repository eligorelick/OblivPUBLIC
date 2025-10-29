import { create } from 'zustand';
import type { ChatMessage } from '../lib/webllm-service';
import type { ModelConfig } from '../lib/model-config';

export interface ChatState {
  messages: ChatMessage[];
  selectedModel: ModelConfig | null;
  isGenerating: boolean;
  modelLoadingProgress: number;
  modelLoadingStatus: string;
  isDarkMode: boolean;
  autoDeleteChats: boolean;
  systemInstruction: string;
  storageEnabled: boolean;
  contextTokenCount: number;
  showContextWarning: boolean;

  // Actions
  addMessage: (message: ChatMessage) => void;
  clearMessages: () => void;
  clearAllHistory: () => void;
  setSelectedModel: (model: ModelConfig) => void;
  setGenerating: (isGenerating: boolean) => void;
  setModelLoadingProgress: (progress: number, status: string) => void;
  toggleDarkMode: () => void;
  setAutoDeleteChats: (autoDelete: boolean) => void;
  setSystemInstruction: (instruction: string) => void;
  enableStorage: () => void;
  disableStorage: () => void;
  exportChat: () => string;
  updateContextTokenCount: (count: number) => void;
  dismissContextWarning: () => void;
}

export const useChatStore = create<ChatState>()((set, get) => ({
  messages: [],
  selectedModel: null,
  isGenerating: false,
  modelLoadingProgress: 0,
  modelLoadingStatus: '',
  isDarkMode: true,
  autoDeleteChats: false,
  systemInstruction: '',
  storageEnabled: false,
  contextTokenCount: 0,
  showContextWarning: false,

  addMessage: (message: ChatMessage) => {
    set((state) => {
      const newMessages = [...state.messages, { ...message, timestamp: new Date() }];

      // Estimate token count (rough: ~4 chars per token)
      const totalChars = newMessages.reduce((sum, msg) => sum + msg.content.length, 0);
      const estimatedTokens = Math.ceil(totalChars / 4);

      // Show warning if context > 2048 tokens (consumer GPUs struggle with long context)
      const showWarning = estimatedTokens > 2048;

      return {
        messages: newMessages,
        contextTokenCount: estimatedTokens,
        showContextWarning: showWarning
      };
    });
  },

  clearMessages: () => {
    set({
      messages: [],
      contextTokenCount: 0,
      showContextWarning: false
    });
  },

  clearAllHistory: () => {
    set({ messages: [] });

    // Clear any potential browser storage
    try {
      localStorage.removeItem('oblivai-storage');
      sessionStorage.clear();
    } catch (e) {
      // Storage clearing not available
    }

    // Clear potential WebLLM caches
    if ('caches' in window) {
      caches.keys().then(cacheNames => {
        cacheNames.forEach(cacheName => {
          if (cacheName.includes('mlc') || cacheName.includes('webllm')) {
            caches.delete(cacheName);
          }
        });
      }).catch(() => {
        // Cache clearing not available
      });
    }

    // Clear potential IndexedDB data
    if ('indexedDB' in window) {
      try {
        indexedDB.deleteDatabase('mlc-cache');
        indexedDB.deleteDatabase('webllm-cache');
      } catch (e) {
        // IndexedDB clearing not available
      }
    }
  },

  setSelectedModel: (model: ModelConfig) => {
    set({ selectedModel: model });
  },

  setGenerating: (isGenerating: boolean) => {
    set({ isGenerating });
  },

  setModelLoadingProgress: (progress: number, status: string) => {
    set({ modelLoadingProgress: progress, modelLoadingStatus: status });
  },

  toggleDarkMode: () => {
    set((state) => {
      const newMode = !state.isDarkMode;
      if (newMode) {
        document.documentElement.classList.remove('light');
        document.documentElement.classList.add('dark');
      } else {
        document.documentElement.classList.remove('dark');
        document.documentElement.classList.add('light');
      }
      return { isDarkMode: newMode };
    });
  },

  setAutoDeleteChats: (autoDelete: boolean) => {
    set({ autoDeleteChats: autoDelete });
  },

  setSystemInstruction: (instruction: string) => {
    set({ systemInstruction: instruction });
  },

  // Note: Storage is always disabled for privacy - these functions are no-ops
  enableStorage: () => {
    // Intentionally does nothing - storage always disabled for privacy
    set({ storageEnabled: false });
  },

  disableStorage: () => {
    set({ storageEnabled: false });
  },

  exportChat: () => {
    const state = get();
    const markdown = state.messages
      .map(msg => `**${msg.role === 'user' ? 'You' : 'AI'}**: ${msg.content}`)
      .join('\n\n');

    const header = `# OBLIVAI Chat Export\n\nExported: ${new Date().toISOString()}\nModel: ${state.selectedModel?.name || 'Unknown'}\n\n---\n\n`;

    return header + markdown;
  },

  updateContextTokenCount: (count: number) => {
    set({
      contextTokenCount: count,
      showContextWarning: count > 2048
    });
  },

  dismissContextWarning: () => {
    set({ showContextWarning: false });
  }
}));