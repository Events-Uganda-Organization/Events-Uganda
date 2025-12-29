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
    final screenHeight = MediaQuery.of(context).size.height;
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

                      

                              SizedBox(height: screenHeight * 0.04),


                              SizedBox(height: screenHeight * 0.05),

                              GestureDetector(
                                child: Container(
                                  width: screenWidth * 0.5,
                                  height: screenHeight * 0.06,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
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
