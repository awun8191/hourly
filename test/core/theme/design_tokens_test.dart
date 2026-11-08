import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/core/theme/app_theme.dart';

/// Guards the single source of truth.
///
/// The widget cannot import Dart, so its colours live in XML. These tests fail
/// when the XML drifts from `design_tokens.dart`, when moss leaves the toggle,
/// or when the dark accent stops being white.
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

      expect(colors['widget_background'], AppColors.surfaceDark);
      expect(colors['widget_active_text'], AppColors.ink);
      expect(colors['widget_active_bg'], AppColors.paperRaised);
      expect(colors['widget_done_text'], AppColors.bloodRedDeep);
      expect(colors['widget_done_bg'], AppColors.bloodRedSurfaceLight);
      expect(colors['widget_accent'], AppColors.white);
      expect(colors['widget_progress_fill'], AppColors.white);
    });
  });

  test('the dark theme uses a white accent on a soft indigo surface', () {
    final ThemeData theme = AppTheme.dark;

    expect(AppColors.surfaceDark, const Color(0xFF55559B));
    expect(theme.scaffoldBackgroundColor, AppColors.surfaceDark);
    expect(theme.colorScheme.surface, AppColors.surfaceDark);
    expect(theme.colorScheme.primary, AppColors.white);
    expect(theme.colorScheme.onPrimary, AppColors.black);
    expect(theme.colorScheme.error, AppColors.bloodRed);
    expect(StatusPalette.dark.active, AppColors.white);
    expect(StatusPalette.dark.activeSurface, AppColors.paperRaised);
    expect(StatusPalette.dark.activeText, AppColors.ink);
    expect(StatusPalette.dark.completed, AppColors.bloodRed);
    expect(StatusPalette.dark.completedSurface, AppColors.bloodRedSurfaceLight);
    expect(StatusPalette.dark.completedText, AppColors.bloodRedDeep);
  });

  test('the light theme uses an ink accent on paper', () {
    final ThemeData theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, AppColors.paper);
    expect(theme.colorScheme.primary, AppColors.ink);
    expect(StatusPalette.light.active, AppColors.ink);
    expect(StatusPalette.light.completed, AppColors.bloodRedDeep);
  });

  test('the toggle is moss when on', () {
    expect(StatusPalette.dark.switchOn, AppColors.switchOn);
    expect(StatusPalette.dark.switchOn, const Color(0xFFB7D9B0));
    expect(StatusPalette.light.switchOn, AppColors.switchOnLight);
    expect(StatusPalette.light.switchOn, const Color(0xFF2E5B3E));
  });

  test('the toggle is bark when off, with a 1.5px border', () {
    expect(StatusPalette.dark.switchOff, AppColors.switchOff);
    expect(StatusPalette.dark.switchOff, const Color(0xFF14291D));
    expect(StatusPalette.light.switchOff, AppColors.switchOffLight);
    expect(StatusPalette.light.switchOff, const Color(0xFFE8EDE8));
    expect(StatusPalette.dark.switchBorderOff, AppColors.switchBorderOff);
    expect(StatusPalette.dark.switchBorderOff, const Color(0xFF33463A));
    expect(
      StatusPalette.light.switchBorderOff,
      AppColors.switchBorderOffLight,
    );
    expect(
      StatusPalette.light.switchBorderOff,
      const Color(0xFFC2CFC4),
    );
  });

  test('the toggle knob is solid, ink on moss and grey-green when off', () {
    expect(StatusPalette.dark.switchKnobOn, AppColors.switchKnobOn);
    expect(StatusPalette.dark.switchKnobOn, const Color(0xFF0C1A12));
    expect(StatusPalette.light.switchKnobOn, AppColors.switchKnobOnLight);
    expect(StatusPalette.light.switchKnobOn, const Color(0xFFFFFFFF));
    expect(StatusPalette.dark.switchKnobOff, AppColors.switchKnobOff);
    expect(StatusPalette.dark.switchKnobOff, const Color(0xFF6B7F71));
    expect(StatusPalette.light.switchKnobOff, AppColors.switchKnobOffLight);
    expect(StatusPalette.light.switchKnobOff, const Color(0xFF7A8A7E));
  });

  test('moss lives only in the toggle, never in the accents', () {
    final List<Color> accents = <Color>[
      AppColors.black,
      AppColors.white,
      AppColors.ink,
      AppColors.paper,
      AppColors.paperRaised,
      AppColors.lineLight,
      AppColors.mutedLight,
      AppColors.mutedDark,
      AppColors.bloodRed,
      AppColors.bloodRedDeep,
      AppColors.bloodRedText,
      AppColors.bloodRedSurfaceDark,
      AppColors.bloodRedSurfaceLight,
      AppColors.bloodRedMuted,
      StatusPalette.light.active,
      StatusPalette.light.activeSurface,
      StatusPalette.light.activeText,
      StatusPalette.light.completed,
      StatusPalette.light.completedSurface,
      StatusPalette.light.completedText,
      StatusPalette.dark.active,
      StatusPalette.dark.activeSurface,
      StatusPalette.dark.activeText,
      StatusPalette.dark.completed,
      StatusPalette.dark.completedSurface,
      StatusPalette.dark.completedText,
    ];

    for (final Color color in accents) {
      final double other = color.r > color.b ? color.r : color.b;
      expect(
        color.g,
        lessThanOrEqualTo(other),
        reason: 'green dominates $color',
      );
    }
  });

  test('the background ramp is a soft indigo tint', () {
    for (final Color surface in <Color>[
      AppColors.surfaceDark,
      AppColors.surfaceDarkRaised,
      AppColors.surfaceDarkSunken,
      AppColors.surfaceDarkHigh,
      AppColors.surfaceDarkHighest,
    ]) {
      expect(surface.b, greaterThan(surface.r), reason: 'not indigo: $surface');
      expect(surface.b, greaterThan(surface.g), reason: 'not indigo: $surface');
    }
    expect(AppColors.surfaceDark.computeLuminance(), lessThan(0.13));
  });
}

Color _parseHex(String hex) {
  final String value = hex.length == 6 ? 'FF$hex' : hex;
  return Color(int.parse(value, radix: 16));
}
