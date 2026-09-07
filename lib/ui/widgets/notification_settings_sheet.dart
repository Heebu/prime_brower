import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationSettingsSheet extends StatefulWidget {
  final NotificationService? notificationService;

  const NotificationSettingsSheet({
    super.key,
    this.notificationService,
  });

  @override
  State<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  late final NotificationService _service;

  @override
  void initState() {
    super.initState();
    _service = widget.notificationService ?? NotificationService.instance;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        return Material(
          color: isDark ? const Color(0xFF09090B) : Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: SafeArea(
              child: SingleChildScrollView(
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
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
                                'Notifications & Alerts',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'FCM push alerts & background notifications',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white54 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // Section 1: Push Alert Channels
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                    child: Text(
                       'ALERT PREFERENCES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: isDark ? Colors.white38 : Colors.grey[500],
                      ),
                    ),
                  ),

                  // News Notifications
                  SwitchListTile(
                    secondary: const Icon(Icons.newspaper_rounded, color: Color(0xFF10B981)),
                    title: const Text('News & Breaking Stories'),
                    subtitle: const Text('Daily headlines and personalized articles'),
                    value: _service.newsEnabled,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (_) => _service.toggleNewsNotifications(),
                  ),

                  // Advert Notifications
                  SwitchListTile(
                    secondary: const Icon(Icons.campaign_rounded, color: Color(0xFF10B981)),
                    title: const Text('Promotions & Adverts'),
                    subtitle: const Text('Special offers, partner discounts and sponsor highlights'),
                    value: _service.advertsEnabled,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (_) => _service.toggleAdvertNotifications(),
                  ),

                  // Download Complete Notifications
                  SwitchListTile(
                    secondary: const Icon(Icons.download_done_rounded, color: Color(0xFF10B981)),
                    title: const Text('Download Complete Alerts'),
                    subtitle: const Text('Heads-up notification when a file finishes downloading'),
                    value: _service.downloadsEnabled,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (_) => _service.toggleDownloadNotifications(),
                  ),

                  // Background Page Load Notifications
                  SwitchListTile(
                    secondary: const Icon(Icons.tab_unselected_rounded, color: Color(0xFF10B981)),
                    title: const Text('Background Page Ready Alerts'),
                    subtitle: const Text('Notify when a tab finishes loading while browser is minimized'),
                    value: _service.backgroundPageLoadsEnabled,
                    activeThumbColor: const Color(0xFF10B981),
                    onChanged: (_) => _service.toggleBackgroundPageLoads(),
                  ),

                  const Divider(height: 24),

                  // Section 2: Quick Test Triggers
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TEST NOTIFICATIONS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                            color: isDark ? Colors.white38 : Colors.grey[500],
                          ),
                        ),
                        Text(
                          'Instant simulation',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white38 : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.newspaper, size: 16, color: Color(0xFF10B981)),
                          label: const Text('Test News Alert'),
                          onPressed: () {
                            _service.showNewsNotification(
                              title: 'Breaking: Flutter 3.44 Released',
                              body: 'Exciting multi-platform performance enhancements announced.',
                              url: 'https://flutter.dev',
                            );
                            _showToast(context, 'Sent News Alert notification');
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.campaign, size: 16, color: Color(0xFF10B981)),
                          label: const Text('Test Advert Alert'),
                          onPressed: () {
                            _service.showAdvertNotification(
                              title: 'Special Offer: 50% Off Cloud Sync Pro',
                              body: 'Upgrade your browser sync storage today!',
                              targetUrl: 'https://primebrowser.com/offer',
                            );
                            _showToast(context, 'Sent Advert Alert notification');
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.download_done, size: 16, color: Color(0xFF10B981)),
                          label: const Text('Test Download Alert'),
                          onPressed: () {
                            _service.showDownloadCompleteNotification(
                              fileName: 'prime_browser_v2.apk',
                              filePath: '/downloads/prime_browser_v2.apk',
                              bytes: 32500000,
                            );
                            _showToast(context, 'Sent Download Complete notification');
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.tab_unselected, size: 16, color: Color(0xFF10B981)),
                          label: const Text('Test Background Load'),
                          onPressed: () {
                            _service.showBackgroundPageLoadedNotification(
                              tabId: 'test_tab_01',
                              title: 'TechCrunch - AI News',
                              url: 'https://techcrunch.com/artificial-intelligence',
                            );
                            _showToast(context, 'Sent Background Page notification');
                          },
                        ),
                      ],
                    ),
                  ),

                  // Section 3: Recent Notifications Log
                  if (_service.recentNotifications.isNotEmpty) ...[
                    const Divider(height: 28),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                      child: Text(
                        'RECENT ALERTS LOG (${_service.recentNotifications.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: isDark ? Colors.white38 : Colors.grey[500],
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _service.recentNotifications.length > 5
                          ? 5
                          : _service.recentNotifications.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final alert = _service.recentNotifications[index];
                        IconData alertIcon;
                        const alertColor = Color(0xFF10B981);
                        switch (alert.type) {
                          case NotificationType.news:
                            alertIcon = Icons.newspaper;
                            break;
                          case NotificationType.advert:
                            alertIcon = Icons.campaign;
                            break;
                          case NotificationType.download:
                            alertIcon = Icons.download_done;
                            break;
                          case NotificationType.backgroundPage:
                            alertIcon = Icons.tab_unselected;
                            break;
                        }

                        return ListTile(
                          dense: true,
                          leading: Icon(alertIcon, color: alertColor, size: 20),
                          title: Text(
                            alert.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            alert.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  void _showToast(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
