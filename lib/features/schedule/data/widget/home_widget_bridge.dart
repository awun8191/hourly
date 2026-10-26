import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../../domain/entities/hour_entry.dart';
import 'widget_payload.dart';

/// Sends the current day to the Android home screen widget.
abstract interface class WidgetBridge {
  Future<void> sync({required DateTime now, required List<HourEntry> entries});
}

/// `home_widget` implementation. Everywhere except Android this is a no-op.
class HomeWidgetBridge implements WidgetBridge {
  static const String payloadKey = 'hourly_payload';
  static const String providerName = 'com.awun.todo_app.HourlyWidgetProvider';

  @override
  Future<void> sync({required DateTime now, required List<HourEntry> entries}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    final String payload = jsonEncode(WidgetPayload.build(now: now, entries: entries));
    await HomeWidget.saveWidgetData<String>(payloadKey, payload);
    await HomeWidget.updateWidget(qualifiedAndroidName: providerName);
  }
}
