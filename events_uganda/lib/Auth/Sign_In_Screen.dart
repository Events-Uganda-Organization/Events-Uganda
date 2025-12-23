import 'package:events_uganda/Auth/Forgot_Password_Screen.dart';
import 'package:events_uganda/Other%20Screens/Role_Selection_Screen.dart';
import 'package:events_uganda/Auth/Sign_Up_Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _contactFocus = FocusNode();

  final bool obscureText = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // EMAIL/PHONE + PASSWORD SIGN-IN
  Future<void> _signInUser() async {
    final emailOrPhone = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validation
    if (emailOrPhone.isEmpty) {
      _showCustomSnackBar(context, 'Please enter your email or phone number');
      return;
    }
    if (password.isEmpty) {
      _showCustomSnackBar(context, 'Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? emailToUse = emailOrPhone;

      // Check if input is a phone number (contains only digits and optional +)
      final isPhone = RegExp(r'^[\d+]+$').hasMatch(emailOrPhone);

      if (isPhone) {
        // Query Firestore to find user by phone number
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('phone', isEqualTo: emailOrPhone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          _showCustomSnackBar(context, 'No account found with this phone number');
          setState(() => _isLoading = false);
          return;
        }

        emailToUse = querySnapshot.docs.first.data()['email'] as String?;
        
        if (emailToUse == null || emailToUse.isEmpty) {
          _showCustomSnackBar(context, 'Account error. Please contact support.');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Sign in with Firebase Auth
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToUse!,
        password: password,
      );

      // Update FCM token and last active timestamp
      final user = userCredential.user;
      if (user != null) {
        String? fcmToken;
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          debugPrint('Failed to get FCM token: $e');
        }

        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'lastActiveTimestamp': Timestamp.now(),
          if (fcmToken != null) 'fcmToken': fcmToken,
        });

        // Save login state
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        _showCustomSnackBar(context, 'Sign in successful!');
        await Future.delayed(const Duration(seconds: 1));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Sign in failed. Please try again.';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password';
          break;
      }
      
      _showCustomSnackBar(context, message);
    } catch (e) {
      debugPrint('Sign in error: $e');
      _showCustomSnackBar(context, 'An error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // APPLE SIGN-IN (NEW!)
  Future<void> _signInWithApple() async {
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

      // Prepare user data to update
      final Map<String, dynamic> userData = {
        'email': user.email ?? 'hidden@privaterelay.appleid.com',
        'profilePicUrl': user.photoURL,
        'authProvider': 'apple',
        'isAdmin': (user.email ?? '').toLowerCase() == 'adminuser@gmail.com',
        'fcmToken': await FirebaseMessaging.instance.getToken(),
        'lastActiveTimestamp': Timestamp.now(),
      };

      // Handle Name: Apple only sends this on the FIRST login.
      // On subsequent logins, givenName/familyName will be null.
      // We only want to update the name if Apple provides it.
      if (credential.givenName != null || credential.familyName != null) {
        final name =
            "${credential.givenName ?? ''} ${credential.familyName ?? ''}"
                .trim();
        if (name.isNotEmpty) {
          userData['fullName'] = name;
        }
      }

      // Check if user exists to handle 'createdAt' and default name
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnapshot = await userDocRef.get();

      if (!docSnapshot.exists) {
        userData['createdAt'] = FieldValue.serverTimestamp();
        // If it's a new user and we didn't get a name from Apple, set a default
        if (!userData.containsKey('fullName')) {
          userData['fullName'] = "Apple User";
        }
      }

      await userDocRef.set(userData, SetOptions(merge: true));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await _saveFcmToken();

      _showCustomSnackBar(context, 'Signed in with Apple!');
      await Future.delayed(const Duration(seconds: 1));
      _navigateBasedOnEmail(user.email);
    } on FirebaseAuthException {
      _showCustomSnackBar(
        context,
        'Authentication failed. Please try again later.',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      // Handle different Apple Sign-In errors
      switch (e.code) {
        case AuthorizationErrorCode.canceled:
          // User canceled - don't show error
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

  void _showCustomSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFCC471B),
      ),
    );
  }

  Future<void> _saveFcmToken() async {
    // Token is already saved in _signInWithApple
  }

  void _navigateBasedOnEmail(String? email) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
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
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    const accent = Color(0xFFCC471B);
    const socialBg = Color(0xFFF4D7C7);
    const lightGrad = Color(0xFFE8C7B6);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Gradient background (black → deep orange)
            Container(),
            // Orange glow overlay at top
            Positioned(
              top: MediaQuery.of(context).size.height * 0.0, // adjust as needed
              right:
                  (MediaQuery.of(context).size.width +
                      MediaQuery.of(context).size.width * 1) /
                  300,
              child: Image.asset(
                'assets/backgroundcolors/signinscreen.png',
                width:
                    MediaQuery.of(context).size.width *
                    1.08, // responsive width
                height:
                    MediaQuery.of(context).size.height *
                    0.9, // responsive height
                fit: BoxFit.contain,
              ),
            ),
            // Decorative vectors
            Positioned(
              top: screen.height * 0.21,
              left:
                  (MediaQuery.of(context).size.width -
                      MediaQuery.of(context).size.width * 0.15) /
                  1,
              child: Image.asset(
                'assets/vectors/signinvect.png',
                width: screen.width * 0.10,
                height: screen.width * 0.10,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screen.height * 0.18,
              right:
                  (MediaQuery.of(context).size.width -
                      MediaQuery.of(context).size.width * 0.15) /
                  1,
              child: Image.asset(
                'assets/vectors/signinvect.png',
                width: screen.width * 0.10,
                height: screen.width * 0.10,
                fit: BoxFit.contain,
              ),
            ),
            // Logo ring
            Positioned(
              top: screen.height * 0.03,
              left: (screen.width - screen.width * 0.30) / 2,
              child: Image.asset(
                'assets/vectors/logo.png',
                width: screen.width * 0.30,
                height: screen.width * 0.30,
                fit: BoxFit.contain,
              ),
            ),
            // Back button
            Positioned(
              top: MediaQuery.of(context).size.height * 0.04,
              left: MediaQuery.of(context).size.width * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.13,
                  height: MediaQuery.of(context).size.width * 0.13,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C2B0),
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
            // Heading
            Positioned(
              top: screen.height * 0.16,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    "Let's get you",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: screen.width * 0.08,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "signed in!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: screen.width * 0.08,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            // Form container
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
                padding: EdgeInsets.symmetric(
                  horizontal: screen.width * 0.08,
                  vertical: screen.height * 0.03,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height *
                          1.2, // 120% of screen height
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Sign In",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                            fontSize: screen.width * 0.05,
                          ),
                        ),
                        SizedBox(height: screen.height * 0.006),
                        Text(
                          'Please enter either your email or phone number to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Abril Fatface',
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            fontSize: screen.width * 0.035,
                          ),
                        ),
                        SizedBox(height: screen.height * 0.03),
                        _ResponsiveTextField(
                          controller: _emailController,
                          label: 'Email/Phone Number',
                          hint: 'Enter Your Email or Phone Number',
                          icon: Icons.mail,
                          focusNode: _emailFocus,
                          nextFocusNode: _passwordFocus,
                          textInputAction: TextInputAction.next,
                          iconColor: Colors.black,
                          fontSize: screenWidth * 0.045,
                        ),
                        SizedBox(height: screen.height * 0.03),
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
                        SizedBox(height: screen.height * 0.016),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: screen.width * 0.02,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screen.width * 0.038,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screen.height * 0.028),
                        // Sign In button
                        SizedBox(
                          width: double.infinity,
                          height: screen.width * 0.12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFCB471B),
                                width: 1,
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [lightGrad, accent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoleSelectionScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: screen.width * 0.045,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screen.height * 0.028),
                        // Divider
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 0.8,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: screen.width * 0.02,
                              ),
                              child: Text(
                                'Or Sign Up With',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: screen.width * 0.035,
                                  fontFamily: 'Epunda Slab',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Colors.grey,
                                thickness: 0.8,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screen.height * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: signInWithGoogle,
                              child: _SocialBtn(
                                bg: socialBg,
                                asset: 'assets/vectors/google.png',
                                size: screen.width * 0.16,
                              ),
                            ),
                            SizedBox(width: screen.width * 0.06),
                            GestureDetector(
                              onTap: _signInWithApple,
                              child: _SocialBtn(
                                bg: socialBg,
                                asset: 'assets/vectors/apple.png',
                                size: screen.width * 0.16,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screen.height * 0.025),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screen.width * 0.037,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignUpScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: screen.width * 0.040,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screen.height * 0.015),
                      ],
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

