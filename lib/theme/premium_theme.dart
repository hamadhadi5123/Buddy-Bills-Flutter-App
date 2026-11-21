import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium theme configuration for Buddy Bills
/// Inspired by Gold Century app aesthetic
class PremiumTheme {
  // ============ COLORS ============
  
  // Golden Accents (Primary)
  static const Color goldenPrimary = Color(0xFFD4AF37);
  static const Color goldenLight = Color(0xFFF4C430);
  static const Color goldenDark = Color(0xFFB8941E);
  
  // Green Accents (Success/Add Actions)
  static const Color accentGreen = Color(0xFF27C46E);
  static const Color accentGreenLight = Color(0xFF3FD87E);
  static const Color accentGreenDark = Color(0xFF1FA855);
  
  // Dark Backgrounds
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkBackgroundLight = Color(0xFF2A2A2A);
  static const Color darkBackgroundDark = Color(0xFF0F0F0F);
  
  // Cream/Beige (Input Cards)
  static const Color creamCard = Color(0xFFE8D5B5);
  static const Color creamCardLight = Color(0xFFF0E5D0);
  static const Color creamCardDark = Color(0xFFD4C4A8);
  
  // Text Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGray = Color(0xFFB0B0B0);
  static const Color textDarkGray = Color(0xFF6A6A6A);
  static const Color textBlack = Color(0xFF1A1A2E);
  
  // Glass Effects
  static Color glassWhite(double opacity) => Colors.white.withOpacity(opacity);
  static Color glassBlack(double opacity) => Colors.black.withOpacity(opacity);
  
  // ============ GRADIENTS ============
  
  static const LinearGradient goldenGradient = LinearGradient(
    colors: [goldenLight, goldenPrimary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [accentGreenLight, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [darkBackground, darkBackgroundLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static LinearGradient glassGradient(bool isDark) => LinearGradient(
    colors: isDark 
      ? [glassWhite(0.05), glassWhite(0.02)]
      : [glassWhite(0.3), glassWhite(0.1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============ SHADOWS ============
  
  static List<BoxShadow> goldenGlow = [
    BoxShadow(
      color: goldenPrimary.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: goldenPrimary.withOpacity(0.15),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];
  
  static List<BoxShadow> greenGlow = [
    BoxShadow(
      color: accentGreen.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> cardShadow(bool isDark) => [
    BoxShadow(
      color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  // ============ TYPOGRAPHY ============
  
  static TextStyle headingLarge(Color color) => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: color,
    letterSpacing: -0.5,
  );
  
  static TextStyle headingMedium(Color color) => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: -0.3,
  );
  
  static TextStyle headingSmall(Color color) => GoogleFonts.outfit(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color,
  );
  
  static TextStyle bodyLarge(Color color) => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: color,
  );
  
  static TextStyle bodyMedium(Color color) => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: color,
  );
  
  static TextStyle bodySmall(Color color) => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: color,
  );
  
  static TextStyle buttonText(Color color) => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color,
    letterSpacing: 0.5,
  );
  
  static TextStyle amountLarge(Color color) => GoogleFonts.outfit(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: color,
    letterSpacing: -1,
  );
  
  // ============ THEME DATA ============
  
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.dark(
      primary: goldenPrimary,
      secondary: accentGreen,
      surface: darkBackgroundLight,
      background: darkBackground,
      error: Colors.redAccent,
    ),
    useMaterial3: true,
    textTheme: TextTheme(
      displayLarge: headingLarge(textWhite),
      displayMedium: headingMedium(textWhite),
      displaySmall: headingSmall(textWhite),
      bodyLarge: bodyLarge(textWhite),
      bodyMedium: bodyMedium(textGray),
      bodySmall: bodySmall(textGray),
    ),
  );
  
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: goldenPrimary,
      secondary: accentGreen,
      surface: Colors.grey[100]!,
      background: Colors.white,
      error: Colors.redAccent,
    ),
    useMaterial3: true,
    textTheme: TextTheme(
      displayLarge: headingLarge(textBlack),
      displayMedium: headingMedium(textBlack),
      displaySmall: headingSmall(textBlack),
      bodyLarge: bodyLarge(textBlack),
      bodyMedium: bodyMedium(textDarkGray),
      bodySmall: bodySmall(textDarkGray),
    ),
  );
  
  // ============ BORDER RADIUS ============
  
  static const BorderRadius radiusSmall = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusMedium = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusLarge = BorderRadius.all(Radius.circular(24));
  static const BorderRadius radiusXLarge = BorderRadius.all(Radius.circular(32));
}
