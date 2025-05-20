import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NavBar extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback onGetStarted;

  const NavBar({
    Key? key,
    required this.primaryColor,
    required this.onGetStarted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Basisstijlen definiëren
    final titleStyle = GoogleFonts.manrope(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    );
    
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(
              Colors.black.r.toInt(),
              Colors.black.g.toInt(),
              Colors.black.b.toInt(),
              0.05,
            ),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          
          // We verwijderen de Column en het grote logo hier
          // En keren terug naar de eenvoudigere Row structuur
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo en titel row - nu klikbaar naar home
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, '/'),
                child: Row(
                  children: [
                    Image.asset(
                      'lib/utils/images/LogoZonderTitel.png',
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Text('Time2Bill', style: titleStyle),
                  ],
                ),
              ),
              
              // Navigatie-items
              if (isDesktop)
                Row(
                  children: [
                    _buildNavItems(context),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: onGetStarted,
                      style: buttonStyle,
                      child: Text(
                        'Get Started', 
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _showMobileMenu(context),
                ),
            ],
          );
        }
      ),
    );
  }
  
  /// Helper methode om navigatie-items te bouwen
  Widget _buildNavItems(BuildContext context) {
    return Row(
      children: [
        NavBarItem(title: 'Features', onTap: () => Navigator.pushNamed(context, '/features')),
        NavBarItem(title: 'How It Works', onTap: () => Navigator.pushNamed(context, '/how-it-works')),
        NavBarItem(title: 'About', onTap: () => Navigator.pushNamed(context, '/about')),
        NavBarItem(title: 'Login', onTap: () => Navigator.pushNamed(context, '/login')),
      ],
    );
  }
  
  /// Toont het mobile menu wanneer op de hamburger icon wordt geklikt
  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
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
                title: const Text('How It Works'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/how-it-works');
                },
              ),
              ListTile(
                title: const Text('About'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/about');
                },
              ),
              ListTile(
                title: const Text('Login'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onGetStarted();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Get Started',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class NavBarItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const NavBarItem({
    Key? key,
    required this.title,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      hoverColor: Color.fromRGBO(
        Colors.grey.r.toInt(),
        Colors.grey.g.toInt(),
        Colors.grey.b.toInt(),
        0.1,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
