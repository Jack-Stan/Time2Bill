import 'package:flutter/material.dart';

class AboutPageModel extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

AboutPageModel createModel(BuildContext context, Function() updateCallback) =>
    AboutPageModel();
