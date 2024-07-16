import 'dart:math';

import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final String text;

  const LoadingScreen({
    super.key,
    required this.text,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final List<String> placeholderImages = [
    'assets/images/emoji/emoji1.png',
    'assets/images/emoji/emoji2.png',
    'assets/images/emoji/emoji3.png',
    'assets/images/emoji/emoji4.png',
    'assets/images/emoji/emoji5.png',
    'assets/images/emoji/emoji6.png',
    'assets/images/emoji/emoji7.png',
    'assets/images/emoji/emoji8.png',
    'assets/images/emoji/emoji9.png',
    'assets/images/emoji/emoji10.png',
  ];

  @override
  Widget build(BuildContext context) {
    final randomImage =
        placeholderImages[Random().nextInt(placeholderImages.length)];
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              randomImage,
              width: 100,
            ),
            const SizedBox(height: 20),
            Text(
              widget.text,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
