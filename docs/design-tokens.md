# Design tokens

`lib/core/theme/design_tokens.dart` is the single source of truth for the app.
The Android widget cannot import Dart, so its XML mirrors the same values by
name. `test/core/theme/design_tokens_test.dart` fails when the two drift.

## Palette

| Token | Value | Use |
|---|---|---|
| `AppColors.black` | `#000000` | Text on white, dark onPrimary |
| `AppColors.white` | `#FFFFFF` | In-place meter tick and legend dot, primary on dark |
| `AppColors.ink` | `#111111` | Card titles and primary on light |
| `AppColors.paper` | `#FFFFFF` | Light background |
| `AppColors.paperRaised` | `#F4F1E9` | Hour card on either background, warm paper |
| `AppColors.surfaceDark` | `#2B2B85` | Dark background, deep indigo full bleed |
| `AppColors.surfaceDarkSunken` | `#23236F` | Sheet and card base on dark |
| `AppColors.surfaceDarkRaised` | `#353595` | Raised layer on dark |
| `AppColors.surfaceDarkHigh` | `#3F3F9E` | Raised layer on dark |
| `AppColors.surfaceDarkHighest` | `#4D4DAE` | Faint track on dark |
| `AppColors.lineDark` | `#4A4AA3` | Hairlines on dark |
| `AppColors.lineLight` | `#E2E2E2` | Hairlines on light |
| `AppColors.mutedDark` | `#C6C6E6` | Secondary text on dark |
| `AppColors.mutedLight` | `#5A5A5A` | Secondary text on light |
| `AppColors.bloodRed` | `#FF3B30` | Done and missed fill, meter tick |
| `AppColors.bloodRedText` | `#FF3B30` | Done and missed text on indigo |
| `AppColors.bloodRedDeep` | `#D92D20` | Done text on the light cards |
| `AppColors.bloodRedSurfaceDark` | `#2E0B09` | Error container on dark |
| `AppColors.bloodRedSurfaceLight` | `#FCEAE8` | Done card on either background |
| `AppColors.switchOn` | `#B7D9B0` | Toggle fill when on, dark (pale moss, flat) |
| `AppColors.switchOnLight` | `#2E5B3E` | Toggle fill when on, light (deep moss, flat) |
| `AppColors.switchOff` | `#14291D` | Toggle track when off, dark (bark, flat) |
| `AppColors.switchOffLight` | `#E8EDE8` | Toggle track when off, light (flat) |
| `AppColors.switchKnobOn` | `#0C1A12` | Toggle knob when on, dark (solid) |
| `AppColors.switchKnobOnLight` | `#FFFFFF` | Toggle knob when on, light (solid) |
| `AppColors.switchKnobOff` | `#6B7F71` | Toggle knob when off, dark (solid) |
| `AppColors.switchKnobOffLight` | `#7A8A7E` | Toggle knob when off, light (solid) |
| `AppColors.switchBorderOff` | `#33463A` | Toggle off track border, dark, 1.5px |
| `AppColors.switchBorderOffLight` | `#C2CFC4` | Toggle off track border, light, 1.5px |

Rules:

- Deep indigo sits behind everything on dark. Hours are light cards on
  either background: ink title plus the hour range under it, struck red text
  when done. White is the accent on indigo. Moss bark greens appear only in
  the toggle, never in the rest of the UI.
- Red is one bright hue, `#FF3B30` on indigo. On the light cards it deepens
  to `#D92D20` so it stays legible. It belongs to done, missed, and the
  error role.
- The toggle is Moss on bark: flat fills only, no gradient, no glow. Off
  tracks carry a 1.5px border; on tracks have none. The knob keeps a neutral
  black shadow for lift.
- Cards lift with neutral black shadows only. No coloured glow.

## Mapping to the widget

| Widget resource | Light | Dark | Token |
|---|---|---|---|
| `widget_background` | `#FFFFFF` | `#2B2B85` | `paper` / `surfaceDark` |
| `widget_stroke` | `#E2E2E2` | `#4A4AA3` | `lineLight` / `lineDark` |
| `widget_text` | `#111111` | `#F2F2F2` | `ink` / white text |
| `widget_muted` | `#5A5A5A` | `#C6C6E6` | `mutedLight` / `mutedDark` |
| `widget_active_text` | `#111111` | `#111111` | `ink` / `ink` |
| `widget_active_bg` | `#F4F1E9` | `#F4F1E9` | `paperRaised` / `paperRaised` |
| `widget_active_stroke` | `#111111` | `#CCFFFFFF` | ink / white at 80 percent |
| `widget_done_text` | `#D92D20` | `#D92D20` | `bloodRedDeep` / `bloodRedDeep` |
| `widget_done_bg` | `#FCEAE8` | `#FCEAE8` | `bloodRedSurfaceLight` / `bloodRedSurfaceLight` |
| `widget_missed_text` | `#A03A2E` | `#C4463A` | blood red, muted |
| `widget_missed_bar` | `#8B0000` | `#8B0000` | blood red, muted |
| `widget_accent` | `#111111` | `#FFFFFF` | `ink` / `white` |
| `widget_progress_fill` | `#111111` | `#FFFFFF` | `ink` / `white` |
| `widget_track` | `#E4E4E4` | `#4D4DAE` | neutral track / `surfaceDarkHighest` |

## Scale

- Spacing: 2, 4, 8, 12, 16, 24, 32. Touch target 48.
- Radii: card 16, chip 20, field 14, sheet 28.
- Motion: 140 ms fast, 220 ms normal, 320 ms slow, ease-out cubic.
- Type: nothing below 9.5 sp. Body line height 1.45. The day header pairs a
  30 sp weekday title with the full date under it; each hour card pairs a
  15 sp title with the hour range under it.
- Elevation: neutral black shadows only. No coloured glow.
