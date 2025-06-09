import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sections/navbar.dart';
import 'landing_page_model.dart';
import 'widgets/floating_element.dart';
import 'widgets/animated_gradient_box.dart';
import 'widgets/dashboard_preview.dart';

// Helper method to handle opacity while avoiding deprecated methods
Color withOpacity(Color color, double opacity) {
  return Color.fromRGBO(
    color.r.toInt(),
    color.g.toInt(),
    color.b.toInt(),
    opacity,
  );
}

class LandingPageWidget extends StatefulWidget {
  final bool disableAnimations;
  final bool useSimpleLayout;

  const LandingPageWidget({
    super.key,
    this.disableAnimations = false,
    this.useSimpleLayout = false,
  });

  static String routeName = 'LandingPage';
  static String routePath = '/landingPage';

  @override
  State<LandingPageWidget> createState() => _LandingPageWidgetState();
}

class _LandingPageWidgetState extends State<LandingPageWidget> with TickerProviderStateMixin {
  late LandingPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final Color primaryColor = const Color(0xFF0B5394);
  final Color secondaryColor = const Color(0xFF4285F4);
  final Color lightBackgroundColor = const Color(0xFFF1F4F8);

  late AnimationController _floatingController;
  late AnimationController _backgroundAnimationController;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LandingPageModel());

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    if (!widget.disableAnimations) {
      _floatingController.repeat(reverse: true);
      _backgroundAnimationController.repeat();
    }
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _backgroundAnimationController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);    if (widget.useSimpleLayout) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NavBar(
              primaryColor: primaryColor,
              onGetStarted: () {
                Navigator.pushNamed(context, '/register');
              },
            ),
            _buildSimpleHeroSection(textTheme),
            _buildSimpleFeaturesSection(textTheme),
            _buildSimpleAppPreviewSection(textTheme),
            _buildFooterSection(textTheme),
          ],
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          fit: StackFit.expand,
          children: [
            if (!widget.disableAnimations)
              AnimatedGradientBox(controller: _backgroundAnimationController),
            if (!widget.disableAnimations) ...[
              Positioned(
                right: 100,
                top: 200,
                child: FloatingElement(
                  controller: _floatingController,
                  size: 60,
                  color: withOpacity(secondaryColor, 0.1),
                  shape: BoxShape.circle,
                  offset: const Offset(0, 20),
                ),
              ),
              Positioned(
                left: 120,
                top: 500,
                child: FloatingElement(
                  controller: _floatingController,
                  size: 80,
                  color: withOpacity(primaryColor, 0.1),
                  shape: BoxShape.circle,
                  offset: const Offset(0, 30),
                  delay: 1.5,
                ),
              ),
              Positioned(
                right: 80,
                bottom: 300,
                child: FloatingElement(
                  controller: _floatingController,
                  size: 100,
                  color: withOpacity(Colors.amber, 0.08),
                  shape: BoxShape.circle,
                  offset: const Offset(0, 25),
                  delay: 2.2,
                ),
              ),
            ],
            Listener(
              onPointerSignal: (event) {
                // Handle mouse wheel events
              },
              child: SingleChildScrollView(
                controller: _model.scrollController,
                physics: kIsWeb
                    ? const NeverScrollableScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                    minHeight: MediaQuery.of(context).size.height,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NavBar(
                        primaryColor: primaryColor,
                        onGetStarted: () {
                          Navigator.pushNamed(context, '/register');
                        },
                      ),
                      _buildHeroSection(textTheme),
                      _buildFeaturesSection(textTheme),
                      _buildAppPreviewSection(textTheme),
                      _buildTestimonialsSection(textTheme),
                      _buildCtaSection(textTheme),
                      _buildFooterSection(textTheme),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleHeroSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 400),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Image.asset(
              'lib/utils/images/LogoMetTitel.jpg',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          Text(
            'Smart Time Tracking,\nEffortless Billing',
            style: GoogleFonts.manrope(
              fontSize: 42,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'Streamline your workflow with elegant time tracking and professional invoicing.',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildPrimaryButton(
            'Get Started Free',
            onPressed: () => Navigator.pushNamed(context, '/register'),
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleFeaturesSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Powerful Features',
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Everything you need for effortless time tracking and invoicing',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Column(
            children: [
              _buildFeatureCard(
                icon: Icons.timer,
                title: 'Smart Tracking',
                description: 'Track time on any device with one click. Automated timers remember your ongoing tasks.',
                index: 0,
                fullWidth: true,
              ),
              const SizedBox(height: 24),
              _buildFeatureCard(
                icon: Icons.description,
                title: 'Professional Invoicing',
                description: 'Generate pixel-perfect invoices with custom branding and detailed time breakdowns.',
                index: 1,
                fullWidth: true,
              ),
              const SizedBox(height: 24),
              _buildFeatureCard(
                icon: Icons.insights,
                title: 'Advanced Analytics',
                description: 'Gain valuable insights with detailed reports on productivity and profitability.',
                index: 2,
                fullWidth: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleAppPreviewSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Designed for Productivity',
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Our intuitive interface helps you focus on what matters most - your work.',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 60),
          Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: DashboardPreview(
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 180,
                      width: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: withOpacity(primaryColor, 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'lib/utils/images/LogoMetTitel.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              primaryColor,
                              secondaryColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'Time2Bill',
                            style: GoogleFonts.manrope(
                              fontSize: 60,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          'Smart Time Tracking & Invoicing',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isDesktop)
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildHeroContent(textTheme, isDesktop),
                    ),
                    Expanded(
                      flex: 5,
                      child: _buildEnhancedHeroImage(),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildHeroContent(textTheme, isDesktop),
                    const SizedBox(height: 40),
                    _buildEnhancedHeroImage(),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroContent(TextTheme textTheme, bool isDesktop) {
    return Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Smart Time Tracking,\nEffortless Billing',
          style: GoogleFonts.manrope(
            fontSize: isDesktop ? 48 : 36,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          'Streamline your workflow with elegant time tracking and professional invoicing designed for modern businesses and professionals.',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
            height: 1.6,
          ),
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 40),
        _buildPrimaryButton(
          'Get Started Free',
          onPressed: () => Navigator.pushNamed(context, '/register'),
          isLarge: true,
        ),
      ],
    );
  }

  Widget _buildEnhancedHeroImage() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: withOpacity(Colors.black, 0.1),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: withOpacity(primaryColor, 0.05),
              blurRadius: 50,
              spreadRadius: 2,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'lib/utils/images/dashboard_preview.jpg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required int index,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: withOpacity(Colors.black, 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: primaryColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Powerful Features',
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Everything you need for effortless time tracking and invoicing',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            children: [
              _buildFeatureCard(
                icon: Icons.timer,
                title: 'Smart Tracking',
                description: 'Track time on any device with one click.',
                index: 0,
              ),
              _buildFeatureCard(
                icon: Icons.description,
                title: 'Professional Invoicing',
                description: 'Generate pixel-perfect invoices with custom branding.',
                index: 1,
              ),
              _buildFeatureCard(
                icon: Icons.insights,
                title: 'Advanced Analytics',
                description: 'Gain valuable insights with detailed reports.',
                index: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreviewSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Designed for Productivity',
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'Our intuitive interface helps you focus on what matters most - your work.',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 60),
          Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: DashboardPreview(
              primaryColor: primaryColor,
              secondaryColor: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(child: Text('Testimonials Placeholder')),
    );
  }

  Widget _buildCtaSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(child: Text('CTA Placeholder')),
    );
  }

  Widget _buildFooterSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      color: const Color(0xFF0A1F3D),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'lib/utils/images/LogoZonderTitel.png',
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Time2Bill',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        'Smart time tracking and invoicing for businesses and professionals.',
                        style: GoogleFonts.inter(
                          color: withOpacity(Colors.white, 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;

                    return Wrap(
                      spacing: 60,
                      runSpacing: 40,
                      alignment: isSmallScreen ? WrapAlignment.start : WrapAlignment.end,
                      children: [
                        _buildFooterLinks(
                          title: 'Product',
                          links: ['Features', 'Pricing', 'Integrations', 'FAQ'],
                        ),
                        _buildFooterLinks(
                          title: 'Company',
                          links: ['About us', 'Contact', 'Privacy Policy', 'Terms'],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2024 Time2Bill. All rights reserved.',
                style: GoogleFonts.inter(
                  color: withOpacity(Colors.white, 0.7),
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.facebook, color: Colors.white70),
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.telegram, color: Colors.white70),
                    iconSize: 20,
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.email, color: Colors.white70),
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLinks({required String title, required List<String> links}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {},
            child: Text(
              link,
              style: GoogleFonts.inter(
                color: withOpacity(Colors.white, 0.7),
                fontSize: 15,
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, {required VoidCallback onPressed, bool isLarge = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 40 : 32,
          vertical: isLarge ? 20 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: isLarge ? 18 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
