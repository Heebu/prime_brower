import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

typedef PiAiService = AiCopilotService;

class AiCopilotService with ChangeNotifier {
  static const String _configFileName = 'ai_config.json';
  File? _configFile;
  bool _mockMode = false;
  String? _mockKey;
  String? _geminiApiKey;
  String? _remoteApiKey;

  String? get apiKey => _geminiApiKey;
  String? get personalApiKey => _geminiApiKey;
  String? get remoteApiKey => _remoteApiKey;
  String? get effectiveApiKey => (_geminiApiKey != null && _geminiApiKey!.isNotEmpty) ? _geminiApiKey : _remoteApiKey;
  String? get geminiApiKey => effectiveApiKey;
  bool get hasApiKey => effectiveApiKey != null && effectiveApiKey!.isNotEmpty;
  bool get isUsingPersonalKey => _geminiApiKey != null && _geminiApiKey!.isNotEmpty;
  bool get isUsingRemoteKey => !isUsingPersonalKey && _remoteApiKey != null && _remoteApiKey!.isNotEmpty;
  bool get isMockMode => _mockMode;

  bool get _isTestEnv {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  AiCopilotService([String? initialApiKey]) : _geminiApiKey = initialApiKey {
    if (_isTestEnv) {
      _mockMode = true;
    }
    _loadSavedApiKey();
  }

  @visibleForTesting
  void enableMockMode([String? initialKey]) {
    _mockMode = true;
    _mockKey = initialKey;
    _geminiApiKey = initialKey;
    _remoteApiKey = null;
  }

  @visibleForTesting
  void setRemoteApiKey(String? key) {
    final cleanKey = key?.trim();
    _remoteApiKey = (cleanKey != null && cleanKey.isNotEmpty) ? cleanKey : null;
    notifyListeners();
  }

  /// Automatically retrieves shared project API key from Firestore (/app_config/ai)
  Future<void> fetchRemoteApiKey({FirebaseFirestore? firestore}) async {
    if (_mockMode && firestore == null) return;
    try {
      FirebaseFirestore? db = firestore;
      if (db == null) {
        try {
          if (Firebase.apps.isNotEmpty) {
            db = FirebaseFirestore.instance;
          }
        } catch (_) {}
      }
      if (db == null) return;

      final doc = await db.collection('app_config').doc('ai').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final key = (data['geminiApiKey'] as String?) ?? (data['apiKey'] as String?);
        if (key != null && key.trim().isNotEmpty) {
          _remoteApiKey = key.trim();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('AiCopilotService: Error fetching remote AI config: $e');
    }
  }

  Future<File?> _getConfigFile() async {
    if (_mockMode) return null;
    if (_configFile != null) return _configFile!;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _configFile = File('${dir.path}/$_configFileName');
      return _configFile!;
    } catch (e) {
      debugPrint('AiCopilotService: Error resolving storage directory: $e');
      return null;
    }
  }

  Future<void> _loadSavedApiKey() async {
    if (_mockMode) {
      _geminiApiKey = _mockKey;
      return;
    }
    try {
      final file = await _getConfigFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          final key = data['geminiApiKey'] as String?;
          if (key != null && key.trim().isNotEmpty) {
            _geminiApiKey = key.trim();
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('AiCopilotService: Error loading saved API key: $e');
    }
  }

  Future<void> setApiKey(String? key) async {
    final cleanKey = key?.trim();
    _geminiApiKey = (cleanKey != null && cleanKey.isNotEmpty) ? cleanKey : null;
    notifyListeners();

    if (_mockMode) {
      _mockKey = _geminiApiKey;
      return;
    }

    try {
      final file = await _getConfigFile();
      if (file == null) return;
      if (_geminiApiKey == null) {
        if (await file.exists()) {
          await file.delete();
        }
      } else {
        final data = jsonEncode({'geminiApiKey': _geminiApiKey});
        await file.writeAsString(data, flush: true);
      }
    } catch (e) {
      debugPrint('AiCopilotService: Error persisting API key: $e');
    }
  }

  /// Generates a structured 3-bullet page summary
  Future<String> summarize(String pageContent, {String? title, String? url}) async {
    if (pageContent.trim().isEmpty) {
      return 'No readable page content available to summarize.';
    }

    if (hasApiKey) {
      final prompt = '''
You are Pi AI, the intelligent browser assistant. Analyze the following webpage content titled "$title"${url != null && url.isNotEmpty ? ' at $url' : ''}.
Provide:
1. A 1-sentence executive overview.
2. Exactly three high-impact bullet points capturing the core takeaways.
3. Keep the tone crisp, objective, and clear.

Webpage Content:
$pageContent
''';
      final response = await _callGemini(prompt);
      if (response != null) return response;
    }

    // Fallback: Smart Local Extractive NLP Engine
    return _localSummarize(pageContent, title: title);
  }

  /// Answers contextual user questions about the active webpage
  Future<String> askPage(
    String question,
    String pageContent, {
    String? title,
    String? url,
    String? selectedText,
  }) async {
    if (question.trim().isEmpty) return 'Please enter a question.';
    if (pageContent.trim().isEmpty && (selectedText == null || selectedText.trim().isEmpty)) {
      return 'No page content or selection available to reference for this answer.';
    }

    if (hasApiKey) {
      final promptBuffer = StringBuffer();
      promptBuffer.writeln('You are Pi AI, the intelligent browser assistant.');
      if (title != null && title.isNotEmpty) {
        promptBuffer.writeln('Webpage Title: "$title"');
      }
      if (url != null && url.isNotEmpty) {
        promptBuffer.writeln('Webpage URL: $url');
      }
      if (selectedText != null && selectedText.trim().isNotEmpty) {
        promptBuffer.writeln('Highlighted Text by User on Screen:\n"""\n${selectedText.trim()}\n"""');
      }
      promptBuffer.writeln('Webpage Content:\n"""\n$pageContent\n"""\n');
      promptBuffer.writeln('User Question: "$question"');
      promptBuffer.writeln('Answer accurately, concisely, and directly grounded in the page text and screen context.');

      final response = await _callGemini(promptBuffer.toString());
      if (response != null) return response;
    }

    return _localQuestionAnswer(question, pageContent, selectedText: selectedText);
  }

  /// Explains complex concepts in simple terms
  Future<String> explainSimply(
    String pageContent, {
    String? title,
    String? url,
    String? selectedText,
  }) async {
    if (hasApiKey) {
      final promptBuffer = StringBuffer();
      promptBuffer.writeln('You are Pi AI. Explain the core concept of the following webpage content as if explaining to a beginner or 12-year-old. Use clear analogies and avoid unnecessary jargon.');
      if (title != null && title.isNotEmpty) {
        promptBuffer.writeln('Title: "$title"');
      }
      if (selectedText != null && selectedText.trim().isNotEmpty) {
        promptBuffer.writeln('User specifically highlighted this part:\n"""\n${selectedText.trim()}\n"""');
      }
      promptBuffer.writeln('Content:\n$pageContent');

      final response = await _callGemini(promptBuffer.toString());
      if (response != null) return response;
    }

    return _localExplainSimply(selectedText != null && selectedText.trim().isNotEmpty ? selectedText : pageContent);
  }

  /// Performs a multi-turn conversation preserving full context of past messages and on-screen page text
  Future<String> chat({
    required List<Map<String, String>> messages,
    required String pageContent,
    String? title,
    String? url,
    String? selectedText,
  }) async {
    if (messages.isEmpty) {
      return 'How can I assist you with this page?';
    }

    if (hasApiKey) {
      final response = await _callGeminiChat(
        messages: messages,
        pageContent: pageContent,
        title: title,
        url: url,
        selectedText: selectedText,
      );
      if (response != null && response.trim().isNotEmpty) {
        return response;
      }
    }

    // Fallback: Smart Local Extractive Engine
    final lastUserMessage = messages.reversed.firstWhere(
      (m) => m['role'] == 'user',
      orElse: () => {'text': ''},
    );
    final query = lastUserMessage['text'] ?? '';
    if (query.toLowerCase().contains('summar')) {
      return _localSummarize(pageContent, title: title);
    } else if (query.toLowerCase().contains('explain')) {
      return _localExplainSimply(
        selectedText != null && selectedText.trim().isNotEmpty ? selectedText : pageContent,
      );
    } else {
      return _localQuestionAnswer(query, pageContent, selectedText: selectedText);
    }
  }

  // --- Gemini API Gateway using built-in dart:io ---
  Future<String?> _callGemini(String prompt) async {
    final key = effectiveApiKey;
    if (key == null || key.isEmpty) return null;

    HttpClient? client;
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key',
      );

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.4,
          'maxOutputTokens': 800,
        }
      });

      client = HttpClient();
      final request = await client.postUrl(url);
      request.headers.contentType = ContentType.json;
      request.write(payload);

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) return text.toString().trim();
      }
    } catch (_) {
    } finally {
      client?.close();
    }
    return null;
  }

  Future<String?> _callGeminiChat({
    required List<Map<String, String>> messages,
    required String pageContent,
    String? title,
    String? url,
    String? selectedText,
  }) async {
    final key = effectiveApiKey;
    if (key == null || key.isEmpty) return null;

    HttpClient? client;
    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key',
      );

      final systemPromptBuffer = StringBuffer();
      systemPromptBuffer.writeln('You are Pi AI, the intelligent and insightful browser copilot for Prime Browser.');
      systemPromptBuffer.writeln('You assist users while they browse the web.');
      if (title != null && title.isNotEmpty) {
        systemPromptBuffer.writeln('Active Webpage Title: "$title"');
      }
      if (url != null && url.isNotEmpty) {
        systemPromptBuffer.writeln('Active Webpage URL: $url');
      }
      if (selectedText != null && selectedText.trim().isNotEmpty) {
        systemPromptBuffer.writeln('User specifically highlighted this text on screen:\n"""\n${selectedText.trim()}\n"""');
      }
      if (pageContent.trim().isNotEmpty) {
        // Limit page content in system prompt to prevent token limit overflows
        final trimmedContent = pageContent.length > 25000 ? '${pageContent.substring(0, 25000)}... [truncated]' : pageContent;
        systemPromptBuffer.writeln('Active Webpage Content:\n"""\n$trimmedContent\n"""');
      }
      systemPromptBuffer.writeln(
        '\nGuidelines:\n'
        '1. Answer accurately, concisely, and directly grounded in the active page and on-screen context.\n'
        '2. Remember all previous turns in this conversation and provide seamless follow-up answers.\n'
        '3. If asked about something not mentioned in the page, provide an answer from general knowledge while politely noting that it is not covered on this page.\n'
        '4. Format answers using markdown: bold highlights, bullet points, and clean brief paragraphs.',
      );

      // Build alternating contents array (Gemini requires starting with 'user' and alternating roles)
      final contents = <Map<String, dynamic>>[];
      String? lastRole;

      for (final msg in messages) {
        final rawRole = msg['role'] ?? 'user';
        final role = (rawRole == 'model' || rawRole == 'assistant') ? 'model' : 'user';
        final text = (msg['text'] ?? '').trim();
        if (text.isEmpty) continue;

        // Gemini contents must start with 'user'
        if (contents.isEmpty && role != 'user') {
          continue;
        }

        if (role == lastRole) {
          final lastParts = contents.last['parts'] as List<dynamic>;
          lastParts.add({'text': text});
        } else {
          contents.add({
            'role': role,
            'parts': [
              {'text': text}
            ],
          });
          lastRole = role;
        }
      }

      if (contents.isEmpty) return null;

      final payload = jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemPromptBuffer.toString()}
          ]
        },
        'contents': contents,
        'generationConfig': {
          'temperature': 0.5,
          'maxOutputTokens': 1000,
        }
      });

      client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(payload);

      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) return text.toString().trim();
      }
    } catch (_) {
    } finally {
      client?.close();
    }
    return null;
  }

  // --- Smart Local NLP Algorithm (Offline Heuristic Engine) ---
  String _localSummarize(String content, {String? title}) {
    final cleaned = content
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\{.*?\}'), '')
        .trim();

    final sentences = cleaned
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.length > 35 && s.length < 250)
        .toList();

    if (sentences.isEmpty) {
      return 'Content preview: ${cleaned.length > 200 ? cleaned.substring(0, 200) + '...' : cleaned}';
    }

    // Score sentences by word variety and length
    sentences.sort((a, b) {
      final scoreA = a.split(' ').toSet().length;
      final scoreB = b.split(' ').toSet().length;
      return scoreB.compareTo(scoreA);
    });

    final topTakeaways = sentences.take(3).toList();

    final buffer = StringBuffer();
    if (title != null && title.isNotEmpty) {
      buffer.writeln('📋 **Overview for "$title":**\n');
    } else {
      buffer.writeln('📋 **Executive Summary:**\n');
    }

    for (int i = 0; i < topTakeaways.length; i++) {
      buffer.writeln('• ${topTakeaways[i].trim()}');
    }

    buffer.writeln(
      '\n💡 *Powered by Smart Local Extractive AI. Add an API key in Pi AI settings for generative synthesis.*',
    );
    return buffer.toString();
  }

  String _localQuestionAnswer(String question, String content, {String? selectedText}) {
    final effectiveContent = (selectedText != null && selectedText.trim().isNotEmpty)
        ? '$selectedText\n$content'
        : content;

    final qKeywords = question
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3)
        .toSet();

    final sentences = effectiveContent.split(RegExp(r'(?<=[.!?])\s+'));
    String? bestSentence;
    int maxMatches = 0;

    for (final sentence in sentences) {
      final sWords = sentence.toLowerCase().split(RegExp(r'\W+')).toSet();
      final matches = sWords.intersection(qKeywords).length;
      if (matches > maxMatches) {
        maxMatches = matches;
        bestSentence = sentence;
      }
    }

    if (bestSentence != null && maxMatches > 0) {
      return '🔎 **Found relevant passage:**\n\n"$bestSentence"\n\n*(Add an API key in settings for full conversational AI).*';
    }

    return 'I could not find a direct answer in this article for "$question". Try refining your keywords or connecting an API key in Pi AI settings.';
  }

  String _localExplainSimply(String content) {
    final sentences = content
        .split(RegExp(r'(?<=[.!?])\s+'))
        .where((s) => s.length > 40 && s.length < 180)
        .take(2)
        .join(' ');

    return '💡 **In Simple Terms:**\n\n'
        'This page explains: "${sentences.trim()}".\n\n'
        'Essentially, it addresses the main themes shown above in straightforward language.';
  }
}
