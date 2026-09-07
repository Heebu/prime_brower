import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/download_item.dart';
import 'notification_service.dart';

class DownloadService with ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  final List<DownloadItem> _downloads = [];
  final Map<String, StreamSubscription<List<int>>> _activeSubscriptions = {};
  final Map<String, IOSink> _activeFileSinks = {};

  List<DownloadItem> get downloads => List.unmodifiable(_downloads);
  List<DownloadItem> get activeDownloads =>
      _downloads.where((d) => d.status == DownloadStatus.downloading).toList();
  int get activeDownloadsCount => activeDownloads.length;

  Future<String> _getDownloadDirectory() async {
    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }
    final downloadDir = Directory('${dir.path}/Downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      if (lastSegment.isNotEmpty && lastSegment.contains('.')) {
        return _sanitizeFileName(lastSegment);
      }
    } catch (_) {}
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<DownloadItem> startDownload(String url, {String? customFileName}) async {
    final fileName = customFileName != null && customFileName.isNotEmpty
        ? _sanitizeFileName(customFileName)
        : _extractFileNameFromUrl(url);

    final downloadDir = await _getDownloadDirectory();
    final filePath = '$downloadDir/$fileName';

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = DownloadItem(
      id: id,
      url: url,
      fileName: fileName,
      filePath: filePath,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
    );

    _downloads.insert(0, item);
    notifyListeners();

    _executeStreamingDownload(item);
    return item;
  }

  Future<void> _executeStreamingDownload(DownloadItem item) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final request = await client.getUrl(Uri.parse(item.url));
      final response = await request.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        item.totalBytes = response.contentLength;
        final file = File(item.filePath);
        final sink = file.openWrite();
        _activeFileSinks[item.id] = sink;

        int received = 0;
        DateTime lastNotify = DateTime.now();

        final subscription = response.listen(
          (List<int> chunk) {
            received += chunk.length;
            sink.add(chunk);
            item.downloadedBytes = received;

            // Throttle UI notification to every 100ms for smooth 60fps animations
            final now = DateTime.now();
            if (now.difference(lastNotify).inMilliseconds > 100 ||
                (item.totalBytes > 0 && received >= item.totalBytes)) {
              lastNotify = now;
              notifyListeners();
            }
          },
          onDone: () async {
            await sink.flush();
            await sink.close();
            _activeFileSinks.remove(item.id);
            _activeSubscriptions.remove(item.id);

            item.status = DownloadStatus.completed;
            item.downloadedBytes = received;
            if (item.totalBytes <= 0) {
              item.totalBytes = received;
            }
            notifyListeners();
            client.close();

            NotificationService.instance.showDownloadCompleteNotification(
              fileName: item.fileName,
              filePath: item.filePath,
              bytes: item.downloadedBytes,
            );
          },
          onError: (dynamic error) async {
            await sink.close();
            _activeFileSinks.remove(item.id);
            _activeSubscriptions.remove(item.id);

            item.status = DownloadStatus.failed;
            item.errorMessage = error.toString();
            notifyListeners();
            client.close();
          },
          cancelOnError: true,
        );

        _activeSubscriptions[item.id] = subscription;
      } else {
        item.status = DownloadStatus.failed;
        item.errorMessage = 'HTTP status ${response.statusCode}';
        notifyListeners();
        client.close();
      }
    } catch (e) {
      item.status = DownloadStatus.failed;
      item.errorMessage = e.toString();
      notifyListeners();
      client.close();
    }
  }

  Future<void> cancelDownload(String id) async {
    final sub = _activeSubscriptions.remove(id);
    if (sub != null) {
      await sub.cancel();
    }
    final sink = _activeFileSinks.remove(id);
    if (sink != null) {
      try {
        await sink.close();
      } catch (_) {}
    }

    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      final item = _downloads[index];
      item.status = DownloadStatus.cancelled;
      // Delete partially downloaded file
      final file = File(item.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  Future<void> deleteDownload(String id) async {
    await cancelDownload(id);
    final index = _downloads.indexWhere((d) => d.id == id);
    if (index != -1) {
      final item = _downloads.removeAt(index);
      final file = File(item.filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      notifyListeners();
    }
  }

  void clearCompleted() {
    _downloads.removeWhere((d) => d.status == DownloadStatus.completed || d.status == DownloadStatus.cancelled);
    notifyListeners();
  }

  Future<void> openFile(DownloadItem item) async {
    final file = File(item.filePath);
    if (!await file.exists()) return;

    final uri = Uri.file(item.filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> shareFile(DownloadItem item) async {
    final file = File(item.filePath);
    if (!await file.exists()) return;

    await Share.shareXFiles(
      [XFile(item.filePath, name: item.fileName)],
      text: 'Sharing ${item.fileName} from Prime Browser',
    );
  }
}
