import 'package:flutter/material.dart';

/// Een mixin die widgets kunnen implementeren om refresh functionaliteit te bieden
mixin RefreshableWidget<T extends StatefulWidget> on State<T> {
  void refresh();
}
