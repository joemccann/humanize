# Task Plan

## Change: Review latest provider/fallback updates, strengthen tests, and verify green

## Dependency Graph

- T1 -> T2
- T2 -> T3
- T2 -> T4
- T3 -> T5
- T4 -> T5

## Tasks

- [x] T1: Capture baseline by running full test suite and identifying any current failures/warnings (`depends_on: []`)
- [x] T2: Review latest code changes for regression risks and missing coverage (providers, fallback order, key selection behavior) (`depends_on: [T1]`)
- [x] T3: Implement/adjust tests to cover identified gaps and behavioral contracts (`depends_on: [T2]`)
- [x] T4: Fix any code issues uncovered during review that block correctness or testability (`depends_on: [T2]`)
- [x] T5: Re-run `swift build && swift test` and confirm all tests pass (`depends_on: [T3, T4]`)

## Review

- Confirmed and retained existing correctness fixes in the latest code: whitespace-only keys are treated as missing and Anthropic parsing selects the first text block.
- Added/expanded regression tests for:
  - `AIProvider.fallbackProviders` order for every provider and recommended-order completeness (`TypesTests`).
  - `SettingsStore.providerAttemptOrder` across all providers and `selectableProviders` ordering (`SettingsStoreTests`).
  - request-header isolation (provider-incompatible headers must be absent) and token-limit payload fields (`HumanizeAPIServiceTests`).
  - malformed Cerebras response parity (`missing choices`, `empty choices`, `missing message/content`) (`HumanizeAPIServiceTests`).
- Verification passed:
  - `swift build`
  - `swift test` (`145 tests`, `17 suites`, `0 failures`)
