import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/hour_entry.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../repositories/schedule_local_repository.dart';
import 'home_widget_bridge.dart';
import 'widget_window.dart';

/// Runs in a background isolate when the user taps the widget.
///
/// Two URIs are handled:
/// - `hourly://toggle?date=...&hour=...` flips one item.
/// - `hourly://refresh` re-reads today and repaints, after the quick add
///   dialog wrote a new item natively.
@pragma('vm:entry-point')
Future<void> handleWidgetToggle(Uri? uri) async {
  if (uri == null) {
    return;
  }
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final ScheduleRepository repository = ScheduleLocalRepository(preferences);
  final DateTime now = DateTime.now();

  if (uri.host == 'refresh') {
    await HomeWidgetBridge().sync(
      now: now,
      entries: await WidgetWindow.collect(repository, now),
    );
    return;
  }

  final String? dateKey = uri.queryParameters['date'];
  final int? hour = int.tryParse(uri.queryParameters['hour'] ?? '');
  if (dateKey == null || hour == null || hour < 0 || hour > 23) {
    return;
  }

  final List<HourEntry> entries = await repository.fetchDay(dateKey);
  HourEntry? target;
  for (final HourEntry entry in entries) {
    if (entry.hour == hour) {
      target = entry;
      break;
    }
  }
  if (target == null) {
    return;
  }

  await repository.upsert(
    target.copyWith(
      status: target.isCompleted ? HourStatus.active : HourStatus.completed,
      updatedAt: now,
    ),
  );
  await HomeWidgetBridge().sync(
    now: now,
    entries: await WidgetWindow.collect(repository, now),
  );
}
