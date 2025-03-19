import 'package:flutter/material.dart';
import 'features/home/presentation/landing_page.dart';

void main() {
  runApp(const Time2BillApp());
}

class Time2BillApp extends StatelessWidget {
  const Time2BillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time2Bill',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0175C2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}
