# Humanize

Humanize is an application that removes signs of AI-generated writing from text. Use when editing or reviewing text to make it sound more natural and human-written. Based on Wikipedia's comprehensive "Signs of AI writing" guide. Detects and fixes patterns including inflated symbolism, promotional language, superficial -ing analyses, vague attributions, em dash overuse, rule of three, AI vocabulary words, negative parallelisms, and excessive conjunctive phrases.

## Usage

As a user, I want to be able to paste in my copied text and have Humanize automatically remove the AI slop from it. Then, I need to be able to easily copy the new text to use elsewhere.

## Requirements

In order to use Humanize you'll need to either have an API key powering the editing of the text or use a local model.

- Anthropic API Key
- OpenAI API Key
- Local LLM Model

The app uses a local-first provider flow. On startup it checks `http://localhost:1234` for available models:

- If a local model is available, it defaults to Local.
- If local is unavailable, it defaults to Auto and uses the cheapest available cloud providers by default.
- If OpenAI is available it uses `gpt-4o-mini` by default.
- If Anthropic is available it uses `claude-3-haiku-20240307` by default.

## Run locally

- Start the web workflow:
  - `npm install`
  - `npm run dev`
- Open `http://localhost:3000`
- The app auto-detects whether a local model is available and preselects it when present.

## BYOK and settings

- API keys are stored in the UI Settings panel (gear icon).
- Keys can be used per-session or persisted in browser local storage.
- OpenAI/Anthropic are only callable when the corresponding key is provided in Settings.
- If Local is not available, the user can explicitly switch to OpenAI or Anthropic.

## Environment variables

- `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`
- `OPENAI_MODEL`, `ANTHROPIC_MODEL` (defaults shown above)
- `LOCAL_LLM_ENDPOINT` (defaults to `http://localhost:1234`)
- `LOCAL_LLM_MODEL`
- `LOCAL_LLM_API_FLAVOR` (`auto`, `openai`, `lmstudio`)

## Testing

- Run all tests:
  - `npm test`
- Run focused suites:
  - `npm run test:unit`
  - `npm run test:integration`

## Roadmap

- MacOS MenuBar App
- NextJS WebApp
- iOS App
