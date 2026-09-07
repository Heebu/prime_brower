import 'package:flutter/material.dart';

class AppColors {
  // Brand Green Constants
  static const Color primaryGreen = Color(0xFF10B981);
  static const Color primaryGreenDark = Color(0xFF059669);
  static const Color primaryGreenLight = Color(0xFF34D399);
  static const Color primaryGreenAccent = Color(0xFF00E676);

  // Pure Base Colors
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pureBlack = Color(0xFF000000);

  // Brand & Feature Gradients (Strict Green/Black/White)
  static const LinearGradient primeGreenGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient piAiGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient copilotGradient = piAiGradient;

  // Backward compatibility alias: redirects blue to green
  static const LinearGradient primeBlueGradient = primeGreenGradient;

  static const LinearGradient shieldGradient = LinearGradient(
    colors: [Color(0xFF047857), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x1AFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Semantic Status Colors (strictly green, retaining aliases for build safety)
  static const Color secureGreen = Color(0xFF10B981);
  static const Color shieldGreen = Color(0xFF10B981);
  static const Color insecureOrange = Color(0xFF10B981);
  static const Color shieldOrange = Color(0xFF10B981);
  static const Color devToolsBlue = Color(0xFF10B981);
  static const Color copilotPurple = Color(0xFF10B981);
  static const Color piAiPurple = Color(0xFF10B981);

  // Surfaces - Light (White & Black)
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF4F4F5);
  static const Color lightBorder = Color(0xFFE4E4E7);
  static const Color lightTextPrimary = Color(0xFF09090B);
  static const Color lightTextSecondary = Color(0xFF71717A);

  // Surfaces - Dark (Black & White)
  static const Color darkBackground = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF141416);
  static const Color darkCard = Color(0xFF1C1C1F);
  static const Color darkBorder = Color(0xFF27272A);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);

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
