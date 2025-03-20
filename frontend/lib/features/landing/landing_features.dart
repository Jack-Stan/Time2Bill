import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class LandingFeatures extends StatelessWidget {
  const LandingFeatures({super.key});

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: features.map((feature) => _FeatureCard(feature: feature)).toList(),
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
      child: ListTile(
        leading: Icon(feature.icon, size: 32, color: AppColors.primary),
        title: Text(feature.title, style: AppTextStyles.heading2),
        subtitle: Text(feature.description, style: AppTextStyles.bodyLight),
      ),
    );
  }
}
