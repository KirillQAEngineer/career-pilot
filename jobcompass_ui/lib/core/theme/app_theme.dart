import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),

      scaffoldBackgroundColor: AppColors.lightBackground,

      cardColor: AppColors.lightCard,

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme:
          ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
          ).copyWith(
            surface: AppColors.darkBackground,
            surfaceContainerLowest: AppColors.darkBackground,
            surfaceContainerLow: AppColors.darkCard,
            surfaceContainer: AppColors.darkCard,
            surfaceContainerHigh: const Color(0xFF171717),
            surfaceContainerHighest: const Color(0xFF1F1F1F),
            onSurface: AppColors.textPrimaryDark,
            onSurfaceVariant: AppColors.textSecondaryDark,
          ),

      scaffoldBackgroundColor: AppColors.darkBackground,

      cardColor: AppColors.darkCard,

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        indicatorColor: AppColors.primary.withValues(alpha: 0.20),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF151515),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
