import 'package:events_uganda/Auth/Sign_In_Screen.dart';
import 'package:events_uganda/Auth/Sign_Up_Screen.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReferralCodeScreen extends StatefulWidget {
  const ReferralCodeScreen({super.key});

  @override
  State<ReferralCodeScreen> createState() => _ReferralCodeScreenState();
}

class _ReferralCodeScreenState extends State<ReferralCodeScreen> {
  final TextEditingController _referralCodeController = TextEditingController();
  final FocusNode _referralCodeFocus = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedReferralCode();
  }

  Future<void> _loadSavedReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedReferralCode = prefs.getString('savedReferralCode') ?? '';

    setState(() {
      _referralCodeController.text = savedReferralCode;
    });
  }

  Future<void> _saveReferralCode(String referralCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedReferralCode', referralCode);
  }

  Future<void> _applyReferralCode() async {
    final referralCode = _referralCodeController.text.trim();

    if (referralCode.isEmpty) {
      _showCustomSnackBar(context, 'Please enter your referral code');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement referral code validation logic
      await _saveReferralCode(referralCode);

      _showCustomSnackBar(context, 'Referral code applied successfully!');
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
        );
      }
    } catch (e) {
      _showCustomSnackBar(context, e.toString().replaceFirst('Exception: ', ''));
      debugPrint('Referral code error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF009688),
      ),
    );
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    _referralCodeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    const accent = Color(0xFF009688);
    const socialBg = Color(0xFFB2DFDB);
    const lightGrad = Color(0xFF80CBC4);

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
                'assets/backgroundcolors/referralcodescreen.png',
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
                    color: const Color(0xFFB2DFDB),
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
                    "Enter Your",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: screen.width * 0.08,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "Referral Code",
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
                          "Referral Code",
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
                          'Enter your referral code to unlock exclusive rewards.',
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
                          controller: _referralCodeController,
                          label: 'Referral Code',
                          hint: 'Enter Your Referral Code',
                          icon: Icons.card_giftcard,
                          focusNode: _referralCodeFocus,
                          nextFocusNode: _referralCodeFocus,
                          textInputAction: TextInputAction.done,
                          iconColor: Colors.black,
                          fontSize: screenWidth * 0.045,
                        ),
                        SizedBox(height: screen.height * 0.028),
                        // Apply Referral Code button
                        SizedBox(
                          width: double.infinity,
                          height: screen.width * 0.12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFF009688),
                                width: 1,
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [lightGrad, accent],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withValues(alpha: 0.25),
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
                              onPressed: _isLoading ? null : _applyReferralCode,
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
                                      'Apply Code',
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
                                'Or',
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
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignInScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Skip for now',
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
                        SizedBox(height: screen.height * 0.025),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Don\'t have a code? ',
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
            borderSide: BorderSide(color: const Color(0xFF009688), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: const Color(0xFF009688), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: const Color(0xFF009688), width: 1),
          ),
        ),
        onSubmitted: (_) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        },
      ),
    );
  }
}
