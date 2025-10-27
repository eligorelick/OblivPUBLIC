import { useState, useRef, useEffect, lazy, Suspense } from 'react';
import { LandingPage } from './components/LandingPage';
import { WebLLMService } from './lib/webllm-service';
import { useChatStore } from './store/chat-store';
import { SecurityManager } from './lib/security-init';
import { registerServiceWorker } from './lib/sw-register';
import type { ModelConfig } from './lib/model-config';

// Lazy load heavy components for better initial load performance
const ModelSelector = lazy(() => import('./components/ModelSelector').then(m => ({ default: m.ModelSelector })));
const ChatInterface = lazy(() => import('./components/ChatInterface').then(m => ({ default: m.ChatInterface })));

// Loading fallback component
const LoadingFallback = () => (
  <div className="min-h-screen bg-dark flex items-center justify-center">
    <div className="text-center">
      <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary mx-auto mb-4"></div>
      <p className="text-gray-400">Loading...</p>
    </div>
  </div>
);

function App() {
  const [currentView, setCurrentView] = useState<'landing' | 'model-select' | 'chat'>('landing');
  const [isModelLoading, setIsModelLoading] = useState(false);
  const webllmService = useRef(new WebLLMService());

  const {
    setSelectedModel,
    setModelLoadingProgress,
    isDarkMode,
    modelLoadingProgress,
    modelLoadingStatus
  } = useChatStore();

  useEffect(() => {
    // Initialize security measures (now with IndexedDB model cache support)
    SecurityManager.getInstance();

    // Register service worker for offline support (PWA)
    registerServiceWorker();

    // Set initial dark mode
    if (isDarkMode) {
      document.documentElement.classList.add('dark');
    }
  }, [isDarkMode]);

  const handleStartChat = () => {
    setCurrentView('model-select');
  };

  const handleModelSelect = async (model: ModelConfig) => {
    // Set loading state IMMEDIATELY to show loading bar
    setIsModelLoading(true);
    setSelectedModel(model);
    setModelLoadingProgress(1, 'Initializing model...');

    try {
      // Set up progress callback that handles both number and InitProgressReport
      const progressCallback = (progress: number, status: string) => {
        setModelLoadingProgress(progress, status);
      };

      await webllmService.current.initializeModel(
        model,
        progressCallback
      );

      // Once model is loaded, switch to chat view
      setCurrentView('chat');
      setModelLoadingProgress(100, 'Model loaded successfully');
      setIsModelLoading(false);
    } catch (error) {
      // IMPORTANT: Show error to user (console may be disabled on mobile)
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      setModelLoadingProgress(0, `Failed: ${errorMessage}`);
      setIsModelLoading(false);

      // Show user-friendly error dialog
      const userMessage = `Failed to load model: ${model.name}\n\n` +
        `Error: ${errorMessage}\n\n` +
        `Please try:\n` +
        `• Select a smaller model (Tiny or Small category)\n` +
        `• Refresh the page and try again\n` +
        `• Use a different browser (Chrome/Edge recommended)\n` +
        `• Ensure you have a stable internet connection`;

      alert(userMessage);

      // Log for debugging (will only show on localhost/.onion)
      console.error('Model loading error:', error);
    }
  };

  // Clean up on unmount
  useEffect(() => {
    const currentService = webllmService.current;
    return () => {
      currentService.dispose();
    };
  }, []);

  return (
    <div className="min-h-screen bg-dark">
      {currentView === 'landing' && (
        <LandingPage onStartChat={handleStartChat} />
      )}

      {currentView === 'model-select' && (
        <Suspense fallback={<LoadingFallback />}>
          <div className="min-h-screen flex items-center justify-center p-6">
            <ModelSelector
              onModelSelect={handleModelSelect}
              isLoading={isModelLoading}
              loadingProgress={modelLoadingProgress}
              loadingStatus={modelLoadingStatus}
              // Provide back navigation
              onBack={() => setCurrentView('landing')}
            />
          </div>
        </Suspense>
      )}

      {currentView === 'chat' && (
        <Suspense fallback={<LoadingFallback />}>
          <ChatInterface webllmService={webllmService.current} onBack={() => setCurrentView('model-select')} />
        </Suspense>
      )}
    </div>
  );
}

export default App;