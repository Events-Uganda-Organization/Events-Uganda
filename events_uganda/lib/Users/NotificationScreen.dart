import 'dart:async';
import 'package:events_uganda/Users/Date_Of_Booking_Screen.dart';
import 'package:events_uganda/Users/NotificationDetailsScreen.dart';
import 'package:events_uganda/Users/NotificationSettingsScreen.dart';
import 'package:events_uganda/components/archived_empty_animation.dart';
import 'package:events_uganda/components/notification_empty_cartoon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Services/notification_service.dart';
import 'package:events_uganda/Services/notification_socket_service.dart';
import 'package:events_uganda/components/snackbar_helper.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:events_uganda/models/app_notification.dart';
import 'package:events_uganda/Users/Customers/Chat_Screen.dart';

enum _MenuAction {
  markAllRead,
  deleteAllRead,
  settings,
  archived,
  help,
}

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
  final int _galleryScrollIndex = 0;

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
  final int _selectedGalleryIndex = 0;
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  Timer? _countdownTimer;
  bool _isSearchFocused = false;
  String _searchQuery = '';
  final bool _isFavorite = false;
  Duration _remaining = const Duration(hours: 0, minutes: 0, seconds: 0);
  String _userFullName = '';
  String? _profilePicUrl;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final int _rating = 0;
  final bool _showReviewSection = false;
  bool _showAllReviews = false;
  final bool _canForwardReturn = false;
  String _selectedFilter = 'All';
  final MapController _mapController = MapController();
  final LatLng _pinPosition = const LatLng(0.3136, 32.5811);
  int _currentNavIndex = 0;
  bool _showArchived = false;
  bool _isNavbarVisible = true;
  late AnimationController _navbarSlideController;
  late Animation<Offset> _navbarSlideAnimation;

  bool get _isFiltering =>
      _searchQuery.trim().isNotEmpty || _selectedFilter != 'All';

  bool _matchesSegment(AppNotification item) {
    switch (_selectedFilter) {
      case 'Members':
        return item.category == AppNotificationCategory.members;
      case 'Bookings':
        return item.category == AppNotificationCategory.bookings;
      case 'Reminders':
        return item.category == AppNotificationCategory.reminders;
      default:
        return true;
    }
  }

  bool _matchesQuery(AppNotification item) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;
    return item.title.toLowerCase().contains(query) ||
        item.bodyText.toLowerCase().contains(query);
  }

  bool _matchesFilter(AppNotification item) =>
      _matchesSegment(item) && _matchesQuery(item);

  List<AppNotification> get _filteredActive =>
      _activeNotifications.where(_matchesFilter).toList();
  List<AppNotification> get _filteredArchived =>
      _archivedNotifications.where(_matchesFilter).toList();

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<AppNotification> get _todayActive {
    final now = DateTime.now();
    return _filteredActive.where((n) => _isSameDay(n.createdAt, now)).toList();
  }

  List<AppNotification> get _yesterdayActive {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _filteredActive
        .where((n) => _isSameDay(n.createdAt, yesterday))
        .toList();
  }

  List<AppNotification> get _earlierActive {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
    return _filteredActive
        .where((n) => DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day).isBefore(yDay))
        .toList();
  }

  final List<AppNotification> _activeNotifications = [];
  final List<AppNotification> _archivedNotifications = [];
  int _unreadCount = 0;
  bool _loading = true;
  String? _loadError;
  StreamSubscription<AppNotification>? _socketSub;

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
    _loadNotifications();
    _socketSub = NotificationSocketService.instance.notifications
        .listen(_onSocketNotification);
    NotificationSocketService.instance.ensureConnected();
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

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        NotificationService.fetchNotifications(archived: false),
        NotificationService.fetchNotifications(archived: true),
        NotificationService.getUnreadCount(),
      ]);
      if (!mounted) return;
      final active = results[0] as List<AppNotification>;
      final archived = results[1] as List<AppNotification>;
      final unread = results[2] as int;
      setState(() {
        _activeNotifications
          ..clear()
          ..addAll(active);
        _archivedNotifications
          ..clear()
          ..addAll(archived);
        _unreadCount = unread;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  void _onSocketNotification(AppNotification notification) {
    if (!mounted) return;
    setState(() {
      _activeNotifications.removeWhere((n) => n.id == notification.id);
      _activeNotifications.insert(0, notification);
      if (!notification.isRead) _unreadCount++;
    });
    SnackbarHelper.show(
      context,
      notification.title,
      icon: notification.icon,
    );
  }

  void _replaceNotification(String id, AppNotification updated) {
    for (int i = 0; i < _activeNotifications.length; i++) {
      if (_activeNotifications[i].id == id) {
        _activeNotifications[i] = updated;
        return;
      }
    }
    for (int i = 0; i < _archivedNotifications.length; i++) {
      if (_archivedNotifications[i].id == id) {
        _archivedNotifications[i] = updated;
        return;
      }
    }
  }

  Future<void> _recreate(AppNotification item) async {
    final user = await AuthService.getUser();
    final userId = user?['id'] as String?;
    if (userId == null || userId.isEmpty) return;
    try {
      final recreated = await NotificationService.create(
        type: item.type,
        title: item.title,
        body: item.body,
        category: item.category.serverValue,
        userId: userId,
      );
      if (!mounted) return;
      setState(() {
        _activeNotifications.insert(0, recreated);
        if (!recreated.isRead) _unreadCount++;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _animationController.dispose();
    _navbarSlideController.dispose();
    _countdownTimer?.cancel();
    _galleryScrollController.dispose();
    _reviewController.dispose();
    _searchController.dispose();
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
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.black,
                        size: screenWidth * 0.07,
                      ),
                    ),
                    if (_unreadCount > 0)
                      Positioned(
                        top: -screenWidth * 0.005,
                        right: -screenWidth * 0.005,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.018,
                            vertical: screenWidth * 0.004,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(
                            '$_unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: screenWidth * 0.024,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: offset,
              left: 0,
              right: 0,
              bottom: 0,
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
                                    controller: _searchController,
                                    focusNode: _searchFocus,
                                    onChanged: (value) {
                                      setState(() => _searchQuery = value);
                                    },
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: screenWidth * 0.04,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search for notifications here...',
                                      hintStyle: TextStyle(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: screenWidth * 0.035,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 0,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_searchQuery.isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: screenWidth * 0.03,
                                    ),
                                    child: GestureDetector(
                                      onTap: _clearSearch,
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        size: screenWidth * 0.055,
                                        color: Colors.black.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          PopupMenuButton<_MenuAction>(
                            onSelected: (action) {
                              switch (action) {
                                case _MenuAction.markAllRead:
                                  _markAllAsRead();
                                case _MenuAction.deleteAllRead:
                                  _deleteAllReadNotifications();
                                case _MenuAction.settings:
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationSettingsScreen(),
                                    ),
                                  );
                              case _MenuAction.archived:
                                  setState(() => _showArchived = true);
                                case _MenuAction.help:
                                  _showHelpSheet();
                              }
                            },
                            offset: const Offset(0, 8),
                            elevation: 16,
                            color: const Color(0xFF1A1A2E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            itemBuilder: (ctx) => [
                              _buildMenuItem(
                                icon: Icons.check_circle_outline_rounded,
                                label: 'Mark all as read',
                                dotColor: const Color(0xFF4CAF50),
                                value: _MenuAction.markAllRead,
                                screenWidth: screenWidth,
                              ),
                              _buildMenuItem(
                                icon: Icons.delete_sweep_outlined,
                                label: 'Delete all read',
                                dotColor: const Color(0xFFFF5F5F),
                                isDestructive: true,
                                value: _MenuAction.deleteAllRead,
                                screenWidth: screenWidth,
                              ),
                              const PopupMenuDivider(height: 1),
                              _buildMenuItem(
                                icon: Icons.notifications_outlined,
                                label: 'Notification Settings',
                                dotColor: const Color(0xFF42A5F5),
                                value: _MenuAction.settings,
                                screenWidth: screenWidth,
                              ),
                              const PopupMenuDivider(height: 1),
                              _buildMenuItem(
                                icon: Icons.archive_outlined,
                                label: 'Archived',
                                dotColor: const Color(0xFFF3CA9B),
                                value: _MenuAction.archived,
                                screenWidth: screenWidth,
                              ),
                              _buildMenuItem(
                                icon: Icons.help_outline_rounded,
                                label: 'Help',
                                dotColor: const Color(0xFF90A4AE),
                                value: _MenuAction.help,
                                screenWidth: screenWidth,
                              ),
                            ],
                            child: Container(
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
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadNotifications,
                        color: const Color(0xFFCB471B),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Container(
                            height: screenWidth * 0.12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(screenWidth * 0.06),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildSegment('All', screenWidth),
                                _buildSegment('Members', screenWidth),
                                _buildSegment('Bookings', screenWidth),
                                _buildSegment('Reminders', screenWidth),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.035),
                        if (_loading)
                          Padding(
                            padding: EdgeInsets.only(top: screenHeight * 0.12),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: const Color(0xFFCB471B),
                              ),
                            ),
                          )
                        else if (_loadError != null)
                          _buildLoadError(screenWidth)
                        else if (_showArchived)
                          _buildArchivedView(screenWidth, screenHeight)
                        else if (_filteredActive.isEmpty)
                          _isFiltering
                              ? _buildNoResults(screenWidth)
                              : Padding(
                                  padding: EdgeInsets.only(
                                    top: screenHeight * 0.04,
                                  ),
                                  child: const NotificationEmptyCartoon(),
                                )
                        else
                          ..._buildNotificationLists(screenWidth, screenHeight),
                          ],
                        ),
                      ),
                    ),
                  ),

                  ],
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
            fontWeight: FontWeight.w500,
            color: isActive ? const Color(0xFFCB471B) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSegment(String label, double screenWidth) {
    final isActive = _selectedFilter == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: EdgeInsets.all(screenWidth * 0.01),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFCB471B) : Colors.transparent,
            borderRadius: BorderRadius.circular(screenWidth * 0.05),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.03,
                color: isActive ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNotificationLists(double screenWidth, double screenHeight) {
    final widgets = <Widget>[];
    if (_filteredToday.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.04),
          child: Text(
            'Today',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: screenWidth * 0.04,
              color: Colors.black,
            ),
          ),
        ),
      );
      for (int i = 0; i < _filteredToday.length; i++) {
        if (i > 0) widgets.add(SizedBox(height: screenHeight * 0.015));
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: _buildDismissibleCard(
              item: _filteredToday[i],
              screenWidth: screenWidth,
              child: _buildCardContent(_filteredToday[i], screenWidth),
            ),
          ),
        );
      }
      widgets.add(SizedBox(height: screenHeight * 0.035));
    }
    if (_filteredYesterday.isNotEmpty) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.04),
          child: Text(
            'Yesterday',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: screenWidth * 0.04,
              color: Colors.black,
            ),
          ),
        ),
      );
      for (int i = 0; i < _filteredYesterday.length; i++) {
        if (i > 0) widgets.add(SizedBox(height: screenHeight * 0.015));
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: _buildDismissibleCard(
              item: _filteredYesterday[i],
              screenWidth: screenWidth,
              child: _buildCardContent(_filteredYesterday[i], screenWidth),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildArchivedView(double screenWidth, double screenHeight) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.04, right: screenWidth * 0.04),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showArchived = false),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: screenWidth * 0.015,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3CA9B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF3CA9B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        size: screenWidth * 0.04,
                        color: const Color(0xFFCB471B),
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      Text(
                        'Active Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: screenWidth * 0.03,
                          color: const Color(0xFFCB471B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_archivedNotifications.length} archived',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: screenWidth * 0.028,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.025),
        if (_filteredArchived.isEmpty)
          _isFiltering
              ? _buildNoResults(screenWidth)
              : _buildArchivedEmptyState(screenWidth)
        else
          ..._filteredArchived.map(
            (item) => Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
                bottom: screenHeight * 0.015,
              ),
              child: _buildCardContent(item, screenWidth),
            ),
          ),
      ],
    );
  }

  Widget _buildArchivedEmptyState(double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(top: screenWidth * 0.08),
      child: Center(
        child: SizedBox(
          width: screenWidth * 0.8,
          child: const ArchivedEmptyAnimation(),
        ),
      ),
    );
  }

  Widget _buildDismissibleCard({
    required _NotificationItem item,
    required Widget child,
    required double screenWidth,
  }) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      background: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5F5F), Color(0xFFD32F2F)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: screenWidth * 0.06),
        child: Container(
          width: screenWidth * 0.09,
          height: screenWidth * 0.09,
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: screenWidth * 0.045,
          ),
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: screenWidth * 0.06),
        child: Container(
          width: screenWidth * 0.09,
          height: screenWidth * 0.09,
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.archive_rounded,
            color: Colors.white,
            size: screenWidth * 0.045,
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        final completer = Completer<bool>();
        final isArchive = direction == DismissDirection.startToEnd;

        SnackbarHelper.show(
          context,
          isArchive ? 'Notification archived' : 'Notification dismissed',
          icon: isArchive ? Icons.archive_rounded : Icons.notifications_off_outlined,
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFFF3CA9B),
            onPressed: () => completer.complete(false),
          ),
          duration: const Duration(seconds: 3),
        );
        final result = await completer.future.timeout(
          const Duration(seconds: 3),
          onTimeout: () => true,
        );
        if (result) {
          setState(() {
            if (isArchive) {
              _itemArchived(item);
            } else {
              _itemDismissed(item);
            }
          });
        }
        return result;
      },
      child: child,
    );
  }

  void _itemDismissed(_NotificationItem item) {
    _todayNotifications.removeWhere((e) => e.id == item.id);
    _yesterdayNotifications.removeWhere((e) => e.id == item.id);
  }

  void _itemArchived(_NotificationItem item) {
    _todayNotifications.removeWhere((e) => e.id == item.id);
    _yesterdayNotifications.removeWhere((e) => e.id == item.id);
    _archivedNotifications.add(item);
  }

  List<_NotificationItem> _sortedNotifications(List<_NotificationItem> list) {
    final sorted = List<_NotificationItem>.from(list);
    sorted.sort((a, b) => a.isRead == b.isRead ? 0 : a.isRead ? 1 : -1);
    return sorted;
  }

  void _markAsRead(_NotificationItem item) {
    if (!item.isRead) {
      setState(() => item.isRead = true);
    }
  }

  void _openNotificationDetails(_NotificationItem item) {
    if (!item.isRead) {
      setState(() => item.isRead = true);
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailsScreen(
          icon: item.icon,
          iconColor: item.iconColor,
          title: item.title,
          subtitle: item.subtitle,
          timestamp: item.timestamp,
          isRead: item.isRead,
        ),
      ),
    );
  }

  Widget _buildCardContent(_NotificationItem item, double screenWidth) {
    return GestureDetector(
      onTap: () => _openNotificationDetails(item),
      child: Container(
        width: double.infinity,
        height: screenWidth * 0.19,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (item.isRead)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(2, 7),
              ),
            if (!item.isRead)
              BoxShadow(
                color: const Color(0xFFCB471B).withValues(alpha: 0.25),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(4, 10),
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
                  color: item.iconColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    item.icon,
                    color: Colors.black,
                    size: screenWidth * 0.07,
                  ),
                ),
              ),
            ),
            if (!item.isRead)
              Positioned(
                left: screenWidth * 0.03 + screenWidth * 0.128 - screenWidth * 0.015,
                top: (screenWidth * 0.19 - screenWidth * 0.128) / 2 - screenWidth * 0.005,
                child: Container(
                  width: screenWidth * 0.028,
                  height: screenWidth * 0.028,
                  decoration: BoxDecoration(
                    color: const Color(0xFF42A5F5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF42A5F5).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: screenWidth * 0.04,
              top: screenWidth * 0.025,
              child: Text(
                item.timestamp,
                style: TextStyle(
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
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.035,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.01),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontFamily: 'Abril Fatface',
                        fontWeight: FontWeight.w400,
                        fontSize: screenWidth * 0.035,
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
    );
  }

  PopupMenuItem<_MenuAction> _buildMenuItem({
    required IconData icon,
    required String label,
    required Color dotColor,
    required _MenuAction value,
    required double screenWidth,
    bool isDestructive = false,
  }) {
    return PopupMenuItem<_MenuAction>(
      value: value,
      height: screenWidth * 0.14,
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
        ],
      ),
    );
  }

  void _showStyledSnackBar(String message, IconData icon) {
    SnackbarHelper.show(context, message, icon: icon);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Widget _buildNoResults(double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(top: screenWidth * 0.1),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: screenWidth * 0.14,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            SizedBox(height: screenWidth * 0.03),
            Text(
              'No notifications found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.04,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              'Try a different search or filter',
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

  void _showHelpSheet() {
    final w = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.04, w * 0.06, w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: w * 0.12,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: w * 0.06),
            Text(
              'Help & Support',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: w * 0.05,
                color: Colors.white,
              ),
            ),
            SizedBox(height: w * 0.04),
            _buildHelpOption(
              icon: Icons.chat_outlined,
              label: 'Live Chat',
              subtitle: 'Talk to our support team',
              screenWidth: w,
            ),
            _buildHelpOption(
              icon: Icons.email_outlined,
              label: 'Email Us',
              subtitle: 'support@eventsuganda.com',
              screenWidth: w,
            ),
            _buildHelpOption(
              icon: Icons.help_outline_rounded,
              label: 'FAQ',
              subtitle: 'Find answers to common questions',
              screenWidth: w,
            ),
            _buildHelpOption(
              icon: Icons.phone_outlined,
              label: 'Call Us',
              subtitle: '+256 700 123456',
              screenWidth: w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.025),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            _showStyledSnackBar('$label selected', Icons.check_circle_outline);
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenWidth * 0.04,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.1,
                  height: screenWidth * 0.1,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3CA9B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFF3CA9B), size: screenWidth * 0.05),
                ),
                SizedBox(width: screenWidth * 0.035),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.038,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: screenWidth * 0.005),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: screenWidth * 0.028,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: screenWidth * 0.05,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (final item in _todayNotifications) {
        item.isRead = true;
      }
      for (final item in _yesterdayNotifications) {
        item.isRead = true;
      }
    });
    _showStyledSnackBar('All notifications marked as read', Icons.done_all_rounded);
  }

  Future<void> _deleteAllReadNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width;
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            padding: EdgeInsets.fromLTRB(w * 0.06, w * 0.08, w * 0.06, w * 0.04),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: w * 0.14,
                  height: w * 0.14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5F5F).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_sweep_outlined,
                    color: const Color(0xFFFF5F5F),
                    size: w * 0.07,
                  ),
                ),
                SizedBox(height: w * 0.04),
                Text(
                  'Delete All Read',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: w * 0.045,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: w * 0.02),
                Text(
                  'This will permanently remove all read notifications. This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: w * 0.03,
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: w * 0.06),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: w * 0.1,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: w * 0.035,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    Expanded(
                      child: SizedBox(
                        height: w * 0.1,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5F5F),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: w * 0.035,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      final removedToday = _todayNotifications.where((n) => n.isRead).toList();
      final removedYesterday = _yesterdayNotifications.where((n) => n.isRead).toList();

      setState(() {
        _todayNotifications.removeWhere((n) => n.isRead);
        _yesterdayNotifications.removeWhere((n) => n.isRead);
      });

      SnackbarHelper.show(
        context,
        'Read notifications deleted',
        icon: Icons.delete_sweep_outlined,
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFFF3CA9B),
          onPressed: () {
            setState(() {
              _todayNotifications.addAll(removedToday);
              _yesterdayNotifications.addAll(removedYesterday);
            });
          },
        ),
        duration: const Duration(seconds: 4),
      );
    }
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

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.category,
    this.isRead = false,
  });

  final int id;
  final IconData icon;
  final Color iconColor;
  final String timestamp;
  final String title;
  final String subtitle;
  final _NotificationCategory category;
  bool isRead;
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

