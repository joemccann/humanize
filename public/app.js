const form = document.querySelector('#humanize-form');
const input = document.querySelector('#input');
const output = document.querySelector('#output');
const submitButton = document.querySelector('#submit');
const status = document.querySelector('#status');
const tone = document.querySelector('#tone');
const provider = document.querySelector('#provider');
const preserveMeaning = document.querySelector('#preserveMeaning');
const maxTokens = document.querySelector('#maxTokens');
const providerOut = document.querySelector('#providerOut');
const latencyOut = document.querySelector('#latency');
const counts = document.querySelector('#counts');
const edits = document.querySelector('#edits');
const warnings = document.querySelector('#warnings');
const copyButton = document.querySelector('#copy');
const copyState = document.querySelector('#copy-state');
const themeToggle = document.querySelector('#theme-toggle');
const openaiKey = document.querySelector('#openaiKey');
const anthropicKey = document.querySelector('#anthropicKey');
const providerHint = document.querySelector('#provider-hint');
const saveKeysButton = document.querySelector('#save-keys');
const clearKeysButton = document.querySelector('#clear-keys');
const keyStatus = document.querySelector('#key-status');
const ephemeralKeysToggle = document.querySelector('#keys-ephemeral');
const providerAuth = document.querySelector('#providerAuth');
const settingsToggle = document.querySelector('#settings-toggle');
const settingsOverlay = document.querySelector('#settings-overlay');
const settingsClose = document.querySelector('#settings-close');
const settingsCloseTargets = document.querySelectorAll('[data-close-settings]');
let settingsReturnFocusTarget = null;

const THEME_KEY = 'humanize-theme';
const PROVIDER_KEYS_KEY = 'humanize-provider-keys';
const PROVIDER_KEYS_SESSION_KEY = 'humanize-provider-keys-session';
const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');

function getStoredTheme() {
  try {
    const stored = localStorage.getItem(THEME_KEY);
    if (stored === 'light' || stored === 'dark') {
      return stored;
    }
  } catch {
    return null;
  }
  return null;
}

function parseStoredProviderKeys(raw, fallback) {
  if (!raw) {
    return fallback;
  }

  try {
    const parsed = JSON.parse(raw);
    return {
      openaiApiKey:
        typeof parsed?.openaiApiKey === 'string' ? parsed.openaiApiKey : '',
      anthropicApiKey:
        typeof parsed?.anthropicApiKey === 'string' ? parsed.anthropicApiKey : '',
    };
  } catch {
    return fallback;
  }
}

function readProviderKeysFromStorage(storage, key) {
  try {
    const raw = storage.getItem(key);
    return parseStoredProviderKeys(raw, {
      openaiApiKey: '',
      anthropicApiKey: '',
    });
  } catch {
    return {
      openaiApiKey: '',
      anthropicApiKey: '',
    };
  }
}

function hasStoredKeys(value) {
  return Boolean(value?.openaiApiKey || value?.anthropicApiKey);
}

function loadProviderKeys() {
  const sessionKeys = readProviderKeysFromStorage(
    sessionStorage,
    PROVIDER_KEYS_SESSION_KEY,
  );
  if (hasStoredKeys(sessionKeys)) {
    if (ephemeralKeysToggle) {
      ephemeralKeysToggle.checked = true;
    }
    return sessionKeys;
  }

  const localKeys = readProviderKeysFromStorage(localStorage, PROVIDER_KEYS_KEY);
  if (ephemeralKeysToggle) {
    ephemeralKeysToggle.checked = false;
  }
  return localKeys;
}

function persistProviderKeys(openaiApiKeyValue, anthropicApiKeyValue) {
  const payload = {
    openaiApiKey: openaiApiKeyValue || '',
    anthropicApiKey: anthropicApiKeyValue || '',
  };

  const useSession = ephemeralKeysToggle?.checked === true;
  const destination = useSession ? sessionStorage : localStorage;
  const destinationKey = useSession
    ? PROVIDER_KEYS_SESSION_KEY
    : PROVIDER_KEYS_KEY;
  const cleanupStorage = useSession ? localStorage : sessionStorage;
  const cleanupKey = useSession ? PROVIDER_KEYS_KEY : PROVIDER_KEYS_SESSION_KEY;

  try {
    cleanupStorage.removeItem(cleanupKey);
  } catch {
    // noop
  }

  if (!payload.openaiApiKey && !payload.anthropicApiKey) {
    try {
      destination.removeItem(destinationKey);
    } catch {
      // noop
    }
    return;
  }

  try {
    destination.setItem(destinationKey, JSON.stringify(payload));
  } catch {
    // noop
  }
}

