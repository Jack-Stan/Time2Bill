import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class Navbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const Navbar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset(
                'lib/assets/images/LogoTransparant.png',
                height: 40,
              ),
              const SizedBox(width: 12),
              Text('Time2Bill', style: AppTextStyles.heading2),
            ],
          ),
          Row(
            children: [
              _NavItem(
                title: 'Home',
                isSelected: selectedIndex == 0,
                onTap: () => onItemSelected(0),
              ),
              _NavItem(
                title: 'Features',
                isSelected: selectedIndex == 1,
                onTap: () => onItemSelected(1),
              ),
              _NavItem(
                title: 'Pricing',
                isSelected: selectedIndex == 2,
                onTap: () => onItemSelected(2),
              ),
              _NavItem(
                title: 'Contact',
                isSelected: selectedIndex == 3,
                onTap: () => onItemSelected(3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: AppTextStyles.body.copyWith(
            color: isSelected ? AppColors.primary : AppColors.text,
          ),
        ),
      ),
    );
  }
}
