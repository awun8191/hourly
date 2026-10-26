import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/date/date_key.dart';
import '../../domain/entities/hour_entry.dart';
import '../cubit/day_schedule_cubit.dart';
import '../cubit/day_schedule_state.dart';
import '../widgets/day_header.dart';
import '../widgets/hour_block.dart';
import '../widgets/hour_editor_sheet.dart';

/// The day view: 24 hour rows, one item per hour.
class DayScreen extends StatefulWidget {
  const DayScreen({super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  static const double _rowExtent = 76;
  static const int _lastHour = 23;

  final ScrollController _controller = ScrollController();
  String? _scrolledFor;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEditor(int hour, HourEntry? entry) async {
    final DayScheduleCubit cubit = context.read<DayScheduleCubit>();
    final HourEditorResult? result = await showHourEditor(
      context,
      hour: hour,
      entry: entry,
    );
    if (result == null) {
      return;
    }
    switch (result.action) {
      case HourEditorAction.save:
        await cubit.saveEntry(hour, result.text);
      case HourEditorAction.delete:
        await cubit.deleteEntry(hour);
    }
  }

  /// Opens the list a little above the current hour, once per selected day.
  void _scrollToCurrentHour(DayScheduleState state, int? currentHour) {
    if (currentHour == null) {
      return;
    }
    final String key = DateKey.of(state.day);
    if (_scrolledFor == key) {
      return;
    }
    _scrolledFor = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      final double target = (currentHour - 1).clamp(0, _lastHour) * _rowExtent;
      _controller.jumpTo(target.clamp(0.0, _controller.position.maxScrollExtent));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<DayScheduleCubit, DayScheduleState>(
          listenWhen: (DayScheduleState previous, DayScheduleState current) =>
              current.errorMessage != null &&
              current.errorMessage != previous.errorMessage,
          listener: (BuildContext context, DayScheduleState state) {
            final String? message = state.errorMessage;
            if (message == null) {
              return;
            }
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          },
          builder: (BuildContext context, DayScheduleState state) {
            final DayScheduleCubit cubit = context.read<DayScheduleCubit>();
            final int? currentHour = cubit.currentHourIfToday;
            if (state.status == ScheduleStatus.ready) {
              _scrollToCurrentHour(state, currentHour);
            }
            return Column(
              children: <Widget>[
                DayHeader(
                  day: state.day,
                  isToday: state.isTodayAt(DateTime.now()),
                  doneCount: state.doneCount,
                  total: state.filledCount,
                  onPrevious: () => cubit.shiftDay(-1),
                  onNext: () => cubit.shiftDay(1),
                  onToday: cubit.goToToday,
                ),
                Expanded(
                  child: state.status == ScheduleStatus.initial ||
                          state.status == ScheduleStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          controller: _controller,
                          padding: const EdgeInsets.fromLTRB(8, 4, 16, 24),
                          itemExtent: _rowExtent,
                          itemCount: 24,
                          itemBuilder: (BuildContext context, int index) {
                            final int hour = index;
                            final HourEntry? entry = state.entries[hour];
                            return HourBlock(
                              key: ValueKey<String>('hour-$hour'),
                              hour: hour,
                              entry: entry,
                              isCurrentHour: currentHour == hour,
                              onTap: () => _openEditor(hour, entry),
                              onToggle: () => cubit.toggle(hour),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
