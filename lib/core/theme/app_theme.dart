import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto', // Using Google Fonts later or default
    );
  }

  static ThemeData get darkTheme {
    const tealColor = Color(0xFF4DB6AC); // A nice teal
    const darkBackground = Color(0xFF121212);
    const darkSurface = Color(0xFF1E1E1E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tealColor,
        brightness: Brightness.dark,
        surface: darkSurface,
        background: darkBackground,
        primary: tealColor,
        secondary: tealColor,
        tertiary: const Color(0xFF80CBC4),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent, // Remove M3 tint
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0, // Flat look
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      fontFamily: 'Roboto',
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkBackground,
        indicatorColor: tealColor.withOpacity(0.2),
        iconTheme: MaterialStateProperty.all(const IconThemeData(color: Colors.white70)),
      ),
    );
  }
}
