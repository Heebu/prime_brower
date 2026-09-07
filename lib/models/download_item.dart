enum DownloadStatus {
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadItem {
  final String id;
  final String url;
  final String fileName;
  final String filePath;
  int totalBytes;
  int downloadedBytes;
  DownloadStatus status;
  final DateTime createdAt;
  String? errorMessage;

  DownloadItem({
    required this.id,
    required this.url,
    required this.fileName,
    required this.filePath,
    this.totalBytes = -1,
    this.downloadedBytes = 0,
    this.status = DownloadStatus.downloading,
    required this.createdAt,
    this.errorMessage,
  });

  double get progress {
    if (totalBytes <= 0) return 0.0;
    final p = downloadedBytes / totalBytes;
    return p.clamp(0.0, 1.0);
  }

  String get fileExtension {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1).toLowerCase();
    }
    return '';
  }

  String get fileCategory {
    final ext = fileExtension;
    switch (ext) {
      case 'pdf':
      case 'doc':
      case 'docx':
      case 'txt':
      case 'xls':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'csv':
        return 'Documents';
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'Media';
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return 'Archives';
      default:
        return 'Other';
    }
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double count = bytes.toDouble();
    while (count >= 1024 && i < suffixes.length - 1) {
      count /= 1024;
      i++;
    }
    return '${count.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
  }

  String get formattedTotalSize => totalBytes > 0 ? formatBytes(totalBytes) : 'Unknown size';
  String get formattedDownloadedSize => formatBytes(downloadedBytes);
}
