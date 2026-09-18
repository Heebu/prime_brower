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
  final String? pageUrl;
  final String? selectedText;

  const CopilotSheet({
    Key? key,
    required this.copilotService,
    required this.pageTitle,
    required this.pageContent,
    this.pageUrl,
    this.selectedText,
  }) : super(key: key);

  @override
  State<CopilotSheet> createState() => _CopilotSheetState();
}

class _CopilotSheetState extends State<CopilotSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  double _lastKeyboardHeight = 0;

  @override
  void initState() {
    super.initState();
    // Context-aware welcome message from Pi AI
    final hasSelection = widget.selectedText != null && widget.selectedText!.trim().isNotEmpty;
    final hasContent = widget.pageContent.trim().isNotEmpty;

    String initialGreeting;
    if (hasSelection) {
      initialGreeting = 'Hi! I\'m your **Pi AI**. I noticed you highlighted:\n\n> "${widget.selectedText!.trim()}"\n\nHow can I help you understand this selection or this page?';
    } else if (hasContent) {
      initialGreeting = 'Hi! I\'m your **Pi AI**. I\'ve read "${widget.pageTitle}". How can I help you understand this page?';
    } else {
      initialGreeting = 'Hi! I\'m your **Pi AI**. Ask me any question, or navigate to a web page and I can summarize or explain it for you!';
    }

    _messages.add({
      'role': 'assistant',
      'text': initialGreeting,
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

    final answer = await widget.copilotService.chat(
      messages: _messages,
      pageContent: widget.pageContent,
      title: widget.pageTitle,
      url: widget.pageUrl,
      selectedText: widget.selectedText,
    );

    if (!mounted) return;
    setState(() {
      _messages.add({'role': 'assistant', 'text': answer});
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _openSettingsDialog() {
    final controller = TextEditingController(text: widget.copilotService.apiKey ?? '');
    final isPersonal = widget.copilotService.isUsingPersonalKey;
    final isRemote = widget.copilotService.isUsingRemoteKey;

    final Color badgeColor = isPersonal
        ? const Color(0xFF10B981)
        : (isRemote ? const Color(0xFF0284C7) : Colors.grey);
    final String badgeText = isPersonal
        ? 'Personal Gemini Key Active'
        : (isRemote ? 'Prime Cloud AI Active' : 'Smart Local Engine Active');
    final IconData badgeIcon = (isPersonal || isRemote)
        ? Icons.check_circle
        : Icons.info_outline;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Pi AI Settings', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 14, color: badgeColor),
                  const SizedBox(width: 6),
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isPersonal
                  ? 'Your personal Gemini API key is saved on this device and takes precedence over default settings.'
                  : (isRemote
                      ? 'Connected to Prime Browser\'s shared Cloud AI backend. Add your own key below if you wish to override it.'
                      : 'Add your Google AI Studio Gemini API key to enable generative synthesis and deep multi-turn understanding.'),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: isPersonal ? 'Personal Key Set' : 'Paste Personal Gemini API Key',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.copilotService.setApiKey(null);
              if (mounted) setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Clear Key'),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.copilotService.setApiKey(controller.text);
              if (mounted) setState(() {});
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final topPadding = mediaQuery.padding.top;
    final systemBottomPadding = mediaQuery.viewPadding.bottom;
    final screenHeight = mediaQuery.size.height;

    if (keyboardHeight > 0 && _lastKeyboardHeight == 0) {
      _scrollToBottom();
    }
    _lastKeyboardHeight = keyboardHeight;

    final double maxAvailableHeight = screenHeight - topPadding - 16 - keyboardHeight;
    final double defaultHeight = screenHeight * 0.75;
    final double sheetHeight = keyboardHeight > 0
        ? maxAvailableHeight.clamp(220.0, defaultHeight)
        : defaultHeight;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF09090B) : Colors.white,
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
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF4F4F5),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (widget.selectedText != null && widget.selectedText!.trim().isNotEmpty)
                    _buildPromptChip(
                      '🔍 Explain Selection',
                      'Explain what this selected passage means: "${widget.selectedText!.trim()}"',
                    ),
                  _buildPromptChip('📌 3-Bullet Summary', 'Summarize this page in 3 bullets'),
                  _buildPromptChip('💡 Explain Simply', 'Explain the content of this page simply'),
                  _buildPromptChip('❓ Key Takeaways', 'What are the main takeaways from this article?'),
                  _buildPromptChip('📅 Deadlines & Dates', 'What are the key dates, deadlines, or timelines mentioned on this page?'),
                  _buildPromptChip('🎯 Requirements', 'What are the requirements or eligibility criteria mentioned?'),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView.builder(
                  controller: _scrollController,
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5)),
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
                                color: isUser ? Colors.white : (isDark ? Colors.white : const Color(0xFF09090B)),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
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
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                keyboardHeight > 0
                    ? 8
                    : (12 + systemBottomPadding).clamp(16.0, 36.0),
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF09090B) : Colors.white,
                border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF18181B) : const Color(0xFFF4F4F5),
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
            color: const Color(0xFF10B981).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF10B981),
            ),
          ),
        ),
      ),
    );
  }
}
