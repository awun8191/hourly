# Tasks

## Active

- [ ] Install `build/app/outputs/flutter-apk/app-debug.apk` on a phone
- [ ] Add the widget from the home screen picker and check the five rows
- [ ] Check the widget toggle loop on the device: chip tap, red state, app state
- [ ] Add a screenshot of the widget to the README

## Waiting On

- A physical Android device for the widget test

## Someday

- iOS widget with App Intents
- Open the app at the tapped hour (the intent already sends the hour)
- Notes on a block
- Drag an item to another hour
- Week view
- Reminders before an hour starts

## Done

- [x] Debug APK builds with the widget code (2026-10-26)
- [x] Android SDK 36, build-tools 36, JDK 17 on the host (2026-10-26)
- [x] Swap raised to 8 GB for the Gradle build (2026-10-26)
- [x] Hourly day model: 24 blocks, one item each (2026-10-26)
- [x] Green in place, red done, with switch toggle (2026-10-26)
- [x] Day arrows with history per date (2026-10-26)
- [x] Local store: one JSON document per day (2026-10-26)
- [x] Widget payload and `home_widget` bridge (2026-10-26)
- [x] Android `HourlyWidgetProvider` with RemoteViews (2026-10-26)
- [x] Background toggle callback from the widget (2026-10-26)
- [x] 29 unit and widget tests pass (2026-10-26)
- [x] `flutter analyze` no issues, web release build ok (2026-10-26)
