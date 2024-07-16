// animated_loading_text.dart
import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedLoadingText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const AnimatedLoadingText({
    Key? key,
    required this.text,
    this.style,
  }) : super(key: key);

  @override
  _AnimatedLoadingTextState createState() => _AnimatedLoadingTextState();
}

class _AnimatedLoadingTextState extends State<AnimatedLoadingText> {
  int _dotCount = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _dotCount = (_dotCount + 1) % 4;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.text,
          style: widget.style,
        ),
        Text(
          '.' * _dotCount,
          style: widget.style,
        ),
      ],
    );
  }
}
