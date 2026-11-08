# Hourly

A day planner where every hour is one block. A Flutter app for Android.
The Android home screen widget is the main feature.

All data stays on the device. The app makes no network call.

## Concept

The day is 24 blocks, from 00:00 to 23:00. Each block holds one item.

| State | Look | Meaning |
|---|---|---|
| Empty | Outline and "Add task" | No item in this hour |
| In place | Accent card, toggle on | The item is set for this hour |
| Done | Small red struck text, toggle off | The item is complete |

White is in place on dark, ink on light. Red `#FF3B30` is done. This mapping is
the user's choice.

Every hour carries the toggle, empty hours too. The track is bark when the hour is
off and pale moss when the toggle is on. The knob is a solid disc, with a
shadow, and a lift. On an empty hour the toggle opens the planner. Dark mode uses
a deep indigo background.

Tap an empty block to type. Tap an item to edit or remove it. Use the toggle to
move between in place and done. The arrows change the day, and every day stays in
history.

The list is grouped by part of day (night, morning, afternoon, evening), and the
live hour carries a `NOW` tag and a tinted card. Empty hours stay quiet so a
planned day stands out.

## Android widget

One compact live row for the current hour, then the whole of today as cards.

- The live hour is one row: the time, the item, a state chip. No big type,
  no meta line. The widget repaints just after each hour starts, and after
  every edit.
- The chip and the card colour carry the state: `IN PLACE` on the green card,
  `DONE` on the red card, `+ ADD` on the empty card. The live hour comes from the
  device clock, not from the payload's timestamp.
- **The whole of today, midnight to 23:00**: one header (`TODAY · FRIDAY 30`)
  with a hairline rule, then 24 hour cards in order. Morning items stay visible
  all day. The live hour card carries an accent border and a `NOW` tag. A past
  hour still in place reads MISSED in red. Each card carries its time and its
  item, or a muted `+ Add task`. The list fills the cell when the widget is
  tall and scrolls when it is short. It resets at midnight by itself.
- **Tap any card** and a small text field opens over the home screen, prefilled
  with that hour's item. Android widgets cannot host an `EditText`, so
  `QuickAddActivity` is a dialog-style activity with a real field. `Save` writes
  the item, `Clear` removes it, `Cancel` changes nothing.
- **Tap the hero chip** to flip the live hour between in place and done. On an
  empty hero, the chip and the card open the text field.

No 24 hour strip, no counts, no progress bars. The widget asks for a 4x4 cell
(`minHeight` 240dp) and resizes both ways.

### Quick add

A tap on the hero or on any hour card opens one small card over the home screen,
in the widget's colours.

- A day overline (`FRIDAY 30`), the hour at 26sp, and a 34dp close control.
- One recessed text field, three lines tall, with the item already in it.
- `Clear` sits on the left in red and stays dim until the field has text.
- `Save` is the accent pill. `Cancel` and the close control change nothing.
- The card is centered with 20dp margins, a 26dp radius, a 1dp border, and a
  24dp lift. The keyboard pushes the card up instead of covering it.

`HourlyWidgetProvider` builds the hero card with `RemoteViews`, and
`HourlyWidgetService` builds the rows. The app sends one small JSON document
through `home_widget` under `hourly_payload`:

```json
{
  "date": "2026-10-30",
  "day": "Friday 30",
  "hour": 22,
  "slots": [
    {
      "date": "2026-10-30",
      "hour": 0,
      "label": "00:00",
      "text": "",
      "status": "empty"
    },
    {
      "date": "2026-10-30",
      "hour": 9,
      "label": "09:00",
      "text": "Gym",
      "status": "active"
    },
    {
      "date": "2026-10-30",
      "hour": 22,
      "label": "22:00",
      "text": "Brush teeth",
      "status": "active"
    }
  ]
}
```

`slots` holds all 24 hours of today, midnight to 23:00, in order. Every slot
carries its own date, so a tap writes to the right day. The widget finds the
live slot with the device clock, which keeps the hero correct when the app has
not run for a while. The app sends today only. At midnight the new day arrives
with the next sync, and the list starts over.

