import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/Landingscreen/LandingPage.dart';
import 'screens/Featuresscreen/FeaturesPage.dart';
import 'screens/Aboutscreen/AboutPage.dart';
import 'screens/Authscreen/LoginPage.dart';
import 'screens/Authscreen/register_page.dart';
import 'screens/Dashboard/dashboard_page.dart';
import 'screens/Dashboard/models/timer_state.dart';
import 'screens/Projects/projects_page.dart';
import 'screens/Projects/project_detail_page.dart';
import 'screens/placeholder_page.dart';
import 'screens/TimeTracking/time_tracking_page.dart';
import 'screens/Profile/profile_page.dart';
import 'screens/Invoices/invoices_page.dart';
import 'screens/Clients/clients_page.dart';
import 'screens/Reports/reports_page.dart';
import 'screens/Settings/settings_page.dart';
import 'widgets/firebase_connectivity_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Starting Firebase initialization...');
    
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCovzoOZbdbTyS-paUoPGoWuV2eGBBnzW8",
        authDomain: "time2bill-19f64.firebaseapp.com",
        projectId: "time2bill-19f64",
        storageBucket: "time2bill-19f64.appspot.com",
        messagingSenderId: "746331757137",
        appId: "1:746331757137:web:c1234567890",
      ),
    );
    
    print('Firebase initialized successfully');
    
    // Firestore instellingen
    final settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    FirebaseFirestore.instance.settings = settings;
    print('Firestore persistence configured with modern settings');
    
    // Test Firestore connectie
    try {
      final timeoutDuration = Duration(seconds: 15);
      print('Testing Firestore connection (timeout: ${timeoutDuration.inSeconds}s)...');
      
      await FirebaseFirestore.instance.collection('system').doc('status').get()
        .timeout(timeoutDuration);
      print('✅ Firestore connection test successful');
      
      // Check huidige gebruiker
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Current user UID: ${user.uid}');
        print('Email verified: ${user.emailVerified}');
        
        // Probeer gebruikersgegevens op te halen
        try {
          final userData = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (userData.exists) {
            print('User document exists: ${userData.data()?.keys.join(", ")}');
          } else {
            print('⚠️ User document does not exist');
          }
        } catch (e) {
          print('⚠️ Failed to fetch user data: $e');
        }
      } else {
        print('No user logged in');
      }
      
    } catch (e) {
      print('❌ Firestore connection test failed: $e');
      
      // Extra debugging
      try {
        await FirebaseFirestore.instance.enableNetwork();
        print('Enabled network for Firestore');
      } catch (netError) {
        print('Failed to enable network: $netError');
      }
    }

    // Controleer de Firestore-instellingen
    try {
      final settings = await FirebaseFirestore.instance.settings;
      print('Firestore persistence enabled: ${settings.persistenceEnabled}');
      print('Firestore cache size: ${settings.cacheSizeBytes == -1 ? "Unlimited" : settings.cacheSizeBytes}');
    } catch (e) {
      print('Error checking Firestore settings: $e');
    }
    
  } catch (e) {
    print('❌❌❌ Critical error initializing Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerState()),
      ],
      child: MaterialApp(
        title: 'Time2Bill',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B5394)),
          useMaterial3: true,
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        ),
        builder: (context, child) {
          // Wrap hele app in connectivity monitor
          return FirebaseConnectivityMonitor(
            child: child ?? const SizedBox(),
          );
        },
        routes: {
          '/': (context) => const LandingPageWidget(),
          '/features': (context) => const FeaturesPageWidget(),
          '/about': (context) => const AboutPageWidget(),
          '/login': (context) => const LoginPageWidget(),
          '/register': (context) => const RegisterPageWidget(),
          '/dashboard': (context) => const DashboardPage(),
          '/projects': (context) => const ProjectsPage(),
          '/project-detail': (context) => const ProjectDetailPage(),
          '/time-tracking': (context) => const TimeTrackingPage(),
          '/invoices': (context) => const InvoicesPage(),
          '/clients': (context) => const ClientsPage(),
          '/reports': (context) => const ReportsPage(),
          '/settings': (context) => const SettingsPage(),
          '/profile': (context) => const ProfilePage(),
        },
        initialRoute: '/',
      ),
    );
  }
}