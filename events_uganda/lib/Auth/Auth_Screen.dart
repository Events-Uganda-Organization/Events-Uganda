import 'dart:ui';
import 'package:events_uganda/Auth/Sign_In_Screen.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:events_uganda/components/snackbar_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '830864962380-butme4ss3fiam7ko130lfe50i8jn3mqo.apps.googleusercontent.com',
        scopes: ['email', 'openid'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final result = await AuthService.googleAuth(
        idToken: kIsWeb ? null : googleAuth.idToken,
        accessToken: kIsWeb ? googleAuth.accessToken : null,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      if (mounted) {
        SnackbarHelper.show(
          context,
          'Sign-in failed: ${e.toString().replaceFirst('Exception: ', '')}',
          icon: Icons.error_outline_rounded,
          backgroundColor: const Color(0xFFCC471B),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
                'assets/backgroundcolors/authscreen.png',
                width: MediaQuery.of(context).size.width * 1.08,
                height: MediaQuery.of(context).size.height * 0.9,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.020,
              left: screenWidth * 0.1,
              child: Transform.rotate(
                angle: 0.663, // -38 degrees in radians
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/brideandgroom.jpg',
                    width: screenWidth * (120 / 390),
                    height: screenHeight * (233 / 844),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.010,
              right: screenWidth * 0.02,
              child: Transform.rotate(
                angle: 0.663, // -38 degrees in radians
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/cake2.jpg',
                    width: screenWidth * (120 / 390),
                    height: screenHeight * (233 / 844),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top:
                  screenHeight *
                  0.25, // Adjust this value to place it just below couple.jpg
              right: screenWidth * 0.345,
              child: Container(
                width: screenWidth * (120 / 390),
                height: screenWidth * (120 / 390),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/vectors/logo.png',
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: MediaQuery.of(context).size.width * 0.15,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.320,
              right: screenWidth * 0.05,
              child: Transform.rotate(
                angle: 0.663, // -38 degrees in radians
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/deco2.jpg',
                    width: screenWidth * (120 / 390),
                    height: screenHeight * (233 / 844),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.360,
              left: screenWidth * 0.03,
              child: Transform.rotate(
                angle: 0.663, // -38 degrees in radians
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.asset(
                    'assets/images/deco5.jpg',
                    width: screenWidth * (120 / 390),
                    height: screenHeight * (233 / 844),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              left:
                  (screenWidth - (screenWidth * (370 / 390))) /
                  2, // Center horizontally
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: screenWidth * (370 / 390),
                    height: screenHeight * (390 / 844),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: screenHeight * 0.03),
                            child: Text(
                              'Sign Up or Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.065,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'PlayfairDisplay',
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.015),
                          Container(
                            width: screenWidth * 0.85, // Adjust width as needed
                            height: screenHeight * 0.07, // Thin rectangle
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/vectors/apple.png',
                                    width: screenWidth * 0.07,
                                    height: screenWidth * 0.07,
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    'Continue with Apple',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.045,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'PlayfairDisplay',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          GestureDetector(
                            onTap: signInWithGoogle,
                            child: Container(
                              width: screenWidth * 0.85,
                              height: screenHeight * 0.07,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/vectors/google.png',
                                      width: screenWidth * 0.07,
                                      height: screenWidth * 0.07,
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Text(
                                      'Continue with Google',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'PlayfairDisplay',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: screenHeight * 0.03,
                          ), // Space between rectangles
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignInScreen(),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 18,
                                  sigmaY: 18,
                                ),
                                child: Container(
                                  width:
                                      screenWidth *
                                      0.85, // Adjust width as needed
                                  height:
                                      screenHeight *
                                      0.07, // Adjust height as needed
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.mail,
                                          color: Colors.white,
                                          size: screenWidth * 0.07,
                                        ),
                                        SizedBox(width: screenWidth * 0.03),
                                        Text(
                                          'Continue with Email',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'PlayfairDisplay',
                                          ),
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
