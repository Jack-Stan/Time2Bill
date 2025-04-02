import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/auth_service.dart';

enum RegistrationStep {
  personalInfo,
  emailVerification,
  businessDetails,
  paymentSetup,
  complete
}

class RegisterPageWidget extends StatefulWidget {
  const RegisterPageWidget({super.key});

  @override
  State<RegisterPageWidget> createState() => _RegisterPageWidgetState();
}

class _RegisterPageWidgetState extends State<RegisterPageWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _peppolIdController = TextEditingController();
  final Color primaryColor = const Color(0xFF0B5394);
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  RegistrationStep _currentStep = RegistrationStep.personalInfo;
  bool _emailVerified = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: Stepper(
            currentStep: _currentStep.index,
            onStepContinue: _handleNextStep,
            onStepCancel: _handlePreviousStep,
            steps: [
              _buildPersonalInfoStep(),
              _buildEmailVerificationStep(),
              _buildBusinessDetailsStep(),
              _buildPaymentSetupStep(),
              _buildCompleteStep(),
            ],
          ),
        ),
      ),
    );
  }

  Step _buildPersonalInfoStep() {
    return Step(
      title: const Text('Personal Information'),
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleInitialRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Continue',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
      isActive: _currentStep == RegistrationStep.personalInfo,
    );
  }

  Step _buildEmailVerificationStep() {
    return Step(
      title: const Text('Email Verification'),
      content: Column(
        children: [
          const Text('Please check your email and verify your account.'),
          ElevatedButton(
            onPressed: _checkEmailVerification,
            child: const Text('I have verified my email'),
          ),
        ],
      ),
      isActive: _currentStep == RegistrationStep.emailVerification,
    );
  }

  Step _buildBusinessDetailsStep() {
    return Step(
      title: const Text('Business Details'),
      content: Form(
        child: Column(
          children: [
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
            ),
            TextFormField(
              controller: _vatNumberController,
              decoration: const InputDecoration(labelText: 'VAT Number'),
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Business Address'),
            ),
          ],
        ),
      ),
      isActive: _currentStep == RegistrationStep.businessDetails,
    );
  }

  Step _buildPaymentSetupStep() {
    return Step(
      title: const Text('Payment Setup (Optional)'),
      content: Column(
        children: [
          TextFormField(
            controller: _peppolIdController,
            decoration: const InputDecoration(labelText: 'Peppol ID (Optional)'),
          ),
          // Add payment integration options here
        ],
      ),
      isActive: _currentStep == RegistrationStep.paymentSetup,
    );
  }

  Step _buildCompleteStep() {
    return Step(
      title: const Text('Complete'),
      content: Column(
        children: [
          const Text('Registration Complete!'),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            child: const Text('Start Using Time2Bill'),
          ),
        ],
      ),
      isActive: _currentStep == RegistrationStep.complete,
    );
  }

  void _handleInitialRegistration() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final userCred = await _authService.registerUser(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );
        
        await _authService.sendEmailVerification();
        setState(() => _currentStep = RegistrationStep.emailVerification);
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'An error occurred during registration';
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

  void _checkEmailVerification() async {
    await FirebaseAuth.instance.currentUser?.reload();
    if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
      setState(() {
        _emailVerified = true;
        _currentStep = RegistrationStep.businessDetails;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your email first')),
      );
    }
  }

  void _handleNextStep() {
    if (_currentStep == RegistrationStep.businessDetails) {
      _saveBusinessDetails();
    }
    setState(() {
      if (_currentStep.index < RegistrationStep.values.length - 1) {
        _currentStep = RegistrationStep.values[_currentStep.index + 1];
      }
    });
  }

  void _handlePreviousStep() {
    setState(() {
      if (_currentStep.index > 0) {
        _currentStep = RegistrationStep.values[_currentStep.index - 1];
      }
    });
  }

  Future<void> _saveBusinessDetails() async {
    await _authService.updateBusinessDetails(
      userId: FirebaseAuth.instance.currentUser!.uid,
      companyName: _companyNameController.text,
      vatNumber: _vatNumberController.text,
      address: _addressController.text,
      peppolId: _peppolIdController.text,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _vatNumberController.dispose();
    _addressController.dispose();
    _peppolIdController.dispose();
    super.dispose();
  }
}
