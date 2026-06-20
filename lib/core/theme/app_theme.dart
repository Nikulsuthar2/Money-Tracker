import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme(ColorScheme? dynamicScheme) {
    final scheme = dynamicScheme ?? ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.light,
    );
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Softer off-white
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.1))
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    );
  }

  static ThemeData darkTheme(ColorScheme? dynamicScheme) {
    const defaultSeed = Color(0xFF4DB6AC); // A nice teal
    const darkBackground = Color(0xFF121212);
    const darkSurface = Color(0xFF1E1E1E);
    
    final scheme = dynamicScheme?.copyWith(
      surface: darkSurface
    ) ?? ColorScheme.fromSeed(
      seedColor: defaultSeed,
      brightness: Brightness.dark,
      surface: darkSurface,
      background: darkBackground,
      primary: defaultSeed,
      secondary: defaultSeed,
      tertiary: const Color(0xFF80CBC4),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkBackground,
        indicatorColor: scheme.primary.withOpacity(0.2),
        iconTheme: WidgetStateProperty.all(const IconThemeData(color: Colors.white70)),
      ),
    );
  }
}
