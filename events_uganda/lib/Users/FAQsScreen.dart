import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';
import 'package:events_uganda/components/sidebar_menu.dart';
import 'package:events_uganda/Users/Customers/Customer_Profile_Screen.dart';

class FAQsScreen extends StatefulWidget {
    const FAQsScreen({super.key});

    @override
    State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> with TickerProviderStateMixin {
    Timer? _countdownTimer;
    Duration _remaining = const Duration(hours: 0, minutes: 0, seconds: 0);
    int _currentNavIndex = 2;
    String _userFullName = '';
    String? _profilePicUrl;
    bool _isNavbarVisible = true;
    late AnimationController _navbarSlideController;
    late Animation<Offset> _navbarSlideAnimation;
    int _expandedIndex = -1;

    final List<Map<String, String>> _faqs = [
        {
            'q': 'How do I book an event service?',
            'a': 'Browse through our service categories, select your preferred vendor, choose a date, and complete the booking. You\'ll receive a confirmation once the vendor accepts.',
        },
        {
            'q': 'Can I cancel or reschedule a booking?',
            'a': 'Yes, you can cancel or reschedule from the My Bookings section. Cancellation policies vary by vendor — please check the terms before confirming.',
        },
        {
            'q': 'How do I earn referral rewards?',
            'a': 'Share your unique referral code with friends. When they book a service using your code, you earn points that can be redeemed on future bookings.',
        },
        {
            'q': 'What payment methods are accepted?',
            'a': 'We accept mobile money, credit/debit cards, and bank transfers. All payments are processed securely through our platform.',
        },
        {
            'q': 'How do I contact customer support?',
            'a': 'You can reach us through the Contact Support section in the sidebar, or via email at support@eventsuganda.com. We typically respond within 24 hours.',
        },
        {
            'q': 'Is my personal information secure?',
            'a': 'Absolutely. We use industry-standard encryption and security measures to protect your data. We never share your information with third parties without your consent.',
        },
        {
            'q': 'Can I leave a review for a vendor?',
            'a': 'Yes, after your event you can rate and review the vendor from the booking details page. Your feedback helps other users make informed decisions.',
        },
    ];

    String get _greetingText {
        final hour = DateTime.now().hour;
        if (hour < 12) return 'Good Morning';
        if (hour < 17) return 'Good Afternoon';
        return 'Good Evening';
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

    void _hideNavbar() {
        _navbarSlideController.forward();
        setState(() => _isNavbarVisible = false);
    }

    void _showNavbar() {
        _navbarSlideController.reverse();
        setState(() => _isNavbarVisible = true);
    }

    @override
    void initState() {
        super.initState();
        _startCountdown();
        _loadUserProfile();
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
    }

    @override
    void dispose() {
        _navbarSlideController.dispose();
        _countdownTimer?.cancel();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final w = MediaQuery.of(context).size.width;
        final h = MediaQuery.of(context).size.height;

        return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
                child: Stack(
                    children: [
                        Positioned(
                            top: h * 0.0,
                            bottom: h * 0.0,
                            right: (w + w * 1) / 300,
                            child: Image.asset(
                                'assets/backgroundcolors/normalscreen.png',
                                width: w * 1.08,
                                height: h * 0.9,
                                fit: BoxFit.contain,
                            ),
                        ),
                        Positioned(
                            top: h * 0.03,
                            left: w * 0.04,
                            child: Row(
                                children: [
                                    GestureDetector(
                                        onTap: () => Navigator.of(context).maybePop(),
                                        child: Container(
                                            width: w * 0.128,
                                            height: w * 0.128,
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFF3CA9B),
                                                borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Center(
                                                child: Icon(
                                                    Icons.chevron_left,
                                                    color: Colors.black,
                                                    size: w * 0.10,
                                                ),
                                            ),
                                        ),
                                    ),
                                    SizedBox(width: w * 0.02),
                                    GestureDetector(
                                        onTap: () => SidebarMenu.show(context),
                                        child: Container(
                                            width: w * 0.128,
                                            height: w * 0.128,
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
                                                    width: w * 0.07,
                                                    height: w * 0.07,
                                                    fit: BoxFit.contain,
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        Positioned(
                            top: h * 0.03,
                            right: w * 0.04,
                            child: Row(
                                children: [
                                    Container(
                                        width: w * 0.128,
                                        height: w * 0.128,
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
                                                    ? Image.network(_profilePicUrl!, fit: BoxFit.cover)
                                                    : Image.file(File(_profilePicUrl!), fit: BoxFit.cover),
                                            )
                                            : Center(
                                                child: Icon(
                                                    Icons.person,
                                                    color: Colors.black,
                                                    size: w * 0.07,
                                                ),
                                            ),
                                    ),
                                    SizedBox(width: w * 0.02),
                                    GestureDetector(
                                        onTap: () {
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) => const NotificationScreen(),
                                                ),
                                            );
                                        },
                                        child: Container(
                                            width: w * 0.128,
                                            height: w * 0.128,
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
                                                    size: w * 0.07,
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        Positioned(
                            top: h * 0.03 + w * 0.015,
                            left: w * 0.04 + w * 0.128 + w * 0.02 + w * 0.128 + w * 0.03,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Text(
                                        _greetingText,
                                        style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontWeight: FontWeight.w700,
                                            fontSize: w * 0.04,
                                            color: Colors.black,
                                        ),
                                    ),
                                    SizedBox(height: w * 0.005),
                                    Text(
                                        _userFullName,
                                        style: TextStyle(
                                            fontFamily: 'Abril Fatface',
                                            fontWeight: FontWeight.w600,
                                            fontSize: w * 0.035,
                                            color: Colors.black,
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        Positioned(
                            top: h * 0.03 + w * 0.128 + h * 0.02,
                            left: w * 0.04,
                            right: w * 0.04,
                            bottom: h * 0.12,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Row(
                                        children: [
                                            Icon(
                                                Icons.quiz_rounded,
                                                color: const Color(0xFFCD7C20),
                                                size: w * 0.06,
                                            ),
                                            SizedBox(width: w * 0.02),
                                            Text(
                                                'Frequently Asked Questions',
                                                style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: w * 0.045,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF1A1A2E),
                                                ),
                                            ),
                                        ],
                                    ),
                                    SizedBox(height: h * 0.01),
                                    Text(
                                        'Everything you need to know about Events Uganda',
                                        style: TextStyle(
                                            fontFamily: 'Montserrat',
                                            fontSize: w * 0.028,
                                            color: Colors.black54,
                                        ),
                                    ),
                                    SizedBox(height: h * 0.02),
                                    Expanded(
                                        child: ListView.builder(
                                            itemCount: _faqs.length,
                                            padding: EdgeInsets.zero,
                                            itemBuilder: (context, index) {
                                                final isExpanded = _expandedIndex == index;
                                                final faq = _faqs[index];
                                                return TweenAnimationBuilder<double>(
                                                    duration: const Duration(milliseconds: 300),
                                                    tween: Tween(begin: 0.0, end: isExpanded ? 1.0 : 0.0),
                                                    builder: (context, value, child) {
                                                        return Padding(
                                                            padding: EdgeInsets.only(bottom: h * 0.01),
                                                            child: Container(
                                                                decoration: BoxDecoration(
                                                                    color: Colors.white,
                                                                    borderRadius: BorderRadius.circular(16),
                                                                    boxShadow: [
                                                                        BoxShadow(
                                                                            color: Colors.black.withValues(alpha: 0.06),
                                                                            blurRadius: 12,
                                                                            offset: const Offset(0, 4),
                                                                        ),
                                                                    ],
                                                                ),
                                                                child: Column(
                                                                    children: [
                                                                        GestureDetector(
                                                                            onTap: () {
                                                                                setState(() {
                                                                                    _expandedIndex = isExpanded ? -1 : index;
                                                                                });
                                                                            },
                                                                            child: Container(
                                                                                padding: EdgeInsets.symmetric(
                                                                                    horizontal: w * 0.04,
                                                                                    vertical: h * 0.018,
                                                                                ),
                                                                                child: Row(
                                                                                    children: [
                                                                                        Container(
                                                                                            width: w * 0.08,
                                                                                            height: w * 0.08,
                                                                                            decoration: BoxDecoration(
                                                                                                shape: BoxShape.circle,
                                                                                                color: isExpanded
                                                                                                    ? const Color(0xFFCD7C20)
                                                                                                    : const Color(0xFFF3CA9B).withValues(alpha: 0.3),
                                                                                            ),
                                                                                            child: Center(
                                                                                                child: Text(
                                                                                                    '${index + 1}',
                                                                                                    style: TextStyle(
                                                                                                        fontFamily: 'Montserrat',
                                                                                                        fontSize: w * 0.032,
                                                                                                        fontWeight: FontWeight.bold,
                                                                                                        color: isExpanded
                                                                                                            ? Colors.white
                                                                                                            : const Color(0xFFCD7C20),
                                                                                                    ),
                                                                                                ),
                                                                                            ),
                                                                                        ),
                                                                                        SizedBox(width: w * 0.03),
                                                                                        Expanded(
                                                                                            child: Text(
                                                                                                faq['q']!,
                                                                                                overflow: TextOverflow.ellipsis,
                                                                                                style: TextStyle(
                                                                                                    fontFamily: 'Montserrat',
                                                                                                    fontSize: w * 0.03,
                                                                                                    fontWeight: FontWeight.w600,
                                                                                                    color: const Color(0xFF1A1A2E),
                                                                                                ),
                                                                                            ),
                                                                                        ),
                                                                                        AnimatedRotation(
                                                                                            turns: isExpanded ? 0.5 : 0.0,
                                                                                            duration: const Duration(milliseconds: 300),
                                                                                            child: Icon(
                                                                                                Icons.keyboard_arrow_down_rounded,
                                                                                                color: isExpanded
                                                                                                    ? const Color(0xFFCD7C20)
                                                                                                    : Colors.black54,
                                                                                                size: w * 0.06,
                                                                                            ),
                                                                                        ),
                                                                                    ],
                                                                                ),
                                                                            ),
                                                                        ),
                                                                        AnimatedCrossFade(
                                                                            duration: const Duration(milliseconds: 300),
                                                                            crossFadeState: isExpanded
                                                                                ? CrossFadeState.showFirst
                                                                                : CrossFadeState.showSecond,
                                                                            firstChild: Container(
                                                                                width: double.infinity,
                                                                                padding: EdgeInsets.only(
                                                                                    left: w * 0.04 + w * 0.08 + w * 0.03,
                                                                                    right: w * 0.04,
                                                                                    bottom: h * 0.018,
                                                                                ),
                                                                                child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                        Container(
                                                                                            height: 1,
                                                                                            color: const Color(0xFFF3CA9B).withValues(alpha: 0.3),
                                                                                        ),
                                                                                        SizedBox(height: h * 0.012),
                                                                                        Text(
                                                                                            faq['a']!,
                                                                                            style: TextStyle(
                                                                                                fontFamily: 'Montserrat',
                                                                                                fontSize: w * 0.026,
                                                                                                color: Colors.black87,
                                                                                                height: 1.5,
                                                                                            ),
                                                                                        ),
                                                                                    ],
                                                                                ),
                                                                            ),
                                                                            secondChild: const SizedBox.shrink(),
                                                                        ),
                                                                    ],
                                                                ),
                                                            ),
                                                        );
                                                    },
                                                );
                                            },
                                        ),
                                    ),
                                ],
                            ),
                        ),
                        if (_isNavbarVisible)
                            Positioned(
                                bottom: h * 0.02,
                                left: 0,
                                right: 0,
                                child: GestureDetector(
                                    onVerticalDragEnd: (details) {
                                        if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                                            _hideNavbar();
                                        }
                                    },
                                    child: SlideTransition(
                                        position: _navbarSlideAnimation,
                                        child: Center(
                                            child: BottomNavbar(
                                                activeIndex: _currentNavIndex,
                                                onItemSelected: (index) {
                                                    setState(() => _currentNavIndex = index);
                                                    if (index == 3) {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder: (context) => const CustomerProfileScreen(),
                                                            ),
                                                        );
                                                    }
                                                },
                                            ),
                                        ),
                                    ),
                                ),
                            ),
                        if (!_isNavbarVisible)
                            Positioned(
                                bottom: h * 0.06,
                                right: w * 0.06,
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
}
