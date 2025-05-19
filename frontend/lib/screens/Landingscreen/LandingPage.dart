import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'sections/navbar.dart';
import 'landing_page_model.dart';
import 'widgets/floating_element.dart';
import 'widgets/parallax_box.dart';
import 'widgets/animated_gradient_box.dart';
import 'widgets/card_3d_effect.dart';
import 'widgets/dashboard_preview.dart';
import 'widgets/invoice_preview.dart';

class LandingPageWidget extends StatefulWidget {
  const LandingPageWidget({super.key});

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
    )..repeat(reverse: true);

    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
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
    final textTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    return Scaffold(
      key: scaffoldKey,
      body: Stack(
        children: [
          AnimatedGradientBox(controller: _backgroundAnimationController),
          Positioned(
            right: 100,
            top: 200,
            child: FloatingElement(
              controller: _floatingController,
              size: 60,
              color: secondaryColor.withOpacity(0.1),
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
              color: primaryColor.withOpacity(0.1),
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
              color: Colors.amber.withOpacity(0.08),
              shape: BoxShape.circle,
              offset: const Offset(0, 25),
              delay: 2.2,
            ),
          ),
          SingleChildScrollView(
            controller: _model.scrollController,
            child: Column(
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

  Widget _buildEnhancedHeroImage() {
    return ParallaxBox(
      child: Card3DEffect(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: primaryColor.withOpacity(0.05),
                  blurRadius: 50,
                  spreadRadius: 2,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'lib/utils/images/LogoMetTitel.jpg',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    )
        .animate(
          onPlay: (controller) => controller.repeat(reverse: false),
        )
        .fadeIn(duration: 800.ms, delay: 300.ms)
        .scaleXY(
          begin: 0.9,
          end: 1.0,
          duration: 800.ms,
          curve: Curves.easeOutQuint,
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
            fontSize: isDesktop ? 52 : 36,
            height: 1.1,
            fontWeight: FontWeight.w800,
            color: primaryColor,
          ),
          textAlign: isDesktop ? TextAlign.start : TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 100.ms)
            .move(begin: const Offset(0, 30), duration: 600.ms, curve: Curves.easeOutQuad)
            .blur(begin: const Offset(5, 0), end: const Offset(0, 0), duration: 600.ms),
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
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 300.ms)
            .move(begin: const Offset(0, 20), duration: 600.ms),
        const SizedBox(height: 40),
        _buildPrimaryButton(
          'Get Started Free',
          onPressed: () => Navigator.pushNamed(context, '/register'),
          isLarge: true,
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 500.ms)
            .move(begin: const Offset(0, 20), duration: 600.ms)
            .then()
            .shimmer(duration: 1200.ms, delay: 300.ms)
            .then()
            .shimmer(duration: 1200.ms, delay: 2000.ms),
      ],
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
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 100.ms)
              .move(begin: const Offset(0, 20), duration: 600.ms),
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
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;

              if (isDesktop) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildEnhancedFeatureCard(
                      icon: Icons.timer,
                      title: 'Smart Tracking',
                      description: 'Track time on any device with one click. Automated timers remember your ongoing tasks.',
                      index: 0,
                    ),
                    const SizedBox(width: 24),
                    _buildEnhancedFeatureCard(
                      icon: Icons.description,
                      title: 'Professional Invoicing',
                      description: 'Generate pixel-perfect invoices with custom branding and detailed time breakdowns.',
                      index: 1,
                    ),
                    const SizedBox(width: 24),
                    _buildEnhancedFeatureCard(
                      icon: Icons.insights,
                      title: 'Advanced Analytics',
                      description: 'Gain valuable insights with detailed reports on productivity and profitability.',
                      index: 2,
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildEnhancedFeatureCard(
                      icon: Icons.timer,
                      title: 'Smart Tracking',
                      description: 'Track time on any device with one click. Automated timers remember your ongoing tasks.',
                      index: 0,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 24),
                    _buildEnhancedFeatureCard(
                      icon: Icons.description,
                      title: 'Professional Invoicing',
                      description: 'Generate pixel-perfect invoices with custom branding and detailed time breakdowns.',
                      index: 1,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 24),
                    _buildEnhancedFeatureCard(
                      icon: Icons.insights,
                      title: 'Advanced Analytics',
                      description: 'Gain valuable insights with detailed reports on productivity and profitability.',
                      index: 2,
                      fullWidth: true,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required int index,
    bool fullWidth = false,
  }) {
    return Card3DEffect(
      child: Container(
        width: fullWidth ? double.infinity : 320,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.8),
                      Colors.white.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAnimatedIconContainer(icon, index),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: (index * 200 + 300).ms)
        .move(begin: const Offset(0, 20), duration: 600.ms)
        .then()
        .shimmer(duration: 1200.ms, delay: (index * 200).ms);
  }

  Widget _buildAnimatedIconContainer(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 32,
        color: primaryColor,
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).scale(
      begin: const Offset(1, 1),
      end: const Offset(1.1, 1.1),
      duration: 2000.ms,
      delay: (index * 200).ms,
      curve: Curves.easeInOut,
    );
  }

  Widget _buildAppPreviewSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;

          return Column(
            children: [
              Text(
                'Designed for Productivity',
                style: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 100.ms),
              const SizedBox(height: 16),
              Container(
                constraints: BoxConstraints(
                  maxWidth: 700,
                ),
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
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms),
              const SizedBox(height: 60),
              Container(
                constraints: BoxConstraints(
                  maxWidth: 1100,
                ),
                child: DashboardPreview(
                  primaryColor: primaryColor,
                  secondaryColor: secondaryColor,
                ),
              ),
              const SizedBox(height: 80),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'INVOICING',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Professional Invoicing, Automated',
                              style: GoogleFonts.manrope(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 600.ms)
                                .move(begin: const Offset(0, 20), duration: 600.ms),
                            const SizedBox(height: 24),
                            Text(
                              'Transform your tracked hours into professional invoices with just a few clicks. Customize templates, set payment terms, and get paid faster.',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.black54,
                                height: 1.6,
                              ),
                            )
                                .animate()
                                .fadeIn(duration: 600.ms, delay: 200.ms),
                            const SizedBox(height: 32),
                            _buildFeatureList([
                              'Automated invoice generation based on tracked time',
                              'Multiple currencies and tax rates support',
                              'Custom branding and payment instructions',
                              'Online payment integration',
                            ]),
                          ],
                        ),
                      ),
                    ),
                  if (isDesktop)
                    Expanded(
                      child: InvoicePreview(
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              'INVOICING',
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Professional Invoicing, Automated',
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(duration: 600.ms),
                          const SizedBox(height: 24),
                          Text(
                            'Transform your tracked hours into professional invoices with just a few clicks.',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          InvoicePreview(
                            primaryColor: primaryColor,
                            secondaryColor: secondaryColor,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFeatureList(List<String> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.asMap().entries.map((entry) {
        final int index = entry.key;
        final String feature = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withOpacity(0.1),
                ),
                child: Icon(Icons.check, color: primaryColor, size: 16),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: (index * 100 + 400).ms)
                  .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 400.ms),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (index * 100 + 500).ms),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTestimonialsSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          Text(
            'Trusted by Professionals',
            style: GoogleFonts.manrope(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 100.ms),
          const SizedBox(height: 60),
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;

              if (isDesktop) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTestimonialCard(
                      quote: "Time2Bill transformed how we track billable hours. It's elegant and efficient.",
                      name: "Alex Mitchell",
                      role: "Design Director",
                      index: 0,
                    ),
                    const SizedBox(width: 24),
                    _buildTestimonialCard(
                      quote: "The invoicing system saves me hours every month. Worth every penny.",
                      name: "Sarah Jensen",
                      role: "Freelance Developer",
                      index: 1,
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildTestimonialCard(
                      quote: "Time2Bill transformed how we track billable hours. It's elegant and efficient.",
                      name: "Alex Mitchell",
                      role: "Design Director",
                      index: 0,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 24),
                    _buildTestimonialCard(
                      quote: "The invoicing system saves me hours every month. Worth every penny.",
                      name: "Sarah Jensen",
                      role: "Freelance Developer",
                      index: 1,
                      fullWidth: true,
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialCard({
    required String quote,
    required String name,
    required String role,
    required int index,
    bool fullWidth = false,
  }) {
    return Card3DEffect(
      child: Container(
        width: fullWidth ? double.infinity : 450,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: -5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.format_quote,
                      size: 40,
                      color: Color(0xFF4285F4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      quote,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: (index * 200 + 300).ms)
        .move(begin: const Offset(0, 20), duration: 600.ms);
  }

  Widget _buildCtaSection(TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor.withOpacity(0.8),
                    secondaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  Text(
                    'Ready to streamline your workflow?',
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 100.ms),
                  const SizedBox(height: 16),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: 700,
                    ),
                    child: Text(
                      'Join thousands of professionals who save time and increase revenue with Time2Bill.',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms),
                  const SizedBox(height: 40),
                  _buildPrimaryButtonWhite(
                    'Start Your Free Trial',
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    isLarge: true,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 300.ms)
                      .scaleXY(begin: 0.95, end: 1.0, duration: 300.ms, curve: Curves.easeOutQuint)
                      .then()
                      .shimmer(duration: 1800.ms, delay: 500.ms)
                      .then()
                      .shimmer(duration: 1800.ms, delay: 2000.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 800.ms, delay: 100.ms);
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

  Widget _buildPrimaryButtonWhite(String text, {required VoidCallback onPressed, bool isLarge = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
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
                      constraints: BoxConstraints(
                        maxWidth: 300,
                      ),
                      child: Text(
                        'Smart time tracking and invoicing for businesses and professionals.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
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
                  color: Colors.white.withOpacity(0.7),
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
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
          ),
        )),
      ],
    );
  }
}
