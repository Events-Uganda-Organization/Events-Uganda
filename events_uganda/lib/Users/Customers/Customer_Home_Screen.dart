import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:events_uganda/Users/Customers/All_Categories_Screen.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with SingleTickerProviderStateMixin {
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchFocused = false;
  Timer? _countdownTimer;
  Duration _remaining = Duration(
    hours: Random().nextInt(24),
    minutes: Random().nextInt(60),
    seconds: Random().nextInt(60),
  );
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
  int _currentNavIndex = 0;
  String _userFullName = '';
  String? _profilePicUrl;

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
    _startCountdown();
    _searchFocus.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocus.hasFocus;
      });
    });
    // Fetch user's display name if available
    _userFullName = FirebaseAuth.instance.currentUser?.displayName ?? 'User';
    _loadUserProfile();
  }

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Future<void> _loadUserProfile() async {
    try {
      // First try to get from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.photoURL != null) {
        setState(() {
          _profilePicUrl = currentUser.photoURL;
        });
        return;
      }

      // If not available, get from Firestore using saved userId
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null && data['profilePicUrl'] != null) {
            setState(() {
              _profilePicUrl = data['profilePicUrl'] as String?;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      // Pick image from gallery
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      // Get current user ID
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      if (userId == null) {
        debugPrint('User ID not found');
        return;
      }

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      await storageRef.putFile(File(image.path));

      // Get download URL
      final downloadURL = await storageRef.getDownloadURL();

      // Save URL to Firestore
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profilePicUrl': downloadURL,
      });

      // Update local state
      setState(() {
        _profilePicUrl = downloadURL;
      });

      debugPrint('Profile picture uploaded successfully: $downloadURL');
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
    }
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: promoHeight,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(2, 7),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.035,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Montserrat',
                            ),
                            children: [
                              TextSpan(text: mainText),
                              TextSpan(text: prefixText),
                              TextSpan(
                                text: percentageText,
                                style: TextStyle(
                                  color: const Color(0xFFB47A25),
                                  fontSize: screenWidth * 0.06,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Time Left',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.036,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Abril Fatface',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.007),
                        Row(
                          children: [
                            Text(
                              countdownText,
                              style: TextStyle(
                                color: const Color.fromARGB(255, 210, 141, 38),
                                fontSize: screenWidth * 0.033,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Montserrat',
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.028,
                                vertical: screenHeight * 0.006,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB47A25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'BOOK NOW',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.026,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.0),
                  Image.asset(
                    'assets/backgroundcolors/booking.png',
                    width: screenWidth * 0.30,
                    height: screenWidth * 0.30,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -screenWidth * 0.02,
            right: -screenWidth * 0.04,
            child: Image.asset(
              imagePath,
              width: screenWidth * 0.35,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final promoTop =
        screenHeight * 0.13 + screenWidth * 0.12 + screenHeight * 0.02;
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
              top: promoTop,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: promoHeight + screenWidth * 0.05,
                      child: SingleChildScrollView(
                        controller: _promoScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                        ),
                        child: Row(
                          children: List.generate(3, (index) {
                            final isLast = index == 2;
                            final images = [
                              'assets/images/nobgcar.png',
                              'assets/images/nobgcake.png',
                              'assets/images/bgcake1.png',
                            ];
                            final promoData = [
                              {
                                'main': 'GET YOUR SPECIAL CAR BOOKING\n',
                                'prefix': 'UP TO ',
                                'percent': '30%',
                              },
                              {
                                'main': 'GET YOUR INTRODUCTION CAKE\n',
                                'prefix': 'SAVE ',
                                'percent': '25%',
                              },
                              {
                                'main': 'LUXURY CAKES AVAILABLE\n',
                                'prefix': 'GET ',
                                'percent': '40%',
                              },
                            ];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: isLast ? 0 : screenWidth * 0.04,
                              ),
                              child: _buildPromoCard(
                                screenWidth,
                                screenHeight,
                                promoHeight,
                                imagePath: images[index],
                                mainText: promoData[index]['main'] as String,
                                prefixText:
                                    promoData[index]['prefix'] as String,
                                percentageText:
                                    promoData[index]['percent'] as String,
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final isActive = index == _activeCardIndex;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.015,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            width: isActive
                                ? screenWidth * 0.035
                                : screenWidth * 0.025,
                            height: isActive
                                ? screenWidth * 0.035
                                : screenWidth * 0.025,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFB47A25)
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Categories Quick Access',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.045,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllCategoriesScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth * 0.030,
                                color: const Color(0xFFB47A25),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    SingleChildScrollView(
                      controller: _circleScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        children: [
                          _buildCircleItem(
                            screenWidth,
                            screenHeight,
                            'assets/images/deco5.jpg',
                            'Decoration',
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildCircleItem(
                            screenWidth,
                            screenHeight,
                            'assets/images/catering.jpg',
                            'Catering',
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildCircleItem(
                            screenWidth,
                            screenHeight,
                            'assets/images/photography.jpg',
                            'Photography\n& Videography',
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildCircleItem(
                            screenWidth,
                            screenHeight,
                            'assets/images/carhire1.jpg',
                            'Car Hire',
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          _buildCircleItem(
                            screenWidth,
                            screenHeight,
                            'assets/images/cake2.jpg',
                            'Cakes',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final isActive = index == _activeCircleIndex;
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.015,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            width: isActive
                                ? screenWidth * 0.035
                                : screenWidth * 0.025,
                            height: isActive
                                ? screenWidth * 0.035
                                : screenWidth * 0.025,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFB47A25)
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'For You',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.045,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'View All',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.030,
                              color: const Color(0xFFB47A25),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    SizedBox(
                      height: 240,
                      child: SingleChildScrollView(
                        controller: _forYouScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                        ),
                        child: Row(
                          children: [
                            _buildForYouImage(
                              'assets/images/cake4.jpg',
                              0,
                              '4.8',
                              'Cake Design',
                              '1,500,000 UGX',
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            _buildForYouImage(
                              'assets/images/deco3.jpg',
                              1,
                              '4.5',
                              'Tent Decoration',
                              '2,000,000 UGX',
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            _buildForYouImage(
                              'assets/images/blacknwhitemen.jpg',
                              2,
                              '4.9',
                              'Photography',
                              '3,100,000 UGX',
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            _buildForYouImage(
                              'assets/images/glassdeco.jpg',
                              3,
                              '4.7',
                              'Decoration',
                              '6,000,000 UGX',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Popular Now',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.045,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'View All',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.030,
                              color: const Color(0xFFB47A25),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.03),
                    SizedBox(
                      height: 240,
                      child: SingleChildScrollView(
                        controller: _popularNowScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                        ),
                        child: Row(
                          children: [
                            _buildPopularNowImage(
                              'assets/images/cake4.jpg',
                              0,
                              '4.8',
                              'Cake Design',
                              '1,500,000 UGX',
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            _buildPopularNowImage(
                              'assets/images/deco3.jpg',
                              1,
                              '4.5',
                              'Tent Decoration',
                              '2,000,000 UGX',
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            _buildPopularNowImage(
                              'assets/images/blacknwhitemen.jpg',
                              2,
                              '4.9',
                              'Photography',
                              '3,100,000 UGX',
                            ),
                            SizedBox(width: screenWidth * 0.04),
                            _buildPopularNowImage(
                              'assets/images/glassdeco.jpg',
                              3,
                              '4.7',
                              'Decoration',
                              '6,000,000 UGX',
                            ),
                          ],
                        ),
                      ),
                    ),
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
