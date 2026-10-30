import 'package:flutter/material.dart';

/// Single source of truth for the visual language.
///
/// The app reads every colour, gap, radius and duration from this file. The
/// Android widget cannot import Dart, so `android/app/src/main/res/values*`
/// mirrors these values by name. `test/core/theme/design_tokens_test.dart`
/// fails when the two drift apart.
///
/// The palette is monochrome plus one blood red. White is the accent for an
/// hour in place. Blood red means done or missed. Yellow belongs to the knob
/// only. There is no green anywhere.
abstract final class AppColors {
  // Base
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF111111);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color paperRaised = Color(0xFFF4F4F4);
  static const Color surfaceDark = Color(0xFF000000);
  static const Color surfaceDarkRaised = Color(0xFF121212);
  static const Color surfaceDarkSunken = Color(0xFF0A0A0A);
  static const Color lineDark = Color(0xFF232323);
  static const Color lineLight = Color(0xFFE2E2E2);
  static const Color mutedDark = Color(0xFFB8B8B8);
  static const Color mutedLight = Color(0xFF5A5A5A);

  /// The red the owner settled on. Bright, with a pure hue so it never reads
  /// orange or pink.
  static const Color bloodRed = Color(0xFFFF3B30);
  static const Color bloodRedText = Color(0xFFFF3B30);

  /// The same red darkened for paper, where #FF3B30 is too light to read.
  static const Color bloodRedDeep = Color(0xFFD92D20);
  static const Color bloodRedSurfaceDark = Color(0xFF2E0B09);
  static const Color bloodRedSurfaceLight = Color(0xFFFCEAE8);
  static const Color bloodRedMuted = Color(0xFFB3403A);

  /// The only warm note: the toggle knob.
  static const Color knobYellow = Color(0xFFFFD24D);
  static const Color knobYellowDeep = Color(0xFFF2B705);

  /// The toggle fill when an item is on. The owner asked for green here only,
  /// after the rest of the green left the product.
  static const Color switchOn = Color(0xFF22C55E);
  static const Color switchOnLight = Color(0xFF15803D);
}

/// Colors for the two hour states.
///
/// In place is white on dark, ink on light. Done is blood red. The values are
/// fixed rather than theme derived so the app and the widget agree.
class StatusPalette {
  const StatusPalette({
    required this.active,
    required this.activeSurface,
    required this.activeText,
    required this.switchOn,
    required this.completed,
    required this.completedSurface,
    required this.completedText,
  });

  /// The in-place accent: white on dark, ink on light.
  final Color active;
  final Color activeSurface;
  final Color activeText;

  /// The toggle fill when the item is on.
  final Color switchOn;

  /// The done red as a fill: the switch track, the row bar, the meter tick.
  final Color completed;
  final Color completedSurface;
  final Color completedText;

  static const StatusPalette light = StatusPalette(
    active: AppColors.ink,
    activeSurface: AppColors.paperRaised,
    activeText: AppColors.ink,
    switchOn: AppColors.switchOnLight,
    completed: AppColors.bloodRedDeep,
    completedSurface: AppColors.bloodRedSurfaceLight,
    completedText: AppColors.bloodRedDeep,
  );

  static const StatusPalette dark = StatusPalette(
    active: AppColors.white,
    activeSurface: AppColors.surfaceDarkRaised,
    activeText: AppColors.white,
    switchOn: AppColors.switchOn,
    completed: AppColors.bloodRed,
    completedSurface: AppColors.bloodRedSurfaceDark,
    completedText: AppColors.bloodRedText,
  );

  static StatusPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// The 4/8 pt spacing scale the layout uses. Every gap is one of these.
abstract final class Insets {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Minimum touch target, per the Material accessibility guidance.
  static const double touch = 48;
}

/// Corner radii. Cards, chips and fields use these only.
abstract final class Radii {
  static const double card = 16;
  static const double chip = 20;
  static const double field = 14;
  static const double sheet = 28;

  static const BorderRadius cardAll = BorderRadius.all(Radius.circular(card));
}

/// Durations and curves used by the day list and the editor.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve state = Curves.easeOutCubic;
}
