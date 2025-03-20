import 'package:flutter/material.dart';
import 'features/dashboard/presentation/pages/landing_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const Time2BillApp());
}

class Time2BillApp extends StatelessWidget {
  const Time2BillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time2Bill',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
