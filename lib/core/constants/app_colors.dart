import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors - Modern iOS Style
  static const Color lightPrimaryBackground = Color(0xFFF8F9FA); // Off-White, luftig
  static const Color lightSecondaryBackground = Color(0xFFFFFFFF); // Reines Weiß
  static const Color lightAccent = Color(0xFFFFC107); // Warmes Gelb als Akzent
  static const Color lightAccentSecondary = Color(0xFF34C759); // Grün als sekundärer Akzent
  static const Color lightTextPrimary = Color(0xFF1C1C1E); // Weiches Schwarz
  static const Color lightTextSecondary = Color(0xFF8E8E93); // Helles Grau für sekundären Text
  static const Color lightCardBackground = Color(0xFFFFFFFF); // Weiß für Karten
  static const Color lightDivider = Color(0xFFE5E5EA); // Sehr helles Grau für Trennlinien
  static const Color lightShadow = Color(0x0F000000); // Sanfter Schatten (6% Opazität)

  // Dark Mode Colors - Modern iOS Style
  static const Color darkPrimaryBackground = Color(0xFF000000); // Tiefes Schwarz
  static const Color darkSecondaryBackground = Color(0xFF1C1C1E); // Dunkles Grau
  static const Color darkAccent = Color(0xFFFFD60A); // Helles Gelb für Dark Mode
  static const Color darkAccentSecondary = Color(0xFF32D74B); // Helles Grün
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // Reines Weiß
  static const Color darkTextSecondary = Color(0xFF8E8E93); // Mittleres Grau
  static const Color darkCardBackground = Color(0xFF1C1C1E); // Dunkle Karten
  static const Color darkDivider = Color(0xFF38383A); // Dunkles Grau für Trennlinien
  static const Color darkShadow = Color(0x33000000); // Stärkerer Schatten für Dark Mode (20% Opazität)

  // Common Colors - iOS System Colors
  static const Color success = Color(0xFF34C759); // iOS Grün
  static const Color warning = Color(0xFFFF9500); // iOS Orange
  static const Color error = Color(0xFFFF3B30); // iOS Rot
  static const Color info = Color(0xFF007AFF); // iOS Blau

  // Gradients - Sanfte, moderne Verläufe
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFFFFD60A), Color(0xFFFFE55C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Zusätzliche Akzentfarben für Vielfalt
  static const Color accentYellow = Color(0xFFFFC107);
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentBlue = Color(0xFF007AFF);
}
