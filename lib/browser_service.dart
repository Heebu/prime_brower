import 'package:prime_brower/web_view_page.dart';
import 'package:flutter/material.dart';

class WebTab {
  final GlobalKey<WebViewPageState> key = GlobalKey<WebViewPageState>();
  final String url;

  WebTab({required this.url});
}