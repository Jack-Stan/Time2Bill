import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class TimerState extends ChangeNotifier {
  int _seconds = 0;
  Timer? _timer;
  bool _isRunning = false;

  int get seconds => _seconds;
  bool get isRunning => _isRunning;
  
  // Formatted time display (HH:MM:SS)
  String get formattedTime {
    final hours = (_seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$secs';
  }

  void startTimer() {
    if (_isRunning) return; // Don't start if already running
    
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _seconds++;
      notifyListeners();
    });
    notifyListeners();
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    _timer?.cancel();
    _seconds = 0;
    _isRunning = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
