import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'screens/Landingscreen/LandingPage.dart';
import 'screens/Featuresscreen/FeaturesPage.dart';
import 'screens/Aboutscreen/AboutPage.dart';
import 'screens/Authscreen/LoginPage.dart';
import 'screens/Authscreen/register_page.dart';
import 'screens/Dashboard/dashboard_page.dart';
import 'screens/Dashboard/models/timer_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        },
        initialRoute: '/',
      ),
    );
  }
}