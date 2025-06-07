import 'package:flutter/material.dart';

/// Helper function to replace withOpacity with Color.fromRGBO
Color fixOpacity(Color color, double opacity) {
  return Color.fromRGBO(
    (color.r * 255.0).round() & 0xff,
    (color.g * 255.0).round() & 0xff,
    (color.b * 255.0).round() & 0xff,
    opacity
  );
}
