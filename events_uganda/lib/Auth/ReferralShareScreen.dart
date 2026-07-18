import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:shared_preferences/shared_preferences.dart';

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
      backgroundColor: const Color(0xFF0D1B2A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Share Referral Code',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.03),
            RepaintBoundary(
              key: _repaintKey,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Container(
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
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.06),
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
              ),
            ),
            SizedBox(height: screenHeight * 0.035),
            _buildActionButton(
              context,
              icon: Icons.download_rounded,
              label: 'Download as PNG',
              color: const Color(0xFFE94560),
              onTap: _downloadCard,
            ),
            SizedBox(height: screenHeight * 0.015),
            _buildActionButton(
              context,
              icon: Icons.share_rounded,
              label: 'Share to Apps',
              color: const Color(0xFF0F3460),
              onTap: _captureAndShare,
            ),
            SizedBox(height: screenHeight * 0.025),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
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
