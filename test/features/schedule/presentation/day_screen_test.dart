import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/app.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';

import '../../../helpers/fake_schedule_repository.dart';
import '../../../helpers/fake_widget_bridge.dart';

void main() {
  final DateTime fixed = DateTime(2026, 10, 26, 9, 30);

  late FakeScheduleRepository repository;
  late FakeWidgetBridge bridge;

  setUp(() {
    repository = FakeScheduleRepository();
    bridge = FakeWidgetBridge();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      HourlyApp(
        repository: repository,
        widgetBridge: bridge,
        clock: () => fixed,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> addItem(WidgetTester tester, int hour, String text) async {
    await tester.tap(find.byKey(Key('hour-$hour')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('hour-text-field')), text);
    await tester.tap(find.byKey(const Key('hour-save-button')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the day and the current hour, then adds an item', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('26 October 2026'), findsOneWidget);
    expect(find.text('Tap an hour to plan it'), findsOneWidget);

    await addItem(tester, 9, 'Standup');

    expect(find.text('Standup'), findsOneWidget);
    expect(find.text('0 of 1 planned hours done'), findsOneWidget);
    expect(repository.day('2026-10-26')[9]!.text, 'Standup');
    expect(repository.day('2026-10-26')[9]!.isCompleted, isFalse);
  });

  testWidgets('the switch turns an item red and counts it as done', (WidgetTester tester) async {
    await pumpApp(tester);
    await addItem(tester, 9, 'Standup');

    await tester.tap(find.byKey(const Key('toggle-9')));
    await tester.pumpAndSettle();

    final Switch toggle = tester.widget<Switch>(
      find.descendant(of: find.byKey(const Key('toggle-9')), matching: find.byType(Switch)),
    );
    expect(toggle.value, isFalse);
    expect(find.text('1 of 1 planned hours done'), findsOneWidget);
    expect(repository.day('2026-10-26')[9]!.isCompleted, isTrue);
  });

  testWidgets('day arrows move between days and keep each day apart', (WidgetTester tester) async {
    await pumpApp(tester);
    await addItem(tester, 9, 'Standup');

    await tester.tap(find.byTooltip('Next day'));
    await tester.pumpAndSettle();

    expect(find.text('27 October 2026'), findsOneWidget);
    expect(find.text('Standup'), findsNothing);

    await tester.tap(find.byTooltip('Previous day'));
    await tester.pumpAndSettle();

    expect(find.text('26 October 2026'), findsOneWidget);
    expect(find.text('Standup'), findsOneWidget);
  });

  testWidgets('an edit updates the widget payload', (WidgetTester tester) async {
    await pumpApp(tester);
    await addItem(tester, 9, 'Standup');

    expect(bridge.syncs, isNotEmpty);
    expect(bridge.syncs.last.now, fixed);
    expect(bridge.syncs.last.entries.single.hour, 9);
  });

  testWidgets('the remove action clears the hour', (WidgetTester tester) async {
    await pumpApp(tester);
    await addItem(tester, 9, 'Standup');

    await tester.tap(find.byKey(const Key('hour-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Standup'), findsNothing);
    expect(find.text('Tap an hour to plan it'), findsOneWidget);
    expect(repository.day('2026-10-26'), isEmpty);
  });

  testWidgets('a saved item survives a new cubit load', (WidgetTester tester) async {
    await pumpApp(tester);
    await addItem(tester, 9, 'Standup');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await pumpApp(tester);

    expect(find.text('Standup'), findsOneWidget);
  });

  testWidgets('a 360x640 phone renders the grouped day without overflow',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repository = FakeScheduleRepository(<String, List<HourEntry>>{
      '2026-10-26': <HourEntry>[
        HourEntry(dateKey: '2026-10-26', hour: 9, text: 'Standup', updatedAt: fixed),
        HourEntry(
          dateKey: '2026-10-26',
          hour: 11,
          text: 'Review',
          status: HourStatus.completed,
          updatedAt: fixed,
        ),
      ],
    });

    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Standup'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('1 of 2 planned hours done'), findsOneWidget);
  });

  testWidgets('the dark theme paints the same day', (WidgetTester tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    repository = FakeScheduleRepository(<String, List<HourEntry>>{
      '2026-10-26': <HourEntry>[
        HourEntry(dateKey: '2026-10-26', hour: 9, text: 'Standup', updatedAt: fixed),
        HourEntry(
          dateKey: '2026-10-26',
          hour: 10,
          text: 'Review',
          status: HourStatus.completed,
          updatedAt: fixed,
        ),
      ],
    });

    await pumpApp(tester);

    expect(tester.takeException(), isNull);
    final BuildContext context = tester.element(find.text('Standup'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(StatusPalette.of(context).activeSurface, StatusPalette.dark.activeSurface);
    expect(find.text('1 of 2 planned hours done'), findsOneWidget);
  });
}
