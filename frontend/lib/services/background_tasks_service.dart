import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'auto_invoice_service.dart';

/// Service to handle background tasks like automatic invoice sending
class BackgroundTasksService {
  static final BackgroundTasksService _instance = BackgroundTasksService._internal();
  factory BackgroundTasksService() => _instance;
  BackgroundTasksService._internal();
  
  final AutoInvoiceService _autoInvoiceService = AutoInvoiceService();
  Timer? _autoInvoiceTimer;
  bool _isInitialized = false;
  
  /// Initialize the background task service
  void initialize() {
    if (_isInitialized) return;
    
    _isInitialized = true;
    print('🔄 Initializing background tasks service');
    
    // Setup auth state listener to start/stop tasks based on login state
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _startBackgroundTasks();
      } else {
        _stopBackgroundTasks();
      }
    });
    
    // Run once at startup if user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      _startBackgroundTasks();
    }
  }
  
  /// Start all background tasks
  void _startBackgroundTasks() {
    _startAutoInvoiceTask();
  }
  
  /// Stop all background tasks
  void _stopBackgroundTasks() {
    _stopAutoInvoiceTask();
  }
  
  /// Start the automatic invoice task
  void _startAutoInvoiceTask() {
    // Cancel any existing timer
    _autoInvoiceTimer?.cancel();
    
    // Check if we should run in the browser (may cause issues with performance)
    if (kIsWeb) {
      // In web, run less frequently to avoid performance issues
      _autoInvoiceTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => _processAutomaticInvoices(),
      );
    } else {
      // In mobile/desktop, run more frequently
      _autoInvoiceTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _processAutomaticInvoices(),
      );
    }
      // Don't run immediately - let the timer handle it
    // _processAutomaticInvoices();
  }
  
  /// Stop the automatic invoice task
  void _stopAutoInvoiceTask() {
    _autoInvoiceTimer?.cancel();
    _autoInvoiceTimer = null;
  }
  
  /// Process automatic invoice sending
  Future<void> _processAutomaticInvoices() async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        print('⏱️ Running automatic invoice processing task');
        await _autoInvoiceService.processAutomaticSending();
      }
    } catch (e) {
      print('❌ Error in automatic invoice processing: $e');
    }
  }
  
  /// Force run the auto invoice task immediately
  Future<void> runInvoiceProcessingNow() async {
    await _processAutomaticInvoices();
  }
  
  /// Clean up resources
  void dispose() {
    _stopBackgroundTasks();
  }
}
