import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/primary_button.dart';

class LandingContact extends StatelessWidget {
  const LandingContact({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Contact', style: AppTextStyles.heading1),
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Naam'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Bericht'),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  text: 'Verstuur',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
