import 'dart:async';
import 'package:events_uganda/Intro/Onboarding_Screen1.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:video_player/video_player.dart';

class DiagonalLogoText extends StatelessWidget {
  const DiagonalLogoText({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Positioned(
          left: screenWidth * 0.05,
          bottom: screenHeight * 0.12,
          child: Row(
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
      ],
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
    _navTimer = Timer(const Duration(seconds: 10), _navigate);
  }

  void _navigate() {
    _videoController.pause();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
      );
    }
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/Bride_and_groom_merge_light_202606290000.mp4',
    );
    try {
      await _videoController.initialize();
      await _videoController.setLooping(true);
      await _videoController.setVolume(0);
      await _videoController.play();
      if (mounted) setState(() => _videoInitialized = true);
    } catch (e) {
      debugPrint('Video init failed: $e');
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background video
          Positioned.fill(
            child: _videoInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : ColoredBox(color: Colors.black),
          ),

          // Ring images (bottom-right)
          Positioned(
            right: screenWidth * 0.55,
            bottom: screenHeight * 0.0,
            child: Transform.rotate(
              angle: 55 * (math.pi / 180),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: screenWidth * 0.30,
                    top: screenHeight * 0.0,
                    child: Transform.rotate(
                      angle: math.pi / 0.1,
                      child: Image.asset(
                        'assets/vectors/diamondrings.png',
                        width: screenWidth * 0.32,
                        height: screenHeight * 0.16,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    left: screenWidth * 0.52,
                    top: screenHeight * 0.02,
                    child: Transform.rotate(
                      angle: math.pi / 0.7,
                      child: Image.asset(
                        'assets/vectors/diamondrings1.png',
                        width: screenWidth * 0.36,
                        height: screenHeight * 0.19,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    left: screenWidth * 0.79,
                    top: screenHeight * 0.1,
                    child: Transform.rotate(
                      angle: math.pi / 0.6,
                      child: Image.asset(
                        'assets/vectors/goldenring.png',
                        width: screenWidth * 0.55,
                        height: screenHeight * 0.25,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Logo and text
          DiagonalLogoText(),
        ],
      ),
    );
  }
}
