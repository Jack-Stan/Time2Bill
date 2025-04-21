import 'package:flutter/material.dart';

class TimerState extends ChangeNotifier {
  bool _isRunning = false;
  int _secondsElapsed = 0;
  String _description = '';
  String? _projectId;
  String? _projectName;
  String? _clientId;
  String? _clientName;
  bool _isBillable = true;
  DateTime? _startTime;
  
  bool get isRunning => _isRunning;
  int get secondsElapsed => _secondsElapsed;
  String get description => _description;
  String? get projectId => _projectId;
  String? get projectName => _projectName;
  String? get clientId => _clientId;
  String? get clientName => _clientName;
  bool get isBillable => _isBillable;
  DateTime? get startTime => _startTime;
  
  DateTime? _lastTick;
  
  void startTimer({
    required String description,
    String? projectId,
    String? projectName,
    String? clientId,
    String? clientName,
    bool isBillable = true,
  }) {
    _isRunning = true;
    _secondsElapsed = 0;
    _description = description;
    _projectId = projectId;
    _projectName = projectName;
    _clientId = clientId;
    _clientName = clientName;
    _isBillable = isBillable;
    _startTime = DateTime.now();
    _lastTick = DateTime.now();
    notifyListeners();
    
    _startTickTimer();
  }
  
  void _startTickTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isRunning) return;
      
      final now = DateTime.now();
      if (_lastTick != null) {
        final secondsDiff = now.difference(_lastTick!).inSeconds;
        // Ensure we add at least 1 second even if system clock adjustments occur
        _secondsElapsed += secondsDiff > 0 ? secondsDiff : 1;
      }
      _lastTick = now;
      
      notifyListeners();
      _startTickTimer();
    });
  }
  
  void stopTimer() {
    _isRunning = false;
    notifyListeners();
  }
  
  void resetTimer() {
    _isRunning = false;
    _secondsElapsed = 0;
    _description = '';
    _projectId = null;
    _projectName = null;
    _clientId = null;
    _clientName = null;
    _isBillable = true;
    _startTime = null;
    notifyListeners();
  }
}
