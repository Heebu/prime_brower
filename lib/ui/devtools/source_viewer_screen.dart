import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SourceViewerScreen extends StatelessWidget {
  final String html;
  final String url;

  const SourceViewerScreen({
    Key? key,
    required this.html,
    required this.url,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lines = html.split('\n');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Page Source', style: TextStyle(fontSize: 16)),
            Text(
              url,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Source',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: html));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('HTML source copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E1E1E),
      body: Scrollbar(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1200,
            child: ListView.builder(
              itemCount: lines.length,
              itemBuilder: (context, index) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      alignment: Alignment.centerRight,
                      color: const Color(0xFF252526),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF858585),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        lines[index],
                        style: const TextStyle(
                          color: Color(0xFFD4D4D4),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
