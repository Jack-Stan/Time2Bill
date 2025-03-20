import 'package:flutter/material.dart';
import '../../widgets/navbar.dart';
import '../../theme/colors.dart';  // Fix: Correct import path
import 'landing_home.dart';
import 'landing_features.dart';
import 'landing_pricing.dart';
import 'landing_contact.dart';
import 'landing_how_it_works.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _selectedIndex = 0;

  final _pages = const [
    LandingHome(),
    LandingFeatures(),
    LandingPricing(),
    LandingContact(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,  // Add background color
      body: Column(
        children: [
          Navbar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
