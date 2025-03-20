import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_button.dart';

class LandingPricing extends StatelessWidget {
  const LandingPricing({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Onze Prijzen', style: AppTextStyles.heading1),
          const SizedBox(height: 48),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              _PriceCard(
                title: 'Starter',
                price: '€9.99',
                features: ['5 klanten', '1 gebruiker', 'Basis rapportages'],
              ),
              _PriceCard(
                title: 'Professional',
                price: '€19.99',
                features: ['Onbeperkt klanten', '3 gebruikers', 'Uitgebreide rapportages'],
                isPrimary: true,
              ),
              _PriceCard(
                title: 'Enterprise',
                price: 'Op aanvraag',
                features: ['Maatwerk', 'Onbeperkt gebruikers', '24/7 support'],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String title;
  final String price;
  final List<String> features;
  final bool isPrimary;

  const _PriceCard({
    required this.title,
    required this.price,
    required this.features,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.primary : AppColors.surface,
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
          Text(
            title,
            style: AppTextStyles.heading2.copyWith(
              color: isPrimary ? AppColors.surface : AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            price,
            style: AppTextStyles.heading1.copyWith(
              color: isPrimary ? AppColors.surface : AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              feature,
              style: AppTextStyles.body.copyWith(
                color: isPrimary ? AppColors.surface : AppColors.text,
              ),
            ),
          )),
          const SizedBox(height: 24),
          PrimaryButton(
            text: 'Kies ${title}',
            onPressed: () {},
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
