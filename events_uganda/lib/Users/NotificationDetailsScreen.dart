import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Users/Date_Of_Booking_Screen.dart';
import 'package:flutter/material.dart';

class NotificationDetailsScreen extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String timestamp;
  final bool isRead;

  const NotificationDetailsScreen({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.isRead = false,
  });

  @override
  State<NotificationDetailsScreen> createState() => _NotificationDetailsScreenState();
}

class _NotificationDetailsScreenState extends State<NotificationDetailsScreen> {
  late bool _isRead;
  String _userFullName = '';
  String? _profilePicUrl;

  String get _greetingText {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void initState() {
    super.initState();
    _isRead = widget.isRead;
    AuthService.getUser().then((userData) {
      if (mounted) {
        setState(() {
          _userFullName = userData?['fullName'] as String? ?? 'User';
          _profilePicUrl = userData?['profilePic'] as String?;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final screenWidth = screen.width;
    final screenHeight = screen.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background image (same as all other screens)
            Positioned(
              top: 0,
              bottom: 0,
              right: (screen.width + screen.width) / 300,
              child: Image.asset(
                'assets/backgroundcolors/normalscreen.png',
                width: screen.width * 1.08,
                height: screen.height * 0.9,
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DateOfBookingScreen(),
                        ),
                      ).then((_) {
                        if (mounted) setState(() {});
                      });
                    },
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
                ],
              ),
            ),
            // Greeting and user name
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
            // Profile picture circle
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
            // Notification bell circle
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
            // Content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(top: screenHeight * 0.18),
              child: Column(
                children: [
                  // Hero Icon
                  Container(
                    width: screenWidth * 0.28,
                    height: screenWidth * 0.28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.iconColor.withValues(alpha: 0.8),
                          widget.iconColor,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withValues(alpha: 0.35),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: screenWidth * 0.12,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.025),
                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w700,
                        fontSize: screenWidth * 0.055,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  // Timestamp + status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: screenWidth * 0.03,
                        color: Colors.grey,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        widget.timestamp,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w400,
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.025,
                          vertical: screenWidth * 0.008,
                        ),
                        decoration: BoxDecoration(
                          color: _isRead
                              ? Colors.grey.withValues(alpha: 0.1)
                              : const Color(0xFFCC471B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isRead
                                ? Colors.grey.withValues(alpha: 0.3)
                                : const Color(0xFFCC471B).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: screenWidth * 0.012,
                              height: screenWidth * 0.012,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isRead ? Colors.grey : const Color(0xFFCC471B),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Text(
                              _isRead ? 'Read' : 'New',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w600,
                                fontSize: screenWidth * 0.025,
                                color: _isRead ? Colors.grey : const Color(0xFFCC471B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.035),
                  // Gradient divider
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFFCC471B).withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.035),
                  // Description
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w600,
                            fontSize: screenWidth * 0.04,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w400,
                            fontSize: screenWidth * 0.038,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  // Action buttons
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _isRead = !_isRead);
                            },
                            child: Container(
                              height: screenWidth * 0.11,
                              decoration: BoxDecoration(
                                color: _isRead
                                    ? const Color(0xFFCC471B).withValues(alpha: 0.1)
                                    : const Color(0xFFCC471B),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _isRead
                                      ? const Color(0xFFCC471B).withValues(alpha: 0.3)
                                      : const Color(0xFFCC471B),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isRead
                                        ? Icons.mark_email_unread_outlined
                                        : Icons.mark_email_read_outlined,
                                    size: screenWidth * 0.045,
                                    color: _isRead ? const Color(0xFFCC471B) : Colors.white,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    _isRead ? 'Mark as Unread' : 'Mark as Read',
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w600,
                                      fontSize: screenWidth * 0.032,
                                      color: _isRead ? const Color(0xFFCC471B) : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: screenWidth * 0.11,
                            height: screenWidth * 0.11,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.share_outlined,
                              size: screenWidth * 0.045,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: screenWidth * 0.11,
                            height: screenWidth * 0.11,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: screenWidth * 0.045,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
