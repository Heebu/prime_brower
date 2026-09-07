import 'package:flutter/material.dart';

class AppColors {
  // Brand & Feature Gradients
  static const LinearGradient piAiGradient = LinearGradient(
    colors: [Color(0xFF7928CA), Color(0xFFFF0080)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient copilotGradient = piAiGradient;

  static const LinearGradient primeBlueGradient = LinearGradient(
    colors: [Color(0xFF0061FF), Color(0xFF60EFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shieldGradient = LinearGradient(
    colors: [Color(0xFFFF4B1F), Color(0xFFFF9068)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x1AFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Semantic Status Colors
  static const Color secureGreen = Color(0xFF10B981);
  static const Color insecureOrange = Color(0xFFF59E0B);
  static const Color shieldOrange = Color(0xFFFF5722);
  static const Color devToolsBlue = Color(0xFF2563EB);
  static const Color copilotPurple = Color(0xFF8B5CF6);
  static const Color piAiPurple = copilotPurple;

  // Surfaces - Light
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF1F3F5);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);

  // Surfaces - Dark
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF282828);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Helper method to retrieve surface color based on theme
  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : lightBorder;
  }
}
