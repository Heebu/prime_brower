import 'package:flutter/material.dart';
import '../../models/download_item.dart';
import '../../services/download_service.dart';
import '../../core/design_system/animated_pressable.dart';

class DownloadsScreen extends StatefulWidget {
  final DownloadService downloadService;

  const DownloadsScreen({Key? key, required this.downloadService}) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final List<String> _categories = ['All', 'Documents', 'Media', 'Archives'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DownloadItem> _filterDownloads(List<DownloadItem> items, String category) {
    if (category == 'All') return items;
    return items.where((item) => item.fileCategory == category).toList();
  }

  IconData _getFileIcon(DownloadItem item) {
    switch (item.fileCategory) {
      case 'Documents':
        return Icons.description_rounded;
      case 'Media':
        return item.fileExtension == 'mp3' || item.fileExtension == 'wav'
            ? Icons.audio_file_rounded
            : Icons.video_file_rounded;
      case 'Archives':
        return Icons.folder_zip_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getFileColor(DownloadItem item) {
    switch (item.fileCategory) {
      case 'Documents':
        return Colors.blue;
      case 'Media':
        return Colors.purple;
      case 'Archives':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.downloadService,
      builder: (context, _) {
        final allDownloads = widget.downloadService.downloads;
        final activeDownloads = widget.downloadService.activeDownloads;

        return Scaffold(
          appBar: AppBar(
            elevation: 0.5,
            title: const Text('Downloads', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              if (allDownloads.any((d) => d.status == DownloadStatus.completed))
                IconButton(
                  icon: const Icon(Icons.cleaning_services_rounded, size: 20),
                  tooltip: 'Clear completed',
                  onPressed: () {
                    widget.downloadService.clearCompleted();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cleared completed downloads')),
                    );
                  },
                ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorColor: Colors.blueAccent,
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              tabs: _categories.map((c) => Tab(text: c)).toList(),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              final filtered = _filterDownloads(allDownloads, category);

              if (filtered.isEmpty && activeDownloads.isEmpty) {
                return _buildEmptyState(category);
              }

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                children: [
                  // Active Downloads Section (shown on "All" or if any active)
                  if (activeDownloads.isNotEmpty && (category == 'All' || _filterDownloads(activeDownloads, category).isNotEmpty)) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        'ACTIVE DOWNLOADS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                    ..._filterDownloads(activeDownloads, category).map((item) => _buildActiveDownloadCard(item)),
                    const SizedBox(height: 16),
                  ],

                  // Completed / Past Downloads
                  if (filtered.any((d) => d.status != DownloadStatus.downloading)) ...[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(
                        'DOWNLOADED FILES',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ...filtered
                        .where((d) => d.status != DownloadStatus.downloading)
                        .map((item) => _buildCompletedDownloadTile(item)),
                  ],
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildActiveDownloadCard(DownloadItem item) {
    final progressPercent = (item.progress * 100).toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.downloading_rounded, color: Colors.blueAccent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.formattedDownloadedSize} of ${item.formattedTotalSize} • $progressPercent%',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                  tooltip: 'Cancel download',
                  onPressed: () => widget.downloadService.cancelDownload(item.id),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.totalBytes > 0 ? item.progress : null,
                minHeight: 6,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedDownloadTile(DownloadItem item) {
    final isSuccess = item.status == DownloadStatus.completed;
    final iconColor = isSuccess ? _getFileColor(item) : Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.8,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSuccess ? _getFileIcon(item) : Icons.error_outline_rounded,
            color: iconColor,
            size: 24,
          ),
        ),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                item.formattedTotalSize,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${_formatDate(item.createdAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (!isSuccess) ...[
                const SizedBox(width: 6),
                Text(
                  '• ${item.status.name}',
                  style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSuccess) ...[
              IconButton(
                icon: const Icon(Icons.share_outlined, size: 20),
                tooltip: 'Share',
                onPressed: () => widget.downloadService.shareFile(item),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 20, color: Colors.blueAccent),
                tooltip: 'Open',
                onPressed: () => widget.downloadService.openFile(item),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.black45),
              tooltip: 'Delete',
              onPressed: () => widget.downloadService.deleteDownload(item.id),
            ),
          ],
        ),
        onTap: isSuccess ? () => widget.downloadService.openFile(item) : null,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inMinutes < 60) {
      final mins = now.difference(dt).inMinutes;
      return mins <= 1 ? 'Just now' : '$mins mins ago';
    }
    if (now.difference(dt).inHours < 24) {
      return '${now.difference(dt).inHours} hrs ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.download_done_rounded,
              size: 56,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            category == 'All' ? 'No downloads yet' : 'No $category found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Files and media you download in Prime Browser will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
