import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';

class ReferralShareScreen extends StatefulWidget {
  const ReferralShareScreen({super.key});

  @override
  State<ReferralShareScreen> createState() => _ReferralShareScreenState();
}

class _ReferralShareScreenState extends State<ReferralShareScreen> {
  String _referralCode = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _referralCode = prefs.getString('userReferralCode') ?? 'No referral code yet';
    });
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
              top: screenHeight * 0.20,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
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
                  ],
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
            Positioned(
              top: screenHeight * 0.10 + screenWidth * 0.22 + screenHeight * 0.015 + screenWidth * 0.13,
              left: screenWidth * 0.03,
              right: screenWidth * 0.03,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: screenHeight * 0.03,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your Referral Code',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey.shade600,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Text(
                        _referralCode,
                        style: TextStyle(
                          fontSize: screenWidth * 0.14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE94560),
                          letterSpacing: 6,
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
    );
  }
}
