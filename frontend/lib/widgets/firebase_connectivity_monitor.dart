import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'overflow_safe_widget.dart';

class FirebaseConnectivityMonitor extends StatefulWidget {
  final Widget child;
  final Duration checkInterval;
  final FirebaseFirestore? firestore;

  const FirebaseConnectivityMonitor({
    super.key,
    required this.child,
    this.checkInterval = const Duration(minutes: 5),
    this.firestore,
  });

  @override
  State<FirebaseConnectivityMonitor> createState() => _FirebaseConnectivityMonitorState();
}

class _FirebaseConnectivityMonitorState extends State<FirebaseConnectivityMonitor> with WidgetsBindingObserver {
  bool _isConnected = true;
  Timer? _checkTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Delay the initial check to avoid conflicts during app startup
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _checkConnectivity();
      }
    });
    
    _checkTimer = Timer.periodic(widget.checkInterval, (_) {
      if (!_isChecking && mounted) {
        _checkConnectivity();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkConnectivity();
    }
  }
  Future<void> _checkConnectivity() async {
    if (_isChecking) return;
    
    _isChecking = true;
    try {
      // Use the injected firestore if provided, otherwise use the default instance
      final firestoreInstance = widget.firestore ?? FirebaseFirestore.instance;
      await firestoreInstance.collection('system').doc('status').get()
          .timeout(const Duration(seconds: 10));
      
      if (!mounted) return;
      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
      });
      print('Firebase connectivity check failed: $e');
    } finally {
      _isChecking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return widget.child;
    }

    // Using SafeArea to ensure proper boundaries
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: true,
              child: Material(
                color: Colors.red,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: SafeRow(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Icon(Icons.cloud_off, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Connection to server lost. Your changes may not be saved.',
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                      TextButton(
                        onPressed: _isChecking ? null : _checkConnectivity,
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}