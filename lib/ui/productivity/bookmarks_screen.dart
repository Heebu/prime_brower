import 'package:flutter/material.dart';
import '../../models/bookmark.dart';
import '../../services/browser_manager.dart';

class BookmarksScreen extends StatelessWidget {
  final BrowserManager browserManager;

  const BookmarksScreen({Key? key, required this.browserManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: browserManager,
      builder: (context, _) {
        final bookmarks = browserManager.bookmarks;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Bookmarks & Collections'),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.bookmark_outline), text: 'Bookmarks'),
                  Tab(icon: Icon(Icons.collections_bookmark_outlined), text: 'Collections'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // Bookmarks tab
                _buildBookmarksList(context, bookmarks.where((b) => !b.isCollection).toList()),
                // Collections tab
                _buildCollectionsList(context, bookmarks.where((b) => b.isCollection).toList()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarksList(BuildContext context, List<Bookmark> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No bookmarks saved yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = list[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.public, color: Color(0xFF10B981), size: 20),
          ),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(item.url, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
            onPressed: () {
              browserManager.removeBookmark(item.id);
            },
          ),
          onTap: () {
            browserManager.navigateCurrentTab(item.url);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildCollectionsList(BuildContext context, List<Bookmark> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections_bookmark_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('No collections yet', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text(
              'Save research, links and articles into themed boards',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.folder, color: Color(0xFF10B981)),
            title: Text(item.title),
            subtitle: Text(item.url),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => browserManager.removeBookmark(item.id),
            ),
            onTap: () {
              browserManager.navigateCurrentTab(item.url);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}
