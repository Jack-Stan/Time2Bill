import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.2,
  );

  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
    height: 1.3,
  );

  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
    height: 1.5,
  );

  static const bodyLight = TextStyle(
    fontSize: 16,
    color: AppColors.textLight,
    height: 1.5,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.surface,
  );
}
