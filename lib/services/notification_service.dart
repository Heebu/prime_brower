import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotificationType {
  news,
  advert,
  download,
  backgroundPage,
}

class NotificationActionPayload {
  final NotificationType type;
  final String title;
  final String body;
  final String? url;
  final String? tabId;
  final String? filePath;

  const NotificationActionPayload({
    required this.type,
    required this.title,
    required this.body,
    this.url,
    this.tabId,
    this.filePath,
  });
}

class NotificationService with ChangeNotifier {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal() {
    _init();
  }

  FlutterLocalNotificationsPlugin? _localNotifications;
  FirebaseMessaging? _messaging;

  bool _isInitialized = false;
  bool _newsEnabled = true;
  bool _advertsEnabled = true;
  bool _downloadsEnabled = true;
  bool _backgroundPageLoadsEnabled = true;

  bool get isInitialized => _isInitialized;
  bool get newsEnabled => _newsEnabled;
  bool get advertsEnabled => _advertsEnabled;
  bool get downloadsEnabled => _downloadsEnabled;
  bool get backgroundPageLoadsEnabled => _backgroundPageLoadsEnabled;

  final StreamController<NotificationActionPayload> _actionController =
      StreamController<NotificationActionPayload>.broadcast();
  Stream<NotificationActionPayload> get onNotificationAction => _actionController.stream;

  // In-memory record of notifications for verification and in-app logs
  final List<NotificationActionPayload> _recentNotifications = [];
  List<NotificationActionPayload> get recentNotifications =>
      List.unmodifiable(_recentNotifications);

  static const String newsChannelId = 'news_channel';
  static const String advertsChannelId = 'adverts_channel';
  static const String downloadsChannelId = 'downloads_channel';
  static const String pageLoadChannelId = 'page_load_channel';

