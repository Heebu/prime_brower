import 'package:flutter/material.dart';
import '../../services/shields_service.dart';

class ShieldsDetailsSheet extends StatelessWidget {
  final ShieldsService shieldsService;
  final String currentUrl;
  final VoidCallback onReload;

  const ShieldsDetailsSheet({
    Key? key,
    required this.shieldsService,
    required this.currentUrl,
    required this.onReload,
  }) : super(key: key);

  String _extractHost(String url) {
    try {
      final host = Uri.parse(url).host;
      if (host.isNotEmpty) return host;
    } catch (_) {}
    return url.isEmpty ? 'New Tab' : url;
  }

  @override
  Widget build(BuildContext context) {
    final host = _extractHost(currentUrl);
    final isWhitelisted = shieldsService.isSiteWhitelisted(host);
    final isShieldsActive = shieldsService.shieldsEnabled && !isWhitelisted;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: shieldsService,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF09090B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Master Toggle
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.shield_rounded, color: Color(0xFF10B981), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prime Shields',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF09090B),
                              ),
                            ),
                            Text(
                              'Deep Network AdBlocker & Anti-Tracker',
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: shieldsService.shieldsEnabled,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (_) => shieldsService.toggleShields(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Current Site Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isShieldsActive
                          ? const Color(0xFF10B981).withOpacity(0.08)
                          : (isDark ? const Color(0xFF18181B) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isShieldsActive
                            ? const Color(0xFF10B981).withOpacity(0.3)
                            : (isDark ? Colors.white12 : Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isShieldsActive ? Icons.verified_user_rounded : Icons.gpp_bad_outlined,
                          color: isShieldsActive ? const Color(0xFF10B981) : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                host,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF09090B),
                                ),
                              ),
                              Text(
                                isShieldsActive ? 'Shields UP on this site' : 'Shields DOWN on this site',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isShieldsActive
                                      ? const Color(0xFF10B981)
                                      : (isDark ? Colors.white60 : Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            shieldsService.toggleSiteExemption(host);
                            onReload();
                          },
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                          child: Text(isWhitelisted ? 'Enable' : 'Pause'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4 Metrics Grid
                  Row(
                    children: [
                      _buildMetricTile(
                        label: 'Total Blocked',
                        value: '${shieldsService.blockedElementsCount}',
                        icon: Icons.block_rounded,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricTile(
                        label: 'Network Requests',
                        value: '${shieldsService.networkBlockedCount}',
                        icon: Icons.wifi_off_rounded,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMetricTile(
                        label: 'Cosmetic Hidden',
                        value: '${shieldsService.cosmeticBlockedCount}',
                        icon: Icons.visibility_off_rounded,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricTile(
                        label: 'Est. Data Saved',
                        value: '${shieldsService.estimatedDataSavedMb.toStringAsFixed(1)} MB',
                        icon: Icons.data_saver_on_rounded,
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Blocked Requests Log
                  const Text(
                    'RECENT BLOCKED REQUESTS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),

                  if (shieldsService.blockedRequests.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18181B) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Clean Page',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF09090B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No malicious trackers or ad calls intercepted yet.',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: shieldsService.blockedRequests.length.clamp(0, 15),
                      itemBuilder: (context, index) {
                        final req = shieldsService.blockedRequests[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF18181B) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? Colors.white12 : Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  req.category,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      req.domain,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: isDark ? Colors.white : const Color(0xFF09090B),
                                      ),
                                    ),
                                    Text(
                                      req.shortUrl,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${req.timestamp.minute}:${req.timestamp.second.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? Colors.white12 : color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
