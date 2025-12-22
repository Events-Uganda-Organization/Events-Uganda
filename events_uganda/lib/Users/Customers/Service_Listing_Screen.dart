import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:events_uganda/Bottom_Navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceListingScreen extends StatefulWidget {
  const ServiceListingScreen({super.key});

  @override
  State<ServiceListingScreen> createState() => _ServiceListingScreenState();
}

class _ServiceListingScreenState extends State<ServiceListingScreen>
    with SingleTickerProviderStateMixin {
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchFocused = false;
  Timer? _countdownTimer;
  Duration _remaining = const Duration(hours: 0, minutes: 0, seconds: 0);
  final ScrollController _promoScrollController = ScrollController();
  int _activeCardIndex = 0;
  final ScrollController _circleScrollController = ScrollController();
  int _activeCircleIndex = 0;
  final ScrollController _forYouScrollController = ScrollController();
  int _activeForYouIndex = 1;
  final ScrollController _popularNowScrollController = ScrollController();
  int _activePopularNowIndex = 1;
  final Set<int> _likedPopularNowImages = {};
  final Set<int> _cartedPopularNowImages = {};
  final Set<int> _likedImages = {};
  final Set<int> _cartedImages = {};
  final Set<int> _likedCategoryImages = {};
  final Set<int> _cartedCategoryImages = {};
  int _currentNavIndex = 0;
  String _userFullName = '';
  bool _canForwardReturn =
      false; // Controls the right-side inactive/active return button

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
    _promoScrollController.addListener(_onPromoScroll);
    _circleScrollController.addListener(_onCircleScroll);
    _popularNowScrollController.addListener(_onPopularNowScroll);
    _forYouScrollController.addListener(_onForYouScroll);
    _popularNowScrollController.addListener(_onPopularNowScroll);
    _startCountdown();
    _searchFocus.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocus.hasFocus;
      });
    });
    // Fetch user's display name if available
    _userFullName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
  }

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _onCircleScroll() {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = 70.0;
    final spacing = screenWidth * 0.03;
    final offset = _circleScrollController.offset;

    final index = ((offset + itemWidth / 2) / (itemWidth + spacing))
        .clamp(0, 4)
        .toInt();

    if (index != _activeCircleIndex) {
      setState(() => _activeCircleIndex = index);
    }
  }

  void _onPromoScroll() {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.82;
    final spacing = screenWidth * 0.04;
    final offset = _promoScrollController.offset;

    final index = ((offset + cardWidth / 2) / (cardWidth + spacing))
        .clamp(0, 2)
        .toInt();

    if (index != _activeCardIndex) {
      setState(() => _activeCardIndex = index);
    }
  }

  void _onPopularNowScroll() {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = 184.0;
    final spacing = screenWidth * 0.04;
    final offset = _popularNowScrollController.offset;
    final maxScroll = _popularNowScrollController.position.maxScrollExtent;

    int index;
    if (offset <= (imageWidth + spacing) * 0.3) {
      index = 0;
    } else if (offset >= maxScroll - (imageWidth + spacing) * 0.3) {
      index = 3;
    } else if (offset < (imageWidth + spacing) * 1.2) {
      index = 1;
    } else {
      index = 2;
    }

    if (index != _activePopularNowIndex) {
      setState(() => _activePopularNowIndex = index);
    }
  }

  void _onForYouScroll() {
    if (!mounted) return;
    final screenWidth = MediaQuery.of(context).size.width;
    final imageWidth = 184.0;
    final spacing = screenWidth * 0.04;
    final offset = _forYouScrollController.offset;
    final maxScroll = _forYouScrollController.position.maxScrollExtent;

    // Better calculation for determining centered image
    int index;
    if (offset <= (imageWidth + spacing) * 0.3) {
      index = 0; // Left image
    } else if (offset >= maxScroll - (imageWidth + spacing) * 0.3) {
      index = 3; // Right image
    } else if (offset < (imageWidth + spacing) * 1.2) {
      index = 1;
    } else {
      index = 2;
    }

    if (index != _activeForYouIndex) {
      setState(() => _activeForYouIndex = index);
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchFocus.dispose();
    _circleScrollController.dispose();
    _promoScrollController.dispose();
    _popularNowScrollController.dispose();
    _forYouScrollController.dispose();
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

  Widget _buildPopularNowImage(
    String imagePath,
    int index,
    String rating,
    String title,
    String price,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCentered = index == _activePopularNowIndex;
    final relativePosition = index - _activePopularNowIndex;
    final angle = relativePosition == -1
        ? -11 *
              3.14159 /
              180 // Left position
        : (relativePosition == 1
              ? 11 *
                    3.14159 /
                    180 // Right position
              : 0.0);

    // Adjust these values to move left/right images
    final offsetX = relativePosition == -1
        ? -28.0 // Left position
        : (relativePosition == 1
              ? 31.0 // Right position
              : 0.0); // Center or other positions

    final offsetY = relativePosition == -1
        ? 35.0 // Left position
        : (relativePosition == 1
              ? -1.0 // Right position
              : 0.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(offsetX, isCentered ? 0.0 : offsetY)
        ..rotateZ(isCentered ? 0.0 : angle),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                width: 184,
                height: 218,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: 50,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: screenWidth * 0.05,
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    rating,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: screenWidth * 0.028,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_likedPopularNowImages.contains(index)) {
                    _likedPopularNowImages.remove(index);
                  } else {
                    _likedPopularNowImages.add(index);
                  }
                });
              },
              child: AnimatedScale(
                scale: _likedPopularNowImages.contains(index) ? 1.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 1.0,
                    end: _likedPopularNowImages.contains(index) ? 1.2 : 1.0,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: screenWidth * 0.1,
                        height: screenWidth * 0.1,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            _likedPopularNowImages.contains(index)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _likedPopularNowImages.contains(index)
                                ? Colors.red
                                : Colors.white,
                            size: screenWidth * 0.07,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_cartedPopularNowImages.contains(index)) {
                    _cartedPopularNowImages.remove(index);
                  } else {
                    _cartedPopularNowImages.add(index);
                  }
                });
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 1.0,
                  end: _cartedPopularNowImages.contains(index) ? 1.2 : 1.0,
                ),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _cartedPopularNowImages.contains(index)
                              ? Colors.yellow
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: _cartedPopularNowImages.contains(index)
                              ? Colors.yellow
                              : Colors.white,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: screenWidth * 0.04,
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(height: screenWidth * 0.008),
                Text(
                  price,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.035,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouImage(
    String imagePath,
    int index,
    String rating,
    String title,
    String price,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCentered = index == _activeForYouIndex;
    final relativePosition = index - _activeForYouIndex;
    final angle = relativePosition == -1
        ? -11 *
              3.14159 /
              180 // Left position
        : (relativePosition == 1
              ? 11 *
                    3.14159 /
                    180 // Right position
              : 0.0);

    // Adjust these values to move left/right images
    final offsetX = relativePosition == -1
        ? -28.0 // Left position
        : (relativePosition == 1
              ? 31.0 // Right position
              : 0.0); // Center or other positions

    final offsetY = relativePosition == -1
        ? 35.0 // Left position
        : (relativePosition == 1
              ? -1.0 // Right position
              : 0.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      transform: Matrix4.identity()
        ..translate(offsetX, isCentered ? 0.0 : offsetY)
        ..rotateZ(isCentered ? 0.0 : angle),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                width: 184,
                height: 218,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              width: 50,
              height: 25,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: screenWidth * 0.05,
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    rating,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.028,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_likedImages.contains(index)) {
                    _likedImages.remove(index);
                  } else {
                    _likedImages.add(index);
                  }
                });
              },
              child: AnimatedScale(
                scale: _likedImages.contains(index) ? 1.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 1.0,
                    end: _likedImages.contains(index) ? 1.2 : 1.0,
                  ),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: screenWidth * 0.1,
                        height: screenWidth * 0.1,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            _likedImages.contains(index)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _likedImages.contains(index)
                                ? Colors.red
                                : Colors.white,
                            size: screenWidth * 0.07,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (_cartedImages.contains(index)) {
                    _cartedImages.remove(index);
                  } else {
                    _cartedImages.add(index);
                  }
                });
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 1.0,
                  end: _cartedImages.contains(index) ? 1.2 : 1.0,
                ),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _cartedImages.contains(index)
                              ? Colors.yellow
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: _cartedImages.contains(index)
                              ? Colors.yellow
                              : Colors.white,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: screenWidth * 0.04,
                    fontFamily: 'Montserrat',
                  ),
                ),
                SizedBox(height: screenWidth * 0.008),
                Text(
                  price,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.035,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(
    double screenWidth,
    double screenHeight,
    double promoHeight, {
    String imagePath = 'assets/images/nobgcar.png',
    String mainText = 'GET YOUR SPECIAL CAR BOOKING\n',
    String prefixText = 'UP TO ',
    String percentageText = '30%',
  }) {
    final cardWidth = screenWidth * 0.82;
    return SizedBox(
      width: cardWidth,
      child: Stack(clipBehavior: Clip.none, children: []),
    );
  }

  Widget _buildCategoryCard(
    String imagePath,
    String title,
    String rating,
    int index,
    String priceRange,
    double screenWidth,
  ) {
    final cardWidth =
        (screenWidth - (screenWidth * 0.04 * 2) - (screenWidth * 0.04)) / 2;
    final cardHeight = cardWidth * 1.185;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                width: cardWidth,
                height: cardHeight,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 50,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: screenWidth * 0.05,
                    ),
                    SizedBox(width: screenWidth * 0.01),
                    Text(
                      rating,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_likedCategoryImages.contains(index)) {
                      _likedCategoryImages.remove(index);
                    } else {
                      _likedCategoryImages.add(index);
                    }
                  });
                },
                child: AnimatedScale(
                  scale: _likedCategoryImages.contains(index) ? 1.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 1.0,
                      end: _likedCategoryImages.contains(index) ? 1.2 : 1.0,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: screenWidth * 0.1,
                          height: screenWidth * 0.1,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              _likedCategoryImages.contains(index)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _likedCategoryImages.contains(index)
                                  ? Colors.red
                                  : Colors.white,
                              size: screenWidth * 0.07,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: screenWidth * 0.035,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.008),
                      Text(
                        priceRange,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.025,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.008),
                      Text(
                        'Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.025,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_cartedCategoryImages.contains(index)) {
                      _cartedCategoryImages.remove(index);
                    } else {
                      _cartedCategoryImages.add(index);
                    }
                  });
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 1.0,
                    end: _cartedCategoryImages.contains(index) ? 1.2 : 1.0,
                  ),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(30),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.03,
                              vertical: screenWidth * 0.01,
                            ),
                            child: Center(
                              child: Text(
                                'Book',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.028,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            Positioned(
              top: screenHeight * 0.001,
              left: -screenWidth * 0.1,
              child: Image.asset(
                'assets/images/chicken.png',
                width: screenWidth * 0.4,
                height: screenWidth * 0.4,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.1,
              right: -screenWidth * 0.1,
              child: Image.asset(
                'assets/images/chicken.png',
                width: screenWidth * 0.4,
                height: screenWidth * 0.4,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              left: screenWidth * 0.04,
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
                  child: Image.asset(
                    'assets/vectors/menu.png',
                    width: screenWidth * 0.07,
                    height: screenWidth * 0.07,
                    fit: BoxFit.contain,
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
                child: Center(
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
            Positioned(
              top: screenHeight * 0.122,
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
                      offset: const Offset(2, 7),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.tune_rounded,
                    color: Colors.black,
                    size: screenWidth * 0.07,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.13,
              left: screenWidth * 0.04,
              right: screenWidth * 0.2,
              child: Container(
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isSearchFocused
                        ? const Color(0xFFCC471B)
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(2, 7),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.04),
                      child: Icon(
                        Icons.search,
                        color: Colors.black.withOpacity(0.5),
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: TextField(
                        focusNode: _searchFocus,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                          fontFamily: 'Montserrat',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for services, vendors',
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                            fontSize: screenWidth * 0.035,
                            fontFamily: 'Montserrat',
                          ),
                          border: InputBorder.none,
                          isDense: true, // Add this
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                          ), // Change to vertical: 0
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.20,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: const Color(0XFFF3CA9B),
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
            ),
            // Forward/inactive return button (mirrors back button)
            Positioned(
              top: screenHeight * 0.20,
              left: screenWidth * 0.27,
              right: screenWidth * 0.04,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catering & Food',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: _canForwardReturn
                        ? () => Navigator.of(context).maybePop()
                        : null,
                    child: Opacity(
                      opacity: _canForwardReturn ? 1.0 : 0.35,
                      child: Container(
                        width: screenWidth * 0.12,
                        height: screenWidth * 0.12,
                        decoration: BoxDecoration(
                          color: const Color(0XFFF3CA9B),
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
            Positioned(
              top: promoTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: screenWidth * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Categories',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.045,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    // Two-column grid of category images
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Wrap(
                        spacing: screenWidth * 0.04,
                        runSpacing: screenWidth * 0.04,
                        children: [
                          _buildCategoryCard(
                            'assets/images/deco5.jpg',
                            'Provider\'s Name',
                            '4.8',
                            0,
                            'UGX 500K - 2M',
                            screenWidth,
                          ),
                          _buildCategoryCard(
                            'assets/images/catering.jpg',
                            'Provider\'s Name',
                            '4.6',
                            1,
                            'UGX 400K - 1.5M',
                            screenWidth,
                          ),
                          _buildCategoryCard(
                            'assets/images/photography.jpg',
                            'Provider\'s Name',
                            '4.9',
                            2,
                            'UGX 600K - 3M',
                            screenWidth,
                          ),
                          _buildCategoryCard(
                            'assets/images/carhire1.jpg',
                            'Provider\'s Name',
                            '4.7',
                            3,
                            'UGX 300K - 1.2M',
                            screenWidth,
                          ),
                          _buildCategoryCard(
                            'assets/images/cake2.jpg',
                            'Provider\'s Name',
                            '4.5',
                            4,
                            'UGX 200K - 800K',
                            screenWidth,
                          ),
                          _buildCategoryCard(
                            'assets/images/cake4.jpg',
                            'Provider\'s Name',
                            '4.9',
                            5,
                            'UGX 800K - 2.5M',
                            screenWidth,
                          ),
                          _buildCategoryCard(
                            'assets/images/deco3.jpg',
                            'Provider\'s Name',
                            '4.4',
                            6,
                            'UGX 400K - 1.8M',
                            screenWidth,
                          ),
                          _buildCategoryCard(
                            'assets/images/glassdeco.jpg',
                            'Provider\'s Name',
                            '4.7',
                            7,
                            'UGX 350K - 1.5M',
                            screenWidth,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.1),
                  ],
                ),
              ),
            ),
            // Bottom Navigation Bar - Floating
            Positioned(
              bottom: screenHeight * 0.02,
              left: 0,
              right: 0,
              child: Center(
                child: BottomNavbar(
                  activeIndex: _currentNavIndex,
                  onItemSelected: (index) {
                    setState(() {
                      _currentNavIndex = index;
                    });
                    // Add navigation logic here if needed
                    // if (index == 0) { Navigator.push(...) }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
