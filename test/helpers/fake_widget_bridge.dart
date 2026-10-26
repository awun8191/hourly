import 'package:todo_app/features/schedule/data/widget/home_widget_bridge.dart';
import 'package:todo_app/features/schedule/domain/entities/hour_entry.dart';

/// Records every widget sync instead of calling the platform channel.
class FakeWidgetBridge implements WidgetBridge {
  final List<({DateTime now, List<HourEntry> entries})> syncs =
      <({DateTime now, List<HourEntry> entries})>[];

  bool shouldFail = false;

  @override
  Future<void> sync({required DateTime now, required List<HourEntry> entries}) async {
    if (shouldFail) {
      throw StateError('widget sync failed');
    }
    syncs.add((now: now, entries: List<HourEntry>.of(entries)));
  }
}
