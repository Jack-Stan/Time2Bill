import 'package:flutter/material.dart';

class FeaturesPageModel extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

FeaturesPageModel createModel(BuildContext context, Function() updateCallback) =>
    FeaturesPageModel();
