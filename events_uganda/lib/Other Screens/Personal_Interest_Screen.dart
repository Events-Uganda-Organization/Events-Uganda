import 'package:flutter/material.dart';

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
    final cardWidth = screenWidth * 0.35;
    return GestureDetector(
      onTap: () => _toggleSelection(key),
      child: Container(
        width: cardWidth,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white, width: 2),
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
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
              top: size.height * 0.15,
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
              top: size.height * 0.24,
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
