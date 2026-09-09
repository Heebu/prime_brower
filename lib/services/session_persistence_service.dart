import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class SavedTabSession {
  final List<Map<String, dynamic>> tabs;
  final int activeIndex;

  SavedTabSession({required this.tabs, required this.activeIndex});

  Map<String, dynamic> toJson() => {
    'tabs': tabs,
    'activeIndex': activeIndex,
  };

  factory SavedTabSession.fromJson(Map<String, dynamic> json) {
    final rawTabs = json['tabs'] as List<dynamic>? ?? [];
    final tabs = rawTabs.map((t) => Map<String, dynamic>.from(t as Map)).toList();
    final activeIndex = json['activeIndex'] as int? ?? 0;
    return SavedTabSession(tabs: tabs, activeIndex: activeIndex);
  }
}

class SessionPersistenceService {
  static final SessionPersistenceService instance = SessionPersistenceService._internal();

  SessionPersistenceService._internal();

  File? _sessionFile;
  bool _mockMode = false;
  SavedTabSession? _mockSession;

  @visibleForTesting
  void enableMockMode([SavedTabSession? initialSession]) {
    _mockMode = true;
    _mockSession = initialSession;
  }

  bool get isMockMode => _mockMode;

  Future<File?> _getFile() async {
    if (_mockMode) return null;
    if (_sessionFile != null) return _sessionFile!;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _sessionFile = File('${dir.path}/tabs_session.json');
      return _sessionFile!;
    } catch (e) {
      debugPrint('SessionPersistenceService: Error resolving storage directory: $e');
      return null;
    }
  }

  /// Persists the list of normal tabs and the active tab index.
  Future<void> saveSession({
    required List<Map<String, dynamic>> normalTabs,
    required int activeIndex,
  }) async {
    if (_mockMode) {
      _mockSession = SavedTabSession(tabs: normalTabs, activeIndex: activeIndex);
      return;
    }

    try {
      final file = await _getFile();
      if (file == null) return;
      final session = SavedTabSession(tabs: normalTabs, activeIndex: activeIndex);
      final jsonString = jsonEncode(session.toJson());
      await file.writeAsString(jsonString, flush: true);
    } catch (e) {
      debugPrint('SessionPersistenceService: Error saving tab session: $e');
    }
  }

  /// Loads the saved session containing tabs and active index from disk.
  Future<SavedTabSession?> loadSession() async {
    if (_mockMode) {
      return _mockSession;
    }

    try {
      final file = await _getFile();
      if (file == null || !await file.exists()) return null;
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      final data = jsonDecode(content) as Map<String, dynamic>;
      return SavedTabSession.fromJson(data);
    } catch (e) {
      debugPrint('SessionPersistenceService: Error loading tab session: $e');
      return null;
    }
  }

  /// Clears saved session on disk.
  Future<void> clearSession() async {
    if (_mockMode) {
      _mockSession = null;
      return;
    }

    try {
      final file = await _getFile();
      if (file != null && await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('SessionPersistenceService: Error clearing tab session: $e');
    }
  }
}
