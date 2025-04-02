import 'package:flutter/material.dart';

class LandingPageModel extends ChangeNotifier {
  bool isMenuOpen = false;
  final ScrollController scrollController = ScrollController();

  void toggleMenu() {
    isMenuOpen = !isMenuOpen;
    notifyListeners();
  }

  void scrollToSection(double offset) {
    scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

LandingPageModel createModel(BuildContext context, Function() updateCallback) =>
    LandingPageModel();
