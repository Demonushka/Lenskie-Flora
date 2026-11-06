import 'package:flutter/material.dart';

const cream = Color(0xFFF3F0E6);
const paper = Color(0xFFFFFCF7);
const forest = Color(0xFF1B4636);
const forestDark = Color(0xFF163228);
const ink = Color(0xFF1C3B2E);
const moss = Color(0xFF5E7A68);
const line = Color(0xFFE4DDD0);
const chipGreen = Color(0xFFE5EDD8);
const chipRed = Color(0xFFF6D9D6);
const chipRedText = Color(0xFF8E3D3A);

const floraText = 'Manrope';
const floraDisplay = 'Neucha';

ThemeData buildFloraTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: floraText,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: forest,
      primary: forest,
      onPrimary: Colors.white,
      surface: paper,
      secondary: moss,
    ),
  );
  final text = base.textTheme.apply(bodyColor: ink, displayColor: ink, fontFamily: floraText);
  TextStyle? display(TextStyle? style) => style?.copyWith(fontFamily: floraDisplay, fontWeight: FontWeight.w400, color: ink);
  return base.copyWith(
    textTheme: text.copyWith(
      displayLarge: display(text.displayLarge),
      displayMedium: display(text.displayMedium),
      displaySmall: display(text.displaySmall),
      headlineLarge: display(text.headlineLarge),
      headlineMedium: display(text.headlineMedium),
      headlineSmall: display(text.headlineSmall),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: cream,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: paper,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: forest,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontFamily: floraText, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: forest,
        backgroundColor: const Color(0xFFE7EFE4),
        minimumSize: const Size.fromHeight(54),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontFamily: floraText, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    dividerColor: line,
  );
}
