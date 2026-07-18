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

class _ReferralShareScreenState extends State<ReferralShareScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();
  String _referralCode = 'Loading...';
  bool _isLoading = false;

  late AnimationController _controller;
  late Animation<double> _offsetAnim;
  late Animation<double> _opacityAnim;
  bool _isDragging = false;
  double _dragStart = 0.0;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _offsetAnim = Tween<double>(
      begin: 0,
      end: 200,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _opacityAnim = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          final last = cardImages.removeLast();
          cardImages.insert(0, last);
          _controller.reset();
          _isDragging = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                child: SingleChildScrollView(
                  child: RepaintBoundary(
                    key: _repaintKey,
                    child: Column(
                      children: [
                        SizedBox(height: screenHeight * 0.02),
                        SizedBox(
                          height: screenHeight * 0.38,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Positioned(
                                top: screenHeight * 0.0,
                                child: Transform.rotate(
                                  angle: 0,
                                  child: _buildImageCard(cardImages[0], screenWidth, screenHeight, 0.92, 0.34),
                                ),
                              ),
                              Positioned(
                                top: screenHeight * 0.02,
                                child: Transform.rotate(
                                  angle: -0.035,
                                  child: _buildImageCard(cardImages[1], screenWidth, screenHeight, 0.92, 0.36),
                                ),
                              ),
                              Positioned(
                                top: screenHeight * 0.06,
                                child: Transform.rotate(
                                  angle: -0.056,
                                  child: _buildImageCard(cardImages[2], screenWidth, screenHeight, 0.92, 0.38),
                                ),
                              ),
                              Positioned(
                                top: screenHeight * 0.11 + _dragOffset,
                                child: GestureDetector(
                                  onVerticalDragStart: (details) {
                                    _dragStart = details.localPosition.dy;
                                    _isDragging = true;
                                  },
                                  onVerticalDragUpdate: (details) {
                                    if (_isDragging && details.localPosition.dy - _dragStart > 60) {
                                      _isDragging = false;
                                      _controller.forward();
                                    }
                                  },
                                  onVerticalDragEnd: (_) {
                                    if (_isDragging) {
                                      _isDragging = false;
                                      _controller.reverse();
                                    }
                                  },
                                  child: AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      return Opacity(
                                        opacity: _opacityAnim.value,
                                        child: Transform.translate(
                                          offset: Offset(0, _offsetAnim.value),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: Transform.rotate(
                                      angle: -0.088,
                                      child: _buildImageCard(cardImages[3], screenWidth, screenHeight, 0.92, 0.40),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        _buildActionButton(
                          icon: Icons.download_rounded,
                          label: 'Download as PNG',
                          color: const Color(0xFFB47A25),
                          onTap: _downloadCard,
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        _buildActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share to Apps',
                          color: const Color(0xFF00695C),
                          onTap: _captureAndShare,
                        ),
                        SizedBox(height: screenHeight * 0.025),
                      ],
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

  Widget _buildImageCard(
    String imagePath,
    double screenWidth,
    double screenHeight,
    double widthFactor,
    double? heightFactor,
  ) {
    return Container(
      width: screenWidth * widthFactor,
      height: screenHeight * (heightFactor ?? 0.25),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.45), BlendMode.darken),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.card_giftcard, color: Colors.white.withValues(alpha: 0.7), size: screenWidth * 0.05),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenWidth * 0.01),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'REFERRAL',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: screenWidth * 0.022,
                      color: Colors.white,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              'YOUR CODE',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: screenWidth * 0.024,
                color: Colors.white.withValues(alpha: 0.7),
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenHeight * 0.006),
            Text(
              _referralCode,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: screenHeight * 0.006),
            Row(
              children: [
                Text(
                  'Events Uganda',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: screenWidth * 0.03,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: Colors.white.withValues(alpha: 0.4), size: screenWidth * 0.035),
              ],
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
          color: color,
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

List<String> cardImages = [
  'assets/images/introduction.jpg',
  'assets/images/introductionbride.jpg',
  'assets/images/women.jpg',
  'assets/images/bdgal4.jpg',
];
