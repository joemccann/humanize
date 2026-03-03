# Humanize

A cross-platform app that rewrites AI-generated text into natural, human-sounding prose. Available as a native macOS menu bar app and an iOS app. Paste text, pick a tone, and get rewritten output copied to your clipboard.

<p align="center">
  <img src=".github/banner.png" alt="Cerebras provider" width="100%" />
</p>

**[Download the latest macOS release (DMG)](https://github.com/joemccann/humanize/releases/latest/download/HumanizeBar.dmg)** — Open the DMG, drag to Applications, then run:

```bash
xattr -cr /Applications/HumanizeBar.app
```

Bring your own key and select your provider. Cerebras is the default and recommended provider as it is the most affordable and provides the best results in fractions of a second.

<p align="center">
  <img src=".github/cerebras.png" alt="Cerebras provider" width="270" />
  <img src=".github/openai.png" alt="OpenAI provider" width="270" />
  <img src=".github/anthropic.png" alt="Anthropic provider" width="270" />
</p>

## Features

- **macOS**: Lives in the menu bar — always one click away
- **iOS**: Full iPhone app with the same design language
- Paste-in, humanize, copy-out workflow
- BYOK: bring your own Cerebras, OpenAI, or Anthropic API key
- Recommended default: Cerebras with automatic backup attempts to OpenAI and Anthropic
- Tone selection: natural, casual, professional
- Light, dark, and system appearance modes
- "See Details" button reveals AI analysis of what patterns were found and fixed
- Built with SwiftUI, no Electron, no web views

## Requirements

- macOS 14 (Sonoma) or later / iOS 17 or later
- Swift 6.0+
- At least one API key (Cerebras recommended)

## Build

### macOS (CLI)

```bash
swift build
```

### iOS (Xcode)

Open `HumanizeMobile.xcodeproj` in Xcode and build the `HumanizeMobile` scheme for an iOS simulator or device.

## Test

### macOS + Shared (CLI)

```bash
swift test
```

163 tests across 18 suites covering types, settings persistence, API service (request building, response parsing, error handling), fallback behavior, whitespace normalization, structured response parsing, multi-provider integration, and UI view instantiation.

### iOS (Xcode)

Build and run the `HumanizeMobileTests` scheme in Xcode targeting an iOS simulator.

41 tests across 7 suites covering app launch, theme tokens, view instantiation, settings, clipboard, ViewModel (analysis state, clear, error mapping), and mobile flow integration.

**Total: 204 tests across 25 suites.**

## Generate app icon assets

```bash
bash scripts/generate-app-icons.sh
```

This generates icon assets from `Resources/AppIcon-1024.png` (or pass `--source <path>`):

- `Resources/AppIcon-1024.png`
- `Resources/AppIcon.iconset/*`
- `Resources/AppIcon.icns`

## Create .app bundle

```bash
bash scripts/build-app.sh
```

The signed app bundle is written to `HumanizeBar.app` in the project root and includes `AppIcon.icns`.

## Publish for production

`scripts/publish-app.sh` is the production packaging flow. It performs:

- Release build
- Developer ID signing (`codesign --options runtime --timestamp`)
- Notarization + stapling (unless explicitly skipped)
- Installation of the final app to `/Applications/HumanizeBar.app`

### Required environment variables

- `PUBLISH_SIGNING_IDENTITY` (Developer ID Application certificate)
- `PUBLISH_NOTARY_PROFILE` (`xcrun notarytool` keychain profile)

### Publish command

```bash
PUBLISH_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
PUBLISH_NOTARY_PROFILE="AC_NOTARY_PROFILE" \
bash scripts/publish-app.sh
```

### Optional: skip notarization (internal use only)

```bash
bash scripts/publish-app.sh \
  --signing-identity "Developer ID Application: Your Name (TEAMID)" \
  --skip-notarization
```

## Configuration

All settings are managed in-app via the settings panel:

- **Provider** — Cerebras (recommended), OpenAI, or Anthropic
- **API Keys** — stored in UserDefaults per provider
- **Cerebras fallback** — tries `zai-glm-4.7`, then `gpt-oss-120b`, then OpenAI, then Anthropic; other providers stay strict
- **Tone** — natural, casual, or professional
- **Appearance** — system, light, or dark

### Provider Models

Current default models by provider (source of truth: `AIProvider.defaultModel` in `Sources/HumanizeShared/Types.swift`):

- **Cerebras** — `zai-glm-4.7` (fallback: `gpt-oss-120b`)
- **OpenAI** — `gpt-5.2-chat-latest`
- **Anthropic** — `claude-sonnet-4-6`

At request time, OpenAI and Anthropic model lists are queried with your API key and the newest compatible available model is selected automatically. If a selected model is unavailable, the app retries with a compatibility fallback model for that provider.

## Architecture

```
Sources/
  HumanizeShared/                        # Cross-platform shared library
  ├── Types.swift                        # HumanizeTone, AIProvider, HumanizeResult, HumanizeError
  ├── AppAppearance.swift                # AppAppearance + #if os(macOS) resolvedColorScheme
  ├── HTTPClient.swift                   # Async networking protocol
  ├── SystemPrompt.swift                 # Embedded rewrite prompt
  ├── HumanizeAPIService.swift           # Provider request orchestration
  ├── SettingsStore.swift                # @Observable persistence via UserDefaults
  └── TextUtilities.swift               # normalizeInputWhitespace, formatLatencySeconds, parseHumanizeResponse

  HumanizeBar/                           # macOS menu bar app
  ├── HumanizeBarApp.swift               # App entry point (menu bar only)
  ├── AppDelegate.swift                  # Status item + popover lifecycle
  ├── PopoverView.swift                  # Main UI + Theme
  ├── PopoverSizing.swift                # NSSize constants
  └── SettingsView.swift                 # macOS settings window

  HumanizeMobile/                        # iOS app
  ├── HumanizeMobileApp.swift            # iOS @main entry
  ├── ContentView.swift                  # NavigationStack root
  ├── HumanizeView.swift                 # iOS main UI + analysis sheet
  ├── HumanizeViewModel.swift            # @Observable MVVM view model
  ├── MobileSettingsView.swift           # iOS settings sheet
  ├── MobileTheme.swift                  # UIColor adaptive colors
  └── Clipboard.swift                    # UIPasteboard wrapper

Tests/
  HumanizeTestSupport/MockHTTPClient.swift  # Shared test infrastructure
  HumanizeSharedTests/                      # Shared library tests (CLI)
  HumanizeBarTests/                         # macOS-only tests (CLI)
  HumanizeMobileTests/                      # iOS tests (Xcode)
```

Operational scripts:

- `scripts/generate-app-icons.sh` — build `.iconset`/`.icns` from source PNG
- `scripts/build-app.sh` — local signed app bundle build
- `scripts/publish-app.sh` — production package/sign/notarize/install flow

## License

MIT
