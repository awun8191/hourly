# Hourly

A day planner where every hour is one block. Flutter app for Android, iOS, and
web. The Android home screen widget is the main feature.

All data stays on the device. The app makes no network call.

## Concept

The day is 24 blocks, from 00:00 to 23:00. Each block holds one item.

| State | Look | Meaning |
|---|---|---|
| Empty | Outline and "Add task" | No item in this hour |
| In place | Green card, switch on | The item is set for this hour |
| Done | Small red struck text, switch off | The item is complete |

Green means in place. Red means done. This mapping is the user's choice.

Tap an empty block to type. Tap an item to edit or remove it. Use the switch to
move between green and red. The arrows change the day, and every day stays in
history.

The list is grouped by part of day (night, morning, afternoon, evening), and the
live hour carries a `NOW` tag, a tinted card, and a soft shadow. Empty hours stay
quiet so a planned day stands out.

The header carries a segmented day meter: one segment per hour, 24 in all, drawn
as four groups of six to match the sections below it. Red is done, green is in
place, the faint track is a free hour, and the live hour carries a ring and a
small lift. It is one semantics node; the segments themselves are decorative.

## Android widget

The widget resizes from a 2x2 cell to a full screen card. `minWidth` and
`minHeight` are 110dp so a small placement is allowed, the default is a 4x4
cell, and `HourlyWidgetProvider.onAppWidgetOptionsChanged` repaints the widget
when the launcher reports a new size. `WidgetSize` picks one of three layouts
from the reported width and height (a cell is about 70dp):

| Bucket | Placement | Layout | Shows |
|---|---|---|---|
| Compact | under 170dp wide or 200dp tall (2x2, 4x2) | `hourly_widget_compact` | the live hour, its state chip, its item |
| Medium | 200dp to 319dp tall (4x3, 4x4) | `hourly_widget` | the hero, 1 to 3 rows after it, the meter, the count |
| Large | 320dp tall or more (4x6, full screen) | `hourly_widget_large` | the day in hour order, the hero in place, up to 6 rows, the meter, the legend |

- **Hero** for the current hour: the time in large tabular figures, a `NOW` tag,
  a state chip (`IN PLACE` green, `DONE` red, `FREE` grey), the item, a bar for
  how much of the hour has run, and a line such as `This hour ends in 18 min`.
- **The day in hour order** in the large bucket, not only the future: hours that
  have passed are dimmed (done ones struck red), the live hour is the hero card
  in its place, then the hours after it. When the day does not fit, the oldest
  hours fold into `+2 earlier hours planned` and the furthest into
  `+3 more hours planned`.
- **Rows** for the hours around the hero: a state bar, the hour, the item, and a
  chip reading `IN PLACE`, `DONE`, or `FREE`. Rows are weighted, so the body
  fills its box instead of leaving a blank band under the last row.
- **Day meter** at the bottom: one segment per planned hour, red for done, green
  for in place, a ring on the live hour, then the count
  (`3 of 7 planned hours done`).

Each hour appears once: the next hour is a row, there is no separate NEXT line,
and only the hero hour says `NOW`.

Tapping a chip runs a Dart callback in a background isolate. It flips the item,
saves it, and repaints the widget. The app and the widget share one store, so a
change in one shows in the other. A tap on a row opens the app at that hour.

The widget also handles its quiet states: a hero with no item asks you to plan
the hour, a day with no items says so, and a payload from another day is marked
`SHOWING MONDAY 26` with a `STALE` chip. Dark mode comes from `values-night`.

`android/app/src/main/kotlin/com/awun/todo_app/HourlyWidgetProvider.kt` builds
the views with `RemoteViews`. `WidgetSize.kt` is the size chooser and
`WidgetDayPlan.kt` decides which hours to paint; both are pure Kotlin and unit
tested. The app sends JSON through the `home_widget` package under the key
`hourly_payload`:

```json
{
  "date": "2026-10-26",
  "day": "Monday 26",
  "done": 1,
  "total": 3,
  "nowHour": 9,
  "minutesIntoHour": 42,
  "minutesLeft": 18,
  "hourPercent": 70,
  "dayPercent": 33,
  "segments": [
    { "hour": 9, "state": "active", "text": "Standup" },
    { "hour": 11, "state": "completed", "text": "Review" }
  ],
  "next": { "hour": 11, "label": "11:00", "text": "Review", "status": "completed" },
  "slots": [
    { "hour": 9, "label": "09:00", "text": "Standup", "status": "active", "current": true }
  ]
}
```

`WidgetPayload.build()` computes every field from the injected `now`, so the
payload tests cover the hour math, the next-up lookup, and the day percent.
`segments` carries every planned hour of the day, which feeds both the meter and
the chronological body. The provider parses it with `optJSONArray` and an hour
range check, and falls back to `slots` when the field is missing.

## Stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.47.8 (Dart 3.13.7) |
| State | `flutter_bloc` 9, Cubit |
| Local store | `shared_preferences` 2 (one JSON document per day) |
| Widget bridge | `home_widget` 0.10 |
| Dates | `intl` |
| Tests | `flutter_test`, `bloc_test` |

## Get started

```bash
flutter pub get
flutter run
```

Add the widget from the Android home screen picker, under "Hourly".

```bash
flutter build apk --debug
flutter build web --release
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
    │   ├── entities/day_segments.dart    # the 24 segment day meter model
    │   └── repositories/schedule_repository.dart
    ├── data/
    │   ├── models/hour_entry_mapper.dart
    │   ├── repositories/schedule_local_repository.dart
    │   └── widget/
    │       ├── widget_payload.dart         # JSON shape for the widget
    │       ├── home_widget_bridge.dart     # home_widget calls
    │       └── widget_toggle_callback.dart # background isolate
    └── presentation/
        ├── cubit/day_schedule_cubit.dart, day_schedule_state.dart
        ├── screens/day_screen.dart
        └── widgets/hour_block.dart, day_header.dart, hour_editor_sheet.dart
```

Data flow: a block calls `DayScheduleCubit`, the cubit changes
`DayScheduleState` and writes through `ScheduleRepository`, then it sends today
to the widget. A failed write restores the old state and shows a message. A
failed widget sync does not block the edit.

The store is an interface, so a different backend is one line in `main.dart`.

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
flutter test      # 53 tests
cd android && ./gradlew :app:testDebugUnitTest   # 18 widget Java/Kotlin tests
```

| Suite | Covers |
|---|---|
| `day_schedule_cubit_test.dart` | load, save, toggle, delete, day change, write failure, widget sync, progress |
| `schedule_local_repository_test.dart` | day isolation, replace, delete, bad records, bad JSON |
| `widget_payload_test.dart` | slot window, midnight stop, day counts, minutes into the hour, next-up lookup, day percent, meter segments |
| `day_segments_test.dart` | 24 segments, in place vs done, live hour, out of range hours, meter label |
| `day_header_test.dart` | segment count, colours, live ring and lift, one semantics node, empty day, dark theme |
| `day_screen_test.dart` | add, toggle, remove, day arrows, repaint, reload, small-screen layout, dark theme |
| `WidgetSizeTest` | compact, medium, and large buckets, row counts, resize headroom |
| `WidgetDayPlanTest` | chronological day, earlier and more lines, free hour fill, one hero per day |

## Limits

- The widget is Android only. iOS uses the same store, but it has no widget yet.
- There is no sync and no backup. Uninstalling the app removes the plan.
- The widget paints at most seven hour cells. A whole 24 hour day in one card
  needs scrolling, which `RemoteViews` does not do simply.
- Due dates, notes, and reminders are not implemented. One hour holds one item.
