import 'dart:async';
import 'package:flutter/material.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:events_uganda/Users/Customers/Chat_Screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 0;
  String _userFullName = '';
  bool _isNavbarVisible = true;
  late AnimationController _navbarSlideController;
  late Animation<Offset> _navbarSlideAnimation;

  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _smsEnabled = false;
  bool _bookingUpdates = true;
  bool _promotions = false;
  bool _messages = true;
  bool _reminders = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
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
    AuthService.getUser().then((userData) {
      if (mounted) {
        setState(() {
          _userFullName = userData?['fullName'] as String? ?? 'User';
        });
      }
    });
  }

  @override
  void dispose() {
    _navbarSlideController.dispose();
    super.dispose();
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

  Widget _buildSettingTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double screenWidth,
    IconData? leadingIcon,
    Color? iconColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.005,
      ),
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
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.025,
        ),
        child: Row(
          children: [
            if (leadingIcon != null)
              Container(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(0xFFCB471B))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  leadingIcon,
                  color: iconColor ?? const Color(0xFFCB471B),
                  size: screenWidth * 0.05,
                ),
              ),
            if (leadingIcon != null) SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.035,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: screenWidth * 0.005),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Abril Fatface',
                        fontWeight: FontWeight.w400,
                        fontSize: screenWidth * 0.035,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            _buildModernToggle(
              value: value,
              onChanged: onChanged,
              screenWidth: screenWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
    required double screenWidth,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        width: screenWidth * 0.14,
        height: screenWidth * 0.068,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(screenWidth * 0.034),
          gradient: LinearGradient(
            colors: value
                ? [const Color(0xFFFFB74D), const Color(0xFFFF8A65)]
                : [const Color(0xFF37474F), const Color(0xFF1A237E)],
          ),
          boxShadow: [
            BoxShadow(
              color: value
                  ? const Color(0xFFFFB74D).withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: value ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (!value)
              Positioned(
                left: screenWidth * 0.015,
                top: screenWidth * 0.01,
                child: Icon(
                  Icons.star,
                  size: screenWidth * 0.016,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            if (!value)
              Positioned(
                left: screenWidth * 0.045,
                bottom: screenWidth * 0.012,
                child: Icon(
                  Icons.star,
                  size: screenWidth * 0.01,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: screenWidth * 0.052,
                height: screenWidth * 0.052,
                margin: EdgeInsets.all(screenWidth * 0.008),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => RotationTransition(
                    turns: child.key == const ValueKey('sun')
                        ? Tween<double>(begin: -0.25, end: 0).animate(anim)
                        : Tween<double>(begin: 0.25, end: 0).animate(anim),
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Icon(
                    value ? Icons.wb_sunny : Icons.nightlight_round,
                    key: ValueKey(value ? 'sun' : 'moon'),
                    size: screenWidth * 0.032,
                    color: value ? const Color(0xFFFF8A65) : const Color(0xFF1A237E),
                  ),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final double headerBottom = screenHeight * 0.03 +
        screenWidth * 0.128 +
        screenHeight * 0.02 +
        screenWidth * 0.12 +
        screenHeight * 0.012;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: (MediaQuery.of(context).size.width +
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
              child: GestureDetector(
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
            ),
            Positioned(
              top: screenHeight * 0.03 + screenWidth * 0.015,
              left: screenWidth * 0.04 + screenWidth * 0.128 + screenWidth * 0.03,
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
              top: screenHeight * 0.03 + screenWidth * 0.128 + screenHeight * 0.02,
              left: screenWidth * 0.04,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notification Settings',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w700,
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.006),
                  Text(
                    'Manage how you receive updates from Events Uganda',
                    style: TextStyle(
                      fontFamily: 'Abril Fatface',
                      fontWeight: FontWeight.w400,
                      fontSize: screenWidth * 0.024,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.003),
                  Text(
                    'Simply tap the toggle button to turn on or off',
                    style: TextStyle(
                      fontFamily: 'Abril Fatface',
                      fontWeight: FontWeight.w400,
                      fontSize: screenWidth * 0.024,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: headerBottom,
              left: 0,
              right: 0,
              bottom: screenHeight * 0.10,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: screenHeight * 0.01),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.04,
                        top: screenHeight * 0.01,
                        bottom: screenHeight * 0.01,
                      ),
                      child: Text(
                        'CHANNELS',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: screenWidth * 0.028,
                          color: const Color(0xFFCB471B),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildSettingTile(
                      screenWidth: screenWidth,
                      title: 'Push Notifications',
                      subtitle: 'Receive notifications on your device',
                      value: _pushEnabled,
                      leadingIcon: Icons.phone_android_rounded,
                      iconColor: const Color(0xFF42A5F5),
                      onChanged: (v) => setState(() => _pushEnabled = v),
                    ),
                    _buildSettingTile(
                      screenWidth: screenWidth,
                      title: 'Email Notifications',
                      subtitle: 'Receive notifications via email',
                      value: _emailEnabled,
                      leadingIcon: Icons.email_rounded,
                      iconColor: const Color(0xFFAB47BC),
                      onChanged: (v) => setState(() => _emailEnabled = v),
                    ),
                    _buildSettingTile(
                      screenWidth: screenWidth,
                      title: 'SMS Notifications',
                      subtitle: 'Receive notifications via text message',
                      value: _smsEnabled,
                      leadingIcon: Icons.sms_rounded,
                      iconColor: const Color(0xFF4CAF50),
                      onChanged: (v) => setState(() => _smsEnabled = v),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.04,
                        top: screenHeight * 0.02,
                        bottom: screenHeight * 0.01,
                      ),
                      child: Text(
                        'NOTIFICATION TYPES',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: screenWidth * 0.028,
                          color: const Color(0xFFCB471B),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildSettingTile(
                      screenWidth: screenWidth,
                      title: 'Booking Updates',
                      subtitle: 'Booking confirmations, changes & cancellations',
                      value: _bookingUpdates,
                      leadingIcon: Icons.calendar_month_rounded,
                      iconColor: const Color(0xFFF3CA9B),
                      onChanged: (v) => setState(() => _bookingUpdates = v),
                    ),
                    _buildSettingTile(
                      screenWidth: screenWidth,
                      title: 'Promotions & Offers',
                      subtitle: 'Special deals and promotional content',
                      value: _promotions,
                      leadingIcon: Icons.local_offer_rounded,
                      iconColor: const Color(0xFFFF5F5F),
                      onChanged: (v) => setState(() => _promotions = v),
                    ),
                    _buildSettingTile(
                      screenWidth: screenWidth,
                      title: 'Messages',
                      subtitle: 'Direct messages from event planners',
                      value: _messages,
                      leadingIcon: Icons.message_rounded,
                      iconColor: const Color(0xFF42A5F5),
                      onChanged: (v) => setState(() => _messages = v),
                    ),
                    _buildSettingTile(
                      screenWidth: screenWidth,
                      title: 'Reminders',
                      subtitle: 'Upcoming event reminders',
                      value: _reminders,
                      leadingIcon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFF96E8F4),
                      onChanged: (v) => setState(() => _reminders = v),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.04,
                        top: screenHeight * 0.02,
                        bottom: screenHeight * 0.01,
                      ),
                      child: Text(
                        'ALERT STYLE',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          fontSize: screenWidth * 0.028,
                          color: const Color(0xFFCB471B),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildSettingTile(
                      screenWidth: screenWidth,
                      title: 'Sound',
                      subtitle: 'Play a sound when notification arrives',
                      value: _soundEnabled,
                      leadingIcon: Icons.volume_up_rounded,
                      iconColor: const Color(0xFFCB471B),
                      onChanged: (v) => setState(() => _soundEnabled = v),
                    ),
                    _buildSettingTile(
                      screenWidth: screenWidth,
                      title: 'Vibration',
                      subtitle: 'Vibrate device on notification',
                      value: _vibrationEnabled,
                      leadingIcon: Icons.vibration_rounded,
                      iconColor: const Color(0xFF546E7A),
                      onChanged: (v) => setState(() => _vibrationEnabled = v),
                    ),
                    SizedBox(height: screenHeight * 0.015),
                    Center(
                      child: Text(
                        'Changes are saved automatically',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.028,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.05,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE0E7FF),
                                Color(0xFFCD7C20),
                              ],
                              stops: [0.0, 0.47],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Restore default settings
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              'Restore Default Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                fontSize: screenWidth * 0.03,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
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
                        setState(() => _currentNavIndex = index);
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
}
