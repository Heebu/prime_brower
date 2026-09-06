import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'models/web_tab.dart';

class WebViewPage extends StatelessWidget {
  final WebTab tab;

  const WebViewPage({Key? key, required this.tab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: tab.controller),
        if (tab.isLoading && tab.progress < 100)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: tab.progress / 100.0,
              minHeight: 3,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
      ],
    );
  }
}