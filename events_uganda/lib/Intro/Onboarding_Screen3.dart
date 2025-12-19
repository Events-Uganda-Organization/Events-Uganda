import 'package:events_uganda/Auth/Auth_Screen.dart';
import 'package:events_uganda/Intro/Onboarding_Screen2.dart';
import 'package:flutter/material.dart';

class OnboardingScreen3 extends StatefulWidget {
  const OnboardingScreen3({super.key});

  @override
  State<OnboardingScreen3> createState() => _OnboardingScreen3State();
}

class _OnboardingScreen3State extends State<OnboardingScreen3> {
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
              'assets/backgroundcolors/onboardingscreen3.png',
              width: MediaQuery.of(context).size.width * 1.08,
              height: MediaQuery.of(context).size.height * 0.9,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: screenHeight * 0.109,
            left: screenWidth * 0.143,
            child: ClipOval(
              child: Image.asset(
                'assets/images/introduction.jpg',
                width: screenWidth * 0.37,
                height: screenWidth * 0.37,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.096, // Adjust as needed
            right: screenWidth * 0.18,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  screenWidth * (50 / 390),
                ), // Responsive radius
              ),
              child: Image.asset(
                'assets/images/brideandladies.jpg',
                width: screenWidth * 0.30, // Adjust as needed
                height: screenHeight * 0.18, // Adjust as needed
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.276,
            left: screenWidth * 0.143,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(
                  screenWidth * (50 / 390),
                ),  // Responsive radius
              ),
              child: Image.asset(
                'assets/images/women.jpg',
                width: screenWidth * 0.31, // Adjust as needed
                height: screenHeight * 0.18, // Adjust as needed
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.276, // Adjust as needed
            right: screenWidth * 0.173,
            child: ClipRRect(
              borderRadius: BorderRadius.only(topRight: Radius.circular(screenWidth * (70 / 390), ), topLeft: Radius.circular(screenWidth * (70 / 390), ), bottomRight: Radius.circular(screenWidth * (70 / 390), ),// Responsive radius
              ),
              child: Image.asset(
                'assets/images/bdgal3.jpg',
                width: screenWidth * 0.37, // Adjust as needed
                height: screenHeight * 0.175, // Adjust as needed
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.45,
            right: screenWidth * 0.209,
            child: ClipRRect(
              borderRadius: BorderRadius.only(topRight: Radius.circular(screenWidth * (50 / 390),
                ), bottomRight: Radius.circular(screenWidth * (50 / 390), ) // Responsive radius
              ),
              child: Image.asset(
                'assets/images/glassdeco.jpg',
                width: screenWidth * 0.33, // Adjust as needed
                height: screenHeight * 0.22, // Adjust as needed
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.45,
            left: screenWidth * 0.143,
            child: ClipRRect(
              borderRadius: BorderRadius.only(topRight: Radius.circular(screenWidth * (140 / 390),
                ), bottomLeft: Radius.circular(screenWidth * (140 / 390), ) // Responsive radius
              ),
              child: Image.asset(
                'assets/images/blacknwhitemen.jpg',
                width: screenWidth * 0.33, // Adjust as needed
                height: screenHeight * 0.19, // Adjust as needed
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
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
              ],
            ),
          ),
          Positioned(
            top: screenHeight * 0.63,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Trusted Services\nEasy Payments',
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
                'Verified service providers,\nsecure payments, and\nsmooth event planning',
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
                  MaterialPageRoute(builder: (context) => OnboardingScreen2()),
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
            top: screenHeight * 0.62, 
            left: -screenWidth * 0.09,
            child: Image.asset(
              'assets/vectors/onboardingscreen3vect.png',
              width: screenWidth * (100 / 390),
              height: screenWidth * (100 / 390),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: screenHeight * 0.82, 
            right: -screenWidth * 0.06,
            child: Image.asset(
              'assets/vectors/onboardingscreen3vect.png',
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
                      builder: (context) => AuthScreen(),
                    ),
                  );
                },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black, Color(0xFFEBD90F)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.2, 0.6],
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
                        'Start',
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
