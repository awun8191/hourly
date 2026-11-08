import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    int? liveHour,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      home: Scaffold(
        body: DayHeader(
          day: day,
          isToday: liveHour != null,
          doneCount: entries.where((HourEntry e) => e.isCompleted).length,
          total: entries.length,
          entries: entries,
          liveHour: liveHour,
          onPrevious: () {},
          onNext: () {},
          onToday: () {},
          onPlanHour: (_) {},
        ),
      ),
    );
  }

  Finder segment(int hour) => find.byKey(Key('day-seg-$hour'));

  BoxDecoration decorationOf(WidgetTester tester, int hour) {
    final AnimatedContainer bar = tester.widget<AnimatedContainer>(segment(hour));
    return bar.decoration! as BoxDecoration;
  }

  testWidgets('paints one segment per hour, 24 in all', (WidgetTester tester) async {
    await tester.pumpWidget(
      header(entries: <HourEntry>[entry(9), entry(11, status: HourStatus.completed)]),
    );

    for (int hour = 0; hour < 24; hour++) {
      expect(segment(hour), findsOneWidget);
    }
    expect(find.byWidgetPredicate(
      (Widget widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('day-seg-'),
    ), findsNWidgets(24));
  });

  testWidgets('colours a done hour red, an in place hour accent, a free hour faint',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      header(entries: <HourEntry>[entry(9), entry(11, status: HourStatus.completed)]),
    );

    final ColorScheme scheme = Theme.of(tester.element(segment(9))).colorScheme;
    expect(decorationOf(tester, 11).color, StatusPalette.light.completed);
    expect(decorationOf(tester, 9).color, StatusPalette.light.active);
    expect(decorationOf(tester, 10).color, scheme.surfaceContainerHighest);
  });

  testWidgets('the live hour carries a ring and a lift', (WidgetTester tester) async {
    await tester.pumpWidget(header(entries: <HourEntry>[entry(9)], liveHour: 9));

    final BoxDecoration live = decorationOf(tester, 9);
    final BoxDecoration quiet = decorationOf(tester, 10);
    expect(live.border, isNotNull);
    expect(quiet.border, isNull);
    expect(tester.widget<AnimatedContainer>(segment(9)).constraints!.maxHeight, 12);
    expect(tester.widget<AnimatedContainer>(segment(10)).constraints!.maxHeight, 8);
  });

  testWidgets('one semantics node describes the whole meter', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      header(
        entries: <HourEntry>[entry(9), entry(11, status: HourStatus.completed)],
        liveHour: 9,
      ),
    );

    final SemanticsNode meter =
        tester.semantics.find(find.byKey(const Key('day-meter')));
    expect(meter.label,
        'Day meter, 24 hours: 1 done, 1 in place, 22 free. Now 09:00');
    // The segments are decorative: they add no nodes of their own.
    expect(meter.childrenCount, 0);
    handle.dispose();
  });

  testWidgets('an empty day shows the plan CTA instead of the meter', (WidgetTester tester) async {
    await tester.pumpWidget(header());

    expect(find.text('Nothing planned yet'), findsOneWidget);
    expect(find.text('Plan the current hour'), findsOneWidget);
    expect(segment(0), findsNothing);
  });

  testWidgets('the CTA plans the live hour, or 9 AM off today', (WidgetTester tester) async {
    int? planned;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DayHeader(
            day: day,
            isToday: false,
            doneCount: 0,
            total: 0,
            entries: const <HourEntry>[],
            liveHour: null,
            onPrevious: () {},
            onNext: () {},
            onToday: () {},
            onPlanHour: (int hour) => planned = hour,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Plan the current hour'));
    expect(planned, 9);
  });

  testWidgets('keeps the count and the legend', (WidgetTester tester) async {
    await tester.pumpWidget(
      header(entries: <HourEntry>[entry(9), entry(11, status: HourStatus.completed)]),
    );

    expect(find.text('1 of 2 planned hours done'), findsOneWidget);
    expect(find.text('In place'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets('paints in the dark theme without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      header(
        entries: <HourEntry>[entry(9), entry(11, status: HourStatus.completed)],
        liveHour: 9,
        brightness: Brightness.dark,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(decorationOf(tester, 11).color, StatusPalette.dark.completed);
    expect(decorationOf(tester, 9).color, StatusPalette.dark.active);
  });
}
