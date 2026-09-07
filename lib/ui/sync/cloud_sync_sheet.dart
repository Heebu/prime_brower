import 'package:flutter/material.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/firebase_sync_service.dart';
import '../../services/browser_manager.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/animated_pressable.dart';
import '../auth/auth_dialog.dart';

class CloudSyncSheet extends StatefulWidget {
  final FirebaseAuthService authService;
  final FirebaseSyncService syncService;
  final BrowserManager browserManager;

  const CloudSyncSheet({
    Key? key,
    required this.authService,
    required this.syncService,
    required this.browserManager,
  }) : super(key: key);

  @override
  State<CloudSyncSheet> createState() => _CloudSyncSheetState();
}

class _CloudSyncSheetState extends State<CloudSyncSheet> {
  bool _syncBookmarks = true;
  bool _syncTabs = true;

  void _openAuthDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AuthDialog(authService: widget.authService),
    );
    if (result == true && mounted) {
      setState(() {});
      widget.browserManager.syncOpenTabsToCloud();
    }
  }

  void _syncNow() {
    widget.browserManager.syncOpenTabsToCloud();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cloud sync completed'),
        duration: Duration(seconds: 1),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthenticated = widget.authService.isAuthenticated;
    final user = widget.authService.currentUser;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Material(
        color: isDark ? const Color(0xFF09090B) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud_sync, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text(
                        'Prime Cloud Sync',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // User Account Card
                  if (!isAuthenticated)
                    _buildSignedOutCard(isDark)
                  else
                    _buildSignedInCard(isDark),

                  const SizedBox(height: 20),

                  // Sync Settings
                  const Text(
                    'Sync Options',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Bookmarks & Collections'),
                    subtitle: const Text('Keep saved pages up to date across devices'),
                    value: _syncBookmarks,
                    activeColor: const Color(0xFF10B981),
                    onChanged: isAuthenticated
                        ? (val) => setState(() => _syncBookmarks = val)
                        : null,
                  ),
                  SwitchListTile(
                    title: const Text('Open Tabs Mirroring'),
                    subtitle: const Text('View and access open tabs from other devices'),
                    value: _syncTabs,
                    activeColor: const Color(0xFF10B981),
                    onChanged: isAuthenticated
                        ? (val) => setState(() => _syncTabs = val)
                        : null,
                  ),

                  const Divider(height: 32),

                  // Tabs From Other Devices
                  const Row(
                    children: [
                      Icon(Icons.devices, size: 18, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text(
                        'Tabs from Other Devices',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (!isAuthenticated)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Sign in to see tabs open on your other phones, tablets, or computers.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600]),
                      ),
                    )
                  else
                    _buildRemoteTabsStream(user!.uid, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSignedOutCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not Signed In',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Local Browsing Mode',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedPressable(
            onTap: _openAuthDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.primeBlueGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Sign In to Sync',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInCard(bool isDark) {
    final name = widget.authService.userDisplayName;
    final email = widget.authService.userEmail;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF10B981),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF09090B),
                      ),
                    ),
                    Text(
                      email,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.logout, size: 20, color: isDark ? Colors.white70 : Colors.black87),
                tooltip: 'Sign Out',
                onPressed: () async {
                  await widget.authService.signOut();
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'Syncing Active',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _syncNow,
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Sync Now', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteTabsStream(String uid, bool isDark) {
    return StreamBuilder<List<RemoteDeviceTabs>>(
      stream: widget.syncService.streamRemoteDevices(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
        }

        final devices = snapshot.data ?? [];
        if (devices.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(
              'No other devices active currently. Sign in on your other devices to see their open tabs here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
            ),
          );
        }

        return Column(
          children: devices.map((dev) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                leading: const Icon(Icons.laptop_chromebook, color: Color(0xFF10B981)),
                title: Text(dev.deviceName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text('${dev.tabs.length} tabs open', style: const TextStyle(fontSize: 11)),
                children: dev.tabs.map((tab) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.link, size: 16),
                    title: Text(tab['title'] ?? 'Tab', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(tab['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () {
                      final url = tab['url'];
                      if (url != null && url.isNotEmpty) {
                        widget.browserManager.openNewTab(url);
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
