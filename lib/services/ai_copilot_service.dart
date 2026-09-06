import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AiCopilotService with ChangeNotifier {
  String? _geminiApiKey;

  String? get geminiApiKey => _geminiApiKey;
  bool get hasApiKey => _geminiApiKey != null && _geminiApiKey!.isNotEmpty;

  void setApiKey(String? key) {
    _geminiApiKey = key?.trim();
    notifyListeners();
  }

  /// Generates a structured 3-bullet page summary
  Future<String> summarize(String pageContent, {String? title}) async {
    if (pageContent.trim().isEmpty) {
      return 'No readable page content available to summarize.';
    }

    if (hasApiKey) {
      final prompt = '''
You are the Edge Copilot browser assistant. Analyze the following webpage content titled "$title".
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
  Future<String> askPage(String question, String pageContent) async {
    if (question.trim().isEmpty) return 'Please enter a question.';
    if (pageContent.trim().isEmpty) {
      return 'No page content available to reference for this answer.';
    }

    if (hasApiKey) {
      final prompt = '''
You are the Edge Copilot AI browser assistant. The user is browsing a webpage with this content:
"""
$pageContent
"""
User Question: "$question"

Answer accurately, concisely, and directly grounded in the page text.
''';
      final response = await _callGemini(prompt);
      if (response != null) return response;
    }

    return _localQuestionAnswer(question, pageContent);
  }

  /// Explains complex concepts in simple terms
  Future<String> explainSimply(String pageContent) async {
    if (hasApiKey) {
      final prompt = '''
Explain the core concept of the following webpage content as if explaining to a beginner or 12-year-old. Use clear analogies and avoid unnecessary jargon.

Content:
$pageContent
''';
      final response = await _callGemini(prompt);
      if (response != null) return response;
    }

    return _localExplainSimply(pageContent);
  }

  // --- Gemini API Gateway using built-in dart:io ---
  Future<String?> _callGemini(String prompt) async {
    HttpClient? client;
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey',
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
      '\n💡 *Powered by Smart Local Extractive AI. Add a Gemini API key in Copilot settings for generative synthesis.*',
    );
    return buffer.toString();
  }

  String _localQuestionAnswer(String question, String content) {
    final qKeywords = question
        .toLowerCase()
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 3)
        .toSet();

    final sentences = content.split(RegExp(r'(?<=[.!?])\s+'));
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
      return '🔎 **Found relevant passage:**\n\n"$bestSentence"\n\n*(Add a Gemini API key for conversational AI answers).*';
    }

    return 'I could not find a direct answer in this article for "$question". Try refining your keywords or connecting a Gemini API key in Copilot settings.';
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
