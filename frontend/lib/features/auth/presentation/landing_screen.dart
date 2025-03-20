import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/primary_button.dart';
import '../../../core/config/app_routes.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(context).animate().fadeIn().slideY(
                  begin: -0.2,
                  duration: const Duration(milliseconds: 500),
                ),
                _buildFeatures(context).animate().fadeIn(
                  delay: const Duration(milliseconds: 300),
                ),
                _buildSteps(context).animate().fadeIn(
                  delay: const Duration(milliseconds: 600),
                ),
                _buildNavigation(context).animate().fadeIn(
                  delay: const Duration(milliseconds: 900),
                ),
                _buildFooter(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.access_time,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          Text('Time2Bill', style: AppTextStyles.heading1),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Beheer je tijd, facturen en klanten in één overzichtelijke applicatie.',
              style: AppTextStyles.bodyLight,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    final features = [
      _Feature(
        icon: Icons.timer,
        title: 'Tijdregistratie',
        description: 'Track je uren eenvoudig en accuraat',
      ),
      _Feature(
        icon: Icons.receipt_long,
        title: 'Facturering',
        description: 'Genereer en beheer je facturen',
      ),
      _Feature(
        icon: Icons.people,
        title: 'Klantenbeheer',
        description: 'Houd je klantenbestand overzichtelijk',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Text('Alles wat je nodig hebt', style: AppTextStyles.heading2),
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: features.map((feature) => SizedBox(
              width: 300,
              child: _FeatureCard(feature: feature),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: AppColors.surface,
      child: Column(
        children: [
          Text('Zo werkt het', style: AppTextStyles.heading2),
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStep(1, 'Account', 'Maak je account aan'),
                _buildStep(2, 'Klanten', 'Voeg je klanten toe'),
                _buildStep(3, 'Start', 'Begin met factureren'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String description) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.button,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: AppTextStyles.heading2),
        const SizedBox(height: 8),
        Text(description, style: AppTextStyles.bodyLight),
      ],
    );
  }

  Widget _buildNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          Text('Klaar om te beginnen?', style: AppTextStyles.heading2),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, AppRouter.login),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Inloggen'),
              ),
              const SizedBox(width: 16),
              PrimaryButton(
                text: 'Registreren',
                onPressed: () => Navigator.pushNamed(context, AppRouter.register),
                isFullWidth: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Over ons'),
              ),
              const SizedBox(width: 24),
              TextButton(
                onPressed: () {},
                child: const Text('Contact'),
              ),
              const SizedBox(width: 24),
              TextButton(
                onPressed: () {},
                child: const Text('Privacy'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '© ${DateTime.now().year} Time2Bill. Alle rechten voorbehouden.',
            style: AppTextStyles.bodyLight,
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;

  _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(feature.icon, size: 32, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title, style: AppTextStyles.heading2),
                const SizedBox(height: 4),
                Text(feature.description, style: AppTextStyles.bodyLight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
