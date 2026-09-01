import 'package:flutter/material.dart';

/// Autumn (Mùa thu) design system.
///
/// Warm golden-amber palette with maple leaves and soft harvest-gold card
/// borders. Material 3 compliant.
abstract final class AutumnTheme {
  // Color Palette
  static const Color primaryAmber = Color(0xFFD97706); // Amber ochre
  static const Color primaryContainer = Color(0xFFFEF3C7); // Soft harvest gold
  static const Color softBackground = Color(0xFFFFFDF7); // Warm off-white
  static const Color surfaceCard = Color(0xFFFFFFFF); // Thẻ trắng điểm viền vàng
  static const Color cardBorder = Color(0xFFFDE68A); // Viền thẻ vàng rơm
  static const Color textDark = Color(0xFF451A03); // Deep walnut brown
  // Falling-leaf palette (warm orange / amber hues).
  static const List<Color> leafPalette = [
    Color(0xFFD97706), // Amber ochre
    Color(0xFFEA580C), // Burnt orange
    Color(0xFFF59E0B), // Golden yellow
    Color(0xFFB45309), // Rust brown
    Color(0xFFCA8A04), // Harvest gold
  ];

  static const Color _cardShadow = Color(0x1AD97706);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryAmber,
        primary: primaryAmber,
        primaryContainer: primaryContainer,
        surface: softBackground,
        onSurface: textDark,
        brightness: Brightness.light,
      ),
      // Transparent so the app-wide seasonal particle layer (which paints the
      // warm backdrop itself) shows through behind every screen.
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: const CardThemeData(
        color: surfaceCard,
        elevation: 1,
        shadowColor: _cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: cardBorder, width: 0.8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: softBackground,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryAmber,
        foregroundColor: Colors.white,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceCard,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceCard,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: textDark,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}