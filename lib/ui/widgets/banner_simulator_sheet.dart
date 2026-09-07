import 'package:flutter/material.dart';
import '../../models/browser_banner.dart';
import '../../services/connectivity_banner_service.dart';
import '../offline/prime_runner_screen.dart';

class BannerSimulatorSheet extends StatelessWidget {
  final String activeTabId;
  final VoidCallback? onReloadTab;

  const BannerSimulatorSheet({
    super.key,
    required this.activeTabId,
    this.onReloadTab,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF09090B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.announcement_rounded,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'In-Browser Banners & Alerts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Test and simulate context-aware alerts',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Launch Offline Game Hero Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.videogame_asset_rounded,
                        color: Color(0xFF38BDF8),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prime Cyber Runner',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Play interactive offline 60fps mini-game',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PrimeRunnerScreen(
                              isOnline: ConnectivityBannerService.instance.isOnline,
                              onRetryConnection: () {
                                Navigator.pop(context);
                                onReloadTab?.call();
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Play', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'TEST CONTEXTUAL BANNERS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // No Network Banner
                  ActionChip(
                    avatar: const Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFF59E0B)),
                    label: const Text('No Network Banner'),
                    onPressed: () {
                      ConnectivityBannerService.instance.simulateNoNetwork(
                        activeTabId,
                        onPlayGame: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PrimeRunnerScreen(
                                isOnline: ConnectivityBannerService.instance.isOnline,
                                onRetryConnection: () {
                                  Navigator.pop(context);
                                  onReloadTab?.call();
                                },
                              ),
                            ),
                          );
                        },
                      );
                      Navigator.pop(context);
                    },
                  ),

                  // Slow Network Banner
                  ActionChip(
                    avatar: const Icon(Icons.speed_rounded, size: 16, color: Color(0xFFFB923C)),
                    label: const Text('Slow Network Banner'),
                    onPressed: () {
                      ConnectivityBannerService.instance.simulateSlowNetwork(activeTabId);
                      Navigator.pop(context);
                    },
                  ),

                  // Page Error Network Banner
                  ActionChip(
                    avatar: const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                    label: const Text('Page Error Banner'),
                    onPressed: () {
                      ConnectivityBannerService.instance.simulatePageError(
                        activeTabId,
                        error: 'ERR_NAME_NOT_RESOLVED: Server DNS resolution timed out.',
                        onRetry: onReloadTab,
                      );
                      Navigator.pop(context);
                    },
                  ),

                  // Scam / Security Privacy Warning
                  ActionChip(
                    avatar: const Icon(Icons.gpp_maybe_rounded, size: 16, color: Color(0xFFDC2626)),
                    label: const Text('Scam / Security Warning'),
                    onPressed: () {
                      ConnectivityBannerService.instance.simulateSecurityWarning(
                        activeTabId,
                        domain: 'paypa1-security-verify.com',
                      );
                      Navigator.pop(context);
                    },
                  ),

                  // Insecure HTTP Warning
                  ActionChip(
                    avatar: const Icon(Icons.lock_open_rounded, size: 16, color: Color(0xFFF97316)),
                    label: const Text('Insecure HTTP Banner'),
                    onPressed: () {
                      ConnectivityBannerService.instance.simulateInsecureHttp(activeTabId);
                      Navigator.pop(context);
                    },
                  ),

                  // Location Permission Banner
                  ActionChip(
                    avatar: const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF3B82F6)),
                    label: const Text('Location Permission'),
                    onPressed: () {
                      ConnectivityBannerService.instance.simulatePermission(
                        activeTabId,
                        type: PermissionType.location,
                        domain: 'maps.google.com',
                      );
                      Navigator.pop(context);
                    },
                  ),

                  // Camera Permission Banner
                  ActionChip(
                    avatar: const Icon(Icons.videocam_rounded, size: 16, color: Color(0xFF3B82F6)),
                    label: const Text('Camera Permission'),
                    onPressed: () {
                      ConnectivityBannerService.instance.simulatePermission(
                        activeTabId,
                        type: PermissionType.camera,
                        domain: 'meet.google.com',
                      );
                      Navigator.pop(context);
                    },
                  ),

                  // Reader Mode Suggestion
                  ActionChip(
                    avatar: const Icon(Icons.chrome_reader_mode_rounded, size: 16, color: Color(0xFF8B5CF6)),
                    label: const Text('Reader Mode Suggestion'),
                    onPressed: () {
                      ConnectivityBannerService.instance.simulateReaderMode(activeTabId);
                      Navigator.pop(context);
                    },
                  ),

                  // Pop-up / Deceptive Redirect Blocked Banner
                  ActionChip(
                    avatar: const Icon(Icons.open_in_new_off_rounded, size: 16, color: Color(0xFF6366F1)),
                    label: const Text('Pop-up Blocked'),
                    onPressed: () {
                      ConnectivityBannerService.instance.simulatePopupBlocked(
                        activeTabId,
                        blockedUrl: 'https://promo-ad-tracker.net/click?offer=123',
                      );
                      Navigator.pop(context);
                    },
                  ),

                  // Clear All Banners
                  ActionChip(
                    avatar: const Icon(Icons.clear_all_rounded, size: 16, color: Color(0xFF10B981)),
                    label: const Text('Clear All Banners'),
                    onPressed: () {
                      ConnectivityBannerService.instance.clearBanners(activeTabId);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
