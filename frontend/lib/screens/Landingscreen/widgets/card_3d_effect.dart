import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';

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
  Timer? _debounceTimer;
  bool _isHovering = false;
  PointerEvent? _lastEvent;

  @override
  void initState() {
    super.initState();
    position = Offset.zero;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleHoverEvent(PointerEvent details) {
    // Skip all hover handling on web to avoid transform issues
    if (kIsWeb) return;
    
    _lastEvent = details;
    
    if (!_isHovering) {
      _isHovering = true;
    }
    
    // Debounce hover events
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 25), () {
      if (_lastEvent != null && mounted) {
        _updateRotation(_lastEvent!);
      }
    });
  }

  void _updateRotation(PointerEvent details) {
    if (size == null || !mounted || kIsWeb) return;

    try {
      final centerX = size!.width / 2;
      final centerY = size!.height / 2;
      
      // Transform absolute position to relative position
      final relativeX = (details.localPosition.dx - centerX) / centerX;
      final relativeY = (details.localPosition.dy - centerY) / centerY;

      // Limit rotation for smoother effect
      final limitedX = math.min(0.5, math.max(-0.5, relativeX));
      final limitedY = math.min(0.5, math.max(-0.5, relativeY));
      
      // Use smoother values
      final newRotationX = -limitedY * widget.depth;
      final newRotationY = limitedX * widget.depth;
      
      if (mounted) {
        setState(() {
          rotationX = newRotationX;
          rotationY = newRotationY;
        });
      }
    } catch (e) {
      // Ignore any errors in rotation calculation
      print('Ignored rotation error: $e');
    }
  }

  void _resetRotation() {
    _isHovering = false;
    _debounceTimer?.cancel();
    
    if (mounted && !kIsWeb) {
      setState(() {
        rotationX = 0;
        rotationY = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // On web, just return the child directly to avoid transform issues
    if (kIsWeb || widget.depth <= 0.001) {
      return widget.child;
    }
    
    // Normal implementation for non-web platforms
    return MouseRegion(
      onEnter: (event) {},
      onExit: (event) => _resetRotation(),
      onHover: _handleHoverEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          size = Size(constraints.maxWidth, constraints.maxHeight);
          return Transform(
            alignment: FractionalOffset.center,
            // Use a safer transform matrix to avoid NaN values
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
