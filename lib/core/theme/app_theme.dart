import 'package:flutter/material.dart';

/// Colors for the two hour states. Green means the item is in place, red means
/// the item is done. The values are fixed, not theme derived, so the Android
/// widget and the app always match.
///
/// The red is a true red family, never a pink tint: on black a light red loses
/// its chroma and reads as rose, so [completed] stays saturated and only moves
/// in lightness. On the dark surface [completedText] is 6.2:1 on black and
/// 5.4:1 on [completedSurface], and [completed], the fill, is 4.5:1 on black,
/// which clears 3:1 for a track and 4.5:1 for the text that rides on it.
class StatusPalette {
  const StatusPalette({
    required this.active,
    required this.activeSurface,
    required this.activeText,
    required this.completed,
    required this.completedSurface,
    required this.completedText,
  });

  final Color active;
  final Color activeSurface;
  final Color activeText;

  /// The done red as a fill: the switch track, the row bar, the meter tick.
  final Color completed;
  final Color completedSurface;
  final Color completedText;

  static const StatusPalette light = StatusPalette(
    active: Color(0xFF1F7A4C),
    activeSurface: Color(0xFFE3F3E9),
    activeText: Color(0xFF0B3A22),
    completed: Color(0xFFD92D20),
    completedSurface: Color(0xFFFCEAE8),
    completedText: Color(0xFFB42318),
  );

  static const StatusPalette dark = StatusPalette(
    active: Color(0xFF7DDBA8),
    activeSurface: Color(0xFF112E1E),
    activeText: Color(0xFFBDEFD3),
    completed: Color(0xFFE02B20),
    completedSurface: Color(0xFF2A0B08),
    completedText: Color(0xFFFF453A),
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

/// Durations used by the day list and the editor.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration normal = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve state = Curves.easeOutCubic;
}

/// Material 3 theme. Light and dark share one seed color.
abstract final class AppTheme {
  static const Color seed = Color(0xFF2F6B57);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    if (brightness == Brightness.dark) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF101010),
        surfaceContainerHigh: const Color(0xFF151515),
        surfaceContainerHighest: const Color(0xFF1C1C1C),
        outlineVariant: const Color(0xFF2B2B2B),
        // Material's dark error is a pink tint. The app has one red family, so
        // the error role borrows it: a destructive action matches the done
        // state instead of introducing a second, pinker red.
        error: StatusPalette.dark.completedText,
        onError: StatusPalette.dark.completedSurface,
        errorContainer: StatusPalette.dark.completedSurface,
        onErrorContainer: StatusPalette.dark.completedText,
      );
    } else {
      scheme = scheme.copyWith(
        error: StatusPalette.light.completedText,
        onError: Colors.white,
        errorContainer: StatusPalette.light.completedSurface,
        onErrorContainer: StatusPalette.light.completedText,
      );
    }
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );

    // Tighter display sizes, calmer label tracking, and airier body copy.
    final TextTheme text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.25,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.45),
      bodySmall: base.textTheme.bodySmall?.copyWith(height: 1.45),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
      ),
    );

    final BorderRadius fieldRadius = BorderRadius.circular(14);

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.lg,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, Insets.touch),
          padding: const EdgeInsets.symmetric(horizontal: Insets.xl),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, Insets.touch),
          textStyle: base.textTheme.labelLarge,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
      ),
    );
  }
}
