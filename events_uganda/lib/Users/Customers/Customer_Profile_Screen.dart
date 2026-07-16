import 'dart:io';
import 'dart:ui';
import 'package:events_uganda/Auth/auth_service.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:flutter/material.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with TickerProviderStateMixin {
  int _currentNavIndex = 3;
  String _userFullName = '';
  String _userEmail = '';
  String? _profilePicUrl;
  int? _hoveredIndex;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _entranceController;
  late Animation<double> _avatarScale;
  late Animation<Offset> _avatarSlide;
  late Animation<double> _infoFade;
  late Animation<double> _statsSlide;
  late Animation<double> _menuSlide;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadUser();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _avatarSlide = Tween<Offset>(
      begin: const Offset(0, -40),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    _infoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );

    _statsSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _menuSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.55, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _userFullName = user['fullName'] as String? ?? 'User';
        _userEmail = user['email'] as String? ?? '';
        _profilePicUrl = user['photoUrl'] as String?;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    if (!mounted) return;
    setState(() {
      _profilePicUrl = pickedFile.path;
    });
  }

  Widget _defaultProfileIcon(double screenWidth) {
    return Icon(Icons.person, color: Colors.white, size: screenWidth * 0.18);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: const Text(
          'Logout',
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              AuthService.clearToken();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D2B),
      body: Stack(
        children: [
          // --- Background gradient with floating orbs ---
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0D0D2B),
                    Color(0xFF1A0A3E),
                    Color(0xFF2D1B69),
                    Color(0xFFCC471B),
                  ],
                  stops: [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Decorative blur orbs
          Positioned(top: -h * 0.08, left: -w * 0.2,
            child: _buildOrb(w * 0.5, const Color(0xFF8715C9).withValues(alpha: 0.3)),
          ),
          Positioned(top: h * 0.25, right: -w * 0.15,
            child: _buildOrb(w * 0.35, const Color(0xFFFF6B35).withValues(alpha: 0.25)),
          ),
          Positioned(bottom: h * 0.35, left: -w * 0.1,
            child: _buildOrb(w * 0.3, const Color(0xFF1BCC94).withValues(alpha: 0.2)),
          ),
          Positioned(bottom: -h * 0.05, right: -w * 0.1,
            child: _buildOrb(w * 0.4, const Color(0xFF7EED27).withValues(alpha: 0.15)),
          ),

          // --- Top bar ---
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: h * 0.01),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(w, Icons.chevron_left, () => Navigator.of(context).maybePop()),
                    _buildIconButton(w, Icons.notifications_none_rounded, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                    }),
                  ],
                ),
              ),
            ),
          ),

          // --- Main scrollable content ---
          Positioned(
            top: h * 0.09,
            left: 0,
            right: 0,
            bottom: h * 0.1,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: h * 0.02),

                  // Avatar
                  SlideTransition(
                    position: _avatarSlide,
                    child: ScaleTransition(
                      scale: _avatarScale,
                      child: _buildAvatar(w, h),
                    ),
                  ),
                  SizedBox(height: h * 0.025),

                  // Name + Email
                  FadeTransition(
                    opacity: _infoFade,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: _entranceController,
                        curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
                      )),
                      child: Column(
                        children: [
                          Text(
                            _userFullName,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: w * 0.06,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: h * 0.006),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.email_outlined, size: w * 0.035, color: Colors.white.withValues(alpha: 0.6)),
                              SizedBox(width: w * 0.015),
                              Text(
                                _userEmail,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w400,
                                  fontSize: w * 0.035,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: h * 0.035),

                  // Stats glass card
                  AnimatedBuilder(
                    animation: _statsSlide,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, 30 * (1 - _statsSlide.value)),
                      child: Opacity(
                        opacity: _statsSlide.value,
                        child: child,
                      ),
                    ),
                    child: _buildStatsCard(w, h),
                  ),
                  SizedBox(height: h * 0.035),

                  // Menu items
                  AnimatedBuilder(
                    animation: _menuSlide,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, 50 * (1 - _menuSlide.value)),
                      child: child,
                    ),
                    child: _buildMenuSection(w, h),
                  ),

                  SizedBox(height: h * 0.04),
                ],
              ),
            ),
          ),

          // --- Bottom Navbar ---
          Positioned(
            bottom: h * 0.02,
            left: 0,
            right: 0,
            child: Center(
              child: BottomNavbar(
                activeIndex: _currentNavIndex,
                onItemSelected: (index) {
                  setState(() => _currentNavIndex = index);
                  if (index == 0) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerHomeScreen()));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: size * 0.3, sigmaY: size * 0.3),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildIconButton(double w, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.128,
        height: w * 0.128,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: w * 0.07),
        ),
      ),
    );
  }

  Widget _buildAvatar(double w, double h) {
    final avatarSize = w * 0.32;
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: avatarSize * _pulseAnimation.value + 12,
            height: avatarSize * _pulseAnimation.value + 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(
                colors: [
                  Color(0xFF7EED27),
                  Color(0xFF1BCC94),
                  Color(0xFFCC471B),
                  Color(0xFF8715C9),
                  Color(0xFF7EED27),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7EED27).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                        _profilePicUrl!.startsWith('http')
                            ? Image.network(_profilePicUrl!, width: avatarSize, height: avatarSize, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _defaultProfileIcon(w))
                            : Image.file(File(_profilePicUrl!), width: avatarSize, height: avatarSize, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _defaultProfileIcon(w))
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFCC471B), Color(0xFF8715C9)],
                            ),
                          ),
                          child: _defaultProfileIcon(w),
                        ),
                      // Camera overlay
                      Positioned(
                        bottom: 0,
                        right: avatarSize * 0.02,
                        child: Container(
                          width: w * 0.08,
                          height: w * 0.08,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(Icons.camera_alt, color: Colors.black, size: w * 0.04),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(double w, double h) {
    final stats = [
      {'value': '24', 'label': 'Events', 'icon': Icons.event, 'color': const Color(0xFF7EED27)},
      {'value': '128', 'label': 'Photos', 'icon': Icons.photo_camera, 'color': const Color(0xFF1BCC94)},
      {'value': '56', 'label': 'Reviews', 'icon': Icons.star, 'color': const Color(0xFFFFC107)},
      {'value': '4.8', 'label': 'Rating', 'icon': Icons.favorite, 'color': const Color(0xFFFF6B6B)},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: h * 0.02),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: stats.map((s) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(s['icon'] as IconData, color: s['color'] as Color, size: w * 0.055),
                    SizedBox(height: h * 0.008),
                    Text(
                      s['value'] as String,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w800,
                        fontSize: w * 0.045,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: h * 0.003),
                    Text(
                      s['label'] as String,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w400,
                        fontSize: w * 0.028,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(double w, double h) {
    final items = [
      _MenuItemData(Icons.person_outline, 'My Profile', const Color(0xFF027AC1), const Color(0xFFCAE8FA)),
      _MenuItemData(Icons.shopping_bag_outlined, 'My Orders', const Color(0xFFF19124), const Color(0xFFFFE0B2)),
      _MenuItemData(Icons.attach_money, 'Refund', const Color(0xFFE24B19), const Color(0xFFF7A083)),
      _MenuItemData(Icons.password_rounded, 'Change Password', const Color(0xFF238E05), const Color(0xFF98EE81)),
      _MenuItemData(Icons.payment_outlined, 'Payment Methods', const Color(0xFF5F0593), const Color(0xFFC491E2)),
      _MenuItemData(Icons.help_outline_rounded, 'Help & Support', const Color(0xFFD76005), const Color(0xFFF3D8C4)),
      _MenuItemData(Icons.logout_rounded, 'Logout', const Color(0xFF009465), const Color(0xFF89E0C4), isDestructive: true),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: h * 0.01),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                final item = items[i];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 400 + (i * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(50 * (1 - value), 0),
                        child: child,
                      ),
                    );
                  },
                  child: _buildMenuItem(w, item, i, i == items.length - 1),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(double w, _MenuItemData item, int index, bool isLast) {
    return GestureDetector(
      onTap: item.isDestructive
          ? _showLogoutDialog
          : () {},
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: _hoveredIndex == index ? 0.97 : 1.0),
        duration: const Duration(milliseconds: 150),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: w * 0.03),
          padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: h * 0.018),
          decoration: BoxDecoration(
            border: !isLast
                ? Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: w * 0.11,
                height: w * 0.11,
                decoration: BoxDecoration(
                  color: item.bgColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(item.icon, color: item.color, size: w * 0.055),
                ),
              ),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Abril Fatface',
                    fontWeight: FontWeight.w600,
                    fontSize: w * 0.04,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                width: w * 0.07,
                height: w * 0.07,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    item.isDestructive ? Icons.logout : Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: w * 0.04,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _MenuItemData {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final bool isDestructive;

  const _MenuItemData(this.icon, this.label, this.color, this.bgColor, {this.isDestructive = false});
}
