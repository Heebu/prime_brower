import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/design_system/animated_pressable.dart';

class AudioReadAloudBar extends StatefulWidget {
  final String text;
  final VoidCallback onClose;

  const AudioReadAloudBar({
    Key? key,
    required this.text,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AudioReadAloudBar> createState() => _AudioReadAloudBarState();
}

class _AudioReadAloudBarState extends State<AudioReadAloudBar> with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  double _speed = 1.0;
  late AnimationController _animController;
  Timer? _timer;
  int _currentWordIndex = 0;
  List<String> _words = [];

  final List<double> _speeds = [0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _words = widget.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _startPlayback();
  }

  void _startPlayback() {
    _timer?.cancel();
    if (!_isPlaying || _words.isEmpty) return;

    final intervalMs = (300 / _speed).round();
    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (t) {
      if (!mounted) return;
      setState(() {
        if (_currentWordIndex < _words.length - 1) {
          _currentWordIndex++;
        } else {
          _isPlaying = false;
          _animController.stop();
          t.cancel();
        }
      });
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.repeat(reverse: true);
        _startPlayback();
      } else {
        _animController.stop();
        _timer?.cancel();
      }
    });
  }

  void _cycleSpeed() {
    final nextIndex = (_speeds.indexOf(_speed) + 1) % _speeds.length;
    setState(() {
      _speed = _speeds[nextIndex];
      _startPlayback();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF09090B) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey[200]!,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play / Pause Action
          AnimatedPressable(
            onTap: _togglePlayPause,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Animated Soundwave Equalizer
          _buildEqualizer(),
          const SizedBox(width: 12),

          // Read Aloud status
          Text(
            _isPlaying ? 'Reading Aloud...' : 'Paused',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(width: 12),

          // Speed Multiplier Chip
          AnimatedPressable(
            onTap: _cycleSpeed,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_speed}x',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Close Action
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizer() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final val = _animController.value;
        return Row(
          children: [
            _bar(8 + val * 10),
            const SizedBox(width: 3),
            _bar(16 - val * 8),
            const SizedBox(width: 3),
            _bar(10 + val * 12),
            const SizedBox(width: 3),
            _bar(14 - val * 6),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 3,
      height: _isPlaying ? height.clamp(4.0, 22.0) : 4.0,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
