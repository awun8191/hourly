import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/schedule/data/reminders/reminder_service.dart';
import 'features/schedule/data/widget/home_widget_bridge.dart';
import 'features/schedule/domain/repositories/schedule_repository.dart';
import 'features/schedule/presentation/cubit/day_schedule_cubit.dart';
import 'features/schedule/presentation/screens/day_screen.dart';

/// Composition root of the widget tree.
///
/// The repository, the widget bridge, and the reminder service are injected.
/// A different store, a widget-free build, or a reminder-free build needs one
/// change in `main.dart` only.
class HourlyApp extends StatelessWidget {
  const HourlyApp({
    super.key,
    required this.repository,
    required this.widgetBridge,
    this.reminderService = const NoopReminderService(),
    this.clock,
  });

  final ScheduleRepository repository;
  final WidgetBridge widgetBridge;
  final ReminderService reminderService;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DayScheduleCubit>(
      create: (BuildContext context) => DayScheduleCubit(
        repository,
        widgetBridge,
        clock: clock,
        reminders: reminderService,
      )..load(),
      child: MaterialApp(
        title: 'Hourly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const DayScreen(),
      ),
    );
  }
}
