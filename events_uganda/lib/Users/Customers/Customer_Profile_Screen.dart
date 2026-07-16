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
  int? _expandedIndex;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _arrowController;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _arrowController.dispose();
    super.dispose();
  }

  void _toggleSection(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
        _arrowController.reverse();
      } else {
        if (_expandedIndex == null) {
          _arrowController.forward();
        }
        _expandedIndex = index;
      }
    });
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (user != null) {
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
    setState(() {
      _profilePicUrl = pickedFile.path;
    });
  }

  Widget _defaultProfileIcon(double screenWidth) {
    return Icon(
      Icons.person,
      color: Colors.black,
      size: screenWidth * 0.18,
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final screen = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.0,
              bottom: MediaQuery.of(context).size.height * 0.0,
              right:
                  (MediaQuery.of(context).size.width +
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
              top: screenHeight * 0.20,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _userFullName,
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w900,
                        fontSize: screenWidth * 0.048,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.009),
                    Text(
                      _userEmail,
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
                  border: Border.all(color: Color(0XFFF19124), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                      ClipOval(
                        child: _profilePicUrl!.startsWith('http')
                            ? Image.network(
                                _profilePicUrl!,
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _defaultProfileIcon(screenWidth);
                                },
                              )
                            : Image.file(
                                File(_profilePicUrl!),
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _defaultProfileIcon(screenWidth);
                                },
                              ),
                      )
                    else
                      _defaultProfileIcon(screenWidth),
                    // Upload icon square at bottom right
                    Positioned(
                      bottom: screenWidth * 0.02,
                      right: screenWidth * 0.13,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFC107),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Center(
                            child: Icon(
                                    Icons.upload,
                                    color: Colors.black,
                                    size: screenWidth * 0.045,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
              top: MediaQuery.of(context).size.height * 0.04,
              left: MediaQuery.of(context).size.width * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.13,
                  height: MediaQuery.of(context).size.width * 0.13,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C2B0),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left,
                      color: Colors.black,
                      size: MediaQuery.of(context).size.width * 0.10,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top:
                  MediaQuery.of(context).size.height * 0.10 +
                  MediaQuery.of(context).size.width * 0.22 +
                  MediaQuery.of(context).size.height * 0.015 +
                  MediaQuery.of(context).size.width * 0.13,
              left: MediaQuery.of(context).size.width * 0.03,
              right: MediaQuery.of(context).size.width * 0.03,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screen.width * 0.08,
                  vertical: screen.height * 0.03,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                  border: Border.all(color: const Color(0xFFDE7A07), width: 1),
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height *
                          1.2, // 120% of screen height
                    ),
                    child: Column(
                      children: [
                        _buildMenuSection(screen, screenWidth, screenHeight),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom Navigation Bar - Floating
            Positioned(
              bottom: screenHeight * 0.02,
              left: 0,
              right: 0,
              child: Center(
                child: BottomNavbar(
                  activeIndex: _currentNavIndex,
                  onItemSelected: (index) {
                    setState(() {
                      _currentNavIndex = index;
                    });
                    if (index == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerHomeScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
