import 'package:flutter/material.dart';
import '../Landingscreen/sections/navbar.dart';
import 'about_page_model.dart';

class AboutPageWidget extends StatefulWidget {
  const AboutPageWidget({super.key});

  static String routeName = 'AboutPage';
  static String routePath = '/about';

  @override
  State<AboutPageWidget> createState() => _AboutPageWidgetState();
}

class _AboutPageWidgetState extends State<AboutPageWidget> {
  late AboutPageModel _model;
  final Color primaryColor = const Color(0xFF0B5394);
  final Color lightBackgroundColor = const Color(0xFFF1F4F8);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AboutPageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackgroundColor,
      body: SingleChildScrollView(
        controller: _model.scrollController,
        child: Column(
          children: [
            NavBar(
              primaryColor: primaryColor,
              onGetStarted: () {},
            ),
            _buildHeroSection(),
            _buildOurStorySection(),
            _buildMissionSection(),
            _buildWhyChooseSection(),
            _buildContactSection(),
            _buildFooterSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'About Time2Bill - Work Smarter, Less Hassle',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'We believe time tracking and invoicing should be simple. No hassle, '
            'no complex software – just a user-friendly solution for entrepreneurs.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOurStorySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      color: lightBackgroundColor,
      child: Column(
        children: [
          Text(
            'Our Story',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'As freelancers and entrepreneurs, we understand the challenge: '
            'you want to focus on your work, but administration takes up too much time. '
            'Time tracking and invoicing are essential, but many existing solutions '
            'are too complex, too expensive, or simply not user-friendly.\n\n'
            'That\'s why we developed Time2Bill – a free and intuitive tool that lets '
            'you easily track your hours and send invoices, without subscription fees '
            'or hidden costs.',
            style: TextStyle(fontSize: 18, color: Colors.black54, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Our Mission & Values',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Our mission is simple: we want to help entrepreneurs spend less time '
            'on administration and have more time for what really matters.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildValueCard('Simplicity', 'No unnecessary complexity', Icons.lightbulb_outline),
              _buildValueCard('Free & Accessible', 'No subscription fees', Icons.lock_open),
              _buildValueCard('Reliability', 'Your data is safe', Icons.security),
              _buildValueCard('Efficiency', 'More focus on business', Icons.speed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard(String title, String description, IconData icon) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: lightBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: primaryColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      color: lightBackgroundColor,
      child: Column(
        children: [
          Text(
            'Why Choose Time2Bill?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Time2Bill is designed with you in mind. We offer a simple, intuitive, and free solution '
            'for time tracking and invoicing. Our platform is built to help you focus on what matters most – your work.',
            style: TextStyle(fontSize: 18, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      color: Colors.white,
      child: Column(
        children: [
          Text(
            'Get in Touch',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Have questions? We\'d love to hear from you.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: primaryColor,
      child: Column(
        children: [
          Text(
            '© 2023 Time2Bill. All rights reserved.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
