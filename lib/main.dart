import 'package:flutter/material.dart';
import 'image_selection_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('オリジナル神経衰弱'),
        ),
        body: const ImageSelectionScreen(),
      ),
    );
  }
}