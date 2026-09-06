import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/devtools_service.dart';

class JsConsoleDialog extends StatefulWidget {
  final WebViewController controller;

  const JsConsoleDialog({Key? key, required this.controller}) : super(key: key);

  @override
  State<JsConsoleDialog> createState() => _JsConsoleDialogState();
}

class _JsConsoleDialogState extends State<JsConsoleDialog> {
  final TextEditingController _scriptController = TextEditingController();
  final List<String> _outputLogs = [];
  bool _isRunning = false;

  final List<String> _quickSnippets = [
    'document.title',
    'location.href',
    'document.cookie',
    'navigator.userAgent',
    'document.querySelectorAll("img").length',
  ];

  @override
  void dispose() {
    _scriptController.dispose();
    super.dispose();
  }

  void _runScript([String? scriptToRun]) async {
    final script = (scriptToRun ?? _scriptController.text).trim();
    if (script.isEmpty) return;

    setState(() {
      _isRunning = true;
      _outputLogs.add('> $script');
    });

    final result = await DevToolsService.executeJavaScript(widget.controller, script);

    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _outputLogs.add('< $result');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 520,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.terminal, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Text(
                      'JavaScript Console',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick snippets chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickSnippets.map((snippet) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        snippet,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                      onPressed: () {
                        _scriptController.text = snippet;
                        _runScript(snippet);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Output log container
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _outputLogs.isEmpty
                    ? const Center(
                        child: Text(
                          'Enter JavaScript and tap Run to see output',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _outputLogs.length,
                        itemBuilder: (context, index) {
                          final log = _outputLogs[index];
                          final isInput = log.startsWith('>');
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: SelectableText(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: isInput
                                    ? Colors.lightBlueAccent
                                    : (log.contains('Error') ? Colors.redAccent : Colors.lightGreenAccent),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _scriptController,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'e.g. alert("Hello")',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _runScript(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isRunning ? null : () => _runScript(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: _isRunning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Run'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
