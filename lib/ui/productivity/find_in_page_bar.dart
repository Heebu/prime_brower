import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/design_system/animated_pressable.dart';

class FindInPageBar extends StatefulWidget {
  final WebViewController controller;
  final VoidCallback onClose;

  const FindInPageBar({
    Key? key,
    required this.controller,
    required this.onClose,
  }) : super(key: key);

  @override
  State<FindInPageBar> createState() => _FindInPageBarState();
}

class _FindInPageBarState extends State<FindInPageBar> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _matchCount = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    // Clear in-page selections on dismiss
    widget.controller.runJavaScript('window.getSelection().removeAllRanges();');
    super.dispose();
  }

  void _search(String query, {bool backward = false}) async {
    final text = query.trim();
    if (text.isEmpty) {
      setState(() {
        _matchCount = 0;
        _currentIndex = 0;
      });
      return;
    }

    // Call native window.find API in browser
    final js = "window.find('$text', false, $backward, true, false, true, false);";
    final result = await widget.controller.runJavaScriptReturningResult(js);
    final found = result.toString() == 'true';

    setState(() {
      if (found) {
        if (_matchCount == 0) _matchCount = 1;
        if (backward) {
          if (_currentIndex > 1) _currentIndex--;
        } else {
          _currentIndex++;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      elevation: 6,
      color: isDark ? const Color(0xFF242424) : Colors.white,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: isDark ? Colors.white12 : Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: (val) => _search(val),
                onSubmitted: (val) => _search(val),
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Find in page...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              Text(
                _matchCount > 0 ? 'Found' : 'No matches',
                style: TextStyle(
                  fontSize: 12,
                  color: _matchCount > 0 ? Colors.green : Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              // Previous Match Arrow
              AnimatedPressable(
                onTap: () => _search(_searchController.text, backward: true),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.keyboard_arrow_up, size: 22),
                ),
              ),
              // Next Match Arrow
              AnimatedPressable(
                onTap: () => _search(_searchController.text, backward: false),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.keyboard_arrow_down, size: 22),
                ),
              ),
            ],
            // Close Action
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}
