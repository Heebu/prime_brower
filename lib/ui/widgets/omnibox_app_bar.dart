import 'package:flutter/material.dart';
import '../../services/browser_manager.dart';
import '../../services/shields_service.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/animated_pressable.dart';

class OmniboxAppBar extends StatefulWidget implements PreferredSizeWidget {
  final BrowserManager browserManager;
  final ShieldsService shieldsService;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenCopilot;
  final VoidCallback onFindInPage;
  final VoidCallback onOpenSync;
  final VoidCallback? onOpenShieldsDetails;

  const OmniboxAppBar({
    Key? key,
    required this.browserManager,
    required this.shieldsService,
    required this.onOpenMenu,
    required this.onOpenCopilot,
    required this.onFindInPage,
    required this.onOpenSync,
    this.onOpenShieldsDetails,
  }) : super(key: key);

  @override
  State<OmniboxAppBar> createState() => _OmniboxAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _OmniboxAppBarState extends State<OmniboxAppBar> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final tab = widget.browserManager.currentTab;
    final isNewTab = tab == null || tab.url == 'prime://newtab';
    _controller = TextEditingController(text: isNewTab ? '' : tab.url);
  }

  @override
  void didUpdateWidget(covariant OmniboxAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus) {
      final tab = widget.browserManager.currentTab;
      final expected = (tab == null || tab.url == 'prime://newtab') ? '' : tab.url;
      if (_controller.text != expected) {
        _controller.text = expected;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitUrl() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _focusNode.unfocus();
      widget.browserManager.navigateCurrentTab(text);
    }
  }

  void _showSecurityInfo() {
    final tab = widget.browserManager.currentTab;
    if (tab == null) return;

    final isHttps = tab.url.startsWith('https://');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isHttps ? Icons.lock : Icons.warning_amber_rounded,
              color: isHttps ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(isHttps ? 'Connection is secure' : 'Not secure', style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHttps
                  ? 'Your information (e.g. passwords or credit card numbers) is private when it is sent to this site.'
                  : 'You should not enter sensitive info on this site (e.g. passwords or credit cards), because it could be stolen by attackers.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text('URL: ${tab.url}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              'Shields: ${widget.shieldsService.blockedElementsCount} trackers/ads blocked',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.deepOrangeAccent),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = widget.browserManager.currentTab;
    final isIncognito = widget.browserManager.isIncognito;
    final isNewTab = tab == null || tab.url == 'prime://newtab';
    final isHttps = tab != null && tab.url.startsWith('https://');

    return AppBar(
      elevation: 0.5,
      backgroundColor: isIncognito ? const Color(0xFF1E1E1E) : Colors.white,
      foregroundColor: isIncognito ? Colors.white : Colors.black87,
      titleSpacing: 8,
      title: Container(
        height: 42,
        decoration: BoxDecoration(
          color: isIncognito ? const Color(0xFF2C2C2C) : Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // SSL / Security Lock Icon
            IconButton(
              icon: Icon(
                isNewTab
                    ? Icons.search
                    : (isIncognito
                        ? Icons.security
                        : (isHttps ? Icons.lock : Icons.info_outline)),
                size: 18,
                color: isNewTab
                    ? (isIncognito ? Colors.white54 : Colors.grey[600])
                    : (isHttps ? Colors.green : (isIncognito ? Colors.white70 : Colors.orange)),
              ),
              tooltip: isNewTab ? 'Search' : 'Site Information',
              onPressed: isNewTab ? null : _showSecurityInfo,
            ),
            // Omnibox URL Input
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.go,
                onSubmitted: (_) => _submitUrl(),
                style: TextStyle(
                  fontSize: 14,
                  color: isIncognito ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Search or type URL',
                  hintStyle: TextStyle(
                    color: isIncognito ? Colors.white38 : Colors.grey[500],
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            // Clear or Shields Badge
            if (_controller.text.isNotEmpty && _focusNode.hasFocus)
              IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                },
              )
            else if (widget.shieldsService.shieldsEnabled)
              GestureDetector(
                onTap: () {
                  if (widget.onOpenShieldsDetails != null) {
                    widget.onOpenShieldsDetails!();
                  } else {
                    _showSecurityInfo();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, size: 13, color: Colors.deepOrangeAccent),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.shieldsService.blockedElementsCount}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        // Copilot AI Action Pill
        AnimatedPressable(
          onTap: widget.onOpenCopilot,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.copilotGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Copilot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Cloud Sync / Account Button
        IconButton(
          icon: Icon(
            widget.browserManager.authService?.isAuthenticated == true
                ? Icons.cloud_done
                : Icons.cloud_outlined,
            size: 20,
            color: widget.browserManager.authService?.isAuthenticated == true
                ? Colors.green
                : null,
          ),
          tooltip: 'Prime Cloud Sync',
          onPressed: widget.onOpenSync,
        ),
        IconButton(
          icon: Icon(
            tab != null && tab.isLoading ? Icons.close : Icons.refresh,
            size: 20,
          ),
          tooltip: tab != null && tab.isLoading ? 'Stop' : 'Reload',
          onPressed: tab == null ? null : () => tab.reload(),
        ),
      ],
    );
  }
}
