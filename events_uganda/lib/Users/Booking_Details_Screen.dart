import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:events_uganda/Users/Date_Of_Booking_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:events_uganda/Auth/auth_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _venueTypeController = TextEditingController();
  final FocusNode _venueTypeFocus = FocusNode();
  final GlobalKey _venueTypeKey = GlobalKey();
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
  final MapController _mapController = MapController();
  LatLng _pinPosition = const LatLng(0.3136, 32.5811);
  final TextEditingController _venueLocationController = TextEditingController();
  final FocusNode _venueLocationFocus = FocusNode();
  Timer? _geocodeDebounce;
  List<Marker> _locationMarkers = [];
  List<_PlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;

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
    _venueLocationController.addListener(_onLocationChanged);
    _venueLocationFocus.addListener(() {
      if (!_venueLocationFocus.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });
    _locationMarkers = [_buildLocationMarker(_pinPosition)];
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

    overlay.insert(entry);
  }

  void _onLocationChanged() {
    final text = _venueLocationController.text;
    if (text.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchSuggestions(text);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json'
        '&limit=5'
        '&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'EventsUgandaApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (mounted) {
          setState(() {
            _suggestions = data.map((item) {
              return _PlaceSuggestion(
                displayName: item['display_name'] as String,
                lat: double.parse(item['lat'] as String),
                lon: double.parse(item['lon'] as String),
              );
            }).toList();
            _showSuggestions = _suggestions.isNotEmpty;
          });
        }
      }
    } catch (_) {}
  }

  void _selectSuggestion(_PlaceSuggestion suggestion) {
    _venueLocationController.text = suggestion.displayName;
    _venueLocationController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.displayName.length),
    );
    setState(() {
      _showSuggestions = false;
      _suggestions = [];
      _pinPosition = LatLng(suggestion.lat, suggestion.lon);
      _locationMarkers = [_buildLocationMarker(_pinPosition)];
    });
    _mapController.move(_pinPosition, 15);
  }

  Marker _buildLocationMarker(LatLng point) {
    return Marker(
      point: point,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFFCB471B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            height: 12,
            color: const Color(0xFFCB471B),
          ),
        ],
      ),
    );
  }

  Future<void> _geocodeAddress(String address) async {
    if (address.trim().isEmpty) return;
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(address)}&format=json&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'EventsUgandaApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'] as String);
          final lon = double.parse(data[0]['lon'] as String);
          final position = LatLng(lat, lon);
          if (mounted) {
            setState(() {
              _pinPosition = position;
              _locationMarkers = [_buildLocationMarker(position)];
            });
            _mapController.move(position, 15);
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer?.cancel();
    _galleryScrollController.dispose();
    _reviewController.dispose();
    _venueTypeController.dispose();
    _venueTypeFocus.dispose();
    _venueLocationController.removeListener(_onLocationChanged);
    _venueLocationController.dispose();
    _venueLocationFocus.dispose();
    _geocodeDebounce?.cancel();
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
        : 1.5; // Increase spacing in landscape
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
                            'Booking Details',
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
                    SizedBox(height: screenHeight * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.08,
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: screenWidth * 0.09,
                            right: screenWidth * 0.15,
                            top: screenWidth * 0.015,
                            child: CustomPaint(
                              size: Size(double.infinity, 2),
                              painter: _DottedLinePainter(),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStepCircle(
                                screenWidth,
                                screenHeight,
                                'Choose Date',
                                true,
                              ),
                              _buildStepCircle(
                                screenWidth,
                                screenHeight,
                                'Booking Details',
                                true,
                              ),
                              _buildStepCircle(
                                screenWidth,
                                screenHeight,
                                'Payment Details',
                                false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    SizedBox(
                      height:
                          screenHeight *
                          2.8 *
                          verticalMultiplier, // Adjust height for landscape
                      child: Stack(
                        children: [
                          // Introduction image
                          Positioned(
                            top: 0,
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
                              ],
                            ),
                          ),
                          // White card below image
                          Positioned(
                            top: screenWidth * 0.95 * (336 / 350) + 8,
                            left: (screenWidth - screenWidth * 0.95) / 2,
                            child: Container(
                              width: screenWidth * 0.95,
                              height: screenWidth * 0.95 * (336 / 350) * 0.7 + screenWidth * 0.65,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: screenWidth * 0.04,
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        'Events Details',
                                        style: TextStyle(
                                          fontFamily: 'Abril Fatface',
                                          fontSize: screenWidth * 0.05,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFFCB471B),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: screenWidth * 0.025),
                                    Divider(
                                      color: Colors.grey[200],
                                      thickness: 1,
                                    ),
                                    SizedBox(height: screenWidth * 0.025),
                                    Focus(
                                      key: _venueTypeKey,
                                      child: Builder(
                                        builder: (context) {
                                          final isFocused = Focus.of(
                                            context,
                                          ).hasFocus;
                                          return AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              boxShadow: isFocused
                                                  ? [
                                                      BoxShadow(
                                                        color:
                                                            const Color(
                                                              0xFFCB471B,
                                                            ).withValues(
                                                              alpha: 0.4,
                                                            ),
                                                        blurRadius: 12,
                                                        spreadRadius: 1,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                            child: TextFormField(
                                              controller: _venueTypeController,
                                              focusNode: _venueTypeFocus,
                                              cursorColor: const Color(
                                                0xFFCB471B,
                                              ),
                                              decoration: InputDecoration(
                                                prefixIcon: Icon(
                                                  Icons.business,
                                                  color: Colors.black,
                                                  size: screenWidth * 0.05,
                                                ),
                                                suffixIcon: GestureDetector(
                                                  onTap: () =>
                                                      _showVenueTypeDropdown(
                                                        context,
                                                      ),
                                                  child: Icon(
                                                    Icons.arrow_drop_down,
                                                    color: const Color(
                                                      0xFFCB471B,
                                                    ),
                                                    size: screenWidth * 0.08,
                                                  ),
                                                ),
                                                labelText:
                                                    'Enter Your Venue Type',
                                                labelStyle: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: screenWidth * 0.035,
                                                  color: Colors.grey[500],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                hintText:
                                                    'Enter Your Venue Type',
                                                hintStyle: TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontSize: screenWidth * 0.035,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                floatingLabelBehavior:
                                                    FloatingLabelBehavior.auto,
                                                filled: true,
                                                fillColor: Colors.grey[100],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(30),
                                                  borderSide: const BorderSide(
                                                    color: Color(0xFFCB471B),
                                                    width: 1,
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFCB471B,
                                                            ),
                                                            width: 1,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            30,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFFCB471B,
                                                            ),
                                                            width: 2,
                                                          ),
                                                    ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                              ),
                                              style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: screenWidth * 0.035,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: screenWidth * 0.05),
                                    TextFormField(
                                      controller: _venueLocationController,
                                      focusNode: _venueLocationFocus,
                                      cursorColor: const Color(0xFFCB471B),
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(
                                          Icons.location_on,
                                          color: Colors.black,
                                          size: screenWidth * 0.05,
                                        ),
                                        labelText: 'Venue Location',
                                        labelStyle: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: screenWidth * 0.035,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w600,
                                        ),
                                        hintText: 'Enter Venue Location',
                                        hintStyle: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: screenWidth * 0.035,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.auto,
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFCB471B),
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFCB471B),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFCB471B),
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: screenWidth * 0.035,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_showSuggestions)
                                      Container(
                                        margin: EdgeInsets.only(
                                          top: screenWidth * 0.01,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.12),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        constraints: BoxConstraints(
                                          maxHeight: screenWidth * 0.6,
                                        ),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          padding: EdgeInsets.symmetric(
                                            vertical: screenWidth * 0.02,
                                          ),
                                          itemCount: _suggestions.length,
                                          separatorBuilder: (context, index) =>
                                              Divider(
                                            height: 1,
                                            color: Colors.grey[200],
                                          ),
                                          itemBuilder: (context, index) {
                                            final suggestion =
                                                _suggestions[index];
                                            return InkWell(
                                              onTap: () =>
                                                  _selectSuggestion(suggestion),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      screenWidth * 0.04,
                                                  vertical:
                                                      screenWidth * 0.03,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.location_on,
                                                      size:
                                                          screenWidth * 0.04,
                                                      color: const Color(
                                                          0xFFCB471B,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width:
                                                          screenWidth * 0.02,
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        suggestion
                                                            .displayName,
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Montserrat',
                                                          fontSize:
                                                              screenWidth *
                                                                  0.03,
                                                          color: Colors
                                                              .black87,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    SizedBox(height: screenWidth * 0.025),
                                    Text(
                                      'Drag the location pin to your location',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: screenWidth * 0.025),
                                    Container(
                                      height: (screenWidth < 380) ? screenWidth * 0.45 : screenWidth * 0.50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: const Color(0xFFCB471B),
                                          width: 1,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: FlutterMap(
                                        options: MapOptions(
                                          initialCenter: _pinPosition,
                                          initialZoom: 15,
                                          onMapEvent: (event) {
                                            if (event is MapEventMoveEnd) {
                                              setState(() {
                                                _pinPosition = event
                                                    .camera
                                                    .center;
                                                _locationMarkers = [
                                                  _buildLocationMarker(
                                                      _pinPosition),
                                                ];
                                              });
                                            }
                                          },
                                        ),
                                        mapController: _mapController,
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            userAgentPackageName:
                                                'com.events_uganda.app',
                                          ),
                                          MarkerLayer(
                                            markers: _locationMarkers,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top:
                                screenWidth * 0.95 * (336 / 350) +
                                8 +
                                screenWidth * 0.95 * (336 / 350) * 0.7 +
                                screenWidth * 0.58 +
                                12,
                            left: (screenWidth - screenWidth * 0.95) / 2,
                            child: Container(
                              width: screenWidth * 0.95,
                              height: screenWidth * 0.95 * (336 / 350) * 0.4,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.05,
                                vertical: screenWidth * 0.04,
                              ),
                            ),
                          ),
                          Positioned(
                            top:
                                screenHeight * 0.59 -
                                offset, // Provider name sits above
                            left: screenWidth * 0.03,
                            right: screenWidth * 0.03,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Provider name card removed
                              ],
                            ),
                          ),
                          // Available badge
                          Positioned(
                            top: screenHeight * 0.14 - offset,
                            left: screenWidth * 0.35,
                            right: screenWidth * 0.35,
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
                          // Glassy UI Rectangle on the right side of image
                          Positioned(
                            top:
                                screenHeight * 0.12 +
                                screenHeight * 0.02 -
                                offset,
                            right:
                                (screenWidth - screenWidth * 0.95) / 2 +
                                screenWidth * 0.015,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 10.0,
                                  sigmaY: 10.0,
                                ),
                                child: Container(
                                  width: 55,
                                  height:
                                      screenWidth * 0.95 * (336 / 350) * 0.95,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(height: 6),
                                      if (_galleryScrollIndex > 0)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _galleryScrollIndex =
                                                  (_galleryScrollIndex - 1)
                                                      .clamp(
                                                        0,
                                                        _galleryImages.length -
                                                            1,
                                                      );
                                            });
                                            _galleryScrollController.animateTo(
                                              (_galleryScrollIndex) * 50.0,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.ease,
                                            );
                                          },
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            alignment: Alignment.center,
                                            child: Transform.rotate(
                                              angle: -1.5708, // 90° CCW → up
                                              child: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(height: 6),
                                      Expanded(
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          controller: _galleryScrollController,
                                          scrollDirection: Axis.vertical,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: _galleryImages.length,
                                          itemBuilder: (context, i) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8.0,
                                            ),
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedGalleryIndex = i;
                                                });
                                              },
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    border:
                                                        _selectedGalleryIndex ==
                                                            i
                                                        ? Border.all(
                                                            color: Colors.white,
                                                            width: 2,
                                                          )
                                                        : null,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
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
                                      SizedBox(height: 6),
                                      if (_galleryScrollIndex <
                                          _galleryImages.length - 6)
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _galleryScrollIndex =
                                                  (_galleryScrollIndex + 1)
                                                      .clamp(
                                                        0,
                                                        (_galleryImages.length -
                                                                6)
                                                            .clamp(
                                                              0,
                                                              _galleryImages
                                                                  .length,
                                                            ),
                                                      );
                                            });
                                            _galleryScrollController.animateTo(
                                              (_galleryScrollIndex) * 50.0,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.ease,
                                            );
                                          },
                                          child: SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: Transform.rotate(
                                              angle: 1.5708, // 90° CW → down
                                              child: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(height: 6),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: screenHeight * 0.85 - offset,
                            left: screenWidth * 0.02,
                            right: screenWidth * 0.02,
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
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: screenHeight * 1.19 - offset,
                            left: screenWidth * 0.02,
                            right: screenWidth * 0.02,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // About provider card removed
                              ],
                            ),
                          ),
                          // Reviews and Ratings card removed

                          // ===== Reviews & Ratings Section in nested cards =====
                          Positioned(
                            top: _showReviewSection
                                ? screenHeight * 1.85 - offset
                                : screenHeight * 1.65 - offset,
                            left: screenWidth * 0.022,
                            right: screenWidth * 0.022,
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
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: (screenWidth - 270) / 2,
                      child: Container(
                        width: 270,
                        height: 62,
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
                  ],
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

class _PlaceSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  const _PlaceSuggestion({
    required this.displayName,
    required this.lat,
    required this.lon,
  });
}
