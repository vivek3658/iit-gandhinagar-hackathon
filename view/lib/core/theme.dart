import 'package:flutter/material.dart';

abstract final class UrjaColors {
  static const forest = Color(0xFF176B45);
  static const leaf = Color(0xFF32A96B);
  static const mint = Color(0xFFE5F5E9);
  static const canvas = Color(0xFFF5F8F1);
  static const ink = Color(0xFF182A22);
  static const muted = Color(0xFF718078);
  static const line = Color(0xFFE0E9E1);
  static const gold = Color(0xFFF2AA36);
  static const peach = Color(0xFFFFEEE0);
  static const sky = Color(0xFFE9F4FF);
  static const navy = Color(0xFF102C27);
}

abstract final class UrjaTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: UrjaColors.canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: UrjaColors.forest,
      primary: UrjaColors.forest,
      secondary: UrjaColors.gold,
      surface: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: UrjaColors.ink,
        fontSize: 30,
        height: 1.08,
        fontWeight: FontWeight.w900,
      ),
      headlineSmall: TextStyle(
        color: UrjaColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
      titleLarge: TextStyle(
        color: UrjaColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
      bodyMedium: TextStyle(color: UrjaColors.ink, fontSize: 14, height: 1.45),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: UrjaColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: UrjaColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: UrjaColors.line),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: UrjaColors.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
  );
}