A chip tap runs a Dart callback in a background isolate, which flips the item and
repaints the widget. The quick add dialog writes the same store the app reads
(`FlutterSharedPreferences`, key `flutter.hours.v1.<date>`), then sends
`hourly://refresh` so the Dart callback repaints from the store. The app picks up
a widget-written item on its next load.

## Stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.47.8 (Dart 3.13.7) |
| State | `flutter_bloc` 9, Cubit |
| Local store | `shared_preferences` 2 (one JSON document per day) |
| Widget bridge | `home_widget` 0.10 |
| Dates | `intl` |
| Tests | `flutter_test` |

## Get started

```bash
flutter pub get
flutter run
```

Add the widget from the Android home screen picker, under "Hourly".

```bash
flutter build apk --debug
```

## Architecture

```
lib/
├── main.dart                     # store, widget callback registration
├── app.dart                      # MaterialApp, BlocProvider
├── core/
│   ├── date/date_key.dart        # yyyy-MM-dd keys and hour labels
│   └── theme/app_theme.dart      # Material 3 theme, StatusPalette
└── features/schedule/
    ├── domain/
    │   ├── entities/hour_entry.dart
    │   └── repositories/schedule_repository.dart
    ├── data/
    │   ├── models/hour_entry_mapper.dart
    │   ├── repositories/schedule_local_repository.dart
    │   └── widget/
    │       ├── widget_payload.dart         # all 24 hours of today
    │       ├── widget_window.dart          # today only, for the widget
    │       ├── home_widget_bridge.dart     # home_widget calls
    │       └── widget_toggle_callback.dart # toggle and refresh callbacks
    └── presentation/
        ├── cubit/day_schedule_cubit.dart, day_schedule_state.dart
        ├── screens/day_screen.dart
        └── widgets/hour_block.dart, hour_toggle.dart, day_header.dart,
            hour_editor_sheet.dart
```

Android side:

```
android/app/src/main/kotlin/com/awun/todo_app/
├── MainActivity.kt
├── HourlyWidgetProvider.kt   # hero card, RemoteViews
├── HourlyWidgetService.kt    # the scrolling list of hour cards
└── QuickAddActivity.kt       # the text field the widget opens
```

Data flow: a block calls `DayScheduleCubit`, the cubit changes
`DayScheduleState` and writes through `ScheduleRepository`, then it sends the
current hour to the widget. A failed write restores the old state and shows a
message. A failed widget sync does not block the edit.

The store is an interface, so a different backend is one line in `main.dart`.

The palette, spacing, radii and motion live in `lib/core/theme/design_tokens.dart`.
The Android widget mirrors those values in XML, and
`docs/design-tokens.md` maps every name. A test fails when the two drift.

## Data format

`shared_preferences` key `hours.v1.<yyyy-MM-dd>` holds one JSON object per day:

```json
{
  "9": {
    "text": "Standup",
    "status": "active",
    "updatedAt": "2026-10-26T09:12:00.000"
  },
  "11": {
    "text": "Review",
    "status": "completed",
    "updatedAt": "2026-10-26T09:40:00.000"
  }
}
```

A day document holds at most 24 entries. Invalid JSON raises
`ScheduleStorageException`. Bad hour keys and blank text are skipped.

## Tests

```bash
flutter analyze   # no issues
flutter test      # 45 tests
```

| Suite | Covers |
|---|---|
| `day_schedule_cubit_test.dart` | load, save, toggle, delete, day change, write failure, widget sync, progress |
| `schedule_local_repository_test.dart` | day isolation, replace, delete, bad records, bad JSON |
| `widget_payload_test.dart` | full day 00 to 23, morning items persist, empty hour |
| `day_header_test.dart` | weekday and date, planned count, empty hint, dark theme |
| `day_screen_test.dart` | add, toggle, remove, day arrows, repaint, reload, small-screen layout, dark theme |
| `design_tokens_test.dart` | the widget XML mirrors the tokens, indigo ramp, no stray green or pink |

## Limits

- There is no sync and no backup. Uninstalling the app removes the plan.
- The widget shows the current hour only. It does not list the day.
- Android widgets cannot host an `EditText`; the text field is a dialog activity
  over the home screen.
- Due dates, notes, and reminders are not implemented. One hour holds one item.
