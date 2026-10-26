import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../data/widget/home_widget_bridge.dart';
import 'day_schedule_state.dart';

/// Owns the selected day, applies the edits, and mirrors today to the widget.
class DayScheduleCubit extends Cubit<DayScheduleState> {
  DayScheduleCubit(
    this._repository,
    this._widgets, {
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(DayScheduleState(day: DateKey.dateOnly((clock ?? DateTime.now)())));

  final ScheduleRepository _repository;
  final WidgetBridge _widgets;
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
    await _syncWidget();
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

  /// Flips green (in place) and red (done).
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
    await _syncWidget();
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
    await _syncWidget();
    return true;
  }

  /// The widget shows today only. A failed sync must not block the edit.
  Future<void> _syncWidget() async {
    final DateTime now = _clock();
    if (!state.isTodayAt(now)) {
      return;
    }
    try {
      await _widgets.sync(
        now: now,
        entries: state.entries.values.toList(growable: false),
      );
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
