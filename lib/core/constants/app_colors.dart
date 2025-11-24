import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF9C27B0);
  static const Color secondary = Color(0xFFBA68C8);
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  static const Color divider = Color(0xFF2E2E2E);
  
  static const Gradient purpleGradient = LinearGradient(
    colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}