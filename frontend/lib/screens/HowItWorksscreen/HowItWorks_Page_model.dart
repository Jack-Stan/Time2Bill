import 'package:flutter/material.dart';

class HowItWorksPageModel {
  final ScrollController scrollController = ScrollController();
  
  void dispose() {
    scrollController.dispose();
  }
}

HowItWorksPageModel createModel(BuildContext context, Function() state) {
  return HowItWorksPageModel();
}