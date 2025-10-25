// lib/app/components/animated_number.dart
import 'package:flutter/material.dart';

class AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedNumber({
    Key? key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: value.toDouble(),
      ),
      duration: duration,
      builder: (context, animatedValue, child) {
        return Text(
          animatedValue.toInt().toString(),
          style: style,
        );
      },
    );
  }
}