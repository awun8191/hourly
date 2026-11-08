import 'package:flutter/material.dart';

/// Single source of truth for the visual language.
///
/// The app reads every colour, gap, radius and duration from this file. The
/// Android widget cannot import Dart, so `android/app/src/main/res/values*`
/// mirrors these values by name. `test/core/theme/design_tokens_test.dart`
/// fails when the two drift apart.
///
/// The palette is deep indigo plus one blood red, plus moss bark greens for
/// the toggle only. White is the accent on indigo. Ink reads on the light
/// cards. Blood red means done or missed. Moss belongs to the toggle fills
/// only.
abstract final class AppColors {
  // Base
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF111111);
  static const Color paper = Color(0xFFFFFFFF);

  /// The light card both themes share: a warm paper that lifts off indigo
  /// and stays calm on white.
  static const Color paperRaised = Color(0xFFF4F1E9);

  /// Deep indigo full bleed surfaces, darkest first.
  static const Color surfaceDark = Color(0xFF2B2B85);
  static const Color surfaceDarkSunken = Color(0xFF23236F);
  static const Color surfaceDarkRaised = Color(0xFF353595);
  static const Color surfaceDarkHigh = Color(0xFF3F3F9E);
  static const Color surfaceDarkHighest = Color(0xFF4D4DAE);
  static const Color lineDark = Color(0xFF4A4AA3);
  static const Color lineLight = Color(0xFFE2E2E2);
  static const Color mutedDark = Color(0xFFC6C6E6);
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

  /// Moss on bark toggle fills. Flat only, no gradient, no glow.
  /// Dark on is pale moss, light on is deep moss.
  static const Color switchOn = Color(0xFFB7D9B0);
  static const Color switchOnLight = Color(0xFF2E5B3E);

  /// Bark toggle tracks when off.
  static const Color switchOff = Color(0xFF14291D);
  static const Color switchOffLight = Color(0xFFE8EDE8);

  /// Toggle knob fills: dark ink on moss, grey-green when off.
  static const Color switchKnobOn = Color(0xFF0C1A12);
  static const Color switchKnobOnLight = Color(0xFFFFFFFF);
  static const Color switchKnobOff = Color(0xFF6B7F71);
  static const Color switchKnobOffLight = Color(0xFF7A8A7E);

  /// 1.5px off-state track borders.
  static const Color switchBorderOff = Color(0xFF33463A);
  static const Color switchBorderOffLight = Color(0xFFC2CFC4);
}

/// Colors for the two hour states.
///
/// In place is a light card with ink text on either background, ticked white
/// on the day meter. Done is blood red. The values are fixed rather than
/// theme derived so the app and the widget agree.
class StatusPalette {
  const StatusPalette({
    required this.active,
    required this.activeSurface,
    required this.activeText,
    required this.switchOn,
    required this.switchOff,
    required this.switchKnobOn,
    required this.switchKnobOff,
    required this.switchBorderOff,
    required this.completed,
    required this.completedSurface,
    required this.completedText,
  });

  /// The in-place accent: white, for the meter tick and the legend dot.
  /// Card text uses [activeText] instead so it stays legible on the light
  /// card.
  final Color active;
  final Color activeSurface;
  final Color activeText;

  /// Moss on bark toggle fills. Flat only, no gradient, no glow.
  final Color switchOn;

  /// Bark track when off, with a 1.5px [switchBorderOff] border.
  final Color switchOff;

  /// Solid knob fills for the on and off positions.
  final Color switchKnobOn;
  final Color switchKnobOff;

  /// Off-state track border. The on state has no border.
  final Color switchBorderOff;

  /// The done red as a fill: the row bar, the meter tick.
  final Color completed;
  final Color completedSurface;
  final Color completedText;

  static const StatusPalette light = StatusPalette(
    active: AppColors.ink,
    activeSurface: AppColors.paperRaised,
    activeText: AppColors.ink,
    switchOn: AppColors.switchOnLight,
    switchOff: AppColors.switchOffLight,
    switchKnobOn: AppColors.switchKnobOnLight,
    switchKnobOff: AppColors.switchKnobOffLight,
    switchBorderOff: AppColors.switchBorderOffLight,
    completed: AppColors.bloodRedDeep,
    completedSurface: AppColors.bloodRedSurfaceLight,
    completedText: AppColors.bloodRedDeep,
  );

  static const StatusPalette dark = StatusPalette(
    active: AppColors.white,
    activeSurface: AppColors.paperRaised,
    activeText: AppColors.ink,
    switchOn: AppColors.switchOn,
    switchOff: AppColors.switchOff,
    switchKnobOn: AppColors.switchKnobOn,
    switchKnobOff: AppColors.switchKnobOff,
    switchBorderOff: AppColors.switchBorderOff,
    completed: AppColors.bloodRed,
    completedSurface: AppColors.bloodRedSurfaceLight,
    completedText: AppColors.bloodRedDeep,
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
