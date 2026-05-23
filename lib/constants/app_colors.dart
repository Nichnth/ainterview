import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core Colors
  static const Color dark = Color(0xFF1A1A1A);
  static const Color light = Color(0xFFF4F6F8);
  static const Color main = Color(0xFF4CABE5);
  static const Color secondary = Color(0xFF556F80);

  // Semantic Status Colors
  static const Color info = Color(0xFF66CBFF);
  static const Color success = Color(0xFF63E45F);
  static const Color warning = Color(0xFFECCC2C);
  static const Color danger = Color(0xFFEC481A);

  // UI Element Mapping Shortcuts
  static const Color textMain = dark;
  static const Color textMuted = secondary;
  static const Color background = light;
  static const Color border = Color(0xFFDCDFE4);
}