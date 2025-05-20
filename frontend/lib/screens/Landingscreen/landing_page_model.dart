import 'package:flutter/material.dart';

class LandingPageModel {
  ScrollController scrollController = ScrollController();
  
  void dispose() {
    scrollController.dispose();
  }
}

LandingPageModel createModel(BuildContext context, Function() updateCallback) {
  return LandingPageModel();
}
