import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../data/reminders/reminder_service.dart';
import '../../data/widget/home_widget_bridge.dart';
import '../../data/widget/widget_window.dart';
import 'day_schedule_state.dart';

/// Owns the selected day, applies the edits, and mirrors today to the widget.
///
/// [reminders] is rescheduled everywhere the widget is synced: on load and
/// after every edit. A reminder failure never blocks the edit.
class DayScheduleCubit extends Cubit<DayScheduleState> {
  DayScheduleCubit(
    this._repository,
    this._widgets, {
    DateTime Function()? clock,
    ReminderService? reminders,
  })  : _reminders = reminders ?? const NoopReminderService(),
        _clock = clock ?? DateTime.now,
        super(DayScheduleState(day: DateKey.dateOnly((clock ?? DateTime.now)())));

  final ScheduleRepository _repository;
  final WidgetBridge _widgets;
  final ReminderService _reminders;
  final DateTime Function() _clock;

  static const String _loadError = 'This day could not be loaded.';
  static const String _saveError = 'The change could not be saved.';

  /// Hour of the current time when the selected day is today. Null otherwise.
  int? get currentHourIfToday {
    final DateTime now = _clock();
    return state.isTodayAt(now) ? now.hour : null;
  }

  Future<void> load() async {
    emit(state.copyWith(status: ScheduleStatus.loading, clearError: true));
    try {
      final List<HourEntry> entries =
          await _repository.fetchDay(DateKey.of(state.day));
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          entries: Map<int, HourEntry>.unmodifiable(_index(entries)),
          status: ScheduleStatus.ready,
          clearError: true,
        ),
      );
    } on Object {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: ScheduleStatus.failure, errorMessage: _loadError));
      return;
    }
    await _syncIntegrations();
  }

  Future<void> selectDay(DateTime day) async {
    final DateTime target = DateKey.dateOnly(day);
    if (DateKey.isSameDay(target, state.day) && state.status == ScheduleStatus.ready) {
      return;
    }
    emit(DayScheduleState(day: target, status: ScheduleStatus.loading));
    await load();
  }

  Future<void> shiftDay(int days) {
    final DateTime current = state.day;
    return selectDay(DateTime(current.year, current.month, current.day + days));
  }

  Future<void> goToToday() => selectDay(_clock());

  /// Saves [text] in [hour]. An empty text removes the entry.
  Future<bool> saveEntry(int hour, String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      return deleteEntry(hour);
    }
    final HourEntry? existing = state.entries[hour];
    final DateTime now = _clock();
    final HourEntry entry = HourEntry(
      dateKey: DateKey.of(state.day),
      hour: hour,
      text: trimmed,
      updatedAt: now,
      status: existing?.status ?? HourStatus.active,
    );
    return _commit(entry);
  }

  /// Flips the hour between in place and done.
  Future<bool> toggle(int hour) async {
    final HourEntry? entry = state.entries[hour];
    if (entry == null) {
      return false;
    }
    return _commit(
      entry.copyWith(
        status: entry.isCompleted ? HourStatus.active : HourStatus.completed,
        updatedAt: _clock(),
      ),
    );
  }

  Future<bool> deleteEntry(int hour) async {
    final HourEntry? entry = state.entries[hour];
    if (entry == null) {
      return false;
    }
    final DayScheduleState previous = state;
    emit(
      state.copyWith(
        entries: Map<int, HourEntry>.unmodifiable(
          Map<int, HourEntry>.from(state.entries)..remove(hour),
        ),
        status: ScheduleStatus.ready,
        clearError: true,
      ),
    );
    try {
      await _repository.delete(entry.dateKey, hour);
    } on Object {
      if (isClosed) {
        return false;
      }
      emit(previous.copyWith(status: ScheduleStatus.failure, errorMessage: _saveError));
      return false;
    }
    await _syncIntegrations();
    return true;
  }

  Future<bool> _commit(HourEntry entry) async {
    final DayScheduleState previous = state;
    emit(
      state.copyWith(
        entries: Map<int, HourEntry>.unmodifiable(
          <int, HourEntry>{...state.entries, entry.hour: entry},
        ),
        status: ScheduleStatus.ready,
        clearError: true,
      ),
    );
    try {
      await _repository.upsert(entry);
    } on Object {
      if (isClosed) {
        return false;
      }
      emit(previous.copyWith(status: ScheduleStatus.failure, errorMessage: _saveError));
      return false;
    }
    await _syncIntegrations();
    return true;
  }

  /// The widget and the reminders cover today only. A failed sync must not
  /// block the edit.
  Future<void> _syncIntegrations() async {
    final DateTime now = _clock();
    if (!state.isTodayAt(now)) {
      return;
    }
    late final List<HourEntry> entries;
    try {
      entries = await WidgetWindow.collect(_repository, now);
    } on Object {
      return;
    }
    try {
      await _widgets.sync(now: now, entries: entries);
    } on Object {
      // Ignore. The app state is already saved.
    }
    try {
      await _reminders.rescheduleDay(now: now, entries: entries);
    } on Object {
      // Ignore. The app state is already saved.
    }
  }

  Map<int, HourEntry> _index(List<HourEntry> entries) {
    return <int, HourEntry>{
      for (final HourEntry entry in entries) entry.hour: entry,
    };
  }
}
