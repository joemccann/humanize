# Design Memory

## Brand Tone
- **Adjectives:** clear, friendly, trustworthy, editorial
- **Avoid:** clutter near icon edges; tiny ornaments that muddy small-size legibility

## Layout & Spacing
- Prefer centered primary object with generous internal padding.
- Keep strong rounded macOS-friendly outer silhouette.
- Reserve top edge for clean contour (removed mini bubble per final decision).

## Typography
- N/A for icon-only asset

## Color
- **Primary blues:** `#E0F2FE`, `#BAE6FD`, `#0EA5E9`, `#0284C7`, `#0369A1`
- **Accent success:** soft green badge for “approved / polished output”
- **Neutrals:** paper whites and muted blue-grays for line/content contrast

## Interaction Patterns
- N/A for icon-only asset

## Accessibility Rules
- Prioritize recognizable silhouette at 16-32px sizes.
- Maintain clear shape separation (background vs notebook vs badge).
- Avoid over-detailed micro-elements.

## Repo Conventions
- Source-of-truth icon at `Resources/AppIcon-1024.png`.
- Derived assets generated via `bash scripts/generate-app-icons.sh`.
- Build/publish scripts expect `Resources/AppIcon.icns`.

---

*Updated by Design Lab workflow*
