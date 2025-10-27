# Contributing to OBLIVAI

Thank you for considering contributing to OBLIVAI! We welcome contributions from the community to help make private AI more accessible and secure.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Pull Request Process](#pull-request-process)
- [Security Considerations](#security-considerations)
- [Adding New Models](#adding-new-models)

## Code of Conduct

This project adheres to a simple code of conduct:

- Be respectful and inclusive
- Focus on constructive feedback
- Prioritize user privacy and security
- Help maintain professional, well-documented code

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce** the behavior
- **Expected vs actual behavior**
- **Browser and OS information** (crucial for WebGPU/WebLLM issues)
- **Device specs** (RAM, GPU if applicable)
- **Console errors** (if any)

**Example:**
```
Title: Llama 3.2 3B fails to load on Safari 17.2

Description: When selecting Llama 3.2 3B on Safari 17.2 (macOS Sonoma 14.2),
the model download starts but fails at 45% with GPU initialization error.

Steps to reproduce:
1. Open OBLIVAI in Safari 17.2
2. Click "Start Chat"
3. Select "Llama 3.2 3B"
4. Wait for download to reach 45%

Expected: Model loads successfully
Actual: Error "WebGPU initialization failed"

Console error: [Paste error message]
Device: MacBook Pro 2019, 16GB RAM, AMD Radeon Pro 5500M
```

### Suggesting Enhancements

Enhancement suggestions are welcome! Please include:

- **Clear use case** - Why is this valuable?
- **Privacy impact** - Does it maintain 100% local operation?
- **Implementation ideas** - How might this work?
- **Alternatives considered** - What other approaches did you think about?

### Contributing Code

We welcome pull requests for:

- **Bug fixes**
- **Performance improvements**
- **Accessibility enhancements**
- **Documentation improvements**
- **New model support** (must be available in WebLLM)
- **UI/UX improvements**
- **Test coverage**

## Development Setup

### Prerequisites

- **Node.js** 18+ and npm
- **Git**
- **Modern browser** with WebGPU support (Chrome 113+, Safari 17+, Firefox 121+)
- **8GB+ RAM** recommended for testing larger models

### Initial Setup

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/Obliv_source.git
cd Obliv_source

# Add upstream remote
git remote add upstream https://github.com/eligorelick/Obliv_source.git

# Install dependencies
npm install

# Start development server
npm run dev
```

The app will be available at `http://localhost:5173`

### Development Workflow

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes and test thoroughly

# Run linter (if configured)
npm run lint

# Build to check for TypeScript errors
npm run build

# Commit your changes
git add .
git commit -m "feat: add your feature description"

# Push to your fork
git push origin feature/your-feature-name

# Open a Pull Request on GitHub
```

## Coding Standards

### TypeScript

- **Use TypeScript** for all new code
- **Define interfaces** for all data structures
- **Avoid `any` type** - use proper typing
- **Export types** that other modules might need

```typescript
// Good
interface ModelConfig {
  id: string;
  name: string;
  size: string;
  requirements: {
    ram: number;
    gpu: 'optional' | 'recommended' | 'required';
  };
}

// Bad
const model: any = { ... }
```

### React Components

- **Use functional components** with hooks
- **Destructure props** in component signature
- **Use meaningful prop names**
- **Add JSDoc comments** for complex components

```typescript
// Good
interface ChatHeaderProps {
  /** Callback function when user clicks back button */
  onBack?: () => void;
}

/**
 * ChatHeader component displays app branding, theme toggle, and settings
 * @param props - Component props
 */
export const ChatHeader: React.FC<ChatHeaderProps> = ({ onBack }) => {
  // Component implementation
};

// Bad
export const ChatHeader = (props: any) => {
  // No documentation, any type
};
```

### File Naming

- **Components**: PascalCase (e.g., `ChatHeader.tsx`)
- **Utilities**: kebab-case (e.g., `hardware-detect.ts`)
- **Types/Interfaces**: PascalCase, usually in component file or separate `.types.ts`

### Code Organization

- **Components** go in `src/components/`
- **Library code** goes in `src/lib/`
- **State management** goes in `src/store/`
- **Types** can be colocated or in `.types.ts` files
- **Keep files focused** - one primary export per file

### Comments and Documentation

```typescript
/**
 * JSDoc for functions, especially public APIs
 * Detects device capabilities including OS, browser, GPU support, and RAM
 * @returns DeviceInfo object with all detected capabilities
 */
export function detectDeviceInfo(): DeviceInfo {
  // Inline comments explain complex logic
  const ua = navigator.userAgent.toLowerCase();

  // Detect OS (handles iOS, Android, Windows, macOS, Linux)
  let os: DeviceInfo['os'] = 'unknown';
  if (/iphone|ipad|ipod/.test(ua)) {
    os = 'ios';
  }
  // ...
}
```

### Privacy & Security

**All code MUST maintain these privacy guarantees:**

1. **No external network calls** except HuggingFace CDN for models
2. **No data collection** of any kind
3. **No analytics or tracking**
4. **IndexedDB only for model cache** (whitelist enforcement)
5. **Service Worker only caches static assets**, never user data

If your contribution involves:
- Network requests → Must update CSP and document in PR
- Storage → Must use IndexedDB whitelist or be in-memory only
- Third-party libraries → Must be privacy-audited and documented

### Accessibility

- **Use semantic HTML** (`<button>`, `<nav>`, etc.)
- **Add ARIA labels** for screen readers
- **Support keyboard navigation** (Tab, Enter, Escape)
- **Test with reduced motion** preference
- **Test with high contrast mode**
- **Maintain focus indicators**

```tsx
// Good
<button
  onClick={handleClick}
  aria-label="Clear all chat messages"
  className="glass p-2 rounded-lg glass-hover"
>
  <Trash2 className="h-5 w-5" />
</button>

// Bad
<div onClick={handleClick}>  {/* Not keyboard accessible */}
  <Trash2 />
</div>
```

## Testing Guidelines

### Manual Testing Checklist

Before submitting a PR, test your changes with:

**Browsers:**
- [ ] Chrome/Edge (latest)
- [ ] Safari (macOS/iOS)
- [ ] Firefox (latest)

**Device Types:**
- [ ] Desktop (1920x1080+)
- [ ] Tablet (768x1024)
- [ ] Mobile (375x667)

**Features:**
- [ ] Model selection works
- [ ] Model loading shows progress
- [ ] Chat input and submission works
- [ ] Streaming responses display correctly
- [ ] Settings panel opens/closes
- [ ] System instructions save and apply
- [ ] Dark/light mode toggle works
- [ ] Export chat to Markdown works
- [ ] Clear chat confirmation works

**Accessibility:**
- [ ] Keyboard navigation works (Tab, Enter, Escape)
- [ ] Screen reader announces key actions
- [ ] Focus indicators are visible
- [ ] High contrast mode looks correct

**Privacy:**
- [ ] No unexpected network requests (check Network tab)
- [ ] No data persisted beyond model cache (check IndexedDB)
- [ ] Service worker only caches static assets (check Application tab)

### Automated Testing

Currently, this project relies on manual testing. Contributions adding automated tests are welcome!

**Ideal test coverage:**
- Unit tests for utility functions (hardware-detect, model-config)
- Component tests for React components
- E2E tests for critical user flows

## Pull Request Process

### Before Submitting

1. **Update documentation** if you changed functionality
2. **Run build** to check for TypeScript errors: `npm run build`
3. **Test thoroughly** using the manual checklist above
4. **Update README.md** if you added features
5. **Follow commit message conventions** (see below)

### Commit Message Format

Use conventional commits format:

```
type(scope): brief description

Longer description if needed (wrap at 72 characters)

Fixes #issue_number
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes (formatting, no logic change)
- `refactor:` Code refactoring (no feature change)
- `perf:` Performance improvements
- `test:` Adding or updating tests
- `chore:` Build process, dependencies, etc.

**Examples:**
```
feat(models): add Llama 3.3 70B support

Add Llama 3.3 70B model to XXL tier with appropriate device requirements
and fallback handling for lower-end devices.

Fixes #42
```

```
fix(security): prevent IndexedDB quota errors

Update IndexedDB whitelist check to handle quota exceeded errors gracefully
by falling back to memory-only mode while preserving model cache.

Fixes #38
```

### PR Description Template

```markdown
## Description
Brief description of what this PR does

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Refactoring

## Testing
Describe what testing you did:
- [ ] Tested on Chrome/Edge
- [ ] Tested on Safari
- [ ] Tested on Firefox
- [ ] Tested on mobile
- [ ] Tested with keyboard navigation

## Privacy Impact
- [ ] No new network requests
- [ ] No new storage beyond model cache
- [ ] Maintains all privacy guarantees

## Screenshots (if applicable)
Add screenshots for UI changes

## Related Issues
Fixes #issue_number
```

### Review Process

1. **Automated checks** (if configured) must pass
2. **Code review** by maintainers
3. **Testing** by maintainers on multiple browsers/devices
4. **Privacy audit** for any storage/network changes
5. **Merge** by maintainers

## Security Considerations

### Reporting Security Issues

**DO NOT** open public issues for security vulnerabilities.

Instead, email: [Insert security email or use GitHub Security Advisories]

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Security Requirements

All contributions must:

1. **Maintain Content Security Policy**
   - No `unsafe-inline` or `unsafe-eval`
   - All external sources whitelisted explicitly

2. **Input Sanitization**
   - Use DOMPurify for any user-generated HTML
   - Validate all user inputs

3. **No Data Leaks**
   - Never log sensitive data
   - Never send data to external services
   - Audit all network requests

4. **Secure Storage**
   - Only IndexedDB whitelist databases can persist
   - Service worker caches static assets only
   - No localStorage for user data

## Adding New Models

To add a new AI model to OBLIVAI:

### 1. Verify Model Availability

Check if the model is available in WebLLM/MLC registry:
- Visit: https://huggingface.co/mlc-ai
- Ensure model has `-MLC` variant available
- Note the exact model ID (e.g., `ModelName-q4f16_1-MLC`)

### 2. Update model-config.ts

```typescript
// src/lib/model-config.ts

export const MODELS: Record<string, ModelConfig> = {
  // ... existing models

  your_model_key: {
    id: 'Exact-Model-ID-From-HuggingFace-MLC',
    name: 'Display Name for UI',
    size: '4.50GB',  // Actual model size
    requirements: {
      ram: 12,  // Minimum RAM in GB
      gpu: 'required'  // optional | recommended | required
    },
    description: 'Brief description of model capabilities',
    category: 'large'  // tiny | small | medium | large | xl | xxl
  }
};
```

### 3. Test Thoroughly

- **Download Test**: Verify model downloads completely
- **Loading Test**: Verify model initializes correctly
- **Inference Test**: Verify model generates coherent responses
- **Memory Test**: Verify model runs on specified RAM requirements
- **GPU Test**: Test on devices with/without GPU if applicable

### 4. Update Documentation

- Add model to README.md in appropriate tier section
- Note any special requirements or considerations

## Questions?

- **General Questions**: Open a [GitHub Discussion](https://github.com/eligorelick/Obliv_source/discussions)
- **Bug Reports**: Open a [GitHub Issue](https://github.com/eligorelick/Obliv_source/issues)
- **Security Issues**: Email [security contact] or use GitHub Security Advisories

---

**Thank you for contributing to private AI!**
