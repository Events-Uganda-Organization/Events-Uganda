import 'dart:async';
import 'dart:ui';
import 'package:events_uganda/Users/Date_Of_Booking_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _venueTypeController = TextEditingController();
  final FocusNode _venueTypeFocus = FocusNode();
  final GlobalKey _venueTypeKey = GlobalKey();
  final TextEditingController _specialRequestsController = TextEditingController();
  final FocusNode _specialRequestsFocus = FocusNode();
  final GlobalKey _specialRequestsKey = GlobalKey();
  final bool _hasText = false;
  final List<ReviewModel> _reviews = [];
  final ScrollController _galleryScrollController = ScrollController();
  int _galleryScrollIndex = 0;

  final List<String> _venueTypes = [
    'Hotel',
    'Banquet Hall',
    'Garden',
    'Beach',
    'Church',
    'Conference Center',
    'Rooftop',
    'Restaurant',
    'Stadium',
    'Museum',
    'Backyard',
    'Other',
  ];

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
  bool _isSearchFocused = false;
  final bool _isFavorite = false;
  Duration _remaining = const Duration(hours: 0, minutes: 0, seconds: 0);
  String _userFullName = '';
  String? _profilePicUrl;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final int _rating = 0;
  final bool _showReviewSection = false;
  bool _showAllReviews = false;
  bool _canForwardReturn = false;
  String _selectedFilter = 'All';
  final MapController _mapController = MapController();
  LatLng _pinPosition = const LatLng(0.3136, 32.5811);
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
    _searchFocus.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocus.hasFocus;
      });
    });
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

  void _showVenueTypeDropdown(BuildContext context) {
    final RenderBox? renderBox =
        _venueTypeKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            width: size.width,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: _venueTypes.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _venueTypeController.text = _venueTypes[index];
                        });
                        entry.remove();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Text(
                          _venueTypes[index],
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: MediaQuery.of(context).size.width * 0.035,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
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
    _venueTypeController.dispose();
    _venueTypeFocus.dispose();
    _specialRequestsController.dispose();
    _specialRequestsFocus.dispose();
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
    final orientation = MediaQuery.of(context).orientation;

    final offset = screenHeight * 0.13;
    final verticalMultiplier = orientation == Orientation.portrait
        ? 1.0
        : 1.5;
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
            Positioned(
              top: offset,
              left: 0,
              right: 0,
              bottom: 0,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.045,
                              color: Colors.black,
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
                                          builder: (context) =>
                                              DateOfBookingScreen(),
                                        ),
                                      ).then((_) {
                                        if (mounted) setState(() {});
                                      });
                                    }
                                  : null,
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
                        SizedBox(height: screenHeight * 0.012),
                        Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.04,
                        right: screenWidth * 0.04,
                      ),
                      child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                           Container(
                             width: screenWidth * 0.78,
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
                                  color: Colors.black.withValues(alpha: 0.1),
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
                                  padding: EdgeInsets.only(
                                    left: screenWidth * 0.04,
                                  ),
                                  child: Icon(
                                    Icons.search,
                                    color: Colors.black.withValues(alpha: 0.5),
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
                                      hintText:
                                          'Search for notifications here...',
                                      hintStyle: TextStyle(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: screenWidth * 0.035,
                                        fontFamily: 'Montserrat',
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(2, 7),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.more_vert,
                                color: Colors.black,
                                size: screenWidth * 0.07,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.04,
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _selectedFilter = 'All'),
                                child: _buildFilterChip(
                                  Icons.done_all,
                                  'All',
                                  screenWidth,
                                  isActive: _selectedFilter == 'All',
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              GestureDetector(
                                onTap: () => setState(() => _selectedFilter = 'Bookings'),
                                child: _buildFilterChip(
                                  Icons.calendar_today,
                                  'Bookings',
                                  screenWidth,
                                  isActive: _selectedFilter == 'Bookings',
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              GestureDetector(
                                onTap: () => setState(() => _selectedFilter = 'Messages'),
                                child: _buildFilterChip(
                                  Icons.message,
                                  'Messages',
                                  screenWidth,
                                  isActive: _selectedFilter == 'Messages',
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.05),
                              GestureDetector(
                                onTap: () => setState(() => _selectedFilter = 'Reminders'),
                                child: _buildFilterChip(
                                  Icons.notifications_active,
                                  'Reminders',
                                  screenWidth,
                                  isActive: _selectedFilter == 'Reminders',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.04,
                          ),
                          child: Container(
                            width: _calculateFilterRowWidth(screenWidth),
                            height: screenWidth * 0.02,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  left: _getFilterOffset(_selectedFilter, screenWidth),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  child: Container(
                                    width: _getFilterWidth(_selectedFilter, screenWidth),
                                    height: screenWidth * 0.02,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCB471B),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.035),
                        Padding(
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.04,
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.04,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: screenWidth * 0.19,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(2, 7),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: screenWidth * 0.03,
                                  top: (screenWidth * 0.19 - screenWidth * 0.128) / 2,
                                  child: Container(
                                    width: screenWidth * 0.128,
                                    height: screenWidth * 0.128,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF55FF27).withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.monetization_on,
                                        color: Colors.black,
                                        size: screenWidth * 0.07,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: screenWidth * 0.04,
                                  top: screenWidth * 0.025,
                                  child: Text(
                                    '15 secs ago',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: screenWidth * 0.025,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.18,
                                  top: (screenWidth * 0.19 - screenWidth * 0.09) / 2 - screenWidth * 0.035,
                                  child: SizedBox(
                                    width: screenWidth * 0.6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Booking Accepted',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w600,
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: screenWidth * 0.01),
                                        Text(
                                          'Your booking has finally been accepted! Congratulations.',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w300,
                                            fontSize: screenWidth * 0.022,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: screenWidth * 0.19,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(2, 7),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: screenWidth * 0.03,
                                  top: (screenWidth * 0.19 - screenWidth * 0.128) / 2,
                                  child: Container(
                                    width: screenWidth * 0.128,
                                    height: screenWidth * 0.128,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE4351D).withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.message,
                                        color: Colors.black,
                                        size: screenWidth * 0.07,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: screenWidth * 0.04,
                                  top: screenWidth * 0.025,
                                  child: Text(
                                    '15 secs ago',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: screenWidth * 0.025,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.18,
                                  top: (screenWidth * 0.19 - screenWidth * 0.09) / 2 - screenWidth * 0.035,
                                  child: SizedBox(
                                    width: screenWidth * 0.6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Booking Accepted',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w600,
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: screenWidth * 0.01),
                                        Text(
                                          'Your booking has finally been accepted! Congratulations.',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w300,
                                            fontSize: screenWidth * 0.022,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.035),
                        Padding(
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.04,
                          ),
                          child: Text(
                            'Yesterday',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.04,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: screenWidth * 0.19,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(2, 7),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: screenWidth * 0.03,
                                  top: (screenWidth * 0.19 - screenWidth * 0.128) / 2,
                                  child: Container(
                                    width: screenWidth * 0.128,
                                    height: screenWidth * 0.128,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF55FF27).withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.monetization_on,
                                        color: Colors.black,
                                        size: screenWidth * 0.07,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: screenWidth * 0.04,
                                  top: screenWidth * 0.025,
                                  child: Text(
                                    '15 secs ago',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: screenWidth * 0.025,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.18,
                                  top: (screenWidth * 0.19 - screenWidth * 0.09) / 2 - screenWidth * 0.035,
                                  child: SizedBox(
                                    width: screenWidth * 0.6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Booking Accepted',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w600,
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: screenWidth * 0.01),
                                        Text(
                                          'Your booking has finally been accepted! Congratulations.',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w300,
                                            fontSize: screenWidth * 0.022,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: screenWidth * 0.19,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(2, 7),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: screenWidth * 0.03,
                                  top: (screenWidth * 0.19 - screenWidth * 0.128) / 2,
                                  child: Container(
                                    width: screenWidth * 0.128,
                                    height: screenWidth * 0.128,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE4351D).withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.message,
                                        color: Colors.black,
                                        size: screenWidth * 0.07,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: screenWidth * 0.04,
                                  top: screenWidth * 0.025,
                                  child: Text(
                                    '15 secs ago',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: screenWidth * 0.025,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.18,
                                  top: (screenWidth * 0.19 - screenWidth * 0.09) / 2 - screenWidth * 0.035,
                                  child: SizedBox(
                                    width: screenWidth * 0.6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Booking Accepted',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w600,
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: screenWidth * 0.01),
                                        Text(
                                          'Your booking has finally been accepted! Congratulations.',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w300,
                                            fontSize: screenWidth * 0.022,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: screenWidth * 0.19,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                  offset: const Offset(2, 7),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: screenWidth * 0.03,
                                  top: (screenWidth * 0.19 - screenWidth * 0.128) / 2,
                                  child: Container(
                                    width: screenWidth * 0.128,
                                    height: screenWidth * 0.128,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF55FF27).withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.monetization_on,
                                        color: Colors.black,
                                        size: screenWidth * 0.07,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: screenWidth * 0.04,
                                  top: screenWidth * 0.025,
                                  child: Text(
                                    '15 secs ago',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: screenWidth * 0.025,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: screenWidth * 0.18,
                                  top: (screenWidth * 0.19 - screenWidth * 0.09) / 2 - screenWidth * 0.035,
                                  child: SizedBox(
                                    width: screenWidth * 0.6,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Booking Accepted',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w600,
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: screenWidth * 0.01),
                                        Text(
                                          'Your booking has finally been accepted! Congratulations.',
                                          style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w300,
                                            fontSize: screenWidth * 0.022,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                    fontSize: screenWidth * 0.045,
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
                    fontSize: screenWidth * 0.045,
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

  Widget _buildStepCircle(
    double screenWidth,
    double screenHeight,
    String label,
    bool isActive,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: screenWidth * 0.035,
          height: screenWidth * 0.035,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFCB471B) : Colors.grey.shade300,
          ),
        ),
        SizedBox(height: screenHeight * 0.006),
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.028,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            color: isActive ? const Color(0xFFCB471B) : Colors.grey,
          ),
        ),
      ],
    );
  }

  double _calculateFilterRowWidth(double screenWidth) {
    final textStyle = TextStyle(
      fontFamily: 'Montserrat',
      fontSize: screenWidth * 0.03,
      fontWeight: FontWeight.w600,
    );

    double textWidth(String text) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp.width;
    }

    final iconSize = screenWidth * 0.035;
    final chipGap = screenWidth * 0.015;
    final betweenChipGap = screenWidth * 0.05;

    final allWidth = iconSize + chipGap + textWidth('All');
    final bookingsWidth = iconSize + chipGap + textWidth('Bookings');
    final messagesWidth = iconSize + chipGap + textWidth('Messages');
    final remindersWidth = iconSize + chipGap + textWidth('Reminders');

    return allWidth +
        betweenChipGap +
        bookingsWidth +
        betweenChipGap +
        messagesWidth +
        betweenChipGap +
        remindersWidth +
        screenWidth * 0.03;
  }

  double _getFilterWidth(String filter, double screenWidth) {
    final textStyle = TextStyle(
      fontFamily: 'Montserrat',
      fontSize: screenWidth * 0.03,
      fontWeight: FontWeight.w600,
    );

    double textWidth(String text) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp.width;
    }

    double extra = screenWidth * 0.02;
    if (filter == 'Bookings') extra = screenWidth * 0.01;

    return screenWidth * 0.035 + screenWidth * 0.015 + textWidth(filter) + extra;
  }

  double _getFilterOffset(String filter, double screenWidth) {
    final textStyle = TextStyle(
      fontFamily: 'Montserrat',
      fontSize: screenWidth * 0.03,
      fontWeight: FontWeight.w600,
    );

    double textWidth(String text) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      return tp.width;
    }

    final iconSize = screenWidth * 0.035;
    final chipGap = screenWidth * 0.015;
    final betweenChipGap = screenWidth * 0.05;

    const filterOrder = ['All', 'Bookings', 'Messages', 'Reminders'];
    final index = filterOrder.indexOf(filter);
    if (index <= 0) return 0;

    double offset = 0;
    for (int i = 0; i < index; i++) {
      offset += iconSize + chipGap + textWidth(filterOrder[i]) + betweenChipGap;
    }
    return offset;
  }

  Widget _buildFilterChip(IconData icon, String label, double screenWidth, {bool isActive = false}) {
    final color = isActive ? const Color(0xFFCB471B) : Colors.grey;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: screenWidth * 0.035,
          color: color,
        ),
        SizedBox(width: screenWidth * 0.015),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: screenWidth * 0.03,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

Widget _availabilityCard(double screenWidth) {
  return Container(
    width: screenWidth * 0.42,
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
            fillAmount = 1;
          } else if (index < rating) {
            fillAmount = rating - index;
          } else {
            fillAmount = 0;
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
    0.9,
    0.6,
    0.2,
    0.1,
    0.05,
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(5, (index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              '${5 - index}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),

            const SizedBox(width: 6),

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

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset((startX + dashWidth).clamp(0, size.width), 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

