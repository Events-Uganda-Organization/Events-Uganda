import 'package:events_uganda/Auth/Forgot_Password_Screen.dart';
import 'package:events_uganda/Auth/Sign_Up_Screen.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmailOrPhone = prefs.getString('savedEmailOrPhone') ?? '';
    final savedPassword = prefs.getString('savedPassword') ?? '';

    setState(() {
      _emailController.text = savedEmailOrPhone;
      _passwordController.text = savedPassword;
    });
  }

  Future<void> _saveCredentials(String emailOrPhone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedEmailOrPhone', emailOrPhone);
    await prefs.setString('savedPassword', password);
  }

  Future<void> _signInUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showCustomSnackBar(context, 'Please enter your email');
      return;
    }
    if (password.isEmpty) {
      _showCustomSnackBar(context, 'Please enter your password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.login(email: email, password: password);

      await _saveCredentials(email, password);

      _showCustomSnackBar(context, 'Sign in successful!');
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
        );
      }
    } catch (e) {
      _showCustomSnackBar(context, e.toString().replaceFirst('Exception: ', ''));
      debugPrint('Sign in error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFCC471B),
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        _showCustomSnackBar(context, 'Failed to get Google ID token');
        return;
      }

      await AuthService.googleAuth(idToken: googleAuth.idToken!);

      _showCustomSnackBar(context, 'Sign in successful!');
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
        );
      }
    } catch (e) {
      _showCustomSnackBar(context, e.toString().replaceFirst('Exception: ', ''));
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
                              onPressed: _isLoading ? null : _signInUser,
                              child: _isLoading
                                  ? SizedBox(
                                      height: screen.width * 0.05,
                                      width: screen.width * 0.05,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.black,
                                            ),
                                      ),
                                    )
                                  : Text(
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
