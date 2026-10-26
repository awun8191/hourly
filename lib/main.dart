import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/schedule/data/repositories/schedule_local_repository.dart';
import 'features/schedule/data/widget/home_widget_bridge.dart';
import 'features/schedule/data/widget/widget_toggle_callback.dart';
import 'features/schedule/domain/repositories/schedule_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences preferences = await SharedPreferences.getInstance();
  final ScheduleRepository repository = ScheduleLocalRepository(preferences);

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await HomeWidget.registerInteractivityCallback(handleWidgetToggle);
  }

  runApp(HourlyApp(repository: repository, widgetBridge: HomeWidgetBridge()));
}
