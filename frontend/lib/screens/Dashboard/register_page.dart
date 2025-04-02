import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../../models/business_details.dart';

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
  final _businessFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _vatNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _peppolIdController = TextEditingController();
  final Color primaryColor = const Color(0xFF0B5394);
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  String? _errorMessage;
  RegistrationStep _currentStep = RegistrationStep.personalInfo;
  bool _emailVerified = false;

  @override
  void initState() {
    super.initState();
    // Check if user needs to resume registration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['resumeStep'] == 'businessDetails') {
        setState(() {
          _currentStep = RegistrationStep.businessDetails;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent going back if resuming registration
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return args?['resumeStep'] == null;
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    Stepper(
                      type: StepperType.vertical,
                      currentStep: _currentStep.index,
                      controlsBuilder: (context, details) {
                        if (_currentStep == RegistrationStep.personalInfo ||
                            _currentStep == RegistrationStep.emailVerification) {
                          return const SizedBox.shrink(); // Hide controls for these steps
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            children: [
                              if (_currentStep.index > 0)
                                TextButton(
                                  onPressed: _handlePreviousStep,
                                  child: const Text('Back'),
                                ),
                              const SizedBox(width: 12),
                              if (_currentStep != RegistrationStep.complete)
                                ElevatedButton(
                                  onPressed: _handleNextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                  ),
                                  child: Text(_currentStep == RegistrationStep.paymentSetup
                                      ? 'Skip'
                                      : 'Continue'),
                                ),
                            ],
                          ),
                        );
                      },
                      steps: [
                        _buildPersonalInfoStep(),
                        _buildEmailVerificationStep(),
                        _buildBusinessDetailsStep(),
                        _buildPaymentSetupStep(),
                        _buildCompleteStep(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _errorMessage!.replaceAll('Exception: ', ''),
        style: TextStyle(color: Colors.red.shade900),
        textAlign: TextAlign.center,
      ),
    );
  }

  Step _buildPersonalInfoStep() {
    return Step(
      title: const Text('Personal Information'),
      content: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                      return 'Please enter a valid email';
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
                    helperText: 'Must contain at least 8 characters, uppercase, lowercase, number and special character',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (!_isPasswordStrong(value)) {
                      return 'Password is not strong enough';
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
                _buildErrorMessage(),
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
        key: _businessFormKey,
        child: Column(
          children: [
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Company name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _vatNumberController,
              decoration: const InputDecoration(
                labelText: 'VAT Number *',
                border: OutlineInputBorder(),
                helperText: 'Format: BE0123456789',
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'VAT number is required';
                if (!RegExp(r'^BE\d{10}$').hasMatch(value!)) {
                  return 'Invalid VAT number format';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Business Address *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Business address is required' : null,
            ),
          ],
        ),
      ),
      isActive: _currentStep == RegistrationStep.businessDetails,
      state: _validateBusinessDetailsStep() ? StepState.complete : StepState.error,
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
        ],
      ),
      isActive: _currentStep == RegistrationStep.paymentSetup,
      state: StepState.indexed,
    );
  }

  Step _buildCompleteStep() {
    final allStepsValid = _validateAllRequiredSteps();
    
    return Step(
      title: const Text('Complete'),
      content: Column(
        children: [
          if (!allStepsValid)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Please complete all required steps before proceeding',
                style: TextStyle(color: Colors.red),
              ),
            ),
          const Text('Registration Complete!'),
          ElevatedButton(
            onPressed: allStepsValid 
              ? () => Navigator.pushReplacementNamed(context, '/dashboard')
              : null,
            child: const Text('Start Using Time2Bill'),
          ),
        ],
      ),
      isActive: _currentStep == RegistrationStep.complete,
      state: allStepsValid ? StepState.complete : StepState.error,
    );
  }

  void _handleInitialRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Passwords do not match';
        });
        return;
      }

      if (!_isPasswordStrong(_passwordController.text)) {
        setState(() {
          _errorMessage = 'Password must be at least 8 characters long and contain uppercase, lowercase, number and special character';
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creating account...')),
        );

        await _firebaseService.registerUser(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully!')),
        );

        setState(() => _currentStep = RegistrationStep.emailVerification);
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  void _checkEmailVerification() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      if (!mounted) return;

      if (FirebaseAuth.instance.currentUser?.emailVerified ?? false) {
        setState(() {
          _currentStep = RegistrationStep.businessDetails;
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please verify your email first')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleNextStep() {
    setState(() {
      switch (_currentStep) {
        case RegistrationStep.personalInfo:
          // Already handled by registration button
          break;
        case RegistrationStep.emailVerification:
          // Handled by verification button
          break;
        case RegistrationStep.businessDetails:
          if (_businessFormKey.currentState?.validate() ?? false) {
            _saveBusinessDetails();
            _currentStep = RegistrationStep.paymentSetup;
          }
          break;
        case RegistrationStep.paymentSetup:
          // Optional step, can always proceed
          _currentStep = RegistrationStep.complete;
          break;
        case RegistrationStep.complete:
          if (!_validateAllRequiredSteps()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please complete all required steps first')),
            );
            return;
          }
          Navigator.pushReplacementNamed(context, '/dashboard');
          break;
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
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firebaseService.updateBusinessDetails(
      user.uid,
      BusinessDetails(
        companyName: _companyNameController.text,
        kboNumber: '', // Add required fields
        vatNumber: _vatNumberController.text,
        address: _addressController.text,
        legalForm: '', // Add required fields
        iban: '', // Add required fields
        defaultVatRate: 21,
        paymentTerms: 30,
        peppolId: _peppolIdController.text.isEmpty ? null : _peppolIdController.text, // Make optional
        phone: '', 
        website: '',
      ),
    );
  }

  bool _validateAllRequiredSteps() {
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false &&
           _validateBusinessDetailsStep();
  }

  bool _validateBusinessDetailsStep() {
    return _companyNameController.text.isNotEmpty &&
           _vatNumberController.text.isNotEmpty &&
           _addressController.text.isNotEmpty;
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