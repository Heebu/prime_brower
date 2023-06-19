import 'package:flutter/material.dart';
import 'brower_home_page.dart';

void main() {
  runApp(BrowserApp());
}

class BrowserApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Browser App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BrowserHomePage(),
    );
  }
}






