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
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 800;
    
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
            if (isSmallScreen)
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _showMobileMenu(context);
                },
              )
            else
              Flexible(
                child: _buildNavItems(context),
              ),
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

  Widget _buildNavItems(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _buildNavLink('Features', context)),
        Flexible(child: _buildNavLink('How it Works', context)),
        Flexible(child: _buildNavLink('About Us', context)),
        Flexible(child: _buildNavLink('Pricing', context)),
        const SizedBox(width: 24),
        Flexible(
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
            ),
            child: const Text('Login'),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(child: _buildGetStartedButton(context)),
      ],
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Features'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/features');
              },
            ),
            ListTile(
              title: const Text('How it Works'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/about');
              },
            ),
            ListTile(
              title: const Text('Pricing'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Login'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/register');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Text('Get Started'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLink(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: TextButton(
        onPressed: () {
          if (text == 'Features') {
            Navigator.pushNamed(context, '/features');
          } else if (text == 'About Us') {
            Navigator.pushNamed(context, '/about');
          }
        },
        child: Text(
          text, 
          style: TextStyle(color: primaryColor),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, '/register'),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: const Text('Get Started'),
    );
  }
}
