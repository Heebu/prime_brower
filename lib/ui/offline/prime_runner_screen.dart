import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimeRunnerScreen extends StatefulWidget {
  final VoidCallback onRetryConnection;
  final bool isOnline;

  const PrimeRunnerScreen({
    super.key,
    required this.onRetryConnection,
    this.isOnline = false,
  });

  @override
  State<PrimeRunnerScreen> createState() => _PrimeRunnerScreenState();
}

enum GameState { ready, playing, gameOver }

class Obstacle {
  double x;
  final double width;
  final double height;
  final Color color;
  final String label;

  Obstacle({
    required this.x,
    required this.width,
    required this.height,
    required this.color,
    required this.label,
  });
}

class _PrimeRunnerScreenState extends State<PrimeRunnerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _gameLoopController;

  GameState _gameState = GameState.ready;
  int _score = 0;
  static int _highScore = 0;

  // Character Physics
  double _characterY = 0.0; // 0 is ground
  double _characterVelocityY = 0.0;
  final double _gravity = 1400.0;
  final double _jumpVelocity = -520.0;
  int _jumpsRemaining = 2; // Supports double jump!

  // Game World
  final double _groundHeight = 90.0;
  double _gameSpeed = 260.0; // pixels per second
  final List<Obstacle> _obstacles = [];
  double _timeUntilNextObstacle = 1.2;
  final Random _random = Random();

  // Parallax Stars
  final List<Offset> _stars = [];

  Timer? _scoreTimer;

  @override
  void initState() {
    super.initState();
    _gameLoopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateGameLoop);

    // Generate random stars for background
    for (int i = 0; i < 40; i++) {
      _stars.add(Offset(_random.nextDouble(), _random.nextDouble()));
    }
  }

  @override
  void dispose() {
    _scoreTimer?.cancel();
    _gameLoopController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameState = GameState.playing;
      _score = 0;
      _characterY = 0.0;
      _characterVelocityY = 0.0;
      _jumpsRemaining = 2;
      _gameSpeed = 260.0;
      _obstacles.clear();
      _timeUntilNextObstacle = 1.0;
    });

    _scoreTimer?.cancel();
    _scoreTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_gameState == GameState.playing && mounted) {
        setState(() {
          _score += 1;
          if (_score > _highScore) {
            _highScore = _score;
          }
          // Gradually ramp up speed
          _gameSpeed = 260.0 + (_score * 0.8).clamp(0, 300);
        });
      }
    });

    _lastTickTime = DateTime.now();
    _gameLoopController.repeat();
  }

  DateTime _lastTickTime = DateTime.now();

  void _updateGameLoop() {
    if (_gameState != GameState.playing) return;

    final now = DateTime.now();
    final dt = (now.difference(_lastTickTime).inMicroseconds / 1000000.0).clamp(0.001, 0.05);
    _lastTickTime = now;

    // 1. Update Character Vertical Physics
    _characterVelocityY += _gravity * dt;
    _characterY += _characterVelocityY * dt;

    if (_characterY >= 0) {
      _characterY = 0.0;
      _characterVelocityY = 0.0;
      _jumpsRemaining = 2; // Reset jump counter upon landing
    }

    // 2. Spawn Obstacles
    _timeUntilNextObstacle -= dt;
    if (_timeUntilNextObstacle <= 0) {
      final obstacleType = _random.nextInt(3);
      double height;
      double width;
      Color color;
      String label;

      switch (obstacleType) {
        case 0:
          height = 36.0;
          width = 24.0;
          color = const Color(0xFFEF4444); // Red glitch pillar
          label = 'DNS';
          break;
        case 1:
          height = 50.0;
          width = 28.0;
          color = const Color(0xFFF59E0B); // Amber firewall
          label = '404';
          break;
        default:
          height = 30.0;
          width = 38.0;
          color = const Color(0xFF8B5CF6); // Purple glitch hurdle
          label = 'ERR';
          break;
      }

      _obstacles.add(
        Obstacle(
          x: 420.0, // relative spawn point
          width: width,
          height: height,
          color: color,
          label: label,
        ),
      );

      // Random delay until next obstacle
      _timeUntilNextObstacle = 1.3 + _random.nextDouble() * 1.5;
    }

    // 3. Move Obstacles & Collision Check
    final characterBox = Rect.fromLTWH(40, -_characterY - 36, 32, 36);

    for (int i = _obstacles.length - 1; i >= 0; i--) {
      final obs = _obstacles[i];
      obs.x -= _gameSpeed * dt;

      final obsBox = Rect.fromLTWH(obs.x, -obs.height, obs.width, obs.height);

      // Check collision
      if (characterBox.overlaps(obsBox)) {
        _triggerGameOver();
        return;
      }

      // Remove offscreen
      if (obs.x < -60) {
        _obstacles.removeAt(i);
      }
    }

    setState(() {});
  }

  void _jump() {
    if (_gameState == GameState.ready || _gameState == GameState.gameOver) {
      _startGame();
      return;
    }

    if (_jumpsRemaining > 0) {
      HapticFeedback.lightImpact();
      setState(() {
        _characterVelocityY = _jumpVelocity;
        _jumpsRemaining--;
      });
    }
  }

  void _triggerGameOver() {
    HapticFeedback.heavyImpact();
    _scoreTimer?.cancel();
    _gameLoopController.stop();
    setState(() {
      _gameState = GameState.gameOver;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Cyber Navy
      body: SafeArea(
        child: Column(
          children: [
            // Top Status & Network Restoration Alert Bar
            _buildTopStatusBanner(),

            // Game World Arena
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _jump,
                child: ClipRect(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          // 1. Cyber Starfield & Neon Grid
                          CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: _CyberBackgroundPainter(
                              stars: _stars,
                              groundHeight: _groundHeight,
                            ),
                          ),

                          // 2. Score HUD
                          Positioned(
                            top: 16,
                            left: 20,
                            right: 20,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PRIME CYBER RUNNER',
                                      style: TextStyle(
                                        color: Color(0xFF38BDF8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'SCORE: $_score',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    'HI: $_highScore',
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. Ground Line
                          Positioned(
                            bottom: _groundHeight,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF38BDF8),
                                    Color(0xFF818CF8),
                                    Color(0xFFC084FC),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF38BDF8),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 4. Obstacles
                          ..._obstacles.map((obs) {
                            return Positioned(
                              left: obs.x,
                              bottom: _groundHeight,
                              child: Container(
                                width: obs.width,
                                height: obs.height,
                                decoration: BoxDecoration(
                                  color: obs.color,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: obs.color.withOpacity(0.6),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  obs.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            );
                          }),

                          // 5. Cyber Runner Character
                          Positioned(
                            left: 40,
                            bottom: _groundHeight - _characterY,
                            child: _buildRunnerCharacter(),
                          ),

                          // 6. Overlays (Ready / Game Over)
                          if (_gameState == GameState.ready) _buildReadyOverlay(),
                          if (_gameState == GameState.gameOver) _buildGameOverOverlay(),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Bottom Diagnostics & Action Bar
            _buildBottomControls(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildRunnerCharacter() {
    final isJumping = _characterY < 0;
    return Container(
      width: 32,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF38BDF8),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF38BDF8),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cyber Visor
          Positioned(
            top: 8,
            right: 4,
            child: Container(
              width: 14,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Thruster flame if jumping
          if (isJumping)
            Positioned(
              bottom: -4,
              left: 10,
              child: Container(
                width: 12,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFF97316),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(6)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF1E293B),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: widget.isOnline ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isOnline ? Icons.wifi : Icons.wifi_off_rounded,
              color: widget.isOnline ? Colors.greenAccent : const Color(0xFFF59E0B),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isOnline ? 'Internet Restored' : 'Offline Mode',
                  style: TextStyle(
                    color: widget.isOnline ? Colors.greenAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  widget.isOnline
                      ? 'Connection is back! Tap Reload to return.'
                      : 'No internet connection detected.',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: widget.onRetryConnection,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.isOnline ? Colors.green : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyOverlay() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38BDF8).withOpacity(0.15),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videogame_asset_rounded, color: Color(0xFF38BDF8), size: 48),
            const SizedBox(height: 12),
            const Text(
              'PRIME CYBER RUNNER',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap anywhere to Jump & Double-Jump\nDodge DNS glitches & Firewalls while offline!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('START RUN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    final isNewHigh = _score >= _highScore && _score > 0;
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CRASHED!',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isNewHigh ? '🏆 NEW RECORD: $_score' : 'Score: $_score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onRetryConnection,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry Network'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: const Color(0xFF0F172A),
                  ),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: const Text('Play Again', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tap screen or jump button to play. Tap reload to reconnect.',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          IconButton.filled(
            onPressed: _jump,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: const Color(0xFF0F172A),
            ),
            icon: const Icon(Icons.arrow_upward_rounded),
            tooltip: 'Jump',
          ),
        ],
      ),
    );
  }
}

class _CyberBackgroundPainter extends CustomPainter {
  final List<Offset> stars;
  final double groundHeight;

  _CyberBackgroundPainter({
    required this.stars,
    required this.groundHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Starfield
    final starPaint = Paint()..color = Colors.white70;
    for (final star in stars) {
      canvas.drawCircle(
        Offset(star.dx * size.width, star.dy * (size.height - groundHeight)),
        1.0,
        starPaint,
      );
    }

    // 2. Cyber Grid under ground
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    final groundY = size.height - groundHeight;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, groundY), Offset(x, size.height), gridPaint);
    }
    for (double y = groundY; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CyberBackgroundPainter oldDelegate) => false;
}
