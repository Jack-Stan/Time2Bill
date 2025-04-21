import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final Color primaryColor = const Color(0xFF0B5394);
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureText = true;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Probeer verbinding te maken met de Firebase backend
        await _testFirebaseConnection();

        print('Attempting login with email: ${_emailController.text}');
        
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );

        if (!mounted) return;

        // Check email verification
        final user = FirebaseAuth.instance.currentUser;
        await user?.reload();
        
        if (user != null && !user.emailVerified) {
          // User is niet geverifieerd, maar nog steeds ingelogd
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please verify your email address first')),
          );
          
          // Log uit en ga naar register met emailVerification stap
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          
          Navigator.pushReplacementNamed(
            context, 
            '/register',
            arguments: {'resumeStep': 'emailVerification'},
          );
          return;
        }
        
        // Controleer of profiel compleet is
        bool isProfileComplete = false;
        try {
          isProfileComplete = await _firebaseService.isProfileComplete(user!.uid);
          print('Profile completeness check: $isProfileComplete');
        } catch (e) {
          print('Failed to check profile completeness: $e');
          // Default actie: ga naar dashboard
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/dashboard');
          return;
        }
        
        if (!isProfileComplete) {
          // Profiel is niet compleet
          if (!mounted) return;
          print('User profile is incomplete, redirecting to business details setup');
          Navigator.pushReplacementNamed(
            context, 
            '/register',
            arguments: {'resumeStep': 'businessDetails'},
          );
        } else {
          // Alles is in orde, ga naar dashboard
          if (!mounted) return;
          print('Login successful, navigating to dashboard');
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        
        // Voor debugging
        print('Firebase authentication error: ${e.code}');
        
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email. Please register first.';
            break;
          case 'wrong-password':
            errorMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address.';
            break;
          case 'user-disabled':
            errorMessage = 'This account has been disabled. Please contact support.';
            break;
          default:
            errorMessage = 'Login failed: ${e.message}';
        }
        
        setState(() {
          _errorMessage = errorMessage;
        });
      } catch (e) {
        print('General error during login: $e');
        
        setState(() {
          _errorMessage = 'An error occurred: ${e.toString()}';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Test Firebase verbinding voordat we proberen in te loggen
  Future<void> _testFirebaseConnection() async {
    try {
      // Test connectie met Firestore
      await FirebaseFirestore.instance.collection('system').doc('status').get()
        .timeout(const Duration(seconds: 10));
      print('Firebase connection test succeeded');
    } catch (e) {
      print('Firebase connection test failed: $e');
      throw Exception('Cannot connect to the server. Check your internet connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/utils/images/LogoMetTitel.jpg',
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureText,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: const Text('Don\'t have an account? Register here'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
