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

## Android widget

The widget shows the current hour and the next four. Each row has the hour, the
item, and a state chip:

- `NOW` in green. Tap it to mark the item done.
- `DONE` in red. Tap it to put the item back in place.
- `Tap to add` on an empty hour. Tap it to open the app.

A tap on a chip runs a Dart callback in a background isolate. It flips the item,
saves it, and repaints the widget. The app and the widget share one store, so a
change in one shows in the other.

`android/app/src/main/kotlin/com/awun/todo_app/HourlyWidgetProvider.kt` builds
the rows with `RemoteViews`. The app sends JSON through the `home_widget`
package under the key `hourly_payload`.

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
flutter test      # 29 tests
```

| Suite | Covers |
|---|---|
| `day_schedule_cubit_test.dart` | load, save, toggle, delete, day change, write failure, widget sync, progress |
| `schedule_local_repository_test.dart` | day isolation, replace, delete, bad records, bad JSON |
| `widget_payload_test.dart` | slot window, midnight stop, day counts |
| `day_screen_test.dart` | add, toggle, remove, day arrows, repaint, reload |

## Limits

- The widget is Android only. iOS uses the same store, but it has no widget yet.
- There is no sync and no backup. Uninstalling the app removes the plan.
- The widget shows five hours. A full day list needs a taller, scrollable widget.
- Due dates, notes, and reminders are not implemented. One hour holds one item.
