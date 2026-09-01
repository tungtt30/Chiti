import 'package:flutter/material.dart';

/// Spring (Mùa xuân) design system.
///
/// Soft cherry-blossom pink palette with warm brown text for high contrast
/// while staying gentle on the eyes. Material 3 compliant.
abstract final class SpringTheme {
  // Color Palette
  static const Color primaryPink = Color(0xFFF06292); // Hoa đào nở
  static const Color primaryContainer = Color(0xFFFFD8E4); // Hồng phấn nhạt
  static const Color softBackground = Color(0xFFFFF5F7); // Nền hồng sữa cực dịu
  static const Color surfaceCard = Color(0xFFFFFFFF); // Thẻ trắng điểm viền hồng
  static const Color petalPink = Color(0xFFFFB7C5); // Màu cánh hoa rơi
  static const Color textDark = Color(0xFF3E2723); // Chữ nâu đậm
  static const Color accentRose = Color(0xFFD81B60); // Điểm nhấn nút bấm / badge

  static const Color _cardBorder = Color(0xFFFFE0E8);
  static const Color _cardShadow = Color(0x1AF06292);

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPink,
        primary: accentRose,
        primaryContainer: primaryContainer,
        surface: softBackground,
        onSurface: textDark,
        brightness: Brightness.light,
      ),
      // Transparent so the app-wide seasonal particle layer (which paints the
      // pastel backdrop itself) shows through as the background behind every
      // screen. Cards / AppBars keep their own solid colors.
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: const CardThemeData(
        color: surfaceCard,
        elevation: 1,
        shadowColor: _cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: _cardBorder, width: 0.8),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: softBackground,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentRose,
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