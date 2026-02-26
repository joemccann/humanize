# Design Memory: Humanize (Modern Editorial Manifesto)

## Brand Tone
- **Adjectives:** Editorial, Manifesto, High-Contrast, Premium, Human.
- **Avoid:** Generic UI, rounded corners, drop shadows, low-contrast text.

## Layout & Spacing
- **Density:** Comfortable, with massive hero statements (`15vw`).
- **Grid:** Split-pane or layered stack with strong vertical hierarchy.
- **Corner radius:** Sharp edges (`0px` or `2px` max).
- **Shadows:** None. Use borders and background contrast for depth.

## Typography
- **Headings:** Fraunces (Variable Serif), weight 100-900. Tight leading (`0.8`).
- **Body:** Manrope (Sans-serif), weight 200-800.
- **Emphasis:** All-caps labels with high letter-spacing (`0.1em` to `0.2em`).

## Color (Inverted Mode)
- **Canvas:** `#e8e6e1` (Paper)
- **Text:** `#0a0a0c` (Canvas)
- **Accent:** `#d4c5a2` (Gold/Cream) for indicators and highlights.
- **Input BG:** `#f5f4f0` for subtle contrast.

## Interaction Patterns
- **Forms:** Large-scale, borderless text areas within contrasted wrappers.
- **Buttons:** High-contrast blocks (`btn-large`) with uppercase labels.
- **Feedback:** Subtle fade-in animations and text-label updates.
- **Transitions:** Cubic-bezier `(0.16, 1, 0.3, 1)` for 0.8s entrances.

## Accessibility Rules
- **Focus:** Visible 1px solid borders on focus.
- **Labels:** Uppercase, high-letter-spacing indicators for all input buffers.
- **Motion:** Fade-in and vertical translation `(20px)` for all new content.

---
*Updated by Gemini CLI Design Lab - 2026-02-25*
