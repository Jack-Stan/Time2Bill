import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';

class LandingHowItWorks extends StatelessWidget {
  const LandingHowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Zo werkt Time2Bill', style: AppTextStyles.heading1),
          const SizedBox(height: 48),
          Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _StepCard(
                number: '1',
                title: 'Account Aanmaken',
                description: 'Registreer je account in enkele minuten',
                icon: Icons.person_add,
              ),
              _StepCard(
                number: '2',
                title: 'Klanten Toevoegen',
                description: 'Voeg je klanten en projecten toe',
                icon: Icons.business,
              ),
              _StepCard(
                number: '3',
                title: 'Tijd Registreren',
                description: 'Begin met het tracken van je uren',
                icon: Icons.timer,
              ),
              _StepCard(
                number: '4',
                title: 'Facturen Genereren',
                description: 'Maak en verstuur professionele facturen',
                icon: Icons.receipt_long,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Icon(icon, size: 32, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyles.bodyLight,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
