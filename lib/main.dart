import 'package:flutter/material.dart';
import 'brower_home_page.dart';

void main() {
  runApp(BrowserApp());
}

class BrowserApp extends StatelessWidget {
  const BrowserApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prime Browser',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const BrowserHomePage(),
    );
  }
}






