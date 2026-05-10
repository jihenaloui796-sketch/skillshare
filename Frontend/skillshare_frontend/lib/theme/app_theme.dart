import 'package:flutter/material.dart';

class AppTheme {
  static const double _radius = 10; // 0.625rem ~= 10px

  static const _light = _ThemePalette(
    background: Color(0xFFFFFFFF),
    foreground: Color(0xFF0B0B0F),
    card: Color(0xFFFFFFFF),
    popover: Color(0xFFFFFFFF),
    primary: Color(0xFF030213),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFFF2F2F5),
    secondaryForeground: Color(0xFF030213),
    muted: Color(0xFFECECF0),
    mutedForeground: Color(0xFF717182),
    accent: Color(0xFFE9EBEF),
    accentForeground: Color(0xFF030213),
    destructive: Color(0xFFD4183D),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0x1A000000),
    inputBackground: Color(0xFFF3F3F5),
    ring: Color(0xFFB5B5B5),
  );

  static const _dark = _ThemePalette(
    background: Color(0xFF0B0B0F),
    foreground: Color(0xFFFAFAFA),
    card: Color(0xFF0B0B0F),
    popover: Color(0xFF0B0B0F),
    primary: Color(0xFFFAFAFA),
    primaryForeground: Color(0xFF1D1D1F),
    secondary: Color(0xFF2B2B2B),
    secondaryForeground: Color(0xFFFAFAFA),
    muted: Color(0xFF2B2B2B),
    mutedForeground: Color(0xFFB5B5B5),
    accent: Color(0xFF2B2B2B),
    accentForeground: Color(0xFFFAFAFA),
    destructive: Color(0xFF7A2A2A),
    destructiveForeground: Color(0xFFFF6B6B),
    border: Color(0xFF2B2B2B),
    inputBackground: Color(0xFF2B2B2B),
    ring: Color(0xFF707070),
  );

  static ThemeData light() => _build(_light, Brightness.light);

  static ThemeData dark() => _build(_dark, Brightness.dark);

  static ThemeData _build(_ThemePalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.primary,
      onPrimary: p.primaryForeground,
      secondary: p.secondary,
      onSecondary: p.secondaryForeground,
      error: p.destructive,
      onError: p.destructiveForeground,
      surface: p.card,
      onSurface: p.foreground,
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      cardColor: p.card,
      dividerColor: p.border,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_radius),
      side: BorderSide(color: p.border),
    );

    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(_radius),
      borderSide: BorderSide(color: p.border),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.foreground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: p.muted,
        selectedColor: p.accent,
        labelStyle: TextStyle(color: p.foreground, fontWeight: FontWeight.w500),
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
          backgroundColor: p.primary,
          foregroundColor: p.primaryForeground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputBackground,
        hintStyle: TextStyle(color: p.mutedForeground),
        labelStyle: TextStyle(color: p.foreground, fontWeight: FontWeight.w500),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.ring)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.destructive)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: p.destructive)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: p.popover,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.card,
        contentTextStyle: TextStyle(color: p.foreground),
        actionTextColor: p.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        behavior: SnackBarBehavior.floating,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: p.foreground,
        displayColor: p.foreground,
      ),
    );
  }
}

class _ThemePalette {
  final Color background;
  final Color foreground;
  final Color card;
  final Color popover;
  final Color primary;
  final Color primaryForeground;
  final Color secondary;
  final Color secondaryForeground;
  final Color muted;
  final Color mutedForeground;
  final Color accent;
  final Color accentForeground;
  final Color destructive;
  final Color destructiveForeground;
  final Color border;
  final Color inputBackground;
  final Color ring;

  const _ThemePalette({
    required this.background,
    required this.foreground,
    required this.card,
    required this.popover,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.border,
    required this.inputBackground,
    required this.ring,
  });
}
