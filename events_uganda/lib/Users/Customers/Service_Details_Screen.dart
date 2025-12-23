import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:events_uganda/Users/Customers/Service_Listing_Catering_Screen.dart';
import 'package:events_uganda/Users/Customers/Service_Listing_Saloon_Screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  const ServiceDetailsScreen({super.key});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen>
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
  String? _profilePicUrl;
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
    _loadUserProfile();
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
            
                      ],
        ),
      ),
    );
  }
}
