import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightPrimaryBackground = Color(0xFFE8F4F8);
  static const Color lightSecondaryBackground = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFFAEEAFB);
  static const Color lightTextPrimary = Color(0xFF000000);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightCardBackground = Color(0xFFFFFFFF);

  // Dark Mode Colors
  static const Color darkPrimaryBackground = Color(0xFF1A1A1A);
  static const Color darkSecondaryBackground = Color(0xFF2D2D2D);
  static const Color darkAccent = Color(0xFF4DD4E8);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkCardBackground = Color(0xFF2D2D2D);

  // Common Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [lightAccent, Color(0xFF87CEEB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkAccent, Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