  void _init() {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      _localNotifications
          ?.initialize(
            settings: initSettings,
            onDidReceiveNotificationResponse: (NotificationResponse response) {
              final payload = response.payload;
              if (payload != null) {
                _handleNotificationPayload(payload);
              }
            },
          )
          .catchError((dynamic err) {
            debugPrint('Local notifications init notice: $err');
            return false;
          });

      _initFCM();
      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService init notice: $e');
    }
  }

  void _initFCM() {
    try {
      if (Firebase.apps.isNotEmpty) {
        _messaging = FirebaseMessaging.instance;

        // Request permissions for user notifications
        _messaging?.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        // Subscribe to standard browser alert topics
        _messaging?.subscribeToTopic('news_updates');
        _messaging?.subscribeToTopic('promotions_adverts');

        // Listen to foreground FCM messages and bridge to local heads-up notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          final data = message.data;

          final title = notification?.title ?? data['title'] ?? 'Prime Browser Alert';
          final body = notification?.body ?? data['body'] ?? '';
          final typeStr = data['type'] as String? ?? 'news';
          final url = data['url'] as String?;

          if (typeStr == 'advert') {
            showAdvertNotification(title: title, body: body, targetUrl: url);
          } else {
            showNewsNotification(title: title, body: body, url: url);
          }
        });

        // App opened from background notification
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final data = message.data;
          final url = data['url'] as String?;
          final typeStr = data['type'] as String? ?? 'news';
          _actionController.add(
            NotificationActionPayload(
              type: typeStr == 'advert' ? NotificationType.advert : NotificationType.news,
              title: message.notification?.title ?? 'Notification',
              body: message.notification?.body ?? '',
              url: url,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('NotificationService FCM notice: $e');
    }
  }

  void _handleNotificationPayload(String payload) {
    try {
      final parts = payload.split('|');
      if (parts.isEmpty) return;
      final typeStr = parts[0];
      final url = parts.length > 1 ? parts[1] : null;
      final tabId = parts.length > 2 ? parts[2] : null;

      NotificationType type;
      switch (typeStr) {
        case 'advert':
          type = NotificationType.advert;
          break;
        case 'download':
          type = NotificationType.download;
          break;
        case 'backgroundPage':
          type = NotificationType.backgroundPage;
          break;
        default:
          type = NotificationType.news;
      }

      final action = NotificationActionPayload(
        type: type,
        title: 'Action Triggered',
        body: '',
        url: url,
        tabId: tabId,
      );

      _actionController.add(action);
    } catch (e) {
      debugPrint('Error handling notification payload: $e');
    }
  }

  // --- Display Methods ---

  Future<void> showNewsNotification({
    required String title,
    required String body,
    String? url,
  }) async {
    if (!_newsEnabled) return;

    final record = NotificationActionPayload(
      type: NotificationType.news,
      title: title,
      body: body,
      url: url,
    );
    _recordNotification(record);

    try {
      const androidDetails = AndroidNotificationDetails(
        newsChannelId,
        'News & Breaking Updates',
        channelDescription: 'Headlines, breaking stories and article feeds',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _localNotifications?.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'news|${url ?? ''}',
      ).catchError((dynamic err) {
        debugPrint('showNewsNotification notice: $err');
      });
    } catch (e) {
      debugPrint('showNewsNotification notice: $e');
    }
  }

  Future<void> showAdvertNotification({
    required String title,
    required String body,
    String? targetUrl,
  }) async {
    if (!_advertsEnabled) return;

    final record = NotificationActionPayload(
      type: NotificationType.advert,
      title: title,
      body: body,
      url: targetUrl,
    );
    _recordNotification(record);

    try {
      const androidDetails = AndroidNotificationDetails(
        advertsChannelId,
        'Promotions & Offers',
        channelDescription: 'Featured deals, discounts and sponsor highlights',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _localNotifications?.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'advert|${targetUrl ?? ''}',
      ).catchError((dynamic err) {
        debugPrint('showAdvertNotification notice: $err');
      });
    } catch (e) {
      debugPrint('showAdvertNotification notice: $e');
    }
  }

  Future<void> showDownloadCompleteNotification({
    required String fileName,
    required String filePath,
    int? bytes,
  }) async {
    if (!_downloadsEnabled) return;

    final sizeStr = bytes != null && bytes > 0
        ? ' (${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB)'
        : '';
    final title = 'Download Complete';
    final body = '$fileName$sizeStr is ready to open.';

    final record = NotificationActionPayload(
      type: NotificationType.download,
      title: title,
      body: body,
      filePath: filePath,
    );
    _recordNotification(record);

    try {
      const androidDetails = AndroidNotificationDetails(
        downloadsChannelId,
        'File Downloads',
        channelDescription: 'Notifications for downloaded documents, media and archives',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _localNotifications?.show(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        title: title,
        body: body,
        notificationDetails: details,
        payload: 'download|$filePath',
      ).catchError((dynamic err) {
        debugPrint('showDownloadCompleteNotification notice: $err');
      });
    } catch (e) {
      debugPrint('showDownloadCompleteNotification notice: $e');
    }
  }

  Future<void> showBackgroundPageLoadedNotification({
    required String tabId,
    required String title,
    required String url,
  }) async {
    if (!_backgroundPageLoadsEnabled) return;

    final displayTitle = title.isNotEmpty && title != 'New Tab' ? title : 'Page Ready';
    final body = 'Finished loading "$url". Tap to return to Prime Browser.';

    final record = NotificationActionPayload(
      type: NotificationType.backgroundPage,
      title: displayTitle,
      body: body,
      url: url,
      tabId: tabId,
    );
    _recordNotification(record);

    try {
      const androidDetails = AndroidNotificationDetails(
        pageLoadChannelId,
        'Background Web Pages',
        channelDescription: 'Alerts when background or minimized tabs finish loading',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _localNotifications?.show(
        id: (tabId.hashCode + DateTime.now().millisecond).abs() % 100000,
        title: displayTitle,
        body: body,
        notificationDetails: details,
        payload: 'backgroundPage|$url|$tabId',
      ).catchError((dynamic err) {
        debugPrint('showBackgroundPageLoadedNotification notice: $err');
      });
    } catch (e) {
      debugPrint('showBackgroundPageLoadedNotification notice: $e');
    }
  }

  void _recordNotification(NotificationActionPayload record) {
    _recentNotifications.insert(0, record);
    if (_recentNotifications.length > 30) {
      _recentNotifications.removeLast();
    }
    notifyListeners();
  }

  // --- Preference Toggles ---

  void toggleNewsNotifications() {
    _newsEnabled = !_newsEnabled;
    if (_messaging != null) {
      if (_newsEnabled) {
        _messaging?.subscribeToTopic('news_updates');
      } else {
        _messaging?.unsubscribeFromTopic('news_updates');
      }
    }
    notifyListeners();
  }

  void toggleAdvertNotifications() {
    _advertsEnabled = !_advertsEnabled;
    if (_messaging != null) {
      if (_advertsEnabled) {
        _messaging?.subscribeToTopic('promotions_adverts');
      } else {
        _messaging?.unsubscribeFromTopic('promotions_adverts');
      }
    }
    notifyListeners();
  }

  void toggleDownloadNotifications() {
    _downloadsEnabled = !_downloadsEnabled;
    notifyListeners();
  }

  void toggleBackgroundPageLoads() {
    _backgroundPageLoadsEnabled = !_backgroundPageLoadsEnabled;
    notifyListeners();
  }

  @override
  void dispose() {
    _actionController.close();
    super.dispose();
  }
}
