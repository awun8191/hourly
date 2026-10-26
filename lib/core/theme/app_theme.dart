import 'package:flutter/material.dart';

/// Colors for the two hour states. Green means the item is in place, red means
/// the item is done. The values are fixed, not theme derived, so the Android
/// widget and the app always match.
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
  final Color completed;
  final Color completedSurface;
  final Color completedText;

  static const StatusPalette light = StatusPalette(
    active: Color(0xFF1F7A4C),
    activeSurface: Color(0xFFE3F3E9),
    activeText: Color(0xFF0B3A22),
    completed: Color(0xFFB3261E),
    completedSurface: Color(0xFFFCEDEB),
    completedText: Color(0xFF8C1D18),
  );

  static const StatusPalette dark = StatusPalette(
    active: Color(0xFF7DDBA8),
    activeSurface: Color(0xFF112E1E),
    activeText: Color(0xFFBDEFD3),
    completed: Color(0xFFFFB4AB),
    completedSurface: Color(0xFF38140F),
    completedText: Color(0xFFFFDAD6),
  );

  static StatusPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Material 3 theme. Light and dark share one seed color.
abstract final class AppTheme {
  static const Color seed = Color(0xFF2F6B57);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final ThemeData base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
    );
    final BorderRadius fieldRadius = BorderRadius.circular(14);

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
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
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: base.textTheme.labelLarge),
      ),
    );
  }
}
