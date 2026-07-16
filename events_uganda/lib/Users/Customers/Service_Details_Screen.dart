import 'dart:async';
import 'dart:ui';
import 'package:events_uganda/Users/Date_Of_Booking_Screen.dart';
import 'package:flutter/material.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';

class ServiceDetailsScreen extends StatefulWidget {
  const ServiceDetailsScreen({super.key});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _reviewController = TextEditingController();
  bool _hasText = false;
  final List<ReviewModel> _reviews = [];
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
  int _rating = 0;
  bool _showReviewSection = false;
  bool _showAllReviews = false;
  bool _canForwardReturn = false;
  int _currentNavIndex = 0;
  bool _isNavbarVisible = true;
  late AnimationController _navbarSlideController;
  late Animation<Offset> _navbarSlideAnimation;

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
    _navbarSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _navbarSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 3),
    ).animate(
      CurvedAnimation(parent: _navbarSlideController, curve: Curves.easeInOut),
    );
    _startCountdown();
    _searchFocus.addListener(() {});
    // Fetch user's display name if available
    AuthService.getUser().then((userData) {
      if (mounted) {
        setState(() {
          _userFullName = userData?['fullName'] as String? ?? 'User';
        });
      }
    });
  }

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _hideNavbar() {
    _navbarSlideController.forward();
    setState(() => _isNavbarVisible = false);
  }

  void _showNavbar() {
    _navbarSlideController.reverse();
    setState(() => _isNavbarVisible = true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _navbarSlideController.dispose();
    _countdownTimer?.cancel();
    _galleryScrollController.dispose();
    _reviewController.dispose();
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

    final offset = screenHeight * 0.13;
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
            // Back and forward buttons
            Positioned(
              top: screenHeight * 0.035,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: screenWidth * 0.128,
                      height: screenWidth * 0.128,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3CA9B),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.black,
                          size: screenWidth * 0.10,
                        ),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: _canForwardReturn ? 1.0 : 0.35,
                    child: GestureDetector(
                      onTap: _canForwardReturn
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DateOfBookingScreen(),
                                ),
                              ).then((_) {
                                if (mounted) setState(() {});
                              });
                            }
                          : null,
                      child: Container(
                        width: screenWidth * 0.128,
                        height: screenWidth * 0.128,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3CA9B),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.black,
                            size: screenWidth * 0.10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
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
                      fontSize: screenWidth * 0.038,
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
                      color: Colors.black.withValues(alpha: 0.15),
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
              top: screenHeight * 0.03,
              right: screenWidth * 0.04,
  child: GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NotificationScreen(),
        ),
      );
    },
    child: Container(
      width: screenWidth * 0.128,
      height: screenWidth * 0.128,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
            ),
            Positioned(
              top: offset,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // ===== IMAGE + BADGE + GALLERY OVERLAY =====
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Stack(
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
                          // Available badge
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 80,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: Text(
                                    'Available',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.03,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Abril Fatface',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Glassy gallery
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                  child: Container(
                                    width: 315,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
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
                                                _galleryScrollIndex = (_galleryScrollIndex - 1).clamp(0, _galleryImages.length - 1);
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
                                                angle: 3.1416,
                                                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                                              ),
                                            ),
                                          ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            controller: _galleryScrollController,
                                            scrollDirection: Axis.horizontal,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _galleryImages.length,
                                            itemBuilder: (context, i) => Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child: GestureDetector(
                                                onTap: () { setState(() { _selectedGalleryIndex = i; }); },
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      border: _selectedGalleryIndex == i ? Border.all(color: Colors.white, width: 2) : null,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Image.asset(_galleryImages[i], width: 42, height: 42, fit: BoxFit.cover),
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
                                                _galleryScrollIndex = (_galleryScrollIndex + 1).clamp(0, (_galleryImages.length - 5).clamp(0, _galleryImages.length));
                                              });
                                              _galleryScrollController.animateTo(
                                                (_galleryScrollIndex) * 50.0,
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.ease,
                                              );
                                            },
                                            child: SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                                            ),
                                          ),
                                        SizedBox(width: 6),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    // ===== PROVIDER NAME + INFO =====
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(32 * (screenWidth / 412)),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.008,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24 * (screenWidth / 412)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Provider's Name", style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w900, fontSize: screenWidth * 0.0341, color: Colors.black)),
                                          ],
                                        ),
                                        SizedBox(width: screenWidth * 0.016),
                                        Icon(Icons.verified, color: Colors.blue, size: screenWidth * 0.055),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () { setState(() { _isFavorite = !_isFavorite; }); _animationController.forward().then((_) => _animationController.reverse()); },
                                        child: Container(
                                          width: 43,
                                          height: 43,
                                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 6))]),
                                          child: Center(
                                            child: ScaleTransition(
                                              scale: _scaleAnimation,
                                              child: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : const Color.fromARGB(255, 182, 113, 34), size: 31),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          width: 45,
                                          height: 45,
                                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 6))]),
                                          child: const Center(child: Icon(Icons.share, color: Color.fromARGB(255, 182, 113, 34), size: 31)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("4.8", style: TextStyle(fontFamily: 'Abril Fatface', fontWeight: FontWeight.w900, fontSize: screenWidth * 0.035, color: Colors.black)),
                                          SizedBox(width: screenWidth * 0.008),
                                          Icon(Icons.star, color: Colors.black, size: screenWidth * 0.03),
                                          SizedBox(width: screenWidth * 0.006),
                                          Icon(Icons.chevron_right, color: Colors.black, size: screenWidth * 0.04),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.004),
                                      Text("(120 Reviews)", style: TextStyle(fontFamily: 'Abril Fatface', fontWeight: FontWeight.w500, fontSize: screenWidth * 0.03, color: Colors.black)),
                                    ],
                                  ),
                                  Container(width: 5, height: 45, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(5))),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text("Kampala", style: TextStyle(fontFamily: 'Abril Fatface', fontWeight: FontWeight.w900, fontSize: screenWidth * 0.035, color: Colors.black)),
                                      SizedBox(height: screenHeight * 0.004),
                                      Text("2.8 km away", style: TextStyle(fontFamily: 'Abril Fatface', fontWeight: FontWeight.w500, fontSize: screenWidth * 0.03, color: Colors.black)),
                                    ],
                                  ),
                                  Container(width: 5, height: 45, decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(5))),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text("5+", style: TextStyle(fontFamily: 'Abril Fatface', fontWeight: FontWeight.w900, fontSize: screenWidth * 0.034, color: Colors.black)),
                                      SizedBox(height: screenHeight * 0.004),
                                      Text("Years of Experience", style: TextStyle(fontFamily: 'Abril Fatface', fontWeight: FontWeight.w500, fontSize: screenWidth * 0.03, color: Colors.black)),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.018),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: screenWidth * 0.38,
                                    height: 30,
                                    decoration: BoxDecoration(color: Color(0xFFFFC107), borderRadius: BorderRadius.circular(20)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.call, color: Color(0xFF5A5A00), size: 20),
                                        SizedBox(width: 8),
                                        Text('Call Now', style: TextStyle(color: Color(0xFF5A5A00), fontWeight: FontWeight.bold, fontSize: screenWidth * 0.034, fontFamily: 'Montserrat')),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: screenWidth * 0.38,
                                    height: 30,
                                    decoration: BoxDecoration(color: Color(0xFFFFC107), borderRadius: BorderRadius.circular(20)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.message, color: Color(0xFF5A5A00), size: 20),
                                        SizedBox(width: 8),
                                        Text('Message', style: TextStyle(color: Color(0xFF5A5A00), fontWeight: FontWeight.bold, fontSize: screenWidth * 0.034, fontFamily: 'Montserrat')),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(
                            32 * (screenWidth / 412),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ===== WHITE CARD 1: PRICE + AVAILABILITY =====
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    24 * (screenWidth / 412),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Starting Price
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Starting Price",
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w900,
                                            fontSize: screenWidth * 0.0341,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.01),
                                        _priceCard(screenWidth),
                                      ],
                                    ),

                                    // Availability
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Availability",
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w900,
                                            fontSize: screenWidth * 0.0341,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.01),
                                        _availabilityCard(screenWidth),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              // ===== WHITE CARD 2: SERVICES OFFERED =====
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.012,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    24 * (screenWidth / 412),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Services Offered",
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w900,
                                        fontSize: screenWidth * 0.0341,
                                        color: Colors.black,
                                      ),
                                    ),

                                    SizedBox(height: screenHeight * 0.01),

                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Left column
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.restaurant_menu,
                                                    color: Colors.black,
                                                    size: screenWidth * 0.055,
                                                  ),
                                                  SizedBox(
                                                    width: screenWidth * 0.02,
                                                  ),
                                                  Text(
                                                    'Catering for weddings',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Abril Fatface',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          screenWidth * 0.04,
                                                      color: Colors.black,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.012,
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.business,
                                                    color: Colors.black,
                                                    size: screenWidth * 0.055,
                                                  ),
                                                  SizedBox(
                                                    width: screenWidth * 0.02,
                                                  ),
                                                  Text(
                                                    'Corporate Catering',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Abril Fatface',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          screenWidth * 0.04,
                                                      color: Colors.black,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: screenHeight * 0.012,
                                              ),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.outdoor_grill,
                                                    color: Colors.black,
                                                    size: screenWidth * 0.055,
                                                  ),
                                                  SizedBox(
                                                    width: screenWidth * 0.02,
                                                  ),
                                                  Text(
                                                    'Outside Catering',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          'Abril Fatface',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize:
                                                          screenWidth * 0.04,
                                                      color: Colors.black,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          SizedBox(width: screenWidth * 0.022),

                                          Container(
                                            width: screenWidth * 0.012,
                                            height: screenHeight * 0.12,
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    screenWidth * 0.01,
                                                  ),
                                            ),
                                          ),

                                          SizedBox(width: screenWidth * 0.022),

                                          SizedBox(
                                            width: screenWidth * 0.35,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.food_bank_rounded,
                                                      color: Colors.black,
                                                      size: screenWidth * 0.055,
                                                    ),
                                                    SizedBox(
                                                      width: screenWidth * 0.02,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        'Buffet Setup',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Abril Fatface',
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize:
                                                              screenWidth *
                                                              0.04,
                                                          color: Colors.black,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: screenHeight * 0.015,
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.soup_kitchen,
                                                      color: Colors.black,
                                                      size: screenWidth * 0.055,
                                                    ),
                                                    SizedBox(
                                                      width: screenWidth * 0.02,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        'Traditional Food',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Abril Fatface',
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize:
                                                              screenWidth *
                                                              0.04,
                                                          color: Colors.black,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== ABOUT PROVIDER TITLE CARD =====
                          Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02,
                                vertical: screenHeight * 0.006,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(
                                  32 * (screenWidth / 412),
                                ),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenHeight * 0.008,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    24 * (screenWidth / 412),
                                  ),
                                ),
                                child: Column(
                                  // Wrap multiple widgets in a Column
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    Text(
                                      "About Provider Name",
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontWeight: FontWeight.w900,
                                        fontSize: screenWidth * 0.0341,
                                        color: Colors.black,
                                      ),
                                    ),

                                    SizedBox(height: screenHeight * 0.015),

                                    // Description
                                    Text(
                                      'The Providers description of the services he/she\nprovides to the customers.',
                                      style: TextStyle(
                                        fontFamily: 'Abril Fatface',
                                        fontWeight: FontWeight.w500,
                                        fontSize: screenWidth * 0.034,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(
                            32 * (screenWidth / 412),
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.02,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              24 * (screenWidth / 412),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ===== TITLE =====
                              Text(
                                "Reviews and Ratings",
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.w900,
                                    fontSize: screenWidth * 0.0341,
                                    color: Colors.black,
                                  ),
                                ),

                                SizedBox(height: screenHeight * 0.008),

                                // ===== SUBTITLE =====
                                Text(
                                  'Rate these services',
                                  style: TextStyle(
                                    fontFamily: 'Abril Fatface',
                                    fontWeight: FontWeight.w500,
                                    fontSize: screenWidth * 0.034,
                                    color: Colors.black,
                                  ),
                                ),

                                SizedBox(height: screenHeight * 0.02),

                                // ===== STARS =====
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      5,
                                      (index) => GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _rating = index + 1;
                                          });
                                          _animationController.forward().then(
                                            (_) =>
                                                _animationController.reverse(),
                                          );
                                        },
                                        child: ScaleTransition(
                                          scale: _scaleAnimation,
                                          child: Icon(
                                            index < _rating
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: screenWidth * 0.15,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: screenHeight * 0.02),

                                // ===== WRITE REVIEW =====
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showReviewSection =
                                            !_showReviewSection;
                                      });
                                    },
                                    child: Text(
                                      'Write a review',
                                      style: TextStyle(
                                        color: const Color.fromARGB(
                                          255,
                                          228,
                                          172,
                                          1,
                                        ),
                                        fontSize: screenWidth * 0.038,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Abril Fatface',
                                        shadows: [
                                          Shadow(
                                            color: Colors.amber,
                                            blurRadius: 10,
                                            offset: Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                if (_showReviewSection) ...[
                                  SizedBox(height: screenHeight * 0.025),
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.amber,
                                        width: 1,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            12,
                                            48,
                                            12,
                                          ),
                                          child: TextField(
                                            controller: _reviewController,
                                            maxLines: 3,
                                            onChanged: (value) {
                                              setState(() {
                                                _hasText = value
                                                    .trim()
                                                    .isNotEmpty;
                                              });
                                            },
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Write your review here...',
                                              border: InputBorder.none,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: AnimatedOpacity(
                                            opacity: _hasText ? 1 : 0.3,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: GestureDetector(
                                              onTap: _hasText
                                                  ? () async {
                                                      final now =
                                                          DateTime.now();
                                                      final date =
                                                          '${now.day.toString().padLeft(2, '0')}/'
                                                          '${now.month.toString().padLeft(2, '0')}/'
                                                          '${now.year}';
                                                      final userData =
                                                          await AuthService.getUser();
                                                      final newReview = ReviewModel(
                                                        id: DateTime.now()
                                                            .millisecondsSinceEpoch
                                                            .toString(),
                                                        userName:
                                                            userData?['fullName']
                                                                as String? ??
                                                            'User Name',
                                                        userImageUrl: '',
                                                        reviewText:
                                                            _reviewController
                                                                .text
                                                                .trim(),
                                                        date: date,
                                                        rating: _rating > 0
                                                            ? _rating
                                                            : 5,
                                                      );

                                                      setState(() {
                                                        _reviews.insert(
                                                          0,
                                                          newReview,
                                                        );
                                                        _hasText = false;
                                                      });
                                                      _reviewController.clear();
                                                    }
                                                  : null,
                                              child: Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: _hasText
                                                      ? Colors.amber
                                                      : Colors.grey.shade300,
                                                  shape: BoxShape.circle,
                                                  boxShadow: _hasText
                                                      ? [
                                                          BoxShadow(
                                                            color: Colors.amber
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  4,
                                                                ),
                                                          ),
                                                        ]
                                                      : [],
                                                ),
                                                child: const Icon(
                                                  Icons.send_rounded,
                                                  color: Colors.black,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: screenHeight * 0.006,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(
                              32 * (screenWidth / 412),
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: screenHeight * 0.018,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                24 * (screenWidth / 412),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rating and some reviews are verified and are\nfrom people who use the same type of device that you use.',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.038,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Abril Fatface',
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // LEFT: Rating column
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '4.8',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: screenWidth * 0.15,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Abril Fatface',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildStarRating(4.8, starSize: 24),
                                      ],
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    // CENTER: Vertical separator
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: screenHeight * 0.02,
                                      ),
                                      child: Container(
                                        width: screenWidth * 0.012,
                                        height: screenHeight * 0.16,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.01,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    // RIGHT: Rating distribution bars
                                    _buildRatingBars(screenWidth),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.025),
                                _buildReviewsList(screenWidth),
                              ],
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: (screenWidth - 270) / 2,
              child: Container(
                width: 270,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3CA9B),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color.fromARGB(255, 182, 122, 53),
                    width: 1,
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DateOfBookingScreen(),
                      ),
                    ).then((_) {
                      if (mounted) {
                        setState(() {
                          _canForwardReturn = true;
                        });
                      }
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Book Now',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      SizedBox(width: 8),
                      Transform.rotate(
                        angle: -40 * 3.14159 / 180,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Navbar - swipe down to hide
            Positioned(
              bottom: screenHeight * 0.02,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity! > 300) {
                    _hideNavbar();
                  }
                },
                child: SlideTransition(
                  position: _navbarSlideAnimation,
                  child: Center(
                    child: BottomNavbar(
                      activeIndex: _currentNavIndex,
                      onItemSelected: (index) {
                        setState(() {
                          _currentNavIndex = index;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Green circle to show navbar when hidden
            if (!_isNavbarVisible)
              Positioned(
                bottom: screenHeight * 0.06,
                right: screenWidth * 0.06,
                child: GestureDetector(
                  onTap: _showNavbar,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7EED27),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(double screenWidth) {
    final reviewsToShow = _showAllReviews
        ? _reviews
        : _reviews.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviewsToShow.length,
          itemBuilder: (context, index) {
            return _buildReviewCard(reviewsToShow[index], screenWidth);
          },
        ),
        if (_reviews.length > 2 && !_showAllReviews)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAllReviews = true;
                  });
                },
                child: Text(
                  'See more',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 228, 172, 1),
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Abril Fatface',
                    shadows: [
                      Shadow(
                        color: Colors.amber,
                        blurRadius: 10,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_reviews.length > 2 && _showAllReviews)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showAllReviews = false;
                  });
                },
                child: Text(
                  'Show less',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 228, 172, 1),
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Abril Fatface',
                    shadows: [
                      Shadow(
                        color: Colors.amber,
                        blurRadius: 10,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(ReviewModel review, double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: review.userImageUrl.isNotEmpty
                    ? NetworkImage(review.userImageUrl)
                    : null,
                child: review.userImageUrl.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        _buildStaticStars(review.rating),
                        const SizedBox(width: 8),
                        Text(
                          review.date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _reviewMenu(review),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black),
            ),
            child: Text(review.reviewText),
          ),
        ],
      ),
    );
  }

  Widget _reviewMenu(ReviewModel review) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          setState(() {
            _reviews.removeWhere((r) => r.id == review.id);
          });
        }
        if (value == 'edit') {
          _reviewController.text = review.reviewText;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }



  Widget _buildStaticStars(int count) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          Icons.star,
          size: 14,
          color: index < count ? Colors.amber : Colors.black26,
        ),
      ),
    );
  }


}

