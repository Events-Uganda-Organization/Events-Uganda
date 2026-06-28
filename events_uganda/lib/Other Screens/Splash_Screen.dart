import 'dart:async';
import 'dart:math' as math;
import 'dart:ui_web' as ui_web;
import 'package:events_uganda/Intro/Onboarding_Screen1.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;
  static bool _registered = false;
  web.HTMLVideoElement? _videoElement;

  @override
  void initState() {
    super.initState();
    if (!_registered) {
      _registered = true;
      _registerVideoPlayer();
    }
    _navTimer = Timer(const Duration(seconds: 10), _navigate);
  }

  void _registerVideoPlayer() {
    ui_web.platformViewRegistry.registerViewFactory(
      'splash-video',
      (int viewId) {
        _videoElement =
            web.document.createElement('video') as web.HTMLVideoElement;
        _videoElement!.src =
            'assets/videos/Bride_and_groom_merge_light_202606290000.mp4';
        _videoElement!.muted = true;
        _videoElement!.loop = true;
        _videoElement!.autoplay = true;
        _videoElement!.playsInline = true;
        _videoElement!.style
          ..width = '100%'
          ..height = '100%'
          ..objectFit = 'cover';
        return _videoElement!;
      },
    );
  }

  void _navigate() {
    _videoElement?.pause();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
      );
    }
  }

  @override
  void dispose() {
    _videoElement?.pause();
    _videoElement?.removeAttribute('src');
    _navTimer?.cancel();
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
            child: ClipRect(
              child: HtmlElementView(viewType: 'splash-video'),
            ),
          ),

          // Rings at bottom center
          Positioned(
            left: 0,
            right: 0,
            bottom: screenHeight * 0.14,
            child: Center(
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
          ),

          // Logo + Events Uganda text at bottom center
          Positioned(
            left: 0,
            right: 0,
            bottom: screenHeight * 0.04,
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
        ],
      ),
    );
  }
}
