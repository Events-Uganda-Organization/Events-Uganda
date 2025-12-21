import 'package:flutter/material.dart';

class PersonalInterestScreen extends StatelessWidget {
  const PersonalInterestScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              top: size.height * 0.05,
              left: 0,
              right: 0,
              child: Text(
                'Time To Choose',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontSize: size.width * 0.08,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            // Subtitle text
            Positioned(
              top: size.height * 0.11,
              left: size.width * 0.08,
              right: size.width * 0.08,
              child: Text(
                'Tell us what you are most interested in to help us deliver the best to you',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Abril Fatface',
                  fontSize: size.width * 0.04,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Select instruction text
            Positioned(
              top: size.height * 0.19,
              left: 0,
              right: 0,
              child: Text(
                'SELECT 3 OR MORE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.w800,
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
