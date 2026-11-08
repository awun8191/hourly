import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/theme/app_theme.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';
import 'package:todo_app/features/schedule/presentation/widgets/day_header.dart';

void main() {
  final DateTime day = DateTime(2026, 10, 26);

  HourEntry entry(int hour, {HourStatus status = HourStatus.active}) {
    return HourEntry(
      dateKey: '2026-10-26',
      hour: hour,
      text: 'Item $hour',
      status: status,
      updatedAt: day,
    );
  }

  Widget header({
    List<HourEntry> entries = const <HourEntry>[],
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: Scaffold(
        body: DayHeader(
          day: day,
          isToday: false,
          doneCount: entries.where((HourEntry e) => e.isCompleted).length,
          total: entries.length,
          onPrevious: () {},
          onNext: () {},
          onToday: () {},
        ),
      ),
    );
  }

  testWidgets('shows the weekday and the full date', (WidgetTester tester) async {
    await tester.pumpWidget(header());

    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('26 October 2026'), findsOneWidget);
  });

  testWidgets('an empty day keeps the plain hint and no meter', (WidgetTester tester) async {
    await tester.pumpWidget(header());

    expect(find.text('Nothing planned yet'), findsOneWidget);
    expect(find.text('Pick an hour below to plan it.'), findsOneWidget);
    expect(find.text('Plan the current hour'), findsNothing);
    expect(find.byKey(const Key('day-meter')), findsNothing);
  });

  testWidgets('keeps the planned count', (WidgetTester tester) async {
    await tester.pumpWidget(
      header(entries: <HourEntry>[entry(9), entry(11, status: HourStatus.completed)]),
    );

    expect(find.text('1 of 2 planned hours done'), findsOneWidget);
    expect(find.text('Nothing planned yet'), findsNothing);
  });

  testWidgets('paints in the dark theme without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      header(
        entries: <HourEntry>[entry(9), entry(11, status: HourStatus.completed)],
        brightness: Brightness.dark,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('1 of 2 planned hours done'), findsOneWidget);
  });
}
