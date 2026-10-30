# Design tokens

`lib/core/theme/design_tokens.dart` is the single source of truth for the app.
The Android widget cannot import Dart, so its XML mirrors the same values by
name. `test/core/theme/design_tokens_test.dart` fails when the two drift.

## Palette

| Token | Value | Use |
|---|---|---|
| `AppColors.black` | `#000000` | Dark background, dark theme surface |
| `AppColors.white` | `#FFFFFF` | In-place accent on dark, primary on dark |
| `AppColors.ink` | `#111111` | In-place accent and primary on light |
| `AppColors.paper` | `#FFFFFF` | Light background |
| `AppColors.surfaceDarkRaised` | `#121212` | In-place card on dark |
| `AppColors.paperRaised` | `#F4F4F4` | In-place card on light |
| `AppColors.lineDark` | `#232323` | Hairlines on dark |
| `AppColors.lineLight` | `#E2E2E2` | Hairlines on light |
| `AppColors.mutedDark` | `#B8B8B8` | Secondary text on dark |
| `AppColors.mutedLight` | `#5A5A5A` | Secondary text on light |
| `AppColors.bloodRed` | `#8B0000` | Done and missed fill, toggle track, meter tick |
| `AppColors.bloodRedText` | `#E00000` | Done and missed text on black |
| `AppColors.bloodRedSurfaceDark` | `#240404` | Done card on dark |
| `AppColors.bloodRedSurfaceLight` | `#F7E7E6` | Done card on light |
| `AppColors.knobYellow` | `#FFD24D` | Toggle knob gradient start |
| `AppColors.knobYellowDeep` | `#F2B705` | Toggle knob gradient end |

Rules:

- White is the accent on black. Ink is the accent on paper. There is no green.
- Blood red is the only hue. It belongs to done, missed, and the error role.
- Yellow belongs to the toggle knob only.

## Mapping to the widget

| Widget resource | Light | Dark | Token |
|---|---|---|---|
| `widget_background` | `#FFFFFF` | `#000000` | `paper` / `black` |
| `widget_stroke` | `#E2E2E2` | `#1F1F1F` | `lineLight` / `lineDark` |
| `widget_text` | `#111111` | `#F2F2F2` | `ink` / white text |
| `widget_muted` | `#5A5A5A` | `#B8B8B8` | `mutedLight` / `mutedDark` |
| `widget_active_text` | `#111111` | `#FFFFFF` | `ink` / `white` |
| `widget_active_bg` | `#F4F4F4` | `#121212` | `paperRaised` / `surfaceDarkRaised` |
| `widget_active_stroke` | `#111111` | `#CCFFFFFF` | ink / white at 80 percent |
| `widget_done_text` | `#8B0000` | `#E00000` | `bloodRed` / `bloodRedText` |
| `widget_done_bg` | `#F7E7E6` | `#240404` | `bloodRedSurfaceLight` / `bloodRedSurfaceDark` |
| `widget_missed_text` | `#7A2B25` | `#C4463A` | blood red, muted |
| `widget_missed_bar` | `#8B0000` | `#8B0000` | `bloodRed` |
| `widget_accent` | `#111111` | `#FFFFFF` | `ink` / `white` |
| `widget_progress_fill` | `#111111` | `#FFFFFF` | `ink` / `white` |
| `widget_track` | `#E4E4E4` | `#262626` | neutral track |

## Scale

- Spacing: 2, 4, 8, 12, 16, 24, 32. Touch target 48.
- Radii: card 16, chip 20, field 14, sheet 28.
- Motion: 140 ms fast, 220 ms normal, 320 ms slow, ease-out cubic.
- Type: nothing below 10 sp. Body line height 1.45.
- Elevation: neutral black shadows only. No coloured glow.
