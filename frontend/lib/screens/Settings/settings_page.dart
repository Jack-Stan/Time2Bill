import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Dashboard/widgets/sidebar.dart';
import 'widgets/profile_settings_card.dart';
import 'widgets/business_settings_card.dart';
import 'widgets/notification_settings_card.dart';
import 'widgets/theme_settings_card.dart';
import 'widgets/export_import_card.dart';
import 'widgets/delete_account_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 5; // Settings tab index
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _userSettings = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      // Fetch user settings
      final settingsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('preferences')
          .get();

      final userData = userDoc.exists ? userDoc.data() ?? {} : {};
      final userSettings = settingsDoc.exists ? settingsDoc.data() ?? {} : {};

      setState(() {
        _userData = Map<String, dynamic>.from(userData);
        _userSettings = Map<String, dynamic>.from(userSettings);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Error loading user data: ${error.toString()}';
        _isLoading = false;
      });
      print('Error fetching user data: $error');
    }
  }

  Future<void> _saveSettings(String cardType, Map<String, dynamic> settings) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get reference to user document
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // Save settings based on card type
      switch (cardType) {
        case 'profile':
          await userDocRef.update({
            'firstName': settings['firstName'],
            'lastName': settings['lastName'],
            'email': settings['email'],
            'phone': settings['phone'],
          });
          break;
        case 'business':
          await userDocRef.update({
            'businessName': settings['businessName'],
            'vatNumber': settings['vatNumber'],
            'address': settings['address'],
            'defaultVatRate': settings['defaultVatRate'],
          });
          break;
        case 'notifications':
          await userDocRef
              .collection('settings')
              .doc('preferences')
              .set({
                'emailNotifications': settings['emailNotifications'],
                'invoiceReminders': settings['invoiceReminders'],
                'overdueInvoices': settings['overdueInvoices'],
                'weeklyReports': settings['weeklyReports'],
              }, SetOptions(merge: true));
          break;
        case 'theme':
          await userDocRef
              .collection('settings')
              .doc('preferences')
              .set({
                'darkMode': settings['darkMode'],
                'compactMode': settings['compactMode'],
              }, SetOptions(merge: true));
          break;
      }

      // Refresh user data
      await _loadUserData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: ${error.toString()}')),
      );
      print('Error saving settings: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          DashboardSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (index) {
              switch (index) {
                case 0: // Dashboard
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1: // Time Tracking
                  Navigator.pushReplacementNamed(context, '/time-tracking');
                  break;
                case 2: // Invoices
                  Navigator.pushReplacementNamed(context, '/invoices');
                  break;
                case 3: // Clients
                  Navigator.pushReplacementNamed(context, '/clients');
                  break;
                case 4: // Reports
                  Navigator.pushReplacementNamed(context, '/reports');
                  break;
                case 5: // Settings (already on this page)
                  setState(() => _selectedIndex = index);
                  break;
                case 6: // Projects
                  Navigator.pushReplacementNamed(context, '/projects');
                  break;
                default:
                  setState(() => _selectedIndex = index);
              }
            },
          ),
          // Main Content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _buildMainContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            _buildErrorView()
          else
            _buildSettingsCards(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCards() {
    return Column(
      children: [
        // Profile Settings
        ProfileSettingsCard(
          userData: _userData,
          onSave: (settings) => _saveSettings('profile', settings),
        ),
        const SizedBox(height: 24),
        
        // Business Settings
        BusinessSettingsCard(
          userData: _userData,
          onSave: (settings) => _saveSettings('business', settings),
        ),
        const SizedBox(height: 24),
        
        // Row with Notifications and Theme settings
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Settings
            Expanded(
              child: NotificationSettingsCard(
                settings: _userSettings,
                onSave: (settings) => _saveSettings('notifications', settings),
              ),
            ),
            const SizedBox(width: 24),
            
            // Theme Settings
            Expanded(
              child: ThemeSettingsCard(
                settings: _userSettings,
                onSave: (settings) => _saveSettings('theme', settings),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Data Export/Import Card
        ExportImportCard(
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
        const SizedBox(height: 24),
        
        // Delete Account Card
        const DeleteAccountCard(),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUserData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
