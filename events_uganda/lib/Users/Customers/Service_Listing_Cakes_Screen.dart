import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:events_uganda/Users/Customers/Chat_Screen.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:events_uganda/Users/Date_Of_Booking_Screen.dart';
import 'package:events_uganda/Users/Customers/Service_Details_Screen.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';
import 'package:events_uganda/components/sidebar_menu.dart';

class _ProviderCardItem {
  const _ProviderCardItem(
    this.imagePath,
    this.title,
    this.rating,
    this.index,
    this.priceRange, {
    this.showVerified = true,
  });

  final String imagePath;
  final String title;
  final String rating;
  final int index;
  final String priceRange;
  final bool showVerified;
}

enum _ProviderFilter {
  nearest,
  rating,
  popular,
  popularLow,
  priceLowToHigh,
  priceHighToLow,
  clear,
}

class ServiceListingCakesScreen extends StatefulWidget {
  final String? category;
  final int? categoryIndex;

  const ServiceListingCakesScreen({
    super.key,
    this.category,
    this.categoryIndex,
  });
  @override
  State<ServiceListingCakesScreen> createState() =>
      _ServiceListingCakesScreenState();
}

class _ServiceListingCakesScreenState extends State<ServiceListingCakesScreen>
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
  final bool _canForwardReturn =
      false; // Controls the right-side inactive/active return button

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _ProviderFilter? _activeFilter;
  late final List<_ProviderCardItem> _featuredProviders;
  late final List<_ProviderCardItem> _allProviders;

  static const LatLng _defaultLocation = LatLng(0.3136, 32.5811);
  static const Map<int, LatLng> _providerCoords = {
    0: LatLng(0.3136, 32.5811),
    1: LatLng(0.3202, 32.5776),
    2: LatLng(0.3056, 32.5954),
    3: LatLng(0.3310, 32.5690),
    4: LatLng(0.2935, 32.6022),
    5: LatLng(0.3402, 32.5600),
    6: LatLng(0.2800, 32.5700),
    7: LatLng(0.3480, 32.5520),
    8: LatLng(0.2720, 32.6100),
    9: LatLng(0.3020, 32.5560),
    10: LatLng(0.3160, 32.5400),
    11: LatLng(0.2890, 32.5200),
    12: LatLng(0.3220, 32.6100),
    13: LatLng(0.3500, 32.5900),
    14: LatLng(0.2680, 32.5460),
    15: LatLng(0.3060, 32.6300),
  };
  LatLng? _userLocation;
  bool _locating = false;

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  bool get _hasActiveFilter => _activeFilter != null;

  bool get _hasNoResults =>
      _isSearching && _matchedFeatured.isEmpty && _matchedAll.isEmpty;

  List<_ProviderCardItem> get _matchedFeatured =>
      _filterProviders(_featuredProviders);

  List<_ProviderCardItem> get _matchedAll => _filterProviders(_allProviders);

  double _parsePrice(String price) {
    double parseToken(String token) {
      final t = token.trim().toUpperCase().replaceAll(',', '');
      if (t.endsWith('M')) {
        final num = double.tryParse(t.replaceAll('M', ''));
        return num == null ? 0 : num * 1000000;
      }
      if (t.endsWith('K')) {
        final num = double.tryParse(t.replaceAll('K', ''));
        return num == null ? 0 : num * 1000;
      }
      return double.tryParse(t) ?? 0;
    }

    final bounds = price.split('-').map(parseToken).toList();
    if (bounds.isEmpty) return 0;
    return bounds.reduce((a, b) => a < b ? a : b);
  }

  List<_ProviderCardItem> _applySort(List<_ProviderCardItem> items) {
    final sorted = List<_ProviderCardItem>.from(items);
    switch (_activeFilter) {
      case _ProviderFilter.nearest:
        final origin = _userLocation ?? _defaultLocation;
        sorted.sort((a, b) => _distanceTo(origin, _coordFor(a.index))
            .compareTo(_distanceTo(origin, _coordFor(b.index))));
      case _ProviderFilter.rating:
        sorted.sort((a, b) =>
            double.parse(b.rating).compareTo(double.parse(a.rating)));
      case _ProviderFilter.popular:
        sorted.sort((a, b) =>
            double.parse(b.rating).compareTo(double.parse(a.rating)));
      case _ProviderFilter.popularLow:
        sorted.sort((a, b) =>
            double.parse(a.rating).compareTo(double.parse(b.rating)));
      case _ProviderFilter.priceLowToHigh:
        sorted.sort((a, b) =>
            _parsePrice(a.priceRange).compareTo(_parsePrice(b.priceRange)));
      case _ProviderFilter.priceHighToLow:
        sorted.sort((a, b) =>
            _parsePrice(b.priceRange).compareTo(_parsePrice(a.priceRange)));
      case _ProviderFilter.clear:
      case null:
        break;
    }
    return sorted;
  }

  List<_ProviderCardItem> _filterProviders(List<_ProviderCardItem> items) {
    final query = _searchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List<_ProviderCardItem>.from(items)
        : items
            .where((c) => c.title.toLowerCase().contains(query))
            .toList();
    return _applySort(filtered);
  }

  Widget _buildNoResults(double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(top: screenWidth * 0.08),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: screenWidth * 0.16,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            SizedBox(height: screenWidth * 0.04),
            Text(
              "No services found for '${_searchQuery.trim()}'",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.04,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              'Try a different search term or category',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_ProviderFilter> _buildFilterMenuItem({
    required IconData icon,
    required String label,
    required Color dotColor,
    required _ProviderFilter value,
    required double screenWidth,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return PopupMenuItem<_ProviderFilter>(
      value: value,
      height: screenWidth * 0.14,
      child: SizedBox(
        width: screenWidth * 0.56,
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.028,
              height: screenWidth * 0.028,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.04),
            Container(
              width: screenWidth * 0.09,
              height: screenWidth * 0.09,
              decoration: BoxDecoration(
                color: dotColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: dotColor, size: screenWidth * 0.048),
            ),
            SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w500,
                  color: isDestructive ? dotColor : Colors.white,
                ),
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: screenWidth * 0.05,
              ),
          ],
        ),
      ),
    );
  }

  double _distanceTo(LatLng a, LatLng b) =>
      const Distance().as(LengthUnit.Kilometer, a, b);

  LatLng _coordFor(int index) => _providerCoords[index] ?? _defaultLocation;

  Future<void> _resolveUserLocation() async {
    LatLng resolved = _defaultLocation;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          );
          resolved = LatLng(pos.latitude, pos.longitude);
        }
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
    _userLocation = resolved;
  }

  void _onPillTap(_ProviderFilter value) {
    setState(() {
      if (_activeFilter == value) {
        _activeFilter = null;
      } else {
        _activeFilter = value;
      }
    });
  }

  Future<void> _onNearestTap() async {
    if (_activeFilter == _ProviderFilter.nearest) {
      setState(() => _activeFilter = null);
      return;
    }
    setState(() => _locating = true);
    await _resolveUserLocation();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _activeFilter = _ProviderFilter.nearest;
    });
  }

  void _onPricePillTap() {
    setState(() {
      switch (_activeFilter) {
        case _ProviderFilter.priceLowToHigh:
          _activeFilter = _ProviderFilter.priceHighToLow;
        case _ProviderFilter.priceHighToLow:
          _activeFilter = null;
        default:
          _activeFilter = _ProviderFilter.priceLowToHigh;
      }
    });
  }

  void _onPopularPillTap() {
    setState(() {
      switch (_activeFilter) {
        case _ProviderFilter.popular:
          _activeFilter = _ProviderFilter.popularLow;
        case _ProviderFilter.popularLow:
          _activeFilter = null;
        default:
          _activeFilter = _ProviderFilter.popular;
      }
    });
  }

  Widget _buildFilterPill({
    required IconData icon,
    required String label,
    required double screenWidth,
    required double screenHeight,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.34,
        height: screenHeight * 0.055,
        margin: EdgeInsets.only(right: screenWidth * 0.03),
        decoration: BoxDecoration(
          color: isActive ? const Color(0XFFF3CA9B) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.01),
          child: Row(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: screenWidth * 0.09,
                  height: screenWidth * 0.09,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : const Color(0XFFF3CA9B),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.black,
                    size: screenWidth * 0.05,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: screenWidth * 0.03,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                color: Colors.black.withValues(alpha: 0.12),
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
    _featuredProviders = [
      const _ProviderCardItem('assets/images/cake1.jpg', 'Royal Cake Atelier', '4.8', 0, 'UGX 500K - 2M'),
      const _ProviderCardItem('assets/images/cake2.jpg', 'Frost & Bloom Cakes', '4.6', 1, 'UGX 400K - 1.5M'),
      const _ProviderCardItem('assets/images/cake3.jpg', 'Ivory Crumb Patisserie', '4.9', 2, 'UGX 600K - 3M'),
      const _ProviderCardItem('assets/images/cake4.jpg', 'Petal Tiers Bakery', '4.7', 3, 'UGX 300K - 1.2M'),
      const _ProviderCardItem('assets/images/cake5.png', 'Golden Buttercream Co.', '4.5', 4, 'UGX 200K - 800K'),
      const _ProviderCardItem('assets/images/cake6.png', 'Velvet & Vanilla Cakes', '4.7', 11, 'UGX 300K - 1.2M'),
      const _ProviderCardItem('assets/images/cake7.png', 'Blissful Bakes Studio', '4.9', 10, 'UGX 600K - 3M'),
      const _ProviderCardItem('assets/images/cake8.png', 'Sugar Orchid Cakes', '4.6', 9, 'UGX 400K - 1.5M'),
    ];
    _allProviders = [
      const _ProviderCardItem('assets/images/cake1.jpg', 'Heritage Cake House', '4.8', 8, 'UGX 500K - 2M', showVerified: false),
      const _ProviderCardItem('assets/images/cake2.jpg', 'Crimson Berry Cakes', '4.6', 9, 'UGX 400K - 1.5M', showVerified: false),
      const _ProviderCardItem('assets/images/cake3.jpg', 'Palm Crest Patisserie', '4.9', 10, 'UGX 600K - 3M', showVerified: false),
      const _ProviderCardItem('assets/images/cake4.jpg', 'Serene Sweets Bakery', '4.7', 11, 'UGX 300K - 1.2M', showVerified: false),
      const _ProviderCardItem('assets/images/cake5.png', 'Bella Crust Confections', '4.5', 12, 'UGX 200K - 800K', showVerified: false),
      const _ProviderCardItem('assets/images/cake6.png', 'Nile Layers Cakes', '4.9', 13, 'UGX 800K - 2.5M', showVerified: false),
      const _ProviderCardItem('assets/images/cake7.png', 'Terra Treats Bakery', '4.4', 14, 'UGX 400K - 1.8M', showVerified: false),
      const _ProviderCardItem('assets/images/cake8.png', 'Atlas Cake Works', '4.7', 15, 'UGX 350K - 1.5M', showVerified: false),
    ];
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
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await AuthService.getUser();
      if (user != null) {
        setState(() {
          _userFullName = user['fullName'] as String? ?? 'User';
          _profilePicUrl = user['photoUrl'] as String?;
        });
      } else {
        setState(() => _userFullName = 'User');
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() => _userFullName = 'User');
    }
  }

  Future<void> _uploadProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      setState(() {
        _profilePicUrl = image.path;
      });
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
    _searchController.dispose();
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
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.verified,
                            color: Colors.blue,
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
                  ),
                ),
                SizedBox(height: screenWidth * 0.008),
                Text(
                  price,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.035,
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
                            Icons.verified,
                            color: Colors.blue,
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
                  ),
                ),
                SizedBox(height: screenWidth * 0.008),
                Text(
                  price,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: screenWidth * 0.035,
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
    double promoHeight) {
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
    double screenWidth, {
    bool showVerified = true,
  }) {
    final cardWidth =
        (screenWidth - (screenWidth * 0.04 * 2) - (screenWidth * 0.04)) / 2;
    final cardHeight = cardWidth * 1.185;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ServiceDetailsScreen()),
        );
      },
      child: Container(
        width: cardWidth,
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                            child: showVerified
                                ? Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: screenWidth * 0.07,
                                  )
                                : Icon(
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
                        Colors.black.withValues(alpha: 0.7),
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
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.008),
                      Text(
                        priceRange,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.025,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.008),
                      Text(
                        'Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: screenWidth * 0.025,
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DateOfBookingScreen(),
                    ),
                  );
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
                              color: Colors.white.withValues(alpha: 0.1),
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
    final promoTop = screenHeight * 0.33;
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
              top: screenHeight * 0.1,
              right: -screenWidth * 0.135,
              child: Image.asset(
                'assets/images/bgcake1.png',
                width: screenWidth * 0.5,
                height: screenWidth * 0.5,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.03,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () => SidebarMenu.show(context),
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
                  child: Image.asset(
                    'assets/vectors/menu.png',
                    width: screenWidth * 0.07,
                    height: screenWidth * 0.07,
                    fit: BoxFit.contain,
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
                        child: _profilePicUrl!.startsWith('http')
                            ? Image.network(
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
                              )
                            : Image.file(
                                File(_profilePicUrl!),
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
              top: screenHeight * 0.122,
              right: screenWidth * 0.04,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  PopupMenuButton<_ProviderFilter>(
                    onSelected: (action) {
                      if (action == _ProviderFilter.clear) {
                        setState(() => _activeFilter = null);
                      } else if (action == _ProviderFilter.nearest) {
                        _onNearestTap();
                      } else {
                        setState(() => _activeFilter = action);
                      }
                    },
                    offset: Offset(-(screenWidth * 0.432 + 16), 8),
                    elevation: 16,
                    color: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    itemBuilder: (ctx) => [
                      _buildFilterMenuItem(
                        icon: Icons.near_me_rounded,
                        label: _locating ? 'Finding Nearest...' : 'Nearest',
                        dotColor: const Color(0xFF26A69A),
                        value: _ProviderFilter.nearest,
                        isActive: _activeFilter == _ProviderFilter.nearest,
                        screenWidth: screenWidth,
                      ),
                      _buildFilterMenuItem(
                        icon: Icons.star_rounded,
                        label: 'Top Rated',
                        dotColor: const Color(0xFFFBC02D),
                        value: _ProviderFilter.rating,
                        isActive: _activeFilter == _ProviderFilter.rating,
                        screenWidth: screenWidth,
                      ),
                      _buildFilterMenuItem(
                        icon: Icons.trending_up_rounded,
                        label: 'Popular',
                        dotColor: const Color(0xFFEF6C00),
                        value: _ProviderFilter.popular,
                        isActive: _activeFilter == _ProviderFilter.popular ||
                            _activeFilter == _ProviderFilter.popularLow,
                        screenWidth: screenWidth,
                      ),
                      _buildFilterMenuItem(
                        icon: Icons.attach_money_rounded,
                        label: 'Price: Low to High',
                        dotColor: const Color(0xFF4CAF50),
                        value: _ProviderFilter.priceLowToHigh,
                        isActive:
                            _activeFilter == _ProviderFilter.priceLowToHigh,
                        screenWidth: screenWidth,
                      ),
                      _buildFilterMenuItem(
                        icon: Icons.attach_money_rounded,
                        label: 'Price: High to Low',
                        dotColor: const Color(0xFF42A5F5),
                        value: _ProviderFilter.priceHighToLow,
                        isActive:
                            _activeFilter == _ProviderFilter.priceHighToLow,
                        screenWidth: screenWidth,
                      ),
                      const PopupMenuDivider(height: 1),
                      _buildFilterMenuItem(
                        icon: Icons.filter_alt_off_rounded,
                        label: 'Clear Filters',
                        dotColor: const Color(0xFFFF5F5F),
                        value: _ProviderFilter.clear,
                        isDestructive: true,
                        screenWidth: screenWidth,
                      ),
                    ],
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
                  if (_hasActiveFilter)
                    Positioned(
                      top: -screenWidth * 0.004,
                      right: -screenWidth * 0.004,
                      child: Container(
                        width: screenWidth * 0.034,
                        height: screenWidth * 0.034,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
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
                      padding: EdgeInsets.only(left: screenWidth * 0.04),
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
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for services, vendors',
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.5),
                            fontSize: screenWidth * 0.035,
                          ),
                          border: InputBorder.none,
                          isDense: true, // Add this
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                          ), // Change to vertical: 0
                          suffixIcon: _isSearching
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                )
                              : null,
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
            // Horizontally scrollable filter rectangles
            Positioned(
              top: screenHeight * 0.268,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill(
                      icon: Icons.location_on,
                      label: 'Nearest',
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isActive: _activeFilter == _ProviderFilter.nearest,
                      onTap: _onNearestTap,
                    ),
                    _buildFilterPill(
                      icon: Icons.star,
                      label: 'Rating',
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isActive: _activeFilter == _ProviderFilter.rating,
                      onTap: () => _onPillTap(_ProviderFilter.rating),
                    ),
                    _buildFilterPill(
                      icon: Icons.attach_money,
                      label: 'Price',
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isActive: _activeFilter == _ProviderFilter.priceLowToHigh ||
                          _activeFilter == _ProviderFilter.priceHighToLow,
                      onTap: _onPricePillTap,
                    ),
                    _buildFilterPill(
                      icon: Icons.trending_up,
                      label: 'Popular',
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      isActive: _activeFilter == _ProviderFilter.popular ||
                          _activeFilter == _ProviderFilter.popularLow,
                      onTap: _onPopularPillTap,
                    ),
                  ],
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
                    'Wedding Cakes',
                    style: TextStyle(
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_hasNoResults) _buildNoResults(screenWidth),
                    if (!_isSearching || _matchedFeatured.isNotEmpty) ...[
                    SizedBox(height: screenWidth * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Featured Providers',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: screenWidth * 0.045,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.02),
                              Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: screenWidth * 0.045,
                              ),
                            ],
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
                          for (int i = 0; i < _matchedFeatured.length; i++)
                            _buildCategoryCard(
                              _matchedFeatured[i].imagePath,
                              _matchedFeatured[i].title,
                              _matchedFeatured[i].rating,
                              _matchedFeatured[i].index,
                              _matchedFeatured[i].priceRange,
                              screenWidth,
                              showVerified: _matchedFeatured[i].showVerified,
                            ),
                        ],
                      ),
                    ),
                    ],
                    if (!_isSearching || _matchedAll.isNotEmpty) ...[
                    SizedBox(height: screenWidth * 0.04),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Providers',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.045,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.04),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                      ),
                      child: Wrap(
                        spacing: screenWidth * 0.04,
                        runSpacing: screenWidth * 0.04,
                        children: [
                          for (int i = 0; i < _matchedAll.length; i++)
                            _buildCategoryCard(
                              _matchedAll[i].imagePath,
                              _matchedAll[i].title,
                              _matchedAll[i].rating,
                              _matchedAll[i].index,
                              _matchedAll[i].priceRange,
                              screenWidth,
                              showVerified: _matchedAll[i].showVerified,
                            ),
                        ],
                      ),
                    ),
                    ],
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
                    if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChatScreen(),
                        ),
                      );
                    }
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
