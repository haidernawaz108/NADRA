import 'package:flutter/material.dart';

class AppTheme {
  // NADRA brand colors
  static const Color primary = Color(0xFF006B3C); // NADRA green
  static const Color primaryDark = Color(0xFF004D2B);
  static const Color primaryLight = Color(0xFF1A8A55);
  static const Color accent = Color(0xFFFFD700); // Gold accent
  static const Color accentLight = Color(0xFFFFF0A0);
  static const Color background = Color(0xFFF5F7FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A2332);
  static const Color textSecondary = Color(0xFF6B7A8D);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFB8C00);
  static const Color info = Color(0xFF1E88E5);
  static const Color divider = Color(0xFFE8ECF0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        background: background,
        surface: cardBg,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardBg,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withOpacity(0.7)),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: TextStyle(
            fontSize: 22, fontWeight: FontWeight.bold, color: textPrimary),
        headlineSmall: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: TextStyle(fontSize: 15, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 13, color: textSecondary),
        labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textSecondary,
            letterSpacing: 0.5),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: primary.withOpacity(0.15),
        labelStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: divider, space: 1),
    );
  }
}

class AppConstants {
  static const List<String> provinces = [
    'Punjab', 'Sindh', 'KPK', 'Balochistan', 'ICT', 'AJK', 'GB'
  ];

  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  static const List<String> appStatuses = [
    'All', 'Submitted', 'Under Review', 'Printed', 'Dispatched', 'Delivered', 'Expired'
  ];

  static const List<String> religions = [
    'Islam', 'Christianity', 'Hinduism', 'Sikhism', 'Other'
  ];

  static Color statusColor(String status) {
    switch (status) {
      case 'Delivered': return AppTheme.success;
      case 'Dispatched': return AppTheme.info;
      case 'Printed': return const Color(0xFF9C27B0);
      case 'Under Review': return AppTheme.warning;
      case 'Submitted': return AppTheme.primary;
      case 'Expired': return AppTheme.error;
      default: return AppTheme.textSecondary;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'Delivered': return Icons.check_circle_rounded;
      case 'Dispatched': return Icons.local_shipping_rounded;
      case 'Printed': return Icons.print_rounded;
      case 'Under Review': return Icons.hourglass_top_rounded;
      case 'Submitted': return Icons.send_rounded;
      case 'Expired': return Icons.warning_rounded;
      default: return Icons.info_rounded;
    }
  }
}
