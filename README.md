# todo-app

An offline to-do application for Android, iOS, and web. Flutter 3.47.8.

All data stays on the device. The app makes no network call.

## Features

- Add, edit, and delete tasks
- Optional notes and due date per task
- Mark a task done with one tap
- Filter by All, Active, or Done
- Progress bar with a done count
- Swipe to delete, with an Undo action
- Clear all completed tasks
- Overdue marker on open tasks
- Light and dark theme

## Stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.47.8 (Dart 3.13.7) |
| State | `flutter_bloc` 9, Cubit |
| Local store | `shared_preferences` 2 (JSON list) |
| Dates | `intl` |
| Ids | `uuid` v4 |
| Tests | `flutter_test`, `bloc_test` |

## Get started

```bash
flutter pub get
flutter run
```

Web build:

```bash
flutter build web --release
```

## Architecture

The app uses a feature-first clean architecture. The storage sits behind one
interface, so a different store is one line in `main.dart`.

```
lib/
├── main.dart                  # builds SharedPreferences and the repository
├── app.dart                   # MaterialApp, BlocProvider, theme
├── core/theme/app_theme.dart  # Material 3 light and dark themes
└── features/tasks/
    ├── domain/
    │   ├── entities/task.dart              # immutable Task
    │   └── repositories/task_repository.dart # interface + exception
    ├── data/
    │   ├── models/task_mapper.dart         # JSON shape
    │   └── repositories/task_local_repository.dart
    └── presentation/
        ├── cubit/task_cubit.dart, task_state.dart
        ├── screens/tasks_screen.dart
        └── widgets/task_tile.dart, task_editor_sheet.dart,
            tasks_empty_state.dart
```

Data flow: a widget calls `TaskCubit`, the cubit changes `TaskState`, then it
calls `TaskRepository.persist`. A failed write restores the old state and
shows a message. There is no use case layer, because each use case would only
forward one repository call.

## Data format

`SharedPreferences` key `tasks.v1` holds one JSON array:

```json
[
  {
    "id": "8f1c...",
    "title": "Pay rent",
    "notes": "Before noon",
    "isDone": false,
    "createdAt": "2026-10-26T09:12:00.000Z",
    "dueDate": "2026-10-30T00:00:00.000"
  }
]
```

`TaskMapper` owns this shape. Records with no id or title are skipped. Invalid
JSON raises `TaskStorageException`, and the UI shows an error.

## Tests

```bash
flutter analyze   # no issues
flutter test      # 22 tests
```

| Suite | Covers |
|---|---|
| `test/.../task_cubit_test.dart` | load, add, update, toggle, delete, undo, clear, filters, ordering, write failure |
| `test/.../task_local_repository_test.dart` | empty store, round trip, bad records, bad JSON, key format |
| `test/.../tasks_screen_test.dart` | add task, empty title, toggle and filter, swipe delete and undo |

## Limits

- There is no sync and no backup. Uninstalling the app removes the tasks.
- The task list is one document per write. This is fine for personal lists.
  A large list needs a row-based store behind the same `TaskRepository`.
- Reminders are not implemented. A due date is display only.
