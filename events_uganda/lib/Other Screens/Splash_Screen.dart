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
          left: screenWidth * 0.01,
          top: screenHeight * 0.44,
          child: Transform.rotate(
            angle: 0.95,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/vectors/logo.png',
                  width: screenWidth * 0.18,
                  height: screenWidth * 0.18,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: screenWidth * 0.04),
                Text(
                  'Events Uganda',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: screenWidth * 0.11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
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

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(
      'assets/videos/Bride_and_groom_merge_light_202606290000.mp4',
    )
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        setState(() {});
        _videoController.play();
      });

    Timer(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
      );
    });
  }

  @override
  void dispose() {
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
          if (_videoController.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            const SizedBox.expand(child: ColoredBox(color: Colors.black)),

          // Ring images (bottom-right decorative container)
          Positioned(
            right: screenWidth * 0.55,
            bottom: screenHeight * 0.0,
            child: Transform.rotate(
              angle: 55 * (math.pi / 180),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                      color: const Color(0xFF31373A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
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
