import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    
    // Vervang de oude methode door de nieuwe aanbevolen methode
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    
    print('Firestore persistence configured with modern settings');
    
    // Maak initiële Firestore verbinding
    try {
      await FirebaseFirestore.instance.collection('system').doc('status').get();
      print('Firestore connection test successful');
    } catch (e) {
      print('Firestore connection test failed: $e');
      
      // Probeer direct naar users collectie te schrijven voor debugging
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          print('Current user UID: ${user.uid}');
        } else {
          print('No user logged in');
        }
      } catch (authError) {
        print('Auth error: $authError');
      }
    }

    // Controleer Firebase connectie
    try {
      final settings = await FirebaseFirestore.instance.settings;
      print('Firestore settings: ${settings.persistenceEnabled}');
    } catch (e) {
      print('Error checking Firestore settings: $e');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
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
        ),
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
          '/invoices': (context) => const PlaceholderPage(title: 'Invoices'),
          '/clients': (context) => const PlaceholderPage(title: 'Clients'),
          '/reports': (context) => const PlaceholderPage(title: 'Reports'),
          '/settings': (context) => const PlaceholderPage(title: 'Settings'),
          '/profile': (context) => const ProfilePage(),
        },
        initialRoute: '/',
      ),
    );
  }
}