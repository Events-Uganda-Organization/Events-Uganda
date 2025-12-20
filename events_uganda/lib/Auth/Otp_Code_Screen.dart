import 'dart:async';
import 'package:events_uganda/Auth/Reset_Password_Screen.dart';
import 'package:events_uganda/Auth/Sign_In_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OTPCodeScreen extends StatefulWidget {
  final String email;
  final String? verificationId; // For phone OTP

  const OTPCodeScreen({super.key, required this.email, this.verificationId});

  @override
  State<OTPCodeScreen> createState() => _OTPCodeScreenState();
}

class _OTPCodeScreenState extends State<OTPCodeScreen> {
  late final int _otpLength;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _countdown = 60;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 6 digits for phone verification, 4 for email OTP
    _otpLength = widget.verificationId != null ? 6 : 4;
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    print('OTPCodeScreen received email: ${widget.email}'); // Debug print
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _checkOTPAndNavigate() async {
    String otp = _controllers.map((controller) => controller.text).join();
    if (otp.length == _otpLength) {
      // Verify OTP
      await _verifyOTP(otp);
    }
  }

  // Verify phone OTP
  Future<void> _verifyPhoneOTP(String otp) async {
    try {
      if (widget.verificationId == null) return;

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId!,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verified successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invalid OTP: $e')));
        // Clear OTP fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  // Verify email OTP
  Future<void> _verifyEmailOTP(String otp) async {
    try {
      final doc = await _firestore
          .collection('otp_codes')
          .doc(widget.email)
          .get();

      if (!doc.exists) {
        throw 'OTP not found';
      }

      final data = doc.data()!;
      final storedOTP = data['otp'] as String;
      final expiryTime = (data['expiryTime'] as Timestamp).toDate();

      if (DateTime.now().isAfter(expiryTime)) {
        throw 'OTP has expired';
      }

      if (storedOTP != otp) {
        throw 'Invalid OTP';
      }

      // OTP is valid, delete it
      await _firestore.collection('otp_codes').doc(widget.email).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified successfully!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResetPasswordScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        // Clear OTP fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    }
  }

  // Main verification method
  Future<void> _verifyOTP(String otp) async {
    if (widget.verificationId != null) {
      // Phone OTP
      await _verifyPhoneOTP(otp);
    } else {
      // Email OTP
      await _verifyEmailOTP(otp);
    }
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
      _isButtonEnabled = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _isButtonEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final contactTarget = widget.email.trim().isEmpty
        ? 'your email/phone'
        : widget.email.trim();
    final contactLabel = contactTarget.contains('@') ? 'email' : 'phone number';

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
                'assets/backgroundcolors/otpcodescreen.png',
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
                    color: const Color(0xFFF3CA9B),
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
                'assets/vectors/otpcodevect.png',
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
                'assets/vectors/otpcodevect.png',
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
                      left: -screenWidth * 0.19,
                      child: Image.asset(
                        'assets/vectors/otpcodestone.png',
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
                          'assets/vectors/otpcodestone.png',
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
                                    width: 15,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF825E34,
                                      ).withOpacity(0.3),
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 18,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF825E34),
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
                                        0xFF825E34,
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
                                  color: Color(0xFF825E34),
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

                              SizedBox(
                                width: screenWidth * 0.8,
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.04,
                                      fontFamily: 'Poppins',
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            'Please enter the $_otpLength digit code we sent to\n',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.04,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                      TextSpan(
                                        text: contactTarget,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.042,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0XFF825E34),
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.04),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_otpLength, (index) {
                                  final otpBoxWidth = screenWidth * 0.15;
                                  final otpBoxHeight = screenWidth * 0.20;

                                  return Container(
                                    width: otpBoxWidth,
                                    height: otpBoxHeight,
                                    margin: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.02,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color.fromARGB(
                                          255,
                                          196,
                                          141,
                                          2,
                                        ),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.bottomCenter,
                                      children: [
                                        Positioned(
                                          bottom: otpBoxHeight * 0.15,
                                          child: Container(
                                            width: otpBoxWidth * 0.5,
                                            height: 2,
                                            color: const Color(0xFFD59A00),
                                          ),
                                        ),
                                        Center(
                                          child: TextFormField(
                                            controller: _controllers[index],
                                            focusNode: _focusNodes[index],
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            maxLength: 1,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                1,
                                              ),
                                            ],
                                            decoration: const InputDecoration(
                                              counterText: '',
                                              border: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.06,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontFamily: 'Poppins',
                                              height: 1.0,
                                            ),
                                            cursorColor: const Color(
                                              0xFFD59A00,
                                            ),
                                            onChanged: (value) {
                                              final trimmedValue = value.trim();
                                              if (trimmedValue.isNotEmpty &&
                                                  index < _otpLength - 1) {
                                                _controllers[index].text =
                                                    trimmedValue;
                                                _focusNodes[index].unfocus();
                                                _focusNodes[index + 1]
                                                    .requestFocus();
                                              } else if (trimmedValue.isEmpty &&
                                                  index > 0) {
                                                _focusNodes[index].unfocus();
                                                _focusNodes[index - 1]
                                                    .requestFocus();
                                              }
                                              _checkOTPAndNavigate();
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),

                              SizedBox(height: screenHeight * 0.05),

                              GestureDetector(
                                onTap: (_isButtonEnabled && !_isLoading)
                                    ? _resendOTP
                                    : null,
                                child: Container(
                                  width: screenWidth * 0.5,
                                  height: screenHeight * 0.06,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isButtonEnabled && !_isLoading
                                          ? [
                                              const Color(0xFFE0E7FF),
                                              const Color(0xFFD59A00),
                                            ]
                                          : [
                                              Colors.grey[300]!,
                                              Colors.grey[500]!,
                                            ],
                                      stops: [0.0, 0.47],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: Color(0xFF825E34),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.refresh,
                                        color: Colors.white,
                                        size: screenWidth * 0.06,
                                      ),
                                      SizedBox(width: screenWidth * 0.03),
                                      Text(
                                        _countdown > 0
                                            ? '$_countdown'
                                            : 'Resend',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    ],
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
                                        color: const Color(0xFFD59A00),
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
