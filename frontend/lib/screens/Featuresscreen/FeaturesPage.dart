import 'package:flutter/material.dart';
import '../Landingscreen/sections/navbar.dart';
import 'features_page_model.dart';

class FeaturesPageWidget extends StatefulWidget {
  const FeaturesPageWidget({super.key});

  static String routeName = 'FeaturesPage';
  static String routePath = '/features';

  @override
  State<FeaturesPageWidget> createState() => _FeaturesPageWidgetState();
}

class _FeaturesPageWidgetState extends State<FeaturesPageWidget> {
  late FeaturesPageModel _model;
  final Color primaryColor = const Color(0xFF0B5394);
  final Color secondaryColor = const Color(0xFF4285F4);
  final Color lightBackgroundColor = const Color(0xFFF1F4F8);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FeaturesPageModel());
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
        controller: _model.scrollController,  // Add scroll controller
        child: Column(
          children: [
            NavBar(
              primaryColor: primaryColor,
              onGetStarted: () {
                // Handle get started action
              },
            ),
            _buildHeroSection(),
            _buildFeaturesGrid(),
            _buildWhyChooseSection(),
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
            'Time Tracking & Invoicing - All-in-One Solution',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'Whether you work by the hour or send fixed monthly invoices, '
            'Time2Bill helps you invoice faster and smarter.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 20,
              ),
            ),
            child: const Text(
              'Get Started - Register Free',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(  // Remove crossAlignment from here
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildFeatureCard(
                title: 'Flexible Invoicing',
                description: 'Send invoices based on tracked hours or choose fixed monthly invoices.',
                icon: Icons.receipt_long,
              ),
              _buildFeatureCard(
                title: 'Simple Time Tracking',
                description: 'Track working hours effortlessly with our user-friendly interface.',
                icon: Icons.timer,
              ),
              _buildFeatureCard(
                title: 'Automated Invoicing',
                description: 'Generate professional invoices automatically based on tracked time.',
                icon: Icons.auto_awesome,
              ),
              _buildFeatureCard(
                title: 'Client Management',
                description: 'Manage client data, billing info, and transactions in one place.',
                icon: Icons.people,
              ),
              _buildFeatureCard(
                title: 'Project Management',
                description: 'Create projects, add tasks, and track time per task.',
                icon: Icons.folder_special,
              ),
              _buildFeatureCard(
                title: 'Reports & Analytics',
                description: 'Get detailed insights into your hours, revenue, and invoices.',
                icon: Icons.insights,
              ),
              _buildFeatureCard(
                title: 'Cloud-Based & Multi-device',
                description: 'Access your data anywhere, anytime, on any device.',
                icon: Icons.cloud_done,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 48, color: primaryColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      color: Colors.white,
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
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _buildReasonCard(
                title: 'No Hidden Costs',
                description: 'Free to use without subscription',
                icon: Icons.attach_money,
              ),
              _buildReasonCard(
                title: 'User-Friendly Interface',
                description: 'No complex settings, start right away',
                icon: Icons.thumb_up,
              ),
              _buildReasonCard(
                title: 'Save Time',
                description: 'Less admin time, more focus on work',
                icon: Icons.schedule,
              ),
              _buildReasonCard(
                title: 'Flexible Billing',
                description: 'Time tracking and monthly invoices',
                icon: Icons.payment,  // Changed from Icons.flexibility
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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

  Widget _buildFooterSection() {
    // Reuse the footer from LandingPage or create a similar one
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      color: primaryColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Time2Bill',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'FAQ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Support',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Contact',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 24),
          const Text(
            '© 2024 Time2Bill. All rights reserved.',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
