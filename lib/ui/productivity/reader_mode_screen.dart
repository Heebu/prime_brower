import 'package:flutter/material.dart';
import 'audio_read_aloud_bar.dart';

class ReaderModeScreen extends StatefulWidget {
  final String title;
  final String content;
  final String url;

  const ReaderModeScreen({
    Key? key,
    required this.title,
    required this.content,
    required this.url,
  }) : super(key: key);

  @override
  State<ReaderModeScreen> createState() => _ReaderModeScreenState();
}

class _ReaderModeScreenState extends State<ReaderModeScreen> {
  double _fontSize = 17.0;
  int _themeMode = 0; // 0: White, 1: Sepia, 2: Dark
  bool _showReadAloud = false;

  final List<Color> _bgColors = [
    Colors.white,
    const Color(0xFFFBF0D9), // Sepia
    const Color(0xFF1E1E1E), // Dark
  ];

  final List<Color> _textColors = [
    Colors.black87,
    const Color(0xFF5F4B32),
    const Color(0xFFE0E0E0),
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _bgColors[_themeMode];
    final textColor = _textColors[_themeMode];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        title: const Text('Immersive Reader', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(_showReadAloud ? Icons.volume_up : Icons.volume_up_outlined),
            tooltip: 'Read Aloud (TTS)',
            onPressed: () {
              setState(() => _showReadAloud = !_showReadAloud);
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Text Size',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: bgColor,
                builder: (ctx) => StatefulBuilder(
                  builder: (ctx, setModalState) => Container(
                    padding: const EdgeInsets.all(20),
                    height: 180,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text('A', style: TextStyle(fontSize: 14, color: textColor)),
                            Expanded(
                              child: Slider(
                                value: _fontSize,
                                min: 13,
                                max: 28,
                                divisions: 15,
                                onChanged: (val) {
                                  setState(() => _fontSize = val);
                                  setModalState(() {});
                                },
                              ),
                            ),
                            Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _themeChoiceChip(0, 'Light', Colors.white, Colors.black87, setModalState),
                            _themeChoiceChip(1, 'Sepia', const Color(0xFFFBF0D9), const Color(0xFF5F4B32), setModalState),
                            _themeChoiceChip(2, 'Dark', const Color(0xFF1E1E1E), Colors.white, setModalState),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                fontSize: _fontSize + 8,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.url,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.6),
              ),
            ),
            const Divider(height: 28),
            SelectableText(
              widget.content.isEmpty
                  ? 'No readable article content found for this webpage.'
                  : widget.content,
              style: TextStyle(
                fontSize: _fontSize,
                color: textColor,
                height: 1.7,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _showReadAloud
          ? SafeArea(
              child: AudioReadAloudBar(
                text: widget.content,
                onClose: () => setState(() => _showReadAloud = false),
              ),
            )
          : null,
    );
  }

  Widget _themeChoiceChip(int index, String label, Color bg, Color border, StateSetter setModalState) {
    final isSelected = _themeMode == index;
    return GestureDetector(
      onTap: () {
        setState(() => _themeMode = index);
        setModalState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: index == 2 ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
