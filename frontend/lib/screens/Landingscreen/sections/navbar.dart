import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onGetStarted;

  const NavBar({
    super.key, 
    required this.primaryColor,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {  // Store context from build
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFd5dedb),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLogo(context),
            _buildNavItems(context),  // Pass context to _buildNavItems
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/'),
      child: Row(
        children: [
          Image.asset(
            'lib/utils/images/LogoZonderTitel.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Text(
            'Time2Bill',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItems(BuildContext context) {  // Accept context parameter
    return Row(
      children: [
        _buildNavLink('Features', context),  // Pass context to _buildNavLink
        _buildNavLink('How it Works', context),
        _buildNavLink('About Us', context),  // Add About Us
        _buildNavLink('Pricing', context),
        const SizedBox(width: 24),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/login');
          },
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
          ),
          child: const Text('Login'),
        ),
        const SizedBox(width: 12),
        _buildGetStartedButton(context),  // Add context parameter
      ],
    );
  }

  Widget _buildNavLink(String text, BuildContext context) {  // Accept context parameter
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextButton(
        onPressed: () {
          if (text == 'Features') {
            Navigator.pushNamed(context, '/features');
          } else if (text == 'About Us') {
            Navigator.pushNamed(context, '/about');
          }
        },
        child: Text(text, style: TextStyle(color: primaryColor)),
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {  // Add context parameter
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, '/register'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: const Text('Get Started'),
    );
  }
}
