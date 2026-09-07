import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bookmark.dart';

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

  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get deviceId => _deviceId;

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
}