Widget _availabilityCard(double screenWidth) {
  return Container(
    width: screenWidth * 0.42, // same width
    height: 35,
    decoration: BoxDecoration(
      color: const Color(0xFFF3CA9B),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: const Color.fromARGB(255, 182, 122, 53),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.calendar_month_rounded, color: Colors.black, size: 20),
        SizedBox(width: 4),
        Text(
          'DD/MM/YYYY',
          style: TextStyle(
            fontFamily: 'Abril Fatface',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}

Widget _priceCard(double screenWidth) {
  return Container(
    width: screenWidth * 0.40,
    height: 35,
    decoration: BoxDecoration(
      color: const Color(0xFFF3CA9B),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: const Color.fromARGB(255, 182, 122, 53),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.payments, color: Colors.black, size: 20),
        SizedBox(width: 4),
        Text(
          'UGX 800,000',
          style: TextStyle(
            fontFamily: 'Abril Fatface',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}

Widget _buildStarRating(double rating, {double starSize = 20}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: List.generate(5, (index) {
          double fillAmount;

          if (index + 1 <= rating) {
            fillAmount = 1; // full star
          } else if (index < rating) {
            fillAmount = rating - index; // partial star
          } else {
            fillAmount = 0; // empty
          }

          return Stack(
            children: [
              Icon(Icons.star, color: Colors.black, size: starSize),
              ClipRect(
                clipper: _StarClipper(fillAmount),
                child: Icon(Icons.star, color: Colors.amber, size: starSize),
              ),
            ],
          );
        }),
      ),

      const SizedBox(height: 2),

      Text(
        'Number of reviews',
        style: TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _StarClipper extends CustomClipper<Rect> {
  final double fill;

  _StarClipper(this.fill);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0, 0, size.width * fill, size.height);
  }

  @override
  bool shouldReclip(_StarClipper oldClipper) {
    return oldClipper.fill != fill;
  }
}

class ReviewModel {
  final String id;
  final String userName;
  final String userImageUrl;
  final String reviewText;
  final String date;
  final int rating;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.userImageUrl,
    required this.reviewText,
    required this.date,
    required this.rating,
  });
}

Widget _buildRatingBars(double screenWidth) {
  final List<double> ratings = [
    0.9, // 5 stars
    0.6, // 4 stars
    0.2, // 3 stars
    0.1, // 2 stars
    0.05, // 1 star
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(5, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // Rating number (5–1)
            Text(
              '${5 - index}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),

            const SizedBox(width: 6),

            // Bar background + fill
            Stack(
              children: [
                Container(
                  width: screenWidth * 0.33,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                Container(
                  width: screenWidth * 0.33 * ratings[index],
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }),
  );
}
