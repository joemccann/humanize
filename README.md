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

116 tests across 16 suites covering types, settings persistence, API service (request building, response parsing, error handling), whitespace normalization, multi-provider integration, and UI view instantiation.

## Create .app bundle

```bash
bash scripts/build-app.sh
```

The signed app bundle is written to `HumanizeBar.app` in the project root.

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
