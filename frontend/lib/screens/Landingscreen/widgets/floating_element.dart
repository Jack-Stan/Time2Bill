import 'package:flutter/material.dart';

class FloatingElement extends StatelessWidget {
  final AnimationController controller;
  final double size;
  final Color color;
  final BoxShape shape;
  final Offset offset;
  final double delay;

  const FloatingElement({
    Key? key,
    required this.controller,
    required this.size,
    required this.color,
    required this.shape,
    required this.offset,
    this.delay = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final sinValue = 
            (controller.value + delay) % 1.0 < 0.5
                ? 2 * ((controller.value + delay) % 0.5)
                : 2 * (0.5 - ((controller.value + delay) % 0.5));
        
        return Transform.translate(
          offset: Offset(offset.dx * sinValue, offset.dy * sinValue),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Color.fromRGBO(
                color.r.toInt(),
                color.g.toInt(),
                color.b.toInt(),
                color.a,
              ),
              shape: shape,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(
                    color.r.toInt(),
                    color.g.toInt(),
                    color.b.toInt(),
                    0.6,
                  ),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