function clearStoredProviderKeys() {
  try {
    localStorage.removeItem(PROVIDER_KEYS_KEY);
  } catch {
    // noop
  }
  try {
    sessionStorage.removeItem(PROVIDER_KEYS_SESSION_KEY);
  } catch {
    // noop
  }
}

function hydrateProviderKeys() {
  const keys = loadProviderKeys();
  if (openaiKey) {
    openaiKey.value = keys.openaiApiKey || '';
  }
  if (anthropicKey) {
    anthropicKey.value = keys.anthropicApiKey || '';
  }
  updateProviderHint();
}

function saveProviderKeysFromForm(showMessage = false) {
  const openaiApiKeyValue = openaiKey?.value?.trim() || '';
  const anthropicApiKeyValue = anthropicKey?.value?.trim() || '';
  persistProviderKeys(openaiApiKeyValue, anthropicApiKeyValue);

  if (showMessage && keyStatus) {
    if (openaiApiKeyValue || anthropicApiKeyValue) {
      if (ephemeralKeysToggle?.checked) {
        keyStatus.textContent = 'API keys saved for this tab only';
      } else {
        keyStatus.textContent = 'API keys saved locally';
      }
    } else {
      keyStatus.textContent = 'Stored API keys cleared';
    }
  }
  updateProviderHint();
}

function resolveAuthSource(requestedProvider, responseProvider) {
  const hasOpenAI = Boolean(openaiKey?.value?.trim());
  const hasAnthropic = Boolean(anthropicKey?.value?.trim());

  if (requestedProvider === 'auto') {
    if (responseProvider === 'openai' && hasOpenAI) {
      return 'OpenAI BYOK';
    }
    if (responseProvider === 'anthropic' && hasAnthropic) {
      return 'Anthropic BYOK';
    }
    if (responseProvider === 'openai') {
      return 'OpenAI env';
    }
    if (responseProvider === 'anthropic') {
      return 'Anthropic env';
    }
    return 'Local';
  }

  if (requestedProvider === 'openai') {
    return hasOpenAI ? 'OpenAI BYOK' : 'OpenAI env';
  }
  if (requestedProvider === 'anthropic') {
    return hasAnthropic ? 'Anthropic BYOK' : 'Anthropic env';
  }
  return 'Local';
}

function clearProviderAuthLabel() {
  if (providerAuth) {
    providerAuth.textContent = '-';
  }
}

function setProviderAuthLabel(requestedProvider, responseProvider) {
  if (!providerAuth) {
    return;
  }

  providerAuth.textContent = resolveAuthSource(
    requestedProvider,
    responseProvider || 'local',
  );
}

function setSettingsOpen(isOpen) {
  if (!settingsOverlay || !settingsToggle) {
    return;
  }

  if (isOpen) {
    settingsReturnFocusTarget = document.activeElement instanceof HTMLElement ? document.activeElement : settingsToggle;
    settingsOverlay.hidden = false;
    settingsToggle.setAttribute('aria-expanded', 'true');
    const firstInput = openaiKey || anthropicKey || settingsClose;
    if (firstInput instanceof HTMLElement) {
      firstInput.focus({ preventScroll: true });
    }

    const onKeyDown = (event) => {
      if (event.key === 'Escape') {
        event.preventDefault();
        setSettingsOpen(false);
      }
    };

    settingsOverlay.__humanizeEscapeHandler = onKeyDown;
    document.addEventListener('keydown', onKeyDown);
    return;
  }

  settingsOverlay.hidden = true;
  settingsToggle.setAttribute('aria-expanded', 'false');

  const handler = settingsOverlay.__humanizeEscapeHandler;
  if (typeof handler === 'function') {
    document.removeEventListener('keydown', handler);
    settingsOverlay.__humanizeEscapeHandler = null;
  }

  if (settingsReturnFocusTarget?.isConnected) {
    settingsReturnFocusTarget.focus();
  } else {
    settingsToggle.focus();
  }
}

function hasSavedOpenAIKey() {
  return Boolean(openaiKey?.value?.trim());
}

function hasSavedAnthropicKey() {
  return Boolean(anthropicKey?.value?.trim());
}

