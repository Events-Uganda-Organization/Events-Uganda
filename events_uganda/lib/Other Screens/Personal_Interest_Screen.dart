import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class PersonalInterestScreen extends StatefulWidget {
  const PersonalInterestScreen({super.key});

  @override
  State<PersonalInterestScreen> createState() => _PersonalInterestScreenState();
}

class _PersonalInterestScreenState extends State<PersonalInterestScreen> {
  final Set<String> selectedInterests = {};

  void _toggleSelection(String interest) {
    setState(() {
      if (selectedInterests.contains(interest)) {
        selectedInterests.remove(interest);
      } else {
        selectedInterests.add(interest);
      }
    });
  }

  Widget _buildInterestCard(
    String label,
    IconData icon,
    String key,
    double screenWidth,
  ) {
    final isSelected = selectedInterests.contains(key);
    final cardWidth = screenWidth * 0.44;
    return GestureDetector(
      onTap: () => _toggleSelection(key),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: cardWidth,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.black : Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/backgroundcolors/personalinterestbg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: screen.height * 0.21,
              left:
                  (MediaQuery.of(context).size.width -
                      MediaQuery.of(context).size.width * 0.15) /
                  1,
              child: Image.asset(
                'assets/vectors/personalinterestvect.png',
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
                'assets/vectors/personalinterestvect.png',
                width: screen.width * 0.10,
                height: screen.width * 0.10,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: size.height * 0.02,
              left: (size.width - size.width * 0.35) / 2,
              child: Container(
                width: size.width * 0.35,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title text below the bar
            Positioned(
              top: screen.height * 0.16,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Text(
                    "Time to choose",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                      fontSize: screen.width * 0.08,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "!",
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
            // Glassy rectangles row
            Positioned(
              top: size.height * 0.30,
              left: size.width * 0.04,
              right: size.width * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Decoration card
                  _buildInterestCard(
                    'Decoration',
                    Icons.celebration,
                    'decoration',
                    size.width,
                  ),
                  SizedBox(width: 12),
                  // Catering card
                  _buildInterestCard(
                    'Catering',
                    Icons.restaurant,
                    'catering',
                    size.width,
                  ),
                ],
              ),
            ),

            // Second row of rectangles
            Positioned(
              top: size.height * 0.39,
              left: size.width * 0.04,
              right: size.width * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Car Hire card
                  _buildInterestCard(
                    'Car Hire',
                    Icons.directions_car,
                    'carHire',
                    size.width,
                  ),
                  SizedBox(width: 12),
                  // Photography card
                  _buildInterestCard(
                    'Photography',
                    Icons.camera_alt,
                    'photography',
                    size.width,
                  ),
                ],
              ),
            ),

            // Third row of rectangles
            Positioned(
              top: size.height * 0.48,
              left: size.width * 0.04,
              right: size.width * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Entertainment card
                  _buildInterestCard(
                    'Entertainment',
                    Icons.music_note,
                    'entertainment',
                    size.width,
                  ),
                  SizedBox(width: 12),
                  // Venue card
                  _buildInterestCard(
                    'Venue',
                    Icons.location_on,
                    'venue',
                    size.width,
                  ),
                ],
              ),
            ),

            // Fourth row of rectangles
            Positioned(
              top: size.height * 0.57,
              left: size.width * 0.04,
              right: size.width * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // MC card
                  _buildInterestCard('MC', Icons.mic, 'mc', size.width),
                  SizedBox(width: 12),
                  // Makeup card
                  _buildInterestCard(
                    'Makeup',
                    Icons.face,
                    'makeup',
                    size.width,
                  ),
                ],
              ),
            ),

            // Start button
            Positioned(
              top: size.height * 0.70,
              left: size.width * 0.04,
              right: size.width * 0.04,
              child: GestureDetector(
                onTap: () {
                  // Add button action here
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'Start',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontSize: size.width * 0.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Skip text
            Positioned(
              top: size.height * 0.80,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CustomerHomeScreen(),
                    ),
                  );
                },
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Montserrat',
                          fontSize: size.width * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.chevron_right, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: size.height * 0.025,
              left: size.width * 0.035,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: size.width * 0.12,
                  height: size.width * 0.12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.chevron_left,
                    color: Colors.black,
                    size: size.width * 0.08,
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
