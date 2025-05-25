import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';

import 'screens/Landingscreen/landing_page_wrapper.dart';
import 'screens/Featuresscreen/FeaturesPage.dart';
import 'screens/HowItWorksscreen/HowItWorksPage.dart';
import 'screens/Aboutscreen/AboutPage.dart';
import 'screens/Authscreen/LoginPage.dart';
import 'screens/Authscreen/register_page.dart';
import 'screens/Dashboard/dashboard_page.dart';
import 'screens/Dashboard/models/timer_state.dart';
import 'screens/Projects/projects_page.dart';
import 'screens/Projects/project_detail_page.dart';
import 'screens/TimeTracking/time_tracking_page.dart';
import 'screens/Profile/profile_page.dart';
import 'screens/Invoices/invoices_page.dart';
import 'screens/Clients/clients_page.dart';
import 'screens/Reports/reports_page.dart';
import 'screens/Settings/settings_page.dart';
import 'widgets/firebase_connectivity_monitor.dart';
import 'screens/Invoices/edit_invoice_template_page.dart';

void _configureApp() {
  if (kIsWeb) {
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null && message.contains('error')) {
        print(message);
      }
    };

    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('transform matrix') ||
          details.exception.toString().contains('hit test') ||
          details.exception.toString().contains('mouse tracker') ||
          details.exception.toString().contains('Vector4') ||
          details.exception.toString().contains('_debugDuringDeviceUpdate')) {
        return;
      }
      FlutterError.presentError(details);
    };

    timeDilation = 0.8;

    if (!kReleaseMode) {
      debugPrint('Disabled debug profiling for better performance');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _configureApp();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

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

    final settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    FirebaseFirestore.instance.settings = settings;
    print('Firestore persistence configured with modern settings');

    try {
      final timeoutDuration = Duration(seconds: 15);
      print('Testing Firestore connection (timeout: ${timeoutDuration.inSeconds}s)...');

      await FirebaseFirestore.instance.collection('system').doc('status').get()
          .timeout(timeoutDuration);
      print('✅ Firestore connection test successful');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Current user UID: ${user.uid}');
        print('Email verified: ${user.emailVerified}');

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

      try {
        await FirebaseFirestore.instance.enableNetwork();
        print('Enabled network for Firestore');
      } catch (netError) {
        print('Failed to enable network: $netError');
      }
    }

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
          visualDensity: VisualDensity.compact,
          textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
          platform: kIsWeb ? TargetPlatform.macOS : null,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.android: ZoomPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            },
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            constraints: BoxConstraints(maxWidth: double.infinity),
          ),
          dialogTheme: const DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
        builder: (context, child) {
          ErrorWidget.builder = (FlutterErrorDetails details) {
            if (kReleaseMode) {
              return Container(
                color: Colors.red.shade100,
                child: const Center(child: Text('Er is een fout opgetreden')),
              );
            }
            return Material(
              color: Colors.red.shade100,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    details.exception.toString(),
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          };

          if (child == null) return const SizedBox.shrink();

          if (kIsWeb) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: true,
                  dragDevices: {
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown,
                  },
                  physics: const ClampingScrollPhysics(),
                ),
                child: child,
              ),
            );
          }

          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: FirebaseConnectivityMonitor(
                  child: child,
                ),
              ),
            ),
          );
        },        routes: {
          '/': (context) => const LandingPageWrapper(),
          '/features': (context) => const FeaturesPageWidget(),
          '/how-it-works': (context) => const HowItWorksPageWidget(),
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
          '/edit-invoice-template': (context) => const EditInvoiceTemplatePage(),
        },
        initialRoute: '/',
      ),
    );
  }
}