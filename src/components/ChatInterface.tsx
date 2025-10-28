import React, { useEffect, useState } from 'react';
import { MessageList } from './MessageList';
import { InputArea } from './InputArea';
import { ChatHeader } from './ChatHeader';
import { sanitizeInput } from '../lib/security';
import { useChatStore } from '../store/chat-store';
import { WebLLMService } from '../lib/webllm-service';
import type { ChatMessage } from '../lib/webllm-service';
import { AlertCircle, X } from 'lucide-react';

interface ChatInterfaceProps {
  webllmService: WebLLMService;
  onBack?: () => void;
}

export const ChatInterface: React.FC<ChatInterfaceProps> = ({ webllmService, onBack }) => {
  const {
    messages,
    isGenerating,
    addMessage,
    setGenerating,
    selectedModel,
    clearMessages
  } = useChatStore();
  const systemInstruction = useChatStore(state => state.systemInstruction);
  const [showContextWarning, setShowContextWarning] = useState(true);

  // Auto-focus input when chat interface mounts
  useEffect(() => {
    // Small delay to ensure DOM is ready
    const timer = setTimeout(() => {
      const textarea = document.querySelector('textarea[aria-label="Message input"]') as HTMLTextAreaElement;
      if (textarea) {
        textarea.focus();
      }
    }, 100);

    // Cleanup timeout to prevent memory leaks
    return () => clearTimeout(timer);
  }, []);

  const handleSendMessage = async (content: string) => {
    if (!selectedModel || !webllmService.isModelLoaded()) {
      return;
    }

    // Sanitize user input before sending to the model
    const cleaned = sanitizeInput(content).slice(0, 4000);

    // Add user message
    const userMessage: ChatMessage = {
      role: 'user',
      content: cleaned,
      timestamp: new Date()
    };
    addMessage(userMessage);
    setGenerating(true);

    try {
      // Prepare messages for the model
      const contextMessages = messages.slice(-10); // Keep last 10 messages for context
      const allMessages = [...contextMessages, userMessage];

      // Generate response
      let assistantContent = '';
      const assistantMessage: ChatMessage = {
        role: 'assistant',
        content: '',
        timestamp: new Date()
      };

      // Add empty assistant message that will be updated
      addMessage(assistantMessage);

      await webllmService.generateResponse(
        allMessages,
        (token) => {
          assistantContent += token;
          // Update the last message in the store
          useChatStore.setState((state) => ({
            messages: [
              ...state.messages.slice(0, -1),
              { ...assistantMessage, content: assistantContent }
            ]
          }));
        },
        undefined,
        systemInstruction
      );
    } catch (error) {
      console.error('Error generating response:', error);

      // Add error message
      addMessage({
        role: 'assistant',
        content: `Error: ${error instanceof Error ? error.message : 'Failed to generate response'}`,
        timestamp: new Date()
      });
    } finally {
      setGenerating(false);
    }
  };

  const handleStopGeneration = () => {
    webllmService.cancelGeneration();
    setGenerating(false);
  };

  // Show context warning when there are 10+ messages
  const shouldShowContextWarning = messages.length >= 10 && showContextWarning;

  return (
    <div className="flex flex-col h-screen bg-dark" role="main" aria-label="Chat interface">
      <ChatHeader onBack={onBack} />

      {/* Context Warning Banner */}
      {shouldShowContextWarning && (
        <div className="bg-yellow-500/10 border-b border-yellow-500/30 px-4 py-3">
          <div className="max-w-6xl mx-auto flex items-start gap-3">
            <AlertCircle className="h-5 w-5 text-yellow-400 flex-shrink-0 mt-0.5" />
            <div className="flex-1 text-sm">
              <p className="text-yellow-200 font-medium mb-1">
                ⚠️ Long conversation detected - Context may affect responses
              </p>
              <p className="text-yellow-300/80 text-xs">
                Large context windows can cause degraded responses on consumer GPUs.
                <button
                  onClick={clearMessages}
                  className="ml-1 underline hover:text-yellow-200 font-medium"
                >
                  Clear chat history
                </button> to start fresh, or continue if your hardware can handle it.
              </p>
            </div>
            <button
              onClick={() => setShowContextWarning(false)}
              className="text-yellow-400/60 hover:text-yellow-400 transition-colors"
              aria-label="Dismiss warning"
            >
              <X className="h-4 w-4" />
            </button>
          </div>
        </div>
      )}

      <div className="flex-1 overflow-hidden flex flex-col max-w-6xl mx-auto w-full px-2 sm:px-4">
        <MessageList messages={messages} isGenerating={isGenerating} />

        <InputArea
          onSendMessage={handleSendMessage}
          isGenerating={isGenerating}
          onStopGeneration={handleStopGeneration}
          disabled={!selectedModel || !webllmService.isModelLoaded()}
        />
      </div>
    </div>
  );
};