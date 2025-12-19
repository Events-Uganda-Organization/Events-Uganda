import 'package:events_uganda/Auth/Otp_Code_Screen.dart';
import 'package:events_uganda/Auth/Reset_Password_Screen.dart';
import 'package:events_uganda/Auth/Sign_In_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _verificationId;
  int? _resendToken;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // Generate 4-digit OTP
  String _generateOTP() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  // Check if input is phone number or email
  bool _isPhoneNumber(String input) {
    // Check if it's a Ugandan phone number (starts with 0 or +256)
    final phoneRegex = RegExp(r'^(\+256|0)[37]\d{8}$');
    return phoneRegex.hasMatch(input.replaceAll(' ', ''));
  }

  // Format Ugandan phone number to international format
  String _formatPhoneNumber(String phone) {
    phone = phone.replaceAll(' ', '');
    if (phone.startsWith('0')) {
      return '+256${phone.substring(1)}';
    } else if (!phone.startsWith('+')) {
      return '+256$phone';
    }
    return phone;
  }

  // Send OTP via Firebase Phone Auth
  Future<void> _sendPhoneOTP(String phoneNumber) async {
    try {
      // Force native flow (no web redirect) by ensuring we're on Android/iOS
      if (kIsWeb) {
        throw Exception('Phone auth not supported on web');
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: _formatPhoneNumber(phoneNumber),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only) - instant verification
          print('Auto-verification completed');
          // Don't sign in here, just navigate to OTP screen
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          print('Verification failed: ${e.code} - ${e.message}');

          String errorMessage = 'Failed to send OTP';
          if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format';
          } else if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please try again later';
          } else if (e.code == 'network-request-failed') {
            errorMessage = 'Network error. Check your connection';
          } else {
            errorMessage = e.message ?? 'Failed to send OTP';
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Code sent successfully. VerificationId: $verificationId');
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF1BCC94),
              content: Text(
                'OTP sent to your phone',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OTPCodeScreen(
                email: _emailController.text.trim(),
                verificationId: verificationId,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto-retrieval timeout. VerificationId: $verificationId');
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Send OTP via email (stored in Firestore)
  Future<void> _sendEmailOTP(String email) async {
    try {
      final otp = _generateOTP();
      final expiryTime = DateTime.now().add(const Duration(minutes: 10));

      // Store OTP in Firestore
      await _firestore.collection('otp_codes').doc(email).set({
        'otp': otp,
        'email': email,
        'expiryTime': expiryTime,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Trigger Firebase Extension "Trigger Email" (or custom function) by writing to 'mail'
      // Install extension from Firebase Console and configure SMTP provider (Gmail/SendGrid/Mailgun)
      await _firestore.collection('mail').add({
        'to': email,
        'message': {
          'subject': 'Your OTP Code - Events Uganda',
          'html':
              '''
            <div style="font-family: Arial, sans-serif; padding: 20px;">
              <h2>Password Reset OTP</h2>
              <p>Your OTP code is:</p>
              <h1 style="color: #D59A00; letter-spacing: 5px;">$otp</h1>
              <p>This code will expire in 10 minutes.</p>
              <p>If you didn't request this, please ignore this email.</p>
              <br>
              <p>Best regards,<br/>Events Uganda Team</p>
            </div>
          ''',
        },
      });

      // Dev-only: log OTP locally (remove in production)
      // print('OTP for $email: $otp');

      setState(() => _isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              OTPCodeScreen(email: email, verificationId: null),
        ),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent to your email')));
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending OTP: $e')));
    }
  }

  // Send OTP based on input type
  Future<void> _sendOTP() async {
    final input = _emailController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email or phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    if (_isPhoneNumber(input)) {
      await _sendPhoneOTP(input);
    } else if (input.contains('@')) {
      await _sendEmailOTP(input);
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email or phone number'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Reduced vector size
    final double vectBaseWidth = screenWidth * 0.10;
    final double vectWidth = vectBaseWidth;
    final double vectHeight = vectBaseWidth * (91 / 67);

    final double leftVectPadding = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Background PNG image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/backgroundcolors/forgotpasswordscreen.png',
                width: screenWidth,
                height: screenHeight * 0.9,
                fit: BoxFit.cover,
              ),
            ),

            // Back arrow button
            Positioned(
              top: screenHeight * 0.04,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: screenWidth * 0.13,
                  height: screenWidth * 0.13,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9EF6DA),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: screenWidth * 0.10,
                    ),
                  ),
                ),
              ),
            ),

            // Logo
            Positioned(
              top: screenHeight * 0.0,
              left: (screenWidth - screenWidth * 0.25) / 2,
              child: Image.asset(
                'assets/vectors/logo.png',
                width: screenWidth * 0.30,
                height: screenWidth * 0.30,
                fit: BoxFit.contain,
              ),
            ),

            // Left decorative vector
            Positioned(
              top: screenHeight * 0.15,
              left: leftVectPadding,
              child: Image.asset(
                'assets/vectors/forgotpasswordvect.png',
                width: vectWidth,
                height: vectHeight,
                fit: BoxFit.contain,
              ),
            ),

            // Right decorative vector
            Positioned(
              top: screenHeight * 0.20,
              right: screenWidth * 0.08,
              child: Image.asset(
                'assets/vectors/forgotpasswordvect.png',
                width: vectWidth,
                height: vectHeight,
                fit: BoxFit.contain,
              ),
            ),

            // Title text
            Positioned(
              top:
                  screenHeight * 0.03 +
                  screenWidth * 0.22 +
                  screenHeight * 0.015,
              left: 0,
              right: 0,
              child: const Center(
                child: Text(
                  "Let's get you\nsorted!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            // White container at the bottom
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.10 +
                  MediaQuery.of(context).size.width * 0.22 +
                  MediaQuery.of(context).size.height * 0.015 +
                  MediaQuery.of(context).size.width * 0.13,
              left: screenWidth * 0.03,
              right: screenWidth * 0.03,
              bottom: 0,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Top-left stone
                    Positioned(
                      top: screenHeight * 0.0,
                      left: -screenWidth * 0.12,
                      child: Image.asset(
                        'assets/vectors/forgotpasswordstone.png',
                        width: screenWidth * 0.35,
                        height: screenWidth * 0.35,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Bottom-right stone (flipped)
                    Positioned(
                      bottom: -screenHeight * 0.05,
                      right: -screenWidth * 0.12,
                      child: Transform.flip(
                        flipX: true,
                        child: Image.asset(
                          'assets/vectors/forgotpasswordstone.png',
                          width: screenWidth * 0.35,
                          height: screenWidth * 0.35,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Form content
                    Padding(
                      padding: EdgeInsets.only(
                        top: screenHeight * 0.015,
                        left: 0,
                        right: 0,
                        bottom: 0,
                      ),
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: screenHeight * 1.2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),

                              // Three horizontal dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF1BCC94),
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 15,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1BCC94,
                                      ).withOpacity(0.3),
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 15,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF1BCC94,
                                      ).withOpacity(0.3),
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.03),

                              // Large mail icon
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1BCC94),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(50),
                                    topRight: Radius.circular(50),
                                    bottomRight: Radius.circular(50),
                                    bottomLeft: Radius.circular(0),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mail,
                                  size: 50,
                                  color: Colors.black,
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.03),

                              // Title
                              Text(
                                "Forgot Your Password?",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.06,
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.01),

                              // Description
                              Text(
                                'Please enter your email address or\nPhone Number below to receive an OTP code.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Abril Fatface',
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.04),

                              // Email field
                              _ResponsiveTextField(
                                controller: _emailController,
                                label: 'Email/Phone Number',
                                hint: 'Enter Your Email/ Phone Number',
                                icon: Icons.person,
                                focusNode: _emailFocus,
                                nextFocusNode: _emailFocus,
                                textInputAction: TextInputAction.done,
                                iconColor: const Color(0xFF0F3D2E),
                              ),

                              SizedBox(height: screenHeight * 0.04),

                              // Submit Button
                              Container(
                                width: screenWidth * 0.8,
                                height: screenWidth * 0.13,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: const Color(0xFF1BCC94),
                                    width: 1,
                                  ),
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFFE0E7FF),
                                      Color(0xFF1BCC94),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(30),
                                    onTap: _isLoading ? null : _sendOTP,
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.black),
                                              ),
                                            )
                                          : Text(
                                              'Submit',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.w800,
                                                fontFamily: 'Montserrat',
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.04),

                              // Sign In link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.038,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SignInScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: const Color(0xFF1BCC94),
                                        fontSize: screenWidth * 0.040,
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reusable Responsive TextField with thin border
class _ResponsiveTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode focusNode;
  final FocusNode nextFocusNode;
  final TextInputAction textInputAction;
  final Color iconColor;

  const _ResponsiveTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.focusNode,
    required this.nextFocusNode,
    required this.textInputAction,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.8,
      height: screenWidth * 0.13,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: textInputAction,
        keyboardType: TextInputType.emailAddress,
        style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: iconColor, size: 30),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 10,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF1BCC94), width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF1BCC94), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFF1BCC94), width: 1.8),
          ),
        ),
        onSubmitted: (_) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        },
      ),
    );
  }
}
