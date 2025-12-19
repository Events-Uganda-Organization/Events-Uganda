import 'package:events_uganda/Intro/Onboarding_Screen1.dart';
import 'package:events_uganda/Intro/Onboarding_Screen3.dart';
import 'package:flutter/material.dart';

class OnboardingScreen2 extends StatefulWidget {
  const OnboardingScreen2({super.key});

  @override
  State<OnboardingScreen2> createState() => _OnboardingScreen2State();
}

class _OnboardingScreen2State extends State<OnboardingScreen2> {
  @override
  void dispose() {
    super.dispose();
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
                'assets/backgroundcolors/onboardingscreen2.png',
                width: MediaQuery.of(context).size.width * 1.08,
                height: MediaQuery.of(context).size.height * 0.9,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.04,
              left: screenWidth * 0.02,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/tent1.jpg',
                  width: screenWidth * (120 / 390),
                  height: screenHeight * (233 / 844),
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.04,
              right: screenWidth * 0.02,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/catering.jpg',
                  width: screenWidth * (120 / 390),
                  height: screenHeight * (233 / 844),
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Positioned(
              top: -screenHeight * 0.05,
              right: screenWidth * 0.345,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/couple.jpg',
                  width: screenWidth * (120 / 390),
                  height: screenHeight * (233 / 844),
                  fit: BoxFit.cover,
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
              top: screenHeight * 0.33,
              left: screenWidth * 0.02,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/photography.jpg',
                  width: screenWidth * (120 / 390),
                  height: screenHeight * (233 / 844),
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.33,
              right: screenWidth * 0.02,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/carhire1.jpg',
                  width: screenWidth * (120 / 390),
                  height: screenHeight * (233 / 844),
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.422,
              right: screenWidth * 0.345,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'assets/images/cake1.jpg',
                  width: screenWidth * (120 / 390),
                  height: screenHeight * (233 / 844),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              // Adjust 'top' to place it below cake1.jpg
              top: screenHeight * 0.52, // Example value, tweak as needed
              left:
                  (screenWidth - (screenWidth * (600 / 390))) /
                  2, // Center horizontally
              child: Image.asset(
                'assets/backgroundcolors/whitebg.png',
                width: screenWidth * (600 / 390),
                height: screenWidth * (600 / 390),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: screenHeight * 0.60,
              left: (screenWidth - (screenWidth * 0.25)) / 2,
              child: Row(
                children: [
                  Container(
                    width: screenWidth * 0.06,
                    height: screenHeight * 0.010,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Container(
                    width: screenWidth * 0.1,
                    height: screenHeight * 0.015,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Container(
                    width: screenWidth * 0.06,
                    height: screenHeight * 0.010,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.63,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Book Everything in one\nApp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.065,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.725,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Compare prices, check\navailability, and book services\neasily in one app on your\nphone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'PlayfairDisplay',
                  ),
                ),
              ),
            ),
            Positioned(
              bottom:
                screenHeight *
                0.02, 
              left: screenWidth * 0.06,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingScreen1(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.015,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.047,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Transform.rotate(
                          angle: 0.628, // 36 degrees in radians
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: screenWidth * 0.067,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.01),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              // Adjust 'top' to place it below cake1.jpg
              top: screenHeight * 0.62, // Example value, tweak as needed
              left: -screenWidth * 0.09,
              child: Image.asset(
                'assets/vectors/onboardingscreen2vect.png',
                width: screenWidth * (100 / 390),
                height: screenWidth * (100 / 390),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              // Adjust 'top' to place it below cake1.jpg
              top: screenHeight * 0.82, // Example value, tweak as needed
              right: -screenWidth * 0.06,
              child: Image.asset(
                'assets/vectors/onboardingscreen2vect.png',
                width: screenWidth * (100 / 390),
                height: screenWidth * (100 / 390),
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom:
                screenHeight *
                0.02, 
              right: screenWidth * 0.06,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingScreen3(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Color(0xFFED9E27)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.1, 0.6],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
                      vertical: screenHeight * 0.015,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.047,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Transform.rotate(
                          angle: -0.628, // -36 degrees in radians
                          child: Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: screenWidth * 0.067,
                          ),
                        ),
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
