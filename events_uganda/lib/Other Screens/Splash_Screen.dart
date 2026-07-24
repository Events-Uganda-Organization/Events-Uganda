import 'dart:async';
import 'package:events_uganda/Intro/Onboarding_Screen1.dart';
import 'package:events_uganda/Other Screens/splash_video.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();
    _navTimer = Timer(const Duration(seconds: 20), _navigate); // fallback if video never ends
  }

  void _navigate() {
    _navTimer?.cancel();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
      );
    }
  }

  void _onVideoEnded() {
    _navTimer?.cancel();
    _navigate();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            SizedBox.expand(child: SplashVideoPlayer(screenWidth: screenWidth, onVideoEnded: _onVideoEnded)),
            SizedBox.expand(
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: screenHeight * 0.12,
              child: AnimatedBuilder(
                animation: _fadeIn,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeIn.value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - _fadeIn.value)),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/vectors/logo.png',
                              width: screenWidth * 0.12,
                              height: screenWidth * 0.12,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Text(
                              'Events Uganda',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: screenWidth * 0.07,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
