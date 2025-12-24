import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceDetailsScreen extends StatefulWidget {
  const ServiceDetailsScreen({super.key});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _galleryScrollController = ScrollController();
  int _galleryScrollIndex = 0;
  // List of images for the glassy rectangle
  final List<String> _galleryImages = [
    'assets/images/introductionbride.jpg',
    'assets/images/deco2.jpg',
    'assets/images/deco3.jpg',
    'assets/images/deco4.jpg',
    'assets/images/deco5.jpg',
    'assets/images/glassdeco.jpg',
    'assets/images/brideandladies.jpg',
    'assets/images/brideandgroom.jpg',
    'assets/images/blacknwhitemen.jpg',
    'assets/images/deco2.jpg',
  ];
  int _selectedGalleryIndex = 0;
  final FocusNode _searchFocus = FocusNode();
  Timer? _countdownTimer;
  bool _isFavorite = false;
  Duration _remaining = const Duration(hours: 0, minutes: 0, seconds: 0);
  String _userFullName = '';
  String? _profilePicUrl;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  Widget _buildCircleItem(
    double screenWidth,
    double screenHeight,
    String imagePath,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.008),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: screenWidth * 0.032,
            color: Colors.black,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(_animationController);
    _startCountdown();
    _searchFocus.addListener(() {});
    // Fetch user's display name if available
    _userFullName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
  }

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    _galleryScrollController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining -= const Duration(seconds: 1);
        } else {
          _countdownTimer?.cancel();
        }
      });
    });
  }

  String _fmt(int v) => v.toString().padLeft(2, '0');

  String get countdownText {
    final hours = _remaining.inHours.remainder(24);
    final mins = _remaining.inMinutes.remainder(60);
    final secs = _remaining.inSeconds.remainder(60);
    return '${_fmt(hours)}:${_fmt(mins)}:${_fmt(secs)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final promoTop =
        screenHeight * 0.19 + screenWidth * 0.12 + screenHeight * 0.02;
    final promoHeight = screenWidth * 0.46;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.0,
              bottom: MediaQuery.of(context).size.height * 0.0,
              right:
                  (MediaQuery.of(context).size.width +
                      MediaQuery.of(context).size.width * 1) /
                  300,
              child: Image.asset(
                'assets/backgroundcolors/normalscreen.png',
                width: MediaQuery.of(context).size.width * 1.08,
                height: MediaQuery.of(context).size.height * 0.9,
                fit: BoxFit.contain,
              ),
            ),
            // Back button
            Positioned(
              top: MediaQuery.of(context).size.height * 0.035,
              left: MediaQuery.of(context).size.width * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.13,
                  height: MediaQuery.of(context).size.width * 0.13,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3CA9B),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: MediaQuery.of(context).size.width * 0.10,
                    ),
                  ),
                ),
              ),
            ),
            // Greeting and user name to the right of the menu circle
            Positioned(
              top: screenHeight * 0.03 + screenWidth * 0.015,
              left:
                  screenWidth * 0.04 + screenWidth * 0.128 + screenWidth * 0.03,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greetingText,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.005),
                  Text(
                    _userFullName,
                    style: TextStyle(
                      fontFamily: 'Abril Fatface',
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.038,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            // Introduction image
            Positioned(
              top: screenHeight * 0.13,
              left: (screenWidth - screenWidth * 0.95) / 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.asset(
                      _galleryImages[_selectedGalleryIndex],
                      width: screenWidth * 0.95,
                      height: screenWidth * 0.95 * (336 / 350),
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.021),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Provider's Name",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w900,
                              fontSize: screenWidth * 0.048,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.020),
                          Padding(
                            padding: EdgeInsets.only(left: screenWidth * 0.02),
                            child: Row(
                              children: [
                                Text(
                                  "4.8",
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.045,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Icon(
                                  Icons.star,
                                  color: Colors.black,
                                  fill: 1.0,
                                  size: screenWidth * 0.045,
                                ),
                                SizedBox(width: screenWidth * 0.005),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.black,
                                  size: screenWidth * 0.06,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.005),
                          Text(
                            "(120 reviews)",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w500,
                              fontSize: screenWidth * 0.035,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: screenWidth * 0.018),
                      Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: screenWidth * 0.055,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: screenHeight * 0.43,
              left: (screenWidth - screenWidth * 1.9) / 1,
              child: Container(
                width: 5,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            // Glassy UI Rectangle at bottom of image
            Positioned(
              top:
                  screenHeight * 0.12 + (screenWidth * 0.95 * (336 / 350)) - 55,
              left: (screenWidth - 315) / 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    width: 315,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 6),
                        if (_galleryScrollIndex > 0)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _galleryScrollIndex = (_galleryScrollIndex - 1)
                                    .clamp(0, _galleryImages.length - 1);
                              });
                              _galleryScrollController.animateTo(
                                (_galleryScrollIndex) * 50.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease,
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: Transform.rotate(
                                angle: 3.1416, // 180° → face left
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(width: 6),
                        Expanded(
                          child: ListView.builder(
                            controller: _galleryScrollController,
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _galleryImages.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedGalleryIndex = i;
                                  });
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: _selectedGalleryIndex == i
                                          ? Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            )
                                          : null,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Image.asset(
                                      _galleryImages[i],
                                      width: 42,
                                      height: 42,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        if (_galleryScrollIndex < _galleryImages.length - 5)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _galleryScrollIndex = (_galleryScrollIndex + 1)
                                    .clamp(
                                      0,
                                      (_galleryImages.length - 5).clamp(
                                        0,
                                        _galleryImages.length,
                                      ),
                                    );
                              });
                              _galleryScrollController.animateTo(
                                (_galleryScrollIndex) * 50.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease,
                              );
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        SizedBox(width: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Heart circle as a separate Positioned below the image on the right
            Positioned(
              top:
                  screenHeight * 0.12 +
                  screenWidth * 0.95 * (336 / 350) +
                  16, // 16px below image
              left:
                  (screenWidth - screenWidth * 0.95) / 2 +
                  screenWidth * 0.95 -
                  110, // right edge of image minus circle size
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isFavorite = !_isFavorite;
                  });
                  _animationController.forward().then(
                    (_) => _animationController.reverse(),
                  );
                },
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite
                            ? Colors.red
                            : const Color.fromARGB(255, 182, 113, 34),
                        size: 31,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              right: screenWidth * 0.2,
              child: Container(
                width: screenWidth * 0.128,
                height: screenWidth * 0.128,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: _profilePicUrl != null && _profilePicUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _profilePicUrl!,
                          width: screenWidth * 0.128,
                          height: screenWidth * 0.128,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.person,
                                color: Colors.black,
                                size: screenWidth * 0.07,
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.black,
                          size: screenWidth * 0.07,
                        ),
                      ),
              ),
            ),
            Positioned(
              top:
                  screenHeight * 0.12 +
                  screenWidth * 0.95 * (336 / 350) +
                  16, // 16px below image
              left:
                  (screenWidth - screenWidth * 0.95) / 2 +
                  screenWidth * 0.95 -
                  45,
              child: GestureDetector(
                onTap: () {
                  // Add share functionality here
                },
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.share,
                      color: Color.fromARGB(255, 182, 113, 34),
                      size: 31,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              right: screenWidth * 0.04,
              child: Container(
                width: screenWidth * 0.128,
                height: screenWidth * 0.128,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: Colors.black,
                    size: screenWidth * 0.07,
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
