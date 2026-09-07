import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/animated_pressable.dart';
import '../../services/ai_copilot_service.dart';

typedef PiAiSheet = CopilotSheet;

class CopilotSheet extends StatefulWidget {
  final AiCopilotService copilotService;
  final String pageTitle;
  final String pageContent;

  const CopilotSheet({
    Key? key,
    required this.copilotService,
    required this.pageTitle,
    required this.pageContent,
  }) : super(key: key);

  @override
  State<CopilotSheet> createState() => _CopilotSheetState();
}

class _CopilotSheetState extends State<CopilotSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Context-aware welcome message from Pi AI
    final hasContent = widget.pageContent.trim().isNotEmpty;
    _messages.add({
      'role': 'assistant',
      'text': hasContent
          ? 'Hi! I\'m your **Pi AI**. I\'ve read "${widget.pageTitle}". How can I help you understand this page?'
          : 'Hi! I\'m your **Pi AI**. Ask me any question, or navigate to a web page and I can summarize or explain it for you!',
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _sendMessage(String query) async {
    final text = query.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    String answer;
    if (text.toLowerCase().contains('summar')) {
      answer = await widget.copilotService.summarize(widget.pageContent, title: widget.pageTitle);
    } else if (text.toLowerCase().contains('explain')) {
      answer = await widget.copilotService.explainSimply(widget.pageContent);
    } else {
      answer = await widget.copilotService.askPage(text, widget.pageContent);
    }

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'text': answer});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _openSettingsDialog() {
    final controller = TextEditingController(text: widget.copilotService.apiKey ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Colors.purple),
            SizedBox(width: 8),
            Text('Pi AI Settings', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add your AI API key to enable high-intelligence generative synthesis. If omitted, Prime Browser uses its smart local extractive AI engine.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter AI Studio API Key',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.copilotService.setApiKey(null);
              Navigator.pop(ctx);
            },
            child: const Text('Clear Key'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.copilotService.setApiKey(controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar with gradient aura
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: AppColors.piAiGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pi AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
                  tooltip: 'Pi AI Settings',
                  onPressed: _openSettingsDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Quick Action Prompt Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: isDark ? const Color(0xFF181818) : Colors.grey[100],
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildPromptChip('📌 3-Bullet Summary', 'Summarize this page in 3 bullets'),
                _buildPromptChip('💡 Explain Simply', 'Explain the content of this page simply'),
                _buildPromptChip('❓ Key Takeaways', 'What are the main takeaways from this article?'),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blueAccent
                          : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6)),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: msg['text'] ?? ''));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied to clipboard'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.copy,
                                  size: 14,
                                  color: isDark ? Colors.white38 : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Typing Indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purpleAccent),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Pi AI is analyzing this page...',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _inputController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendMessage,
                      decoration: const InputDecoration(
                        hintText: 'Ask Pi AI anything about this page...',
                        hintStyle: TextStyle(fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedPressable(
                  onTap: () => _sendMessage(_inputController.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      gradient: AppColors.piAiGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedPressable(
        onTap: () => _sendMessage(prompt),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.purple,
            ),
          ),
        ),
      ),
    );
  }
}
