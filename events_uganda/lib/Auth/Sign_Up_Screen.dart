import 'dart:convert';
import 'dart:math';

import 'package:events_uganda/Auth/Role_Selection_Screen.dart';
import 'package:events_uganda/Auth/Sign_In_Screen.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _fullNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();

  final bool obscureText = true;
  bool _isLoading = false;

  Future<void> _signUpWithApple() async {
    setState(() => _isLoading = true);
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
        rawNonce: rawNonce,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        oauthCredential,
      );
      final user = userCredential.user;

      if (user == null) {
        _showCustomSnackBar(
          context,
          'An error occurred. Please try again later.',
        );
        return;
      }
      final Map<String, dynamic> userData = {
        'email': user.email ?? 'hidden@privaterelay.appleid.com',
        'profilePicUrl': user.photoURL,
        'authProvider': 'apple',
        'isAdmin': (user.email ?? '').toLowerCase() == 'adminuser@gmail.com',
        'fcmToken': await FirebaseMessaging.instance.getToken(),
        'lastActiveTimestamp': Timestamp.now(),
      };

      if (credential.givenName != null || credential.familyName != null) {
        final name =
            "${credential.givenName ?? ''} ${credential.familyName ?? ''}"
                .trim();
        if (name.isNotEmpty) {
          userData['fullName'] = name;
        }
      }

      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
        if (!userData.containsKey('fullName')) {
          userData['fullName'] = "Apple User";
        }
      }

      await userDocRef.set(userData, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      _showCustomSnackBar(context, 'Signed up with Apple!', isSuccess: true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
        );
      }
    } on FirebaseAuthException {
      _showCustomSnackBar(
        context,
        'Authentication failed. Please try again later.',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          break;
        case AuthorizationErrorCode.failed:
        case AuthorizationErrorCode.invalidResponse:
        case AuthorizationErrorCode.notHandled:
        case AuthorizationErrorCode.notInteractive:
        case AuthorizationErrorCode.unknown:
        case AuthorizationErrorCode.credentialExport:
        case AuthorizationErrorCode.credentialImport:
        case AuthorizationErrorCode.matchedExcludedCredential:
          _showCustomSnackBar(
            context,
            'Apple Sign-In error. Please try again.',
          );
          break;
      }
    } catch (e) {
      _showCustomSnackBar(
        context,
        'An error occurred. Please try again later.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateNonce([int length = 32]) {
    final charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _showCustomSnackBar(
    BuildContext context,
    String message, {
    bool isSuccess = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : const Color(0xFF8715C9),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();

    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _contactFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final diameter = screenWidth * 0.9;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.0, 
              right:
                  (MediaQuery.of(context).size.width +
                      MediaQuery.of(context).size.width * 1) /
                  300,
              child: Image.asset(
                'assets/backgroundcolors/signupscreen.png',
                width:
                    MediaQuery.of(context).size.width *
                    1.08, 
                height:
                    MediaQuery.of(context).size.height *
                    0.9, 
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.04,
              left: MediaQuery.of(context).size.width * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.13,
                  height: MediaQuery.of(context).size.width * 0.13,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCB9FE4),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: MediaQuery.of(context).size.width * 0.10,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.0,
              left:
                  (MediaQuery.of(context).size.width -
                      MediaQuery.of(context).size.width * 0.25) /
                  2,
              child: Image.asset(
                'assets/vectors/logo.png',
                width: MediaQuery.of(context).size.width * 0.30,
                height: MediaQuery.of(context).size.width * 0.30,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              left:
                  (MediaQuery.of(context).size.width -
                      MediaQuery.of(context).size.width * 0.15) /
                  1,
              child: Image.asset(
                'assets/vectors/signupvect.png',
                width: MediaQuery.of(context).size.width * 0.10,
                height: MediaQuery.of(context).size.width * 0.10,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              right:
                  (MediaQuery.of(context).size.width -
                      MediaQuery.of(context).size.width * 0.15) /
                  1,
              child: Image.asset(
                'assets/vectors/signupvect.png',
                width: MediaQuery.of(context).size.width * 0.10,
                height: MediaQuery.of(context).size.width * 0.10,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.03 +
                  MediaQuery.of(context).size.width * 0.22 +
                  MediaQuery.of(context).size.height * 0.015,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "Let's get you\n signed up!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                    fontSize: MediaQuery.of(context).size.width * 0.075,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.10 +
                  MediaQuery.of(context).size.width * 0.22 +
                  MediaQuery.of(context).size.height * 0.015 +
                  MediaQuery.of(context).size.width * 0.13,
              left: MediaQuery.of(context).size.width * 0.03,
              right: MediaQuery.of(context).size.width * 0.03,
              bottom: 0,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.015,
                    left: 0,
                    right: 0,
                    bottom: 0,
                  ),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height *
                            1.2, // 120% of screen height
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Sign Up",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.05,
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01,
                          ),
                          Text(
                            'Please enter the details below to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Abril Fatface',
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              fontSize:
                                  MediaQuery.of(context).size.width * 0.035,
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _ResponsiveTextField(
                            controller: _fullNameController,
                            label: 'Full Names',
                            hint: 'Enter Your Full Names',
                            icon: Icons.person,
                            focusNode: _fullNameFocus,
                            nextFocusNode: _emailFocus,
                            textInputAction: TextInputAction.next,
                            iconColor: Colors.black,
                            fontSize: screenWidth * 0.045,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _ResponsiveTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'Enter Your Email',
                            icon: Icons.mail,
                            focusNode: _emailFocus,
                            nextFocusNode: _passwordFocus,
                            textInputAction: TextInputAction.next,
                            iconColor: Colors.black,
                            fontSize: screenWidth * 0.045,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _ResponsiveTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Enter Your Password',
                            icon: Icons.lock,
                            focusNode: _passwordFocus,
                            nextFocusNode: _contactFocus,
                            textInputAction: TextInputAction.next,
                            iconColor: Colors.black,
                            fontSize: screenWidth * 0.045,
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          _ResponsiveTextField(
                            controller: _phoneController,
                            label: 'Phone',
                            hint: 'Enter Your Phone Contact',
                            icon: Icons.phone,
                            focusNode: _contactFocus,
                            nextFocusNode: _contactFocus,
                            textInputAction: TextInputAction.next,
                            iconColor: Colors.black,
                            fontSize: screenWidth * 0.045,
                            ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          Container(
                            width: screenWidth * 0.8,
                            height: screenWidth * 0.13,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF8715C9),
                                width: 1,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                stops: [0.0, 0.47],
                                colors: [Color(0XFFE0E7FF), Color(0XFF8715C9)],
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoleSelectionScreen(),
                                  ),
                                );
                                },
                                child: Center(
                                  child: Text(
                                    'Sign Up',
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
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.08,
                            ),
                            child: _OrDivider(
                              fontSize: screenWidth * 0.04,
                              horizontalPadding: screenWidth * 0.02,
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: signInWithGoogle,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.15,
                                  height:
                                      MediaQuery.of(context).size.width * 0.15,
                                  decoration: BoxDecoration(
                                    color: Color(0XFFCB9FE4),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/vectors/google.png',
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.08,
                                      height:
                                          MediaQuery.of(context).size.width *
                                          0.08,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.06,
                              ),
                              GestureDetector(
                                onTap: _signUpWithApple,
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.15,
                                  height:
                                      MediaQuery.of(context).size.width * 0.15,
                                  decoration: BoxDecoration(
                                    color: Color(0XFFCB9FE4),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Center(
                                    child: Image.asset(
                                      'assets/vectors/apple.png',
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.08,
                                      height:
                                          MediaQuery.of(context).size.width *
                                          0.08,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.038,
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
                                    color: Color(0xFF8715C9),
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.040,
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final double fontSize;
  final double horizontalPadding;

  const _OrDivider({required this.fontSize, required this.horizontalPadding});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return SizedBox(
      width: screenWidth * 0.8,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.grey)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              'Or Sign Up With',
              style: TextStyle(
                color: const Color.fromARGB(255, 36, 37, 38),
                fontSize: fontSize,
                fontFamily: 'Epunda Slab',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: Colors.grey)),
        ],
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
  final Color? iconColor;
  final double? fontSize;

  const _ResponsiveTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.focusNode,
    required this.nextFocusNode,
    required this.textInputAction,
    required this.iconColor,
    required this.fontSize
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
        style: TextStyle(
          fontSize: fontSize ?? screenWidth * 0.045,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: iconColor ?? const Color.fromARGB(255, 0, 0, 0),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: const Color(0xFF8715C9), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: const Color(0xFF8715C9), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: const Color(0xFF8715C9), width: 1),
          ),
        ),
        onSubmitted: (_) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        },
      ),
    );
  }
}
