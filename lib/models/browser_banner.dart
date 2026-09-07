import 'package:flutter/material.dart';

enum BannerType {
  noNetwork,
  slowNetwork,
  pageError,
  securityWarning,
  insecureHttp,
  permission,
  readerModeSuggestion,
}

enum PermissionType {
  location,
  camera,
  microphone,
  notifications,
}

class BrowserBanner {
  final String id;
  final BannerType type;
  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool isDismissible;
  final VoidCallback? onDismiss;
  final DateTime timestamp;
  final PermissionType? permissionType;

  BrowserBanner({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.isDismissible = true,
    this.onDismiss,
    this.permissionType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory BrowserBanner.noNetwork({
    required VoidCallback onRetry,
    required VoidCallback onPlayGame,
    VoidCallback? onDismiss,
  }) {
    return BrowserBanner(
      id: 'no_network_${DateTime.now().microsecondsSinceEpoch}',
      type: BannerType.noNetwork,
      title: 'No Internet Connection',
      message: 'You are currently offline. Check your network or play a mini-game.',
      icon: Icons.wifi_off_rounded,
      accentColor: const Color(0xFFF59E0B), // Amber
      primaryActionLabel: 'Play Game',
      onPrimaryAction: onPlayGame,
      secondaryActionLabel: 'Retry',
      onSecondaryAction: onRetry,
      onDismiss: onDismiss,
    );
  }

  factory BrowserBanner.slowNetwork({
    required VoidCallback onReloadLite,
    VoidCallback? onDismiss,
  }) {
    return BrowserBanner(
      id: 'slow_network_${DateTime.now().microsecondsSinceEpoch}',
      type: BannerType.slowNetwork,
      title: 'Slow Network Connection',
      message: 'This page is taking longer than usual to load.',
      icon: Icons.speed_rounded,
      accentColor: const Color(0xFFFB923C), // Orange
      primaryActionLabel: 'Reload Lite',
      onPrimaryAction: onReloadLite,
      secondaryActionLabel: 'Wait',
      onSecondaryAction: onDismiss,
      onDismiss: onDismiss,
    );
  }

  factory BrowserBanner.pageError({
    required String errorDescription,
    required VoidCallback onRetry,
    VoidCallback? onDismiss,
  }) {
    return BrowserBanner(
      id: 'page_error_${DateTime.now().microsecondsSinceEpoch}',
      type: BannerType.pageError,
      title: 'Page Load Failed',
      message: errorDescription.isNotEmpty
          ? errorDescription
          : 'Unable to reach the server. The site might be down or unreachable.',
      icon: Icons.error_outline_rounded,
      accentColor: const Color(0xFFEF4444), // Red
      primaryActionLabel: 'Reload',
      onPrimaryAction: onRetry,
      onDismiss: onDismiss,
    );
  }

  factory BrowserBanner.securityWarning({
    required String domain,
    required VoidCallback onBackToSafety,
    VoidCallback? onProceedAnyway,
    VoidCallback? onDismiss,
  }) {
    return BrowserBanner(
      id: 'security_warning_${DateTime.now().microsecondsSinceEpoch}',
      type: BannerType.securityWarning,
      title: 'Deceptive Site / Privacy Risk',
      message: 'Prime Shields detected suspicious phishing or malware behavior on "$domain".',
      icon: Icons.gpp_maybe_rounded,
      accentColor: const Color(0xFFDC2626), // Crimson
      primaryActionLabel: 'Back to Safety',
      onPrimaryAction: onBackToSafety,
      secondaryActionLabel: onProceedAnyway != null ? 'Proceed' : null,
      onSecondaryAction: onProceedAnyway,
      isDismissible: true,
      onDismiss: onDismiss,
    );
  }

  factory BrowserBanner.insecureHttp({
    required VoidCallback onUpgradeHttps,
    VoidCallback? onDismiss,
  }) {
    return BrowserBanner(
      id: 'insecure_http_${DateTime.now().microsecondsSinceEpoch}',
      type: BannerType.insecureHttp,
      title: 'Not Secure (HTTP)',
      message: 'Your connection to this site is unencrypted. Do not enter passwords or cards.',
      icon: Icons.lock_open_rounded,
      accentColor: const Color(0xFFF97316), // Warm Orange
      primaryActionLabel: 'Use HTTPS',
      onPrimaryAction: onUpgradeHttps,
      onDismiss: onDismiss,
    );
  }

  factory BrowserBanner.permission({
    required String domain,
    required PermissionType permission,
    required VoidCallback onAllow,
    required VoidCallback onBlock,
    VoidCallback? onDismiss,
  }) {
    IconData icon;
    String permName;
    switch (permission) {
      case PermissionType.location:
        icon = Icons.location_on_rounded;
        permName = 'Location';
        break;
      case PermissionType.camera:
        icon = Icons.videocam_rounded;
        permName = 'Camera';
        break;
      case PermissionType.microphone:
        icon = Icons.mic_rounded;
        permName = 'Microphone';
        break;
      case PermissionType.notifications:
        icon = Icons.notifications_rounded;
        permName = 'Notifications';
        break;
    }

    return BrowserBanner(
      id: 'permission_${permission.name}_${DateTime.now().microsecondsSinceEpoch}',
      type: BannerType.permission,
      permissionType: permission,
      title: 'Permission Request',
      message: '$domain wants to access your $permName.',
      icon: icon,
      accentColor: const Color(0xFF3B82F6), // Blue
      primaryActionLabel: 'Allow',
      onPrimaryAction: onAllow,
      secondaryActionLabel: 'Block',
      onSecondaryAction: onBlock,
      onDismiss: onDismiss,
    );
  }

  factory BrowserBanner.readerModeSuggestion({
    required VoidCallback onOpenReaderMode,
    VoidCallback? onDismiss,
  }) {
    return BrowserBanner(
      id: 'reader_mode_${DateTime.now().microsecondsSinceEpoch}',
      type: BannerType.readerModeSuggestion,
      title: 'Reader View Available',
      message: 'Distraction-free reading mode is available for this article.',
      icon: Icons.chrome_reader_mode_rounded,
      accentColor: const Color(0xFF8B5CF6), // Purple
      primaryActionLabel: 'Reader Mode',
      onPrimaryAction: onOpenReaderMode,
      secondaryActionLabel: 'Dismiss',
      onSecondaryAction: onDismiss,
      onDismiss: onDismiss,
    );
  }
}
