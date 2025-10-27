import DOMPurify from 'dompurify';

// Maximum security input sanitization with comprehensive attack prevention
export const sanitizeInput = (input: string): string => {
  // Input length validation - prevent DoS attacks
  if (input.length > 10000) {
    throw new Error('Input too long');
  }

  // Remove any HTML/script tags with strictest settings
  const cleaned = DOMPurify.sanitize(input, {
    ALLOWED_TAGS: [],
    ALLOWED_ATTR: [],
    KEEP_CONTENT: true,
    FORBID_TAGS: ['script', 'object', 'embed', 'applet', 'iframe', 'form', 'input', 'textarea', 'button', 'select', 'option'],
    FORBID_ATTR: ['onerror', 'onload', 'onclick', 'onmouseover', 'onfocus', 'onblur', 'onchange', 'onsubmit']
  });

  // Comprehensive prompt injection prevention - more targeted patterns
  const injectionPatterns = [
    /ignore previous instructions/gi,
    /forget everything/gi,
    /new instructions:/gi,
    /\[INST\]/gi,
    /<\|im_start\|>/gi,
    /\[\/INST\]/gi,
    /<\|im_end\|>/gi,
    /###\s*system:/gi,
    /###\s*instruction:/gi,
    /<\|system\|>/gi,
    /\[system\]/gi,
    /\[\/system\]/gi,
    /jailbreak/gi,
    /disable safety/gi,
    /ignore safety/gi,
    /remove restrictions/gi,
    /unrestricted mode/gi,
    /developer mode/gi
  ];

  // SQL injection patterns
  const sqlPatterns = [
    /union\s+select/gi,
    /drop\s+table/gi,
    /insert\s+into/gi,
    /delete\s+from/gi,
    /update\s+set/gi,
    /create\s+table/gi,
    /alter\s+table/gi,
    /exec\s*\(/gi,
    /xp_cmdshell/gi,
    /sp_executesql/gi
  ];

  // XSS patterns
  const xssPatterns = [
    /<script/gi,
    /<\/script>/gi,
    /javascript:/gi,
    /vbscript:/gi,
    /onload\s*=/gi,
    /onerror\s*=/gi,
    /onclick\s*=/gi,
    /onmouseover\s*=/gi,
    /onfocus\s*=/gi,
    /onblur\s*=/gi,
    /onchange\s*=/gi,
    /onsubmit\s*=/gi,
    /expression\s*\(/gi,
    /url\s*\(/gi,
    /data:(?:text|image|application|audio|video)\//gi,
    /base64,/gi
  ];

  let sanitized = cleaned;

  // Apply all security patterns
  [...injectionPatterns, ...sqlPatterns, ...xssPatterns].forEach(pattern => {
    sanitized = sanitized.replace(pattern, '[SECURITY_BLOCKED]');
  });

  // Remove null bytes and control characters
  sanitized = sanitized.replace(/[\x00-\x1F\x7F-\x9F]/g, '');

  // Remove excessive whitespace
  sanitized = sanitized.replace(/\s{10,}/g, ' ').trim();

  return sanitized;
};

// Sanitize markdown output from models
export const sanitizeMarkdown = (content: string): string => {
  // Be conservative about allowed HTML in model outputs
  return DOMPurify.sanitize(content, {
    ALLOWED_TAGS: [
      'p', 'br', 'strong', 'em', 'u', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
      'blockquote', 'code', 'pre', 'ol', 'ul', 'li', 'a'
    ],
    ALLOWED_ATTR: ['href', 'title'],
    ALLOW_DATA_ATTR: false,
    FORBID_TAGS: ['img', 'script', 'iframe', 'object', 'embed']
  });
};

// Rate limiting for input
export class RateLimiter {
  private timestamps: number[] = [];
  private readonly maxRequests: number;
  private readonly windowMs: number;

  constructor(maxRequests = 10, windowMs = 60000) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
  }

  canProceed(): boolean {
    const now = Date.now();
    this.timestamps = this.timestamps.filter(t => now - t < this.windowMs);

    if (this.timestamps.length >= this.maxRequests) {
      return false;
    }

    this.timestamps.push(now);
    return true;
  }

  getRemainingTime(): number {
    if (this.timestamps.length === 0) return 0;
    const oldest = Math.min(...this.timestamps);
    return Math.max(0, this.windowMs - (Date.now() - oldest));
  }
}

// Open external links safely by forcing rel attributes and target
export const openExternal = (url: string) => {
  try {
    const a = document.createElement('a');
    a.href = url;
    a.target = '_blank';
    a.rel = 'noopener noreferrer nofollow';
    // Append and click to ensure it's treated as a user gesture
    document.body.appendChild(a);
    a.click();
    a.remove();
  } catch (e) {
    // fallback
    window.open(url, '_blank', 'noopener,noreferrer');
  }
};