import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/theme/app_theme.dart';

/// Guards the single source of truth.
///
/// The widget cannot import Dart, so its colours live in XML. These tests fail
/// when the XML drifts from `design_tokens.dart`, when green comes back, or
/// when the dark accent stops being white.
void main() {
  Map<String, Color> readPalette(String path) {
    final String text = File(path).readAsStringSync();
    final RegExp pattern = RegExp(
      r'<color name="([^"]+)">#([0-9A-Fa-f]{6,8})</color>',
    );
    return <String, Color>{
      for (final RegExpMatch match in pattern.allMatches(text))
        match.group(1)!: _parseHex(match.group(2)!),
    };
  }

  group('widget colours mirror the design tokens', () {
    test('light palette', () {
      final Map<String, Color> colors =
          readPalette('android/app/src/main/res/values/colors.xml');

      expect(colors['widget_background'], AppColors.paper);
      expect(colors['widget_active_text'], AppColors.ink);
      expect(colors['widget_active_bg'], AppColors.paperRaised);
      expect(colors['widget_done_text'], AppColors.bloodRedDeep);
      expect(colors['widget_done_bg'], AppColors.bloodRedSurfaceLight);
      expect(colors['widget_accent'], AppColors.ink);
    });

    test('dark palette', () {
      final Map<String, Color> colors =
          readPalette('android/app/src/main/res/values-night/colors.xml');

      expect(colors['widget_background'], AppColors.black);
      expect(colors['widget_active_text'], AppColors.white);
      expect(colors['widget_active_bg'], AppColors.surfaceDarkRaised);
      expect(colors['widget_done_text'], AppColors.bloodRed);
      expect(colors['widget_done_bg'], AppColors.bloodRedSurfaceDark);
      expect(colors['widget_accent'], AppColors.white);
      expect(colors['widget_progress_fill'], AppColors.white);
    });
  });

  test('the dark theme uses a white accent on a black surface', () {
    final ThemeData theme = AppTheme.dark;

    expect(theme.scaffoldBackgroundColor, AppColors.black);
    expect(theme.colorScheme.surface, AppColors.black);
    expect(theme.colorScheme.primary, AppColors.white);
    expect(theme.colorScheme.onPrimary, AppColors.black);
    expect(theme.colorScheme.error, AppColors.bloodRed);
    expect(StatusPalette.dark.active, AppColors.white);
    expect(StatusPalette.dark.completed, AppColors.bloodRed);
  });

  test('the light theme uses an ink accent on paper', () {
    final ThemeData theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, AppColors.paper);
    expect(theme.colorScheme.primary, AppColors.ink);
    expect(StatusPalette.light.active, AppColors.ink);
    expect(StatusPalette.light.completed, AppColors.bloodRedDeep);
  });

  test('no token carries a green hue', () {
    final List<Color> tokens = <Color>[
      AppColors.black,
      AppColors.white,
      AppColors.ink,
      AppColors.paper,
      AppColors.paperRaised,
      AppColors.surfaceDark,
      AppColors.surfaceDarkRaised,
      AppColors.surfaceDarkSunken,
      AppColors.lineDark,
      AppColors.lineLight,
      AppColors.mutedDark,
      AppColors.mutedLight,
      AppColors.bloodRed,
      AppColors.bloodRedDeep,
      AppColors.bloodRedText,
      AppColors.bloodRedSurfaceDark,
      AppColors.bloodRedSurfaceLight,
      AppColors.bloodRedMuted,
      AppColors.knobYellow,
      AppColors.knobYellowDeep,
      StatusPalette.light.active,
      StatusPalette.light.completed,
      StatusPalette.dark.active,
      StatusPalette.dark.completed,
    ];

    for (final Color color in tokens) {
      final double other = color.r > color.b ? color.r : color.b;
      expect(
        color.g,
        lessThanOrEqualTo(other),
        reason: 'green dominates $color',
      );
    }
  });
}

Color _parseHex(String hex) {
  final String value = hex.length == 6 ? 'FF$hex' : hex;
  return Color(int.parse(value, radix: 16));
}
