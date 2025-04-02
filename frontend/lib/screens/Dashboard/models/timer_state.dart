import 'package:flutter/material.dart';

class TimerState extends ChangeNotifier {
  bool _isRunning = false;
  Duration _elapsed = Duration.zero;
  String? _selectedProject;
  DateTime? _startTime;

  bool get isRunning => _isRunning;
  Duration get elapsed => _elapsed;
  String? get selectedProject => _selectedProject;

  void startTimer() {
    if (!_isRunning) {
      _isRunning = true;
      _startTime = DateTime.now();
      notifyListeners();
    }
  }

  void stopTimer() {
    if (_isRunning) {
      _isRunning = false;
      _elapsed += DateTime.now().difference(_startTime!);
      _startTime = null;
      notifyListeners();
    }
  }

  void resetTimer() {
    _isRunning = false;
    _elapsed = Duration.zero;
    _startTime = null;
    notifyListeners();
  }

  void selectProject(String project) {
    _selectedProject = project;
    notifyListeners();
  }
}
