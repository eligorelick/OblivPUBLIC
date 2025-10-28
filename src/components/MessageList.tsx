import React, { useEffect, useRef } from 'react';
import { User, Bot, Copy, Check } from 'lucide-react';
import type { ChatMessage } from '../lib/webllm-service';
import { sanitizeMarkdown } from '../lib/security';

interface MessageListProps {
  messages: ChatMessage[];
  isGenerating?: boolean;
}

export const MessageList: React.FC<MessageListProps> = ({ messages, isGenerating = false }) => {
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [copiedIndex, setCopiedIndex] = React.useState<number | null>(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const copyToClipboard = async (text: string, index: number) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopiedIndex(index);
      setTimeout(() => setCopiedIndex(null), 2000);
    } catch (err) {
      // Failed to copy text
    }
  };

  const renderMarkdown = (content: string) => {
    // Simple markdown rendering - safe with double sanitization
    const sanitized = sanitizeMarkdown(content);

    // Convert markdown to HTML (basic conversion)
    let html = sanitized
      .replace(/```([\s\S]*?)```/g, '<pre class="bg-gray-800 rounded p-3 my-2 overflow-x-auto"><code>$1</code></pre>')
      .replace(/`([^`]+)`/g, '<code class="bg-gray-800 px-1 py-0.5 rounded text-sm">$1</code>')
      .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
      .replace(/\*([^*]+)\*/g, '<em>$1</em>')
      .replace(/\n/g, '<br />');

    // Apply DOMPurify again after regex replacements for maximum security
    const finalSanitized = sanitizeMarkdown(html);

    return <div dangerouslySetInnerHTML={{ __html: finalSanitized }} className="prose prose-invert max-w-none" />;
  };

  return (
    <div
      className="flex-1 overflow-y-auto p-2 sm:p-4 space-y-3 sm:space-y-4"
      role="log"
      aria-live="polite"
      aria-atomic="false"
      aria-label="Chat messages"
    >
      {messages.length === 0 && (
        <div className="text-center text-gray-500 mt-8 px-4">
          <Bot className="h-12 w-12 mx-auto mb-4 opacity-50" />
          <p className="text-sm sm:text-base">Start a conversation with your private AI assistant</p>
          <p className="text-xs sm:text-sm mt-2">Your messages never leave this device</p>
        </div>
      )}

      {messages.map((message, index) => (
        <div
          key={index}
          className={`flex gap-2 sm:gap-3 ${
            message.role === 'user' ? 'flex-row-reverse' : 'flex-row'
          } animate-fade-in`}
          role="article"
          aria-label={`${message.role === 'user' ? 'Your message' : 'AI response'}`}
        >
          <div
            className={`flex-shrink-0 w-7 h-7 sm:w-8 sm:h-8 rounded-full flex items-center justify-center ${
              message.role === 'user' ? 'bg-primary' : 'glass'
            }`}
          >
            {message.role === 'user' ? (
              <User className="h-3 w-3 sm:h-4 sm:w-4 text-white" />
            ) : (
              <Bot className="h-3 w-3 sm:h-4 sm:w-4 text-accent" />
            )}
          </div>

          <div
            className={`flex-1 max-w-[85%] sm:max-w-[70%] ${
              message.role === 'user' ? 'text-right' : 'text-left'
            }`}
          >
            <div
              className={`inline-block p-3 sm:p-4 rounded-2xl ${
                message.role === 'user'
                  ? 'bg-primary text-white'
                  : 'glass text-gray-100'
              }`}
            >
              {message.role === 'user' ? (
                <p className="whitespace-pre-wrap text-sm sm:text-base">{message.content}</p>
              ) : (
                <div className="text-sm sm:text-base">
                  {renderMarkdown(message.content)}
                </div>
              )}
            </div>

            <div className={`mt-1 sm:mt-2 flex items-center gap-2 text-xs text-gray-500 ${
              message.role === 'user' ? 'justify-end' : 'justify-start'
            }`}>
              <span>{new Date(message.timestamp).toLocaleTimeString()}</span>
              <button
                onClick={() => copyToClipboard(message.content, index)}
                className="hover:text-gray-300 transition-colors p-1"
                aria-label="Copy message"
              >
                {copiedIndex === index ? (
                  <Check className="h-3 w-3" />
                ) : (
                  <Copy className="h-3 w-3" />
                )}
              </button>
            </div>
          </div>
        </div>
      ))}

      {isGenerating && (
        <div className="flex gap-2 sm:gap-3 animate-pulse" aria-live="polite" aria-label="AI is thinking">
          <div className="flex-shrink-0 w-7 h-7 sm:w-8 sm:h-8 rounded-full flex items-center justify-center glass">
            <Bot className="h-3 w-3 sm:h-4 sm:w-4 text-accent" />
          </div>
          <div className="flex-1 max-w-[85%] sm:max-w-[70%]">
            <div className="inline-block p-3 sm:p-4 rounded-2xl glass text-gray-100">
              <span className="text-sm sm:text-base">Thinking...</span>
            </div>
          </div>
        </div>
      )}

      <div ref={messagesEndRef} aria-hidden="true" />
    </div>
  );
};