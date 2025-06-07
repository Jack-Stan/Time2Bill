import 'package:flutter/material.dart';

/// This file contains utility functions for the Time2Bill application
/// to help with color operations and other common tasks.

/// Convert a color with opacity to RGBA format to avoid using deprecated methods
Color colorWithOpacity(Color color, double opacity) {
  return Color.fromRGBO(
    (color.r * 255.0).round() & 0xff,
    (color.g * 255.0).round() & 0xff, 
    (color.b * 255.0).round() & 0xff,
    opacity
  );
}
