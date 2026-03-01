# Task Plan

## Change: Finalize selected Variant E as production app icon

## Dependency Graph

- T1 -> T2
- T2 -> T3
- T3 -> T4
- T4 -> T5

## Tasks

- [x] T1: Promote approved design-lab Variant E PNG to `Resources/AppIcon-1024.png` (`depends_on: []`)
- [x] T2: Update icon generation script to build iconset/icns from master PNG without overwriting approved art (`depends_on: [T1]`)
- [x] T3: Regenerate `Resources/AppIcon.iconset` and `Resources/AppIcon.icns` from approved master (`depends_on: [T2]`)
- [x] T4: Verify build pipeline includes updated icon (`swift build`, `swift test`, `bash scripts/build-app.sh`) (`depends_on: [T3]`)
- [x] T5: Finalize design-lab session artifacts and documentation updates (`depends_on: [T4]`)

## Review

- Promoted final approved icon (Variant E, mini bubble removed) to `Resources/AppIcon-1024.png`.
- Reworked `scripts/generate-app-icons.sh` to generate iconset/icns from a provided master PNG source (`--source`), preventing overwrite of approved artwork.
- Regenerated `Resources/AppIcon.iconset/*` and `Resources/AppIcon.icns` from approved source PNG.
- Verification passed:
  - `swift build`
  - `swift test` (120 tests, 17 suites, 0 failures)
  - `bash scripts/build-app.sh`
  - App bundle contains `HumanizeBar.app/Contents/Resources/AppIcon.icns`
- Design-lab finalization completed:
  - Removed `.claude-design/` temporary artifacts.
  - Created `DESIGN_PLAN.md` and `DESIGN_MEMORY.md`.
