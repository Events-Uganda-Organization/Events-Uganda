import 'package:events_uganda/Auth/Otp_Code_Screen.dart';
import 'package:events_uganda/Auth/Reset_Password_Screen.dart';
import 'package:events_uganda/Auth/Sign_In_Screen.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
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
                                label: 'Email',
                                hint: 'Enter Your Email Address',
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
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              OTPCodeScreen(),
                                        ),
                                      );
                                    },
                                    child: Center(
                                      child: Text(
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
