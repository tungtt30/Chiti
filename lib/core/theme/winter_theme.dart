import 'package:flutter/material.dart';

/// Winter (Mùa đông) design system.
///
/// Crisp frost-blue palette with glacier ice containers, slate accents and
/// midnight-navy text. Material 3 compliant.
abstract final class WinterTheme {
  // Color Palette
  static const Color primaryFrost = Color(0xFF0284C7); // Frost blue
  static const Color primaryContainer = Color(0xFFE0F2FE); // Glacier ice light
  static const Color softBackground = Color(0xFFF8FAFC); // Snow white / cool gray
  static const Color surfaceCard = Color(0xFFFFFFFF); // Thẻ trắng điểm viền băng
  static const Color cardBorder = Color(0xFFBAE6FD); // Viền thẻ băng xanh
  static const Color textDark = Color(0xFF0F172A); // Midnight slate
  // Falling-snow palette (soft whites with a hint of glacier ice).
  static const List<Color> snowPalette = [
    Color(0xFFFFFFFF),
    Color(0xFFF0F9FF),
    Color(0xFFE0F2FE),
  ];

  static const Color _cardShadow = Color(0x1A0284C7);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryFrost,
        primary: primaryFrost,
        primaryContainer: primaryContainer,
        surface: softBackground,
        onSurface: textDark,
        brightness: Brightness.light,
      ),
      // Transparent so the app-wide seasonal particle layer (which paints the
      // snowy backdrop itself) shows through behind every screen.
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
        backgroundColor: primaryFrost,
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