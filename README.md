# Humanize

A native macOS menu bar app that rewrites AI-generated text into natural, human-sounding prose. Paste text, pick a tone, and get rewritten output copied to your clipboard.

## Features

- Lives in the macOS menu bar — always one click away
- Paste-in, humanize, copy-out workflow
- BYOK: bring your own OpenAI or Anthropic API key
- Tone selection: natural, casual, professional
- Light, dark, and system appearance modes
- Built with SwiftUI, no Electron, no web views

## Requirements

- macOS 14 (Sonoma) or later
- Swift 6.0+
- An OpenAI or Anthropic API key

## Build

```bash
swift build
```

## Test

```bash
swift test
```

120 tests across 17 suites covering types, settings persistence, API service (request building, response parsing, error handling), whitespace normalization, multi-provider integration, and UI view instantiation.

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

- **Provider** — OpenAI or Anthropic
- **API Key** — stored in UserDefaults per provider
- **Tone** — natural, casual, or professional
- **Appearance** — system, light, or dark

## Architecture

```
Sources/HumanizeBar/
├── HumanizeBarApp.swift    # App entry point (menu bar only, no windows)
├── AppDelegate.swift       # Status item + popover lifecycle
├── PopoverView.swift       # Main UI: input, output, humanize button
├── SettingsView.swift      # API key and preference management
├── SettingsStore.swift     # @Observable persistence via UserDefaults
├── HumanizeAPIService.swift # Provider request orchestration
├── HTTPClient.swift        # Async networking layer
├── SystemPrompt.swift      # Embedded rewrite prompt
└── Types.swift             # Shared enums and models
```
