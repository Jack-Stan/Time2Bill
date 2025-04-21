import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class FirebaseConnectivityMonitor extends StatefulWidget {
  final Widget child;
  final Duration checkInterval;

  const FirebaseConnectivityMonitor({
    super.key,
    required this.child,
    this.checkInterval = const Duration(minutes: 5),
  });

  @override
  State<FirebaseConnectivityMonitor> createState() => _FirebaseConnectivityMonitorState();
}

class _FirebaseConnectivityMonitorState extends State<FirebaseConnectivityMonitor> {
  bool _isConnected = true;
  late Timer _checkTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _checkTimer = Timer.periodic(widget.checkInterval, (_) => _checkConnectivity());
  }

  @override
  void dispose() {
    _checkTimer.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      await FirebaseFirestore.instance.collection('system').doc('status').get()
          .timeout(const Duration(seconds: 10));
      
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
        _errorMessage = e.toString();
      });
      print('Firebase connectivity check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.red,
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Connection to server lost. Your changes may not be saved.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: _checkConnectivity,
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