class _RoundedField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final FocusNode focusNode;
  final FocusNode nextFocusNode;
  final TextInputAction textInputAction;
  final Color accent;
  final bool isPassword;

  const _RoundedField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.focusNode,
    required this.nextFocusNode,
    required this.textInputAction,
    required this.accent,
    required this.isPassword,
  });

  @override
  State<_RoundedField> createState() => _RoundedFieldState();
}

class _RoundedFieldState extends State<_RoundedField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    return SizedBox(
      width: double.infinity,
      height: screen.width * 0.14,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textInputAction: widget.textInputAction,
        obscureText: _obscure,
        style: TextStyle(
          fontSize: screen.width * 0.042,
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: screen.width * 0.038,
            fontWeight: FontWeight.w700,
          ),
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.55),
            fontSize: screen.width * 0.040,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: screen.width * 0.055,
            ),
          ),
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: widget.accent, width: 1.4),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide(color: widget.accent, width: 2),
          ),
        ),
        onSubmitted: (_) =>
            FocusScope.of(context).requestFocus(widget.nextFocusNode),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String asset;
  final Color bg;
  final double size;

  const _SocialBtn({required this.asset, required this.bg, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.22),
      child: Image.asset(asset, fit: BoxFit.contain),
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
    required this.fontSize,
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
            borderSide: BorderSide(color: const Color(0xFFCB471B), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: const Color(0xFFCB471B), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: const Color(0xFFCB471B), width: 1),
          ),
        ),
        onSubmitted: (_) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        },
      ),
    );
  }
}
