import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';

class ReferralShareScreen extends StatefulWidget {
  const ReferralShareScreen({super.key});

  @override
  State<ReferralShareScreen> createState() => _ReferralShareScreenState();
}

class _ReferralShareScreenState extends State<ReferralShareScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  String _referralCode = 'Loading...';
  bool _isLoading = false;

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

  Future<void> _captureAndShare() async {
    setState(() => _isLoading = true);

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/referral_code.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Join me on Events Uganda! Use my referral code: $_referralCode',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadCard() async {
    setState(() => _isLoading = true);

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/referral_code.png');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral card saved!'),
            backgroundColor: Color(0xFF00695C),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                        fontSize: screenWidth * 0.048,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.009),
                    Text(
                      'Invite friends & earn rewards',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
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
              top: screenHeight * 0.05,
              right: screenWidth * 0.2,
              left: screenWidth * 0.2,
              child: Container(
                width: screenWidth * 0.3,
                height: screenWidth * 0.3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00695C), width: 2),
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
                    Icons.card_giftcard,
                    color: const Color(0xFFE94560),
                    size: screenWidth * 0.12,
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
                  border: Border(
                    top: BorderSide(color: Color(0xFFDE7A07), width: 1),
                    left: BorderSide(color: Color(0xFFDE7A07), width: 1),
                    right: BorderSide(color: Color(0xFFDE7A07), width: 1),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      RepaintBoundary(
                        key: _repaintKey,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.06),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F3460).withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.015),
                              Container(
                                width: screenWidth * 0.15,
                                height: screenWidth * 0.15,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.card_giftcard,
                                    color: const Color(0xFFE94560),
                                    size: screenWidth * 0.07,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                'Events Uganda',
                                style: TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontSize: screenWidth * 0.07,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'Your Referral Code',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: screenWidth * 0.03,
                                  color: Colors.white70,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.025),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.025,
                                  horizontal: screenWidth * 0.05,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE94560).withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _referralCode,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: screenWidth * 0.09,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE94560),
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              Text(
                                'Scan or share this code to invite friends',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: screenWidth * 0.026,
                                  color: Colors.white54,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                                    width: screenWidth * 0.02,
                                    height: screenWidth * 0.02,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE94560).withValues(alpha: 0.5 + index * 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      _buildActionButton(
                        icon: Icons.download_rounded,
                        label: 'Download as PNG',
                        color: const Color(0xFFE94560),
                        onTap: _downloadCard,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildActionButton(
                        icon: Icons.share_rounded,
                        label: 'Share to Apps',
                        color: const Color(0xFF0F3460),
                        onTap: _captureAndShare,
                      ),
                      SizedBox(height: screenHeight * 0.025),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: screenWidth * 0.14,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, color: Colors.white, size: screenWidth * 0.06),
            SizedBox(width: screenWidth * 0.025),
            Text(
              _isLoading ? 'Processing...' : label,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
