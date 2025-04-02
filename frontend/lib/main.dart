import 'package:flutter/material.dart';
import 'screens/Landingscreen/LandingPage.dart';
import 'screens/Featuresscreen/FeaturesPage.dart';
import 'screens/Aboutscreen/AboutPage.dart';
import 'screens/Authscreen/LoginPage.dart';
import 'screens/Authscreen/RegisterPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      },
      initialRoute: '/',
    );
  }
}