function updateProviderHint() {
  if (!providerHint || !provider) {
    return;
  }

  if (provider.value === 'openai' && !hasSavedOpenAIKey()) {
    providerHint.className = 'status error';
    providerHint.textContent =
      'OpenAI is selected. Add an OpenAI API key in Settings to use it.';
    return;
  }

  if (provider.value === 'anthropic' && !hasSavedAnthropicKey()) {
    providerHint.className = 'status error';
    providerHint.textContent =
      'Anthropic is selected. Add an Anthropic API key in Settings to use it.';
    return;
  }

  providerHint.className = 'status';
  providerHint.textContent = '';
}

function applyStoredKeysToPayload(payload) {
  const openaiApiKeyValue = openaiKey?.value?.trim() || '';
  const anthropicApiKeyValue = anthropicKey?.value?.trim() || '';

  if (openaiApiKeyValue) {
    payload.openaiApiKey = openaiApiKeyValue;
  }
  if (anthropicApiKeyValue) {
    payload.anthropicApiKey = anthropicApiKeyValue;
  }
}

function setTheme(theme, persist = false) {
  const nextTheme = theme === 'light' ? 'light' : 'dark';
  document.documentElement.dataset.theme = nextTheme;

  const switchTo = nextTheme === 'dark' ? 'light' : 'dark';
  themeToggle.setAttribute('aria-label', `Switch to ${switchTo} theme`);
  themeToggle.setAttribute('aria-pressed', String(nextTheme === 'dark'));

  if (persist) {
    try {
      localStorage.setItem(THEME_KEY, nextTheme);
    } catch {
      // localStorage may be unavailable in locked-down contexts
    }
  }
}

function hydrateThemeIcons() {
  if (
    typeof window !== 'undefined' &&
    window.lucide &&
    typeof window.lucide.createIcons === 'function' &&
    window.lucide.icons
  ) {
    window.lucide.createIcons({
      icons: window.lucide.icons,
    });
  }
}

function initTheme() {
  const savedTheme = getStoredTheme();
  setTheme(savedTheme ?? (prefersDark.matches ? 'dark' : 'light'), false);
}

function handleThemeToggle() {
  const nextTheme =
    document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
  setTheme(nextTheme, true);
}

function formatWarningMessage(entry) {
  if (typeof entry === 'string' && entry.trim()) {
    return entry;
  }

  return 'Rewrite adjustment applied';
}

function setStatus(message, state = '') {
  status.textContent = message;
  status.className = `status ${state}`.trim();
}

function setButtonLoading(isLoading) {
  if (!submitButton || !copyButton) return;

  submitButton.disabled = isLoading;
  submitButton.classList.toggle('loading', isLoading);
}

function clearMeta() {
  providerOut.textContent = '-';
  clearProviderAuthLabel();
  latencyOut.textContent = '-';
  counts.textContent = '- / -';
  edits.textContent = '-';
  warnings.innerHTML = '';
}

function renderWarnings(items) {
  warnings.innerHTML = '';
  if (!items || !items.length) {
    const empty = document.createElement('li');
    empty.textContent = 'No rewrite warnings';
    warnings.appendChild(empty);
    return;
  }

  items.forEach((item) => {
    const warning = document.createElement('li');
    warning.textContent = formatWarningMessage(item);
    warnings.appendChild(warning);
  });
}

function safeSubmitPayload() {
  const maxTokensValue = maxTokens.value ? Number.parseInt(maxTokens.value, 10) : undefined;
  if (
    maxTokens.value &&
    (Number.isNaN(maxTokensValue) || maxTokensValue <= 0 || !Number.isInteger(maxTokensValue))
  ) {
    throw new Error('Max output tokens must be a positive integer.');
  }

  const payload = {
    text: input.value.trim(),
    provider: provider.value,
    options: {
      tone: tone.value,
      preserveMeaning: preserveMeaning.checked,
    },
  };

  if (maxTokensValue !== undefined) {
    payload.options.maxTokens = maxTokensValue;
  }

  applyStoredKeysToPayload(payload);

  return payload;
}

function resetCopyState() {
  copyButton.textContent = 'COPY_TO_CLIPBOARD';
  copyState.textContent = '';
}

