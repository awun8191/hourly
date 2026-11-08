# Design tokens

`lib/core/theme/design_tokens.dart` is the single source of truth for the app.
The Android widget cannot import Dart, so its XML mirrors the same values by
name. `test/core/theme/design_tokens_test.dart` fails when the two drift.

## Palette

| Token | Value | Use |
|---|---|---|
| `AppColors.black` | `#000000` | Text on white, dark onPrimary |
| `AppColors.white` | `#FFFFFF` | In-place accent on dark, primary on dark |
| `AppColors.ink` | `#111111` | In-place accent and primary on light |
| `AppColors.paper` | `#FFFFFF` | Light background |
| `AppColors.surfaceDark` | `#0C1A12` | Dark background, deep forest |
| `AppColors.surfaceDarkRaised` | `#14291D` | In-place card on dark |
| `AppColors.surfaceDarkSunken` | `#0F2017` | Sheet and card base on dark |
| `AppColors.surfaceDarkHigh` | `#1A3124` | Raised layer on dark |
| `AppColors.surfaceDarkHighest` | `#213B2C` | Faint track on dark |
| `AppColors.paperRaised` | `#F4F4F4` | In-place card on light |
| `AppColors.lineDark` | `#26382C` | Hairlines on dark |
| `AppColors.lineLight` | `#E2E2E2` | Hairlines on light |
| `AppColors.mutedDark` | `#B8C6BC` | Secondary text on dark |
| `AppColors.mutedLight` | `#5A5A5A` | Secondary text on light |
| `AppColors.bloodRed` | `#FF3B30` | Done and missed fill, meter tick |
| `AppColors.bloodRedText` | `#FF3B30` | Done and missed text on black |
| `AppColors.bloodRedDeep` | `#D92D20` | Done text and fill on paper |
| `AppColors.bloodRedSurfaceDark` | `#2E0B09` | Done card on dark |
| `AppColors.bloodRedSurfaceLight` | `#FCEAE8` | Done card on light |
| `AppColors.knobYellow` | `#FFD24D` | Toggle knob gradient start |
| `AppColors.knobYellowDeep` | `#F2B705` | Toggle knob gradient end |
| `AppColors.switchOn` | `#7DDBA8` | Toggle fill when on, dark (original emerald) |
| `AppColors.switchOnLight` | `#1F7A4C` | Toggle fill when on, light (original emerald) |
| `AppColors.switchOff` | `#4D9FFF` | Toggle track when off, dark (blue, never pink) |
| `AppColors.switchOffLight` | `#2563EB` | Toggle track when off, light |

Rules:

- White is the accent on the deep forest. Ink is the accent on paper. Green
  appears only in the toggle, never in the rest of the UI.
- Red is one bright hue, `#FF3B30` on black. On paper it deepens to `#D92D20`
  so it stays legible. It belongs to done, missed, and the error role.
- Yellow belongs to the toggle knob only.

## Mapping to the widget

| Widget resource | Light | Dark | Token |
|---|---|---|---|
| `widget_background` | `#FFFFFF` | `#0C1A12` | `paper` / `surfaceDark` |
| `widget_stroke` | `#E2E2E2` | `#26382C` | `lineLight` / `lineDark` |
| `widget_text` | `#111111` | `#F2F2F2` | `ink` / white text |
| `widget_muted` | `#5A5A5A` | `#B8C6BC` | `mutedLight` / `mutedDark` |
| `widget_active_text` | `#111111` | `#FFFFFF` | `ink` / `white` |
| `widget_active_bg` | `#F4F4F4` | `#14291D` | `paperRaised` / `surfaceDarkRaised` |
| `widget_active_stroke` | `#111111` | `#CCFFFFFF` | ink / white at 80 percent |
| `widget_done_text` | `#D92D20` | `#FF3B30` | `bloodRedDeep` / `bloodRed` |
| `widget_done_bg` | `#FCEAE8` | `#2E0B09` | `bloodRedSurfaceLight` / `bloodRedSurfaceDark` |
| `widget_missed_text` | `#7A2B25` | `#C4463A` | blood red, muted |
| `widget_missed_bar` | `#8B0000` | `#8B0000` | blood red, muted |
| `widget_accent` | `#111111` | `#FFFFFF` | `ink` / `white` |
| `widget_progress_fill` | `#111111` | `#FFFFFF` | `ink` / `white` |
| `widget_track` | `#E4E4E4` | `#262626` | neutral track |

## Scale

- Spacing: 2, 4, 8, 12, 16, 24, 32. Touch target 48.
- Radii: card 16, chip 20, field 14, sheet 28.
- Motion: 140 ms fast, 220 ms normal, 320 ms slow, ease-out cubic.
- Type: nothing below 9.5 sp. Body line height 1.45.
- Elevation: neutral black shadows only. No coloured glow.
