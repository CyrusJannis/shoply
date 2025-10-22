import 'package:flutter/material.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightPrimaryBackground,
    primaryColor: AppColors.lightAccent,
    fontFamily: AppTextStyles.fontFamilyText,
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightAccent,
      secondary: AppColors.lightAccent,
      surface: AppColors.lightCardBackground,
      background: AppColors.lightPrimaryBackground,
      error: AppColors.error,
      onPrimary: AppColors.lightTextPrimary,
      onSecondary: AppColors.lightTextPrimary,
      onSurface: AppColors.lightTextPrimary,
      onBackground: AppColors.lightTextPrimary,
      onError: Colors.white,
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.lightPrimaryBackground,
      foregroundColor: AppColors.lightTextPrimary,
      iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
    ),
    
    // Card Theme - Sanfte Schatten und großzügige Abrundungen
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      ),
      color: AppColors.lightCardBackground,
      shadowColor: AppColors.lightShadow,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.cardMargin,
        vertical: AppDimensions.spacingSmall,
      ),
    ),
    
    // Sanfte Schatten für Karten
    shadowColor: AppColors.lightShadow,
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightCardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
        borderSide: const BorderSide(color: AppColors.lightAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingMedium,
      ),
      hintStyle: const TextStyle(
        color: AppColors.lightTextSecondary,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Elevated Button Theme - Sanfte Schatten und moderne Abrundungen
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: AppColors.lightShadow,
        backgroundColor: AppColors.lightAccent,
        foregroundColor: AppColors.lightTextPrimary,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMedium),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLarge,
          vertical: AppDimensions.paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.lightAccent,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.lightTextPrimary,
        side: const BorderSide(color: AppColors.lightAccent),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
        ),
      ),
    ),
    
    // Bottom Navigation Bar Theme - Modern mit Transparenz
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightCardBackground,
      selectedItemColor: AppColors.lightAccent,
      unselectedItemColor: AppColors.lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 11,
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.lightTextPrimary,
      size: AppDimensions.iconSizeMedium,
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: AppDimensions.dividerThickness,
      space: AppDimensions.spacingMedium,
    ),
    
    // Floating Action Button Theme - Sanfte Schatten
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.lightAccent,
      foregroundColor: AppColors.lightTextPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    // Dialog Theme - Moderne Pop-ups
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: AppColors.lightCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.modalBorderRadius),
      ),
    ),
    
    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      elevation: 0,
      backgroundColor: AppColors.lightCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetBorderRadius),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkPrimaryBackground,
    primaryColor: AppColors.darkAccent,
    fontFamily: AppTextStyles.fontFamilyText,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkAccent,
      secondary: AppColors.darkAccent,
      surface: AppColors.darkCardBackground,
      background: AppColors.darkPrimaryBackground,
      error: AppColors.error,
      onPrimary: AppColors.darkTextPrimary,
      onSecondary: AppColors.darkTextPrimary,
      onSurface: AppColors.darkTextPrimary,
      onBackground: AppColors.darkTextPrimary,
      onError: Colors.white,
    ),
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.darkPrimaryBackground,
      foregroundColor: AppColors.darkTextPrimary,
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
    ),
    
    // Card Theme - Sanfte Schatten und großzügige Abrundungen
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
      ),
      color: AppColors.darkCardBackground,
      shadowColor: AppColors.darkShadow,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.cardMargin,
        vertical: AppDimensions.spacingSmall,
      ),
    ),
    
    // Sanfte Schatten für Karten
    shadowColor: AppColors.darkShadow,
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
        borderSide: const BorderSide(color: AppColors.darkAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputBorderRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.paddingMedium,
      ),
      hintStyle: const TextStyle(
        color: AppColors.darkTextSecondary,
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Elevated Button Theme - Sanfte Schatten und moderne Abrundungen
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        shadowColor: AppColors.darkShadow,
        backgroundColor: AppColors.darkAccent,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMedium),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingLarge,
          vertical: AppDimensions.paddingMedium,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
        ),
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
    ),
    
    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkAccent,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkTextPrimary,
        side: const BorderSide(color: AppColors.darkAccent),
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonBorderRadius),
        ),
      ),
    ),
    
    // Bottom Navigation Bar Theme - Modern mit Transparenz
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkCardBackground,
      selectedItemColor: AppColors.darkAccent,
      unselectedItemColor: AppColors.darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 11,
      ),
      unselectedLabelStyle: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 11,
      ),
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.darkTextPrimary,
      size: AppDimensions.iconSizeMedium,
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.darkDivider,
      thickness: AppDimensions.dividerThickness,
      space: AppDimensions.spacingMedium,
    ),
    
    // Floating Action Button Theme - Sanfte Schatten
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.darkAccent,
      foregroundColor: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    // Dialog Theme - Moderne Pop-ups
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: AppColors.darkCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.modalBorderRadius),
      ),
    ),
    
    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      elevation: 0,
      backgroundColor: AppColors.darkCardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.bottomSheetBorderRadius),
        ),
      ),
    ),
  );
}