async function handleSubmit(event) {
  event.preventDefault();

  const text = input.value.trim();
  if (!text) {
    setStatus('Paste some text first.', 'error');
    return;
  }

  let payload;
  try {
    payload = safeSubmitPayload();
    if (payload.provider === 'openai' && !hasSavedOpenAIKey()) {
      throw new Error('Add an OpenAI API key in Settings before using OpenAI.');
    }
    if (payload.provider === 'anthropic' && !hasSavedAnthropicKey()) {
      throw new Error('Add an Anthropic API key in Settings before using Anthropic.');
    }
  } catch (error) {
    setStatus(error instanceof Error ? error.message : 'Invalid form value', 'error');
    return;
  }

  setButtonLoading(true);
  setStatus('TRANSFORMING...', 'success');
  clearMeta();
  copyButton.disabled = true;
  resetCopyState();
  const requestedProvider = payload?.provider ?? 'auto';

  try {
    const response = await fetch('/api/humanize', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const data = await response.json();
    if (!response.ok) {
      const message = data?.error?.message ?? 'Transform failed';
      throw new Error(message);
    }

    output.value = data.text ?? '';
    const responseProvider = data.provider?.id || 'local';
    providerOut.textContent = `${responseProvider}${
      data.provider?.model ? ` (${data.provider.model})` : ''
    }`;
    setProviderAuthLabel(requestedProvider, responseProvider);
    latencyOut.textContent = `${data.timings?.totalMs ?? '-'} ms`;
    counts.textContent = `${data.stats?.inputLength ?? '-'} / ${data.stats?.outputLength ?? '-'}`;
    edits.textContent = `${data.stats?.editsEstimated ?? '-'}`;
    renderWarnings(data.warnings || []);
    copyButton.disabled = !output.value.trim();
    setStatus('MANIFESTO_COMPLETE', 'success');
    const badge = document.querySelector('#output-badge');
    if(badge) badge.style.opacity = '1';
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Unexpected error';
    setStatus(`Error: ${message}`, 'error');
  } finally {
    setButtonLoading(false);
  }
}

async function handleCopy() {
  if (!output.value.trim()) {
    return;
  }

  try {
    await navigator.clipboard.writeText(output.value);
    copyState.textContent = 'Text copied';
    copyButton.textContent = 'COPIED_TO_CLIPBOARD';

    setTimeout(() => {
      copyButton.textContent = 'COPY_TO_CLIPBOARD';
      copyState.textContent = '';
    }, 1200);
  } catch {
    copyState.textContent = 'Copy failed';
  }
}

function handleSaveKeys(event) {
  event.preventDefault();
  saveProviderKeysFromForm(true);
}

function handleClearKeys(event) {
  event.preventDefault();
  if (openaiKey) {
    openaiKey.value = '';
  }
  if (anthropicKey) {
    anthropicKey.value = '';
  }
  clearStoredProviderKeys();
  if (keyStatus) {
    keyStatus.textContent = 'Stored API keys cleared';
  }
  updateProviderHint();
}

function handleEphemeralToggle() {
  if (!ephemeralKeysToggle) {
    return;
  }

  saveProviderKeysFromForm(true);
}

function handlePageHide() {
  if (ephemeralKeysToggle?.checked) {
    clearStoredProviderKeys();
  }
}

async function hydrateProviderDefaultSelection() {
  if (!provider) {
    return;
  }

  try {
    const response = await fetch('/api/provider-order');
    const data = await response.json();
    if (!response.ok) {
      provider.value = 'auto';
      return;
    }

    provider.value = data?.defaultProvider === 'local' ? 'local' : 'auto';
  } catch (_error) {
    provider.value = 'auto';
  }
  updateProviderHint();
}

form?.addEventListener('submit', handleSubmit);
copyButton?.addEventListener('click', handleCopy);
themeToggle?.addEventListener('click', handleThemeToggle);
saveKeysButton?.addEventListener('click', handleSaveKeys);
clearKeysButton?.addEventListener('click', handleClearKeys);
provider?.addEventListener('change', updateProviderHint);
settingsToggle?.addEventListener('click', () => setSettingsOpen(true));
settingsCloseTargets.forEach((target) => {
  target.addEventListener('click', (event) => {
    event.preventDefault();
    setSettingsOpen(false);
  });
});
if (settingsOverlay) {
  settingsOverlay.addEventListener('click', (event) => {
    if (event.target === settingsOverlay) {
      setSettingsOpen(false);
    }
  });
}

prefersDark.addEventListener('change', () => {
  const stored = getStoredTheme();
  if (!stored) {
    setTheme(prefersDark.matches ? 'dark' : 'light', false);
  }
});
ephemeralKeysToggle?.addEventListener('change', handleEphemeralToggle);
window.addEventListener('pagehide', handlePageHide);
window.addEventListener('unload', handlePageHide);

hydrateThemeIcons();
initTheme();
hydrateProviderKeys();
hydrateProviderDefaultSelection();
