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

  @override
  void initState() {
    super.initState();
    _isRead = widget.isRead;
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
            // Background gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: screenHeight * 0.45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.iconColor.withValues(alpha: 0.15),
                      widget.iconColor.withValues(alpha: 0.05),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -screenWidth * 0.15,
              right: -screenWidth * 0.1,
              child: Container(
                width: screenWidth * 0.5,
                height: screenWidth * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.iconColor.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.1,
              left: -screenWidth * 0.12,
              child: Container(
                width: screenWidth * 0.3,
                height: screenWidth * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.iconColor.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.02,
                      top: screenHeight * 0.01,
                      right: screenWidth * 0.02,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: screenWidth * 0.04,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenWidth * 0.012,
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
                                width: screenWidth * 0.015,
                                height: screenWidth * 0.015,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isRead ? Colors.grey : const Color(0xFFCC471B),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.015),
                              Text(
                                _isRead ? 'Read' : 'New',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w600,
                                  fontSize: screenWidth * 0.028,
                                  color: _isRead ? Colors.grey : const Color(0xFFCC471B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
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
                  SizedBox(height: screenHeight * 0.03),
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
                  // Timestamp
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
