import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PullToRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool isIncognito;

  const PullToRefreshWrapper({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.isIncognito = false,
  }) : super(key: key);

  @override
  State<PullToRefreshWrapper> createState() => _PullToRefreshWrapperState();
}

class _PullToRefreshWrapperState extends State<PullToRefreshWrapper> with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _isRefreshing = false;
  bool _thresholdReached = false;
  static const double _refreshThreshold = 75.0;
  static const double _maxDragOffset = 130.0;

  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isRefreshing) return;

    // Only allow downward drag
    if (details.primaryDelta != null && details.primaryDelta! > 0 || _dragOffset > 0) {
      final delta = details.primaryDelta ?? 0;
      // Damping / friction formula
      final factor = math.max(0.0, 1.0 - (_dragOffset / _maxDragOffset));
      final newOffset = (_dragOffset + delta * factor * 0.7).clamp(0.0, _maxDragOffset);

      if (newOffset >= _refreshThreshold && !_thresholdReached) {
        _thresholdReached = true;
        HapticFeedback.mediumImpact();
      } else if (newOffset < _refreshThreshold && _thresholdReached) {
        _thresholdReached = false;
      }

      setState(() {
        _dragOffset = newOffset;
      });
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) async {
    if (_isRefreshing) return;

    if (_dragOffset >= _refreshThreshold) {
      setState(() {
        _isRefreshing = true;
        _dragOffset = _refreshThreshold;
      });
      _spinController.repeat();

      try {
        await widget.onRefresh();
      } finally {
        if (mounted) {
          _spinController.stop();
          _spinController.reset();
          setState(() {
            _isRefreshing = false;
            _thresholdReached = false;
            _dragOffset = 0.0;
          });
        }
      }
    } else {
      setState(() {
        _dragOffset = 0.0;
        _thresholdReached = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isIncognito;
    final progress = (_dragOffset / _refreshThreshold).clamp(0.0, 1.0);
    final rotation = _isRefreshing
        ? _spinController.view
        : AlwaysStoppedAnimation(progress * 2 * math.pi);

    return Stack(
      children: [
        // Content
        NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            // If scroll view is at the very top, allow pull to refresh
            return false;
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: widget.child,
          ),
        ),

        // Pull-down Floating Reload Disc
        if (_dragOffset > 0 || _isRefreshing)
          Positioned(
            top: math.max(12.0, _dragOffset - 36),
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: (_dragOffset / 25.0).clamp(0.0, 1.0),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: _thresholdReached || _isRefreshing
                          ? (isDark ? Colors.purpleAccent : Colors.blueAccent)
                          : Colors.grey.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: RotationTransition(
                      turns: rotation,
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 22,
                        color: _thresholdReached || _isRefreshing
                            ? (isDark ? Colors.purpleAccent : Colors.blueAccent)
                            : (isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
