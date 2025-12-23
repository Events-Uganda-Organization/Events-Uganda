import 'package:events_uganda/Auth/Sign_In_Screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Update password in Firestore
  Future<void> _changePassword() async {
    final newPassword = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Passwords do not match!'),
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Password must be at least 6 characters'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw 'User not authenticated';
      }

      // Hash the new password
      final hashedPassword = _hashPassword(newPassword);

      // Update password in Firestore users collection
      await _firestore.collection('users').doc(user.uid).update({
        'password': hashedPassword,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also update Firebase Auth password
      await user.updatePassword(newPassword);

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFF23598),
            content: Text(
              'Password changed successfully!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );

        // Navigate to sign in screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error changing password: $e'),
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
                'assets/backgroundcolors/resetpasswordscreen.png',
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
                    color: const Color.fromARGB(255, 230, 96, 163),
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
                'assets/vectors/resetpasswordvect.png',
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
                'assets/vectors/resetpasswordvect.png',
                width: vectWidth,
                height: vectHeight,
                fit: BoxFit.contain,
              ),
            ),
        
            // Title text
            Positioned(
              top:
                  screenHeight * 0.03 + screenWidth * 0.22 + screenHeight * 0.015,
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
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
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
                        'assets/vectors/resetpasswordstone.png',
                        width: screenWidth * 0.33,
                        height: screenWidth * 0.33,
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
                          'assets/vectors/resetpasswordstone.png',
                          width: screenWidth * 0.33,
                          height: screenWidth * 0.33,
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
                                        0xFFF23598,
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
                                        0xFFF23598,
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
                                      color: Color(0xFFF23598),
                                      shape: BoxShape.rectangle,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ],
                              ),
        
                              SizedBox(height: screenHeight * 0.03),
        
                              // Large lock icon
                              Container(
                                padding: const EdgeInsets.all(20),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF23598),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(50),
                                      topRight: Radius.circular(50),
                                      bottomRight: Radius.circular(50),
                                      bottomLeft: Radius.circular(0),
                                    ),
                                  ),
                                child: const Icon(
                                  Icons.lock,
                                  size: 50,
                                  color: Colors.black,
                                ),
                              ),
        
                              SizedBox(height: screenHeight * 0.03),
        
                              // Title
                              Text(
                                " Reset Your Password ",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.07,
                                ),
                              ),
        
                              SizedBox(height: screenHeight * 0.01),
        
                              // Description
                              Text(
                                'Create a new password for your',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Abril Fatface',
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
        
                              Text(
                                'account below.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Abril Fatface',
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
        
                              SizedBox(height: screenHeight * 0.04),
        
                              // New password field
                              ResetPasswordTextField(
                                controller: _passwordController,
                                label: 'New Password',
                                hint: 'Enter Your New Password',
                                icon: Icons.lock,
                                focusNode: _passwordFocus,
                                nextFocusNode: _confirmPasswordFocus,
                                textInputAction: TextInputAction.next,
                                iconColor:  Colors.black,
                              ),
        
                              SizedBox(height: screenHeight * 0.04),
        
                              // Confirm new password field
                              ResetPasswordTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                hint: 'Confirm Your Password',
                                icon: Icons.lock,
                                focusNode: _confirmPasswordFocus,
                                textInputAction: TextInputAction.done,
                                iconColor:  Colors.black,
                              ),
        
                              SizedBox(height: screenHeight * 0.04),
        
                              // Submit Button
                              Container(
                                width: screenWidth * 0.8,
                                height: screenWidth * 0.13,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                  color: const Color(0xFFF23598),
                                  width: 1,
                                ),
                                  gradient: const LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFFE0E7FF),
                                      Color(0xFFEC2A8B),
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
                                      // Handle submit
                                    },
                                    child: Center(
                                      child: Text(
                                        'Change Password',
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
                              SizedBox(height: screenHeight * 0.03),
        
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
                                        color: const Color(0xFFEC2A8B),
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

// Reusable Responsive TextField with thin border and password visibility toggle
class ResetPasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;
  final TextInputAction textInputAction;
  final Color iconColor;

  const ResetPasswordTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.focusNode,
    this.nextFocusNode,
    required this.textInputAction,
    required this.iconColor,
  });

  @override
  State<ResetPasswordTextField> createState() => _ResetPasswordTextFieldState();
}

class _ResetPasswordTextFieldState extends State<ResetPasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.8,
      height: screenWidth * 0.13,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: _obscureText,
        textInputAction: widget.textInputAction,
        keyboardType: TextInputType.visiblePassword,
        style: TextStyle(fontSize: screenWidth * 0.045, color: Colors.black),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon, color: widget.iconColor, size: 30),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: widget.iconColor,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 10,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFF23598), width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFF23598), width: 0.8),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Color(0xFFF23598), width: 1.8),
          ),
        ),
        onSubmitted: (_) {
          if (widget.nextFocusNode != null) {
            FocusScope.of(context).requestFocus(widget.nextFocusNode);
          } else {
            FocusScope.of(context).unfocus();
          }
        },
      ),
    );
  }
}
