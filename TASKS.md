# Tasks

## Active

- [ ] Install `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` on a phone
- [ ] Add the widget from the home screen picker, on a 4x4 cell
- [ ] Resize the widget down to 2x2 and up to the full screen: the compact,
      medium, and large layouts must all fill their box
- [ ] Check the widget toggle loop on the device: chip tap, red state, app state
- [ ] Add a screenshot of the widget to the README

## Waiting On

- A physical Android device for the widget resize and toggle checks

## Someday

- iOS widget with App Intents
- Open the app at the tapped hour (the intent already sends the hour)
- Notes on a block
- Drag an item to another hour
- Week view
- Reminders before an hour starts
- Scrolling inside the widget for a full 24 hour day (RemoteViews only)

## Done

- [x] Segmented day meter in the header: 24 segments, live hour ring (2026-10-29)
- [x] Responsive widget: compact, medium, and large layouts picked from the
      launcher size, repainted on resize (2026-10-29)
- [x] Widget body is the whole day in hour order, hero in place, with
      earlier/more hour counts instead of blank space (2026-10-29)
- [x] One representation per hour: no NEXT line, NOW only on the hero (2026-10-29)
- [x] Legibility: body 12sp or more, labels 10sp or more, stronger muted grey (2026-10-29)
- [x] Copy: every countdown names the hour it ends, footer says planned hours (2026-10-29)
- [x] 53 Flutter tests and 18 widget unit tests pass, analyze clean (2026-10-29)
- [x] Day list grouped by night, morning, afternoon, evening (2026-10-29)
- [x] Current hour marker: NOW tag, tinted card, soft shadow (2026-10-29)
- [x] Motion on toggle, day change, and progress; haptic on toggle (2026-10-29)
- [x] Widget hero for the live hour with hour progress and next-up line (2026-10-29)
- [x] Widget empty, no-items, and stale-day states (2026-10-29)
- [x] 36 tests pass, `flutter analyze` clean, debug APK builds (2026-10-29)

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
