import 'package:events_uganda/Intro/Onboarding_Screen2.dart';
import 'package:flutter/material.dart';

class OnboardingScreen1 extends StatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  State<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends State<OnboardingScreen1>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnim;
  late Animation<double> _opacityAnim;
  bool _isDragging = false;
  bool _showSwipeHint = true;
  double _dragStart = 0.0;
  double _dragOffset = 0.0;
  bool _isAnimating = false;

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isAnimating) {
      setState(() {
        _dragOffset += details.delta.dy;
      });
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragOffset > 60 && !_isAnimating) {
      setState(() {
        _isAnimating = true;
      });
      Future.delayed(const Duration(milliseconds: 250), () {
        setState(() {
          // Move top card to back
          final last = cardImages.removeLast();
          cardImages.insert(0, last);
          _dragOffset = 0.0;
          _isAnimating = false;
        });
      });
    } else {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showSwipeHint = false;
        });
      }
    });
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // slower, smoother
    );
    _offsetAnim = Tween<double>(
      begin: 0,
      end: 200,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnim = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          final last = cardImages.removeLast();
          cardImages.insert(0, last);
          _controller.reset();
          _isDragging = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
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
              'assets/backgroundcolors/onboardingscreen1.png',
              width: MediaQuery.of(context).size.width * 1.08,
              height: MediaQuery.of(context).size.height * 0.9,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: screenHeight * 0.52, 
            left:
                (screenWidth - (screenWidth * (600 / 390))) /
                2, 
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
                'Discover Event\nServices Near You',
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
                'Find trusted Decoration, Catering,\nPhotography & Videography,\nCar hiring, Sound & Lighting\nservices in one app',
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
            top: screenHeight * 0.62, 
            left: -screenWidth * 0.09,
            child: Image.asset(
              'assets/vectors/onboardingscreen1vect.png',
              width: screenWidth * (108 / 390),
              height: screenWidth * (100 / 390),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: screenHeight * 0.82, // Example value, tweak as needed
            right: -screenWidth * 0.06,
            child: Image.asset(
              'assets/vectors/onboardingscreen1vect.png',
              width: screenWidth * (100 / 390),
              height: screenWidth * (100 / 390),
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: screenWidth * 0.15, // Add margin from left
            right: screenWidth * 0.15,
            bottom:
                screenHeight *
                0.02, // Adjust as needed for spacing from the bottom
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnboardingScreen2(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7EED27), Colors.black],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0.26, 0.8],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.010,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/vectors/heart.png',
                          width: screenWidth * 0.07, // Responsive width
                          height: screenWidth * 0.07,
                        ),
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Next',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.06,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // keyboard_double_arrow_right icon on the far right
                        Icon(
                          Icons.keyboard_double_arrow_right,
                          color: Colors.white,
                          size: screenWidth * 0.09,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Place this inside your widget tree (e.g., in the body of your Scaffold)
          // In your build method, replace your Stack's card section with this:
          Stack(
            alignment: Alignment.topCenter,
            children: [
              // 4th card (bottom)
              Positioned(
                top: screenHeight * 0.04,
                child: Transform.rotate(
                  angle: 0,
                  child: _buildCard(
                    cardImages[0],
                    screenWidth,
                    screenHeight,
                    0.92,
                    0.34,
                  ),
                ),
              ),
              // 3rd card
              Positioned(
                top: screenHeight * 0.06,
                child: Transform.rotate(
                  angle: -0.035,
                  child: _buildCard(
                    cardImages[1],
                    screenWidth,
                    screenHeight,
                    0.92,
                    0.36,
                  ),
                ),
              ),
              // 2nd card
              Positioned(
                top: screenHeight * 0.1,
                child: Transform.rotate(
                  angle: -0.056,
                  child: _buildCard(
                    cardImages[2],
                    screenWidth,
                    screenHeight,
                    0.92,
                    0.38,
                  ),
                ),
              ),
              // 1st card (top, swipeable)
              Positioned(
                top: screenHeight * 0.15 + _dragOffset,
                child: GestureDetector(
                  onVerticalDragStart: (details) {
                    _dragStart = details.localPosition.dy;
                    _isDragging = true;
                  },
                  onVerticalDragUpdate: (details) {
                    if (_isDragging &&
                        details.localPosition.dy - _dragStart > 60) {
                      _isDragging = false;
                      _controller.forward();
                    }
                  },
                  onVerticalDragEnd: (_) {
                    if (_isDragging) {
                      _isDragging = false;
                      _controller.reverse();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _opacityAnim.value,
                        child: Transform.translate(
                          offset: Offset(0, _offsetAnim.value),
                          child: child,
                        ),
                      );
                    },
                    child: Transform.rotate(
                      angle: -0.088,
                      child: _buildCard(
                        cardImages[3],
                        screenWidth,
                        screenHeight,
                        0.92,
                        0.40,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showSwipeHint)
            Positioned(
              top: screenHeight * 0.13, // Adjust as needed
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.012,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.swipe_down,
                        color: Colors.white,
                        size: screenWidth * 0.07,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Text(
                        'Swipe down',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildCard(
    String imagePath,
    double screenWidth,
    double screenHeight,
    double widthFactor,
    double? heightFactor,
  ) {
    return Container(
      width: screenWidth * widthFactor,
      height: screenHeight * (heightFactor ?? 0.25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
    );
  }
}

List<String> images = [
  'assets/images/women.jpg',
  'assets/images/introductionbride.jpg',
  'assets/images/introduction.jpg',
  'assets/images/bdgal4.jpg',
];
int topIndex = 0;
List<String> cardImages = List.from(images);
