import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedGradientBox extends StatelessWidget {
  final AnimationController controller;

  const AnimatedGradientBox({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFEDF2FD),
            Color(0xFFF6F9FF),
          ],
          stops: [
            0.0,
            0.5 + 0.2 * math.sin(controller.value * 2 * math.pi),
            1.0,
          ],
        );

        return Container(
          decoration: BoxDecoration(
            gradient: gradient,
          ),
        );
      },
    );
  }
}
