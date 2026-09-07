import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final VoidCallback? onOpenTabs;
  final ValueChanged<bool>? onFocusChanged;
  final ValueChanged<String>? onQueryChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;

  const OmniboxAppBar({
    super.key,
    required this.browserManager,
    required this.shieldsService,
    required this.onOpenMenu,
    required this.onOpenCopilot,
    required this.onFindInPage,
    required this.onOpenSync,
    this.onOpenShieldsDetails,
    this.onOpenTabs,
    this.onFocusChanged,
    this.onQueryChanged,
    this.controller,
    this.focusNode,
  });

  @override
  State<OmniboxAppBar> createState() => _OmniboxAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _OmniboxAppBarState extends State<OmniboxAppBar> {
  TextEditingController? _internalController;
  FocusNode? _internalFocusNode;

  double _verticalDragDistance = 0.0;
  double _horizontalDragDistance = 0.0;

  TextEditingController get _effectiveController => widget.controller ?? _internalController!;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      final tab = widget.browserManager.currentTab;
      final isNewTab = tab == null || tab.url == 'prime://newtab';
      _internalController = TextEditingController(text: isNewTab ? '' : tab.url);
    }
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }

    _effectiveFocusNode.addListener(_handleFocusChange);
    _effectiveController.addListener(_handleTextChange);
  }

  void _handleFocusChange() {
    widget.onFocusChanged?.call(_effectiveFocusNode.hasFocus);
    setState(() {});
  }

  void _handleTextChange() {
    widget.onQueryChanged?.call(_effectiveController.text);
  }

  @override
  void didUpdateWidget(covariant OmniboxAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_effectiveFocusNode.hasFocus) {
      final tab = widget.browserManager.currentTab;
      final expected = (tab == null || tab.url == 'prime://newtab') ? '' : tab.url;
      if (_effectiveController.text != expected) {
        _effectiveController.text = expected;
      }
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _effectiveController.removeListener(_handleTextChange);
    _internalController?.dispose();
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _submitUrl() {
    final text = _effectiveController.text.trim();
    if (text.isNotEmpty) {
      _effectiveFocusNode.unfocus();
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
              color: isHttps ? const Color(0xFF10B981) : Colors.grey,
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
    final isFocused = _effectiveFocusNode.hasFocus;
    final tabsCount = widget.browserManager.currentTabs.length;

    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _verticalDragDistance = 0.0;
          _horizontalDragDistance = 0.0;
        },
        onPanUpdate: (details) {
          if (!isFocused) {
            _verticalDragDistance += details.delta.dy;
            _horizontalDragDistance += details.delta.dx;
          }
        },
        onPanEnd: (details) {
          if (!isFocused) {
            final vy = details.velocity.pixelsPerSecond.dy;
            final vx = details.velocity.pixelsPerSecond.dx;

            // Swiping down from top of app bar moves to all tabs
            if (_verticalDragDistance > 25 || vy > 180) {
              HapticFeedback.mediumImpact();
              widget.onOpenTabs?.call();
            } else if (_horizontalDragDistance > 35 || vx > 180) {
              HapticFeedback.selectionClick();
              widget.browserManager.switchToAdjacentTab(-1);
            } else if (_horizontalDragDistance < -35 || vx < -180) {
              HapticFeedback.selectionClick();
              widget.browserManager.switchToAdjacentTab(1);
            }
          }
          _verticalDragDistance = 0.0;
          _horizontalDragDistance = 0.0;
        },
        child: AppBar(
          elevation: isFocused ? 2 : 0.5,
          backgroundColor: (isIncognito || Theme.of(context).brightness == Brightness.dark)
              ? const Color(0xFF09090B)
              : Colors.white,
          foregroundColor: (isIncognito || Theme.of(context).brightness == Brightness.dark)
              ? Colors.white
              : const Color(0xFF09090B),
          titleSpacing: isFocused ? 0 : 8,
          leading: isFocused
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Cancel',
                  onPressed: () {
                    _effectiveFocusNode.unfocus();
                    final tab = widget.browserManager.currentTab;
                    final expected = (tab == null || tab.url == 'prime://newtab') ? '' : tab.url;
                    _effectiveController.text = expected;
                  },
                )
              : null,
          automaticallyImplyLeading: false,
          title: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (!isFocused) {
                _effectiveFocusNode.requestFocus();
              }
            },
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            height: 42,
            margin: EdgeInsets.only(right: isFocused ? 12 : 0),
            decoration: BoxDecoration(
              color: (isIncognito || Theme.of(context).brightness == Brightness.dark)
                  ? (isFocused ? const Color(0xFF27272A) : const Color(0xFF18181B))
                  : (isFocused ? const Color(0xFFF4F4F5) : const Color(0xFFE4E4E7)),
              borderRadius: BorderRadius.circular(24),
              border: isFocused
                  ? Border.all(
                      color: const Color(0xFF10B981),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // SSL / Security Lock Icon (only if not focused)
                if (!isFocused)
                  IconButton(
                    icon: Icon(
                      isNewTab
                          ? Icons.search
                          : (isIncognito
                              ? Icons.security
                              : (isHttps ? Icons.lock : Icons.info_outline)),
                      size: 18,
                      color: isNewTab
                          ? ((isIncognito || Theme.of(context).brightness == Brightness.dark) ? Colors.white54 : Colors.black54)
                          : (isHttps ? const Color(0xFF10B981) : ((isIncognito || Theme.of(context).brightness == Brightness.dark) ? Colors.white70 : Colors.black87)),
                    ),
                    tooltip: isNewTab ? 'Search' : 'Site Information',
                    onPressed: isNewTab ? null : _showSecurityInfo,
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(left: 12, right: 6),
                    child: Icon(Icons.search, size: 20, color: Color(0xFF10B981)),
                  ),

                // Omnibox URL Input
                Expanded(
                  child: IgnorePointer(
                    ignoring: !isFocused,
                    child: TextField(
                      controller: _effectiveController,
                      focusNode: _effectiveFocusNode,
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
                ),

                // Clear button when focused and text present
                if (_effectiveController.text.isNotEmpty && isFocused)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Clear',
                    onPressed: () {
                      _effectiveController.clear();
                      widget.onQueryChanged?.call('');
                      setState(() {});
                    },
                  )
                else if (!isFocused && widget.shieldsService.shieldsEnabled)
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
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield, size: 13, color: Color(0xFF10B981)),
                          const SizedBox(width: 3),
                          Text(
                            '${widget.shieldsService.blockedElementsCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            ),
          ),
          actions: isFocused
              ? const []
              : [
                  // Pi AI Action Pill
                  AnimatedPressable(
                    onTap: widget.onOpenCopilot,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: AppColors.piAiGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
                            'Pi AI',
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
                  // Home Button (replaces cloud sync)
                  IconButton(
                    icon: const Icon(Icons.home_outlined, size: 22),
                    tooltip: 'Home',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => widget.browserManager.navigateCurrentTab('prime://newtab'),
                  ),
                  // Tab Switcher with live badge
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.layers_outlined, size: 22),
                        tooltip: 'Tabs',
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onOpenTabs,
                      ),
                      if (tabsCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$tabsCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // More Options Overflow Menu
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 22),
                    tooltip: 'Menu',
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onOpenMenu,
                  ),
                ],
        ),
      ),
    );
  }
}
