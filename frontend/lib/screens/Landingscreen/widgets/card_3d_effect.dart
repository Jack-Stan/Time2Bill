import 'package:flutter/material.dart';
import 'dart:math' as math;

class Card3DEffect extends StatefulWidget {
  final Widget child;
  final double depth;

  const Card3DEffect({
    Key? key, 
    required this.child, 
    this.depth = 0.01,
  }) : super(key: key);

  @override
  Card3DEffectState createState() => Card3DEffectState();
}

class Card3DEffectState extends State<Card3DEffect> with TickerProviderStateMixin {
  double rotationX = 0;
  double rotationY = 0;
  late Offset position;
  Size? size;

  @override
  void initState() {
    super.initState();
    position = Offset.zero;
  }

  void _updateRotation(PointerEvent details) {
    if (size == null) return;

    final centerX = size!.width / 2;
    final centerY = size!.height / 2;
    
    // Transform absolute position to relative position from center (-1 to 1)
    final relativeX = (details.localPosition.dx - centerX) / centerX;
    final relativeY = (details.localPosition.dy - centerY) / centerY;

    setState(() {
      rotationX = -relativeY * widget.depth;
      rotationY = relativeX * widget.depth;
    });
  }

  void _resetRotation() {
    setState(() {
      rotationX = 0;
      rotationY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) {},
      onExit: (event) => _resetRotation(),
      onHover: _updateRotation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          size = Size(constraints.maxWidth, constraints.maxHeight);
          return Transform(
            alignment: FractionalOffset.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateX(rotationX)
              ..rotateY(rotationY),
            child: widget.child,
          );
        },
      ),
    );
  }
}
