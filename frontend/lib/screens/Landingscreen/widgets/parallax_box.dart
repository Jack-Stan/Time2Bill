import 'package:flutter/material.dart';

class ParallaxBox extends StatefulWidget {
  final Widget child;
  final double parallaxFactor;
  
  const ParallaxBox({
    Key? key, 
    required this.child, 
    this.parallaxFactor = 20,
  }) : super(key: key);

  @override
  State<ParallaxBox> createState() => _ParallaxBoxState();
}

class _ParallaxBoxState extends State<ParallaxBox> {
  final GlobalKey _backgroundImageKey = GlobalKey();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      key: _backgroundImageKey,
      child: widget.child,
    );
  }
}
