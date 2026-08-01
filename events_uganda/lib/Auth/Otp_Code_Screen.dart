import 'dart:async';
import 'package:events_uganda/Auth/Reset_Password_Screen.dart';
import 'package:events_uganda/Auth/Sign_In_Screen.dart';
import 'package:events_uganda/Auth/otp_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPCodeScreen extends StatefulWidget {
  final String email;

  const OTPCodeScreen({super.key, required this.email});

  @override
  State<OTPCodeScreen> createState() => _OTPCodeScreenState();
}

class _OTPCodeScreenState extends State<OTPCodeScreen> {
  static const int _otpLength = 4;
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  int _countdown = 60;
  bool _isButtonEnabled = false;
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
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
      await _verifyOTP(otp);
    }
  }

  Future<void> _verifyOTP(String otp) async {
    final input = widget.email;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            email: input,
            otp: otp,
          ),
        ),
      );
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
    setState(() => _isLoading = true);

    try {
      final input = widget.email;
      String? email;
      String? phone;

      if (input.contains('@')) {
        email = input;
      } else {
        phone = input;
      }

      await OtpApiService.sendOtp(email: email, phone: phone);
    } catch (_) {
      // Silently handle - user can try again
    }

    setState(() => _isLoading = false);
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
    final otpLength = _otpLength;

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
                        top: screenHeight * 0.00,
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
                                      ).withValues(alpha: 0.3),
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
                                      ).withValues(alpha: 0.3),
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
                                        ),
                                      ),
                                      TextSpan(
                                        text: contactTarget,
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.042,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0XFF825E34),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.04),

                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(_otpLength, (index) {
                                    final otpBoxWidth = screenWidth * 0.12;
                                    final otpBoxHeight = screenWidth * 0.15;

                                    return Container(
                                      width: otpBoxWidth,
                                      height: otpBoxHeight,
                                      margin: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.01,
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
                                              keyboardType:
                                                  TextInputType.number,
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
                                                final trimmedValue = value
                                                    .trim();
                                                if (trimmedValue.isNotEmpty &&
                                                    index < _otpLength - 1) {
                                                  _controllers[index].text =
                                                      trimmedValue;
                                                  _focusNodes[index].unfocus();
                                                  _focusNodes[index + 1]
                                                      .requestFocus();
                                                } else if (trimmedValue
                                                        .isEmpty &&
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

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.038,
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
