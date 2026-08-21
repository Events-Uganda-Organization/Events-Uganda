import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:events_uganda/components/snackbar_helper.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';

class ReferralShareScreen extends StatefulWidget {
  const ReferralShareScreen({super.key});

  @override
  State<ReferralShareScreen> createState() => _ReferralShareScreenState();
}

class _NotchedButtonClipper extends CustomClipper<Path> {
  final double radius;

  _NotchedButtonClipper({this.radius = 15});

  @override
  Path getClip(Size size) {
    final path = Path();
    final r = radius;
    final notchWidth = size.width * 0.1;
    final notchHeight = (size.height / 2 - r - 2).clamp(4.0, size.height * 0.12);

    path.moveTo(r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);
    path.lineTo(size.width, size.height / 2 - notchHeight);
    path.lineTo(size.width - notchWidth, size.height / 2);
    path.lineTo(size.width, size.height / 2 + notchHeight);
    path.lineTo(size.width, size.height - r);
    path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);
    path.lineTo(r, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - r);
    path.lineTo(0, size.height / 2 + notchHeight);
    path.lineTo(notchWidth, size.height / 2);
    path.lineTo(0, size.height / 2 - notchHeight);
    path.lineTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _ReferralShareScreenState extends State<ReferralShareScreen> {
  Future<String> _getReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userReferralCode') ?? 'No referral code yet';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: (screenWidth + screenWidth) / 300,
              child: Image.asset(
                'assets/backgroundcolors/normalscreen.png',
                width: screenWidth * 1.08,
                height: screenHeight * 0.9,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: screenHeight * 0.13,
              left: 0,
              right: 0,
              child: Center(
                child: FutureBuilder<String>(
                  future: _getReferralCode(),
                  builder: (context, snapshot) {
                    final referralCode = snapshot.data ?? 'Loading...';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Share Your Code',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: screenWidth * 0.048,
                            color: Colors.black,
                          ),
                        ),
                         SizedBox(height: screenHeight * 0.009),
                         Text(
                           'Invite friends & earn rewards',
                           style: TextStyle(
                             fontWeight: FontWeight.w500,
                             fontSize: screenWidth * 0.035,
                             color: Colors.black,
                           ),
                         ),
                         SizedBox(height: screenHeight * 0.03),
                        Image.asset(
                          'assets/images/referralcode.png',
                          width: screenWidth * 0.75,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                          child: Text(
                            'Here is your referral code that you can share with friends and family who have not yet joined the app to win gifts.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: screenWidth * 0.032,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        ClipPath(
                          clipper: _NotchedButtonClipper(radius: 20),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                            decoration: BoxDecoration(
                              color: const Color(0xFFCD7C20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    referralCode,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenWidth * 0.04,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: referralCode));
                                  SnackbarHelper.show(
                                    context,
                                    'Referral code copied!',
                                    icon: Icons.check_circle_rounded,
                                    backgroundColor: const Color(0xFFCD7C20),
                                  );
                                },
                                  child: Icon(
                                    Icons.copy,
                                    color: Colors.white,
                                    size: screenWidth * 0.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.01,
              left: 0,
              right: 0,
              child: Center(
                child: Icon(
                  Icons.card_giftcard,
                  color: const Color(0xFFE94560),
                  size: screenWidth * 0.14,
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
              top: screenHeight * 0.04,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: screenWidth * 0.13,
                  height: screenWidth * 0.13,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C2B0),
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
          ],
        ),
      ),
    );
  }
}
