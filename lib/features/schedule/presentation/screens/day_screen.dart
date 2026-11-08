import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/date/date_key.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/hour_entry.dart';
import '../cubit/day_schedule_cubit.dart';
import '../cubit/day_schedule_state.dart';
import '../widgets/day_header.dart';
import '../widgets/hour_block.dart';
import '../widgets/hour_editor_sheet.dart';

/// The day view: 24 hour rows, grouped by part of day, one item per hour.
class DayScreen extends StatefulWidget {
  const DayScreen({super.key});

  @override
  State<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen>
    with SingleTickerProviderStateMixin {
  static const double _rowExtent = 70;
  static const double _sectionExtent = 34;
  static const int _hoursPerSection = 6;
  static const int _lastHour = 23;

  static const List<String> _sections = <String>[
    'Night',
    'Morning',
    'Afternoon',
    'Evening',
  ];

  final ScrollController _controller = ScrollController();
  late final AnimationController _dayFade = AnimationController(
    vsync: this,
    duration: Motion.normal,
    value: 1,
  );

  String? _scrolledFor;

  @override
  void dispose() {
    _dayFade.dispose();
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

  /// Offset of [hour] inside the grouped list.
  double _offsetForHour(int hour) {
    final int section = hour ~/ _hoursPerSection;
    return (section + 1) * _sectionExtent + hour * _rowExtent;
  }

  /// Opens the list a little above the current hour, once per selected day.
  void _syncDay(DayScheduleState state, int? currentHour) {
    final String key = DateKey.of(state.day);
    if (_scrolledFor == key) {
      return;
    }
    final bool firstPaint = _scrolledFor == null;
    _scrolledFor = key;
    if (!firstPaint) {
      _dayFade.forward(from: 0);
    }
    if (currentHour == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) {
        return;
      }
      final double target = _offsetForHour((currentHour - 1).clamp(0, _lastHour));
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
              _syncDay(state, currentHour);
            }
            return Column(
              children: <Widget>[
                DayHeader(
                  day: state.day,
                  isToday: state.isTodayAt(DateTime.now()),
                  doneCount: state.doneCount,
                  total: state.filledCount,
                  entries: state.entries.values,
                  liveHour: currentHour,
                  onPrevious: () => cubit.shiftDay(-1),
                  onNext: () => cubit.shiftDay(1),
                  onToday: cubit.goToToday,
                  onPlanHour: (int hour) => _openEditor(hour, null),
                ),
                Expanded(
                  child: state.status == ScheduleStatus.initial ||
                          state.status == ScheduleStatus.loading
                      ? const Center(child: CircularProgressIndicator())
                      : FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _dayFade,
                            curve: Motion.enter,
                          ),
                          child: _list(state, currentHour),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(DayScheduleState state, int? currentHour) {
    final int itemCount = 24 + _sections.length;

    return ListView.builder(
      controller: _controller,
      padding: const EdgeInsets.fromLTRB(Insets.lg, 0, Insets.lg, 40),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        if (index % (_hoursPerSection + 1) == 0) {
          final int section = index ~/ (_hoursPerSection + 1);
          final int first = section * _hoursPerSection;
          final int filled = _filledInSection(state, first);
          return SizedBox(
            height: _sectionExtent,
            child: _SectionLabel(
              label: _sections[section],
              filled: filled,
              isNow: currentHour != null &&
                  currentHour >= first &&
                  currentHour < first + _hoursPerSection,
            ),
          );
        }
        final int hour = (index ~/ (_hoursPerSection + 1)) * _hoursPerSection +
            (index % (_hoursPerSection + 1)) -
            1;
        final HourEntry? entry = state.entries[hour];
        return SizedBox(
          height: _rowExtent,
          child: HourBlock(
            key: ValueKey<String>('hour-$hour'),
            hour: hour,
            entry: entry,
            isCurrentHour: currentHour == hour,
            onTap: () => _openEditor(hour, entry),
            onToggle: () => context.read<DayScheduleCubit>().toggle(hour),
          ),
        );
      },
    );
  }

  int _filledInSection(DayScheduleState state, int firstHour) {
    int filled = 0;
    for (int hour = firstHour; hour < firstHour + _hoursPerSection; hour++) {
      if (state.entries.containsKey(hour)) {
        filled++;
      }
    }
    return filled;
  }
}

/// A part-of-day divider: the name, the count, then a hairline rule.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.filled,
    required this.isNow,
  });

  final String label;
  final int filled;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color color = isNow ? scheme.primary : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: Insets.sm, bottom: Insets.sm),
      child: Row(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              height: 1.3,
              color: color,
              fontWeight: isNow ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(
            '$filled/6',
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              height: 1.3,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Divider(
              color: scheme.outlineVariant.withValues(alpha: isNow ? 0.9 : 0.45),
            ),
          ),
        ],
      ),
    );
  }
}
