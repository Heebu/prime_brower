import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookmark.dart';
import '../models/search_suggestion.dart';

class RemoteDeviceTabs {
  final String deviceId;
  final String deviceName;
  final DateTime lastActive;
  final List<Map<String, String>> tabs;

  RemoteDeviceTabs({
    required this.deviceId,
    required this.deviceName,
    required this.lastActive,
    required this.tabs,
  });
}

class FirebaseSyncService with ChangeNotifier {
  FirebaseFirestore? _firestore;
  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final String _deviceId = 'device_${DateTime.now().millisecondsSinceEpoch % 100000}';
  List<SearchSuggestion> _cachedSuggestions = [];

  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get deviceId => _deviceId;
  List<SearchSuggestion> get cachedSuggestions => List.unmodifiable(_cachedSuggestions);

  String _safeDocId(String input) {
    return input
        .replaceAll(RegExp(r'[/\\#?%*\[\]]'), '_')
        .trim()
        .toLowerCase();
  }

  FirebaseSyncService() {
    _init();
  }

  void _init() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _firestore = FirebaseFirestore.instance;
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('FirebaseSyncService: Firestore not initialized: $e');
    }
  }

  void refreshInitialization() {
    _init();
    notifyListeners();
  }

  // --- Bookmarks & Collections Cloud Synchronization ---

  Future<void> uploadBookmark(String uid, Bookmark bookmark) async {
    if (_firestore == null) _init();
    if (_firestore == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      await _firestore!
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .doc(bookmark.id)
          .set(bookmark.toMap(), SetOptions(merge: true));

      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error uploading bookmark: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> deleteBookmark(String uid, String bookmarkId) async {
    if (_firestore == null) _init();
    if (_firestore == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      await _firestore!
          .collection('users')
          .doc(uid)
          .collection('bookmarks')
          .doc(bookmarkId)
          .delete();

      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error deleting bookmark: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Stream<List<Bookmark>> streamBookmarks(String uid) {
    if (_firestore == null) _init();
    if (_firestore == null) return const Stream.empty();

    return _firestore!
        .collection('users')
        .doc(uid)
        .collection('bookmarks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      _lastSyncTime = DateTime.now();
      return snapshot.docs.map((doc) => Bookmark.fromMap(doc.data())).toList();
    });
  }

  // --- Multi-Device Open Tabs Mirroring ("Tabs From Other Devices") ---

  Future<void> syncOpenTabs(String uid, String deviceName, List<Map<String, String>> tabs) async {
    if (_firestore == null) _init();
    if (_firestore == null) return;

    try {
      await _firestore!
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(_deviceId)
          .set({
        'deviceId': _deviceId,
        'deviceName': deviceName,
        'lastActive': FieldValue.serverTimestamp(),
        'tabs': tabs,
      }, SetOptions(merge: true));

      _lastSyncTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error syncing device tabs: $e');
    }
  }

  Stream<List<RemoteDeviceTabs>> streamRemoteDevices(String uid) {
    if (_firestore == null) _init();
    if (_firestore == null) return const Stream.empty();

    return _firestore!
        .collection('users')
        .doc(uid)
        .collection('devices')
        .snapshots()
        .map((snapshot) {
      final list = <RemoteDeviceTabs>[];
      for (final doc in snapshot.docs) {
        if (doc.id == _deviceId) continue; // Exclude current device

        final data = doc.data();
        final rawTabs = data['tabs'] as List<dynamic>? ?? [];
        final tabs = rawTabs
            .map((t) => Map<String, String>.from(t as Map))
            .toList();

        final timestamp = data['lastActive'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();

        list.add(RemoteDeviceTabs(
          deviceId: doc.id,
          deviceName: data['deviceName'] as String? ?? 'Other Device',
          lastActive: date,
          tabs: tabs,
        ));
      }
      return list;
    });
  }

  // --- Backend Search Suggestions ---

  Stream<List<SearchSuggestion>> streamSearchSuggestions() {
    if (_firestore == null) _init();
    if (_firestore == null) return Stream.value(_cachedSuggestions);

    return _firestore!
        .collection('search_suggestions')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return SearchSuggestion.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) => b.popularity.compareTo(a.popularity));
      _cachedSuggestions = list;
      notifyListeners();
      return list;
    }).handleError((e) {
      debugPrint('FirebaseSyncService: Error streaming suggestions: $e');
      return _cachedSuggestions;
    });
  }

  Future<List<SearchSuggestion>> fetchSearchSuggestions() async {
    if (_firestore == null) _init();
    if (_firestore == null) return _cachedSuggestions;

    try {
      final snapshot = await _firestore!.collection('search_suggestions').get();
      final list = snapshot.docs.map((doc) {
        return SearchSuggestion.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) => b.popularity.compareTo(a.popularity));
      _cachedSuggestions = list;
      notifyListeners();
      return list;
    } catch (e) {
      debugPrint('FirebaseSyncService: Error fetching suggestions: $e');
      return _cachedSuggestions;
    }
  }

  // --- Search History Cloud Sync ---

  Future<void> saveSearchHistory({String? uid, required String query}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty || trimmed == 'prime://newtab') return;
    if (_firestore == null) _init();
    if (_firestore == null) return;

    final docId = _safeDocId(trimmed);
    final data = {
      'query': trimmed,
      'timestamp': FieldValue.serverTimestamp(),
      'deviceId': _deviceId,
      if (uid != null) 'uid': uid,
    };

    try {
      final batch = _firestore!.batch();
      if (uid != null && uid.isNotEmpty) {
        final userDoc = _firestore!
            .collection('users')
            .doc(uid)
            .collection('search_history')
            .doc(docId);
        batch.set(userDoc, data, SetOptions(merge: true));
      }

      final deviceDoc = _firestore!
          .collection('devices')
          .doc(_deviceId)
          .collection('search_history')
          .doc(docId);
      batch.set(deviceDoc, data, SetOptions(merge: true));

      await batch.commit();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error saving search history: $e');
    }
  }

  Future<void> deleteSearchHistory({String? uid, required String query}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (_firestore == null) _init();
    if (_firestore == null) return;

    final docId = _safeDocId(trimmed);
    try {
      final batch = _firestore!.batch();
      if (uid != null && uid.isNotEmpty) {
        final userDoc = _firestore!
            .collection('users')
            .doc(uid)
            .collection('search_history')
            .doc(docId);
        batch.delete(userDoc);
      }
      final deviceDoc = _firestore!
          .collection('devices')
          .doc(_deviceId)
          .collection('search_history')
          .doc(docId);
      batch.delete(deviceDoc);

      await batch.commit();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error deleting search history: $e');
    }
  }

  Future<void> clearSearchHistory({String? uid}) async {
    if (_firestore == null) _init();
    if (_firestore == null) return;

    try {
      if (uid != null && uid.isNotEmpty) {
        final userDocs = await _firestore!
            .collection('users')
            .doc(uid)
            .collection('search_history')
            .get();
        final batch = _firestore!.batch();
        for (final d in userDocs.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }

      final deviceDocs = await _firestore!
          .collection('devices')
          .doc(_deviceId)
          .collection('search_history')
          .get();
      final batch = _firestore!.batch();
      for (final d in deviceDocs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error clearing search history: $e');
    }
  }

  Stream<List<String>> streamSearchHistory({String? uid}) {
    if (_firestore == null) _init();
    if (_firestore == null) return const Stream.empty();

    final collection = (uid != null && uid.isNotEmpty)
        ? _firestore!.collection('users').doc(uid).collection('search_history')
        : _firestore!.collection('devices').doc(_deviceId).collection('search_history');

    return collection
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final tA = (a.data()['timestamp'] as Timestamp?)?.toDate();
        final tB = (b.data()['timestamp'] as Timestamp?)?.toDate();
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      return docs
          .map((d) => d.data()['query'] as String? ?? '')
          .where((q) => q.isNotEmpty)
          .toList();
    }).handleError((e) {
      debugPrint('FirebaseSyncService: Error streaming search history: $e');
      return <String>[];
    });
  }

  // --- Browsing History Cloud Sync ---

  Future<void> saveBrowsingHistory({String? uid, required String title, required String url}) async {
    if (url.isEmpty || url == 'prime://newtab' || url == 'about:blank') return;
    if (_firestore == null) _init();
    if (_firestore == null) return;

    final docId = _safeDocId(url);
    final data = {
      'title': title.isNotEmpty ? title : url,
      'url': url,
      'timestamp': FieldValue.serverTimestamp(),
      'deviceId': _deviceId,
      if (uid != null) 'uid': uid,
    };

    try {
      final batch = _firestore!.batch();
      if (uid != null && uid.isNotEmpty) {
        final userDoc = _firestore!
            .collection('users')
            .doc(uid)
            .collection('browsing_history')
            .doc(docId);
        batch.set(userDoc, data, SetOptions(merge: true));
      }

      final deviceDoc = _firestore!
          .collection('devices')
          .doc(_deviceId)
          .collection('browsing_history')
          .doc(docId);
      batch.set(deviceDoc, data, SetOptions(merge: true));

      await batch.commit();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error saving browsing history: $e');
    }
  }

  Future<void> deleteBrowsingHistory({String? uid, required String url}) async {
    if (url.isEmpty) return;
    if (_firestore == null) _init();
    if (_firestore == null) return;

    final docId = _safeDocId(url);
    try {
      final batch = _firestore!.batch();
      if (uid != null && uid.isNotEmpty) {
        final userDoc = _firestore!
            .collection('users')
            .doc(uid)
            .collection('browsing_history')
            .doc(docId);
        batch.delete(userDoc);
      }
      final deviceDoc = _firestore!
          .collection('devices')
          .doc(_deviceId)
          .collection('browsing_history')
          .doc(docId);
      batch.delete(deviceDoc);

      await batch.commit();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error deleting browsing history: $e');
    }
  }

  Future<void> clearBrowsingHistory({String? uid}) async {
    if (_firestore == null) _init();
    if (_firestore == null) return;

    try {
      if (uid != null && uid.isNotEmpty) {
        final userDocs = await _firestore!
            .collection('users')
            .doc(uid)
            .collection('browsing_history')
            .get();
        final batch = _firestore!.batch();
        for (final d in userDocs.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }

      final deviceDocs = await _firestore!
          .collection('devices')
          .doc(_deviceId)
          .collection('browsing_history')
          .get();
      final batch = _firestore!.batch();
      for (final d in deviceDocs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      _lastSyncTime = DateTime.now();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error clearing browsing history: $e');
    }
  }

  Stream<List<Map<String, String>>> streamBrowsingHistory({String? uid}) {
    if (_firestore == null) _init();
    if (_firestore == null) return const Stream.empty();

    final collection = (uid != null && uid.isNotEmpty)
        ? _firestore!.collection('users').doc(uid).collection('browsing_history')
        : _firestore!.collection('devices').doc(_deviceId).collection('browsing_history');

    return collection
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final tA = (a.data()['timestamp'] as Timestamp?)?.toDate();
        final tB = (b.data()['timestamp'] as Timestamp?)?.toDate();
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      return docs.map((d) {
        final data = d.data();
        final title = data['title'] as String? ?? '';
        final url = data['url'] as String? ?? '';
        final t = (data['timestamp'] as Timestamp?)?.toDate().toIso8601String() ?? '';
        return {
          'title': title,
          'url': url,
          'timestamp': t,
        };
      }).where((h) => h['url']!.isNotEmpty).toList();
    }).handleError((e) {
      debugPrint('FirebaseSyncService: Error streaming browsing history: $e');
      return <Map<String, String>>[];
    });
  }
}

