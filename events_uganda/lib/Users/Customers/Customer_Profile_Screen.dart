import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:flutter/material.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 3;
  String _userFullName = '';
  String _userEmail = '';
  String? _profilePicUrl;

  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Fetch user's display name if available
    final user = FirebaseAuth.instance.currentUser;
    _userFullName = user?.displayName ?? 'User';
    _userEmail = user?.email ?? '';
    _profilePicUrl = user?.photoURL;
  }

  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _isUploading = true;
    });
    try {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_pics/${user.uid}.jpg',
      );
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();
      // Update Firestore user document (assuming users collection)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'photoURL': downloadUrl},
      );
      // Update Firebase Auth profile
      await user.updatePhotoURL(downloadUrl);
      setState(() {
        _profilePicUrl = downloadUrl;
      });
    } catch (e) {
      // Optionally show error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image.')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
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
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      color: Colors.black,
                      size: screenWidth * 0.18,
                    ),
                    if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                      ClipOval(
                        child: Image.network(
                          _profilePicUrl!,
                          width: screenWidth * 0.3,
                          height: screenWidth * 0.3,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return SizedBox.shrink();
                          },
                        ),
                      ),
                    // Upload icon square at bottom right
                    Positioned(
                      bottom: screenWidth * 0.02,
                      right: screenWidth * 0.13,
                      child: GestureDetector(
                        onTap: _isUploading ? null : _pickAndUploadImage,
                        child: Container(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          decoration: BoxDecoration(
                            color: Color(0xFFFFC107),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Center(
                            child: _isUploading
                                ? SizedBox(
                                    width: screenWidth * 0.045,
                                    height: screenWidth * 0.045,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
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
              child: Container(
                width: screenWidth * 0.128,
                height: screenWidth * 0.128,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Account Overview",
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              fontSize: screen.width * 0.045,
                            ),
                          ),
                        ),
                        SizedBox(height: screen.height * 0.015),
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        (45 / 375),
                                    height:
                                        MediaQuery.of(context).size.width *
                                        (45 / 375),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFCAE8FA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF027AC1),
                                        size:
                                            MediaQuery.of(context).size.width *
                                            (28 / 375),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.06,
                                  ),
                                  Expanded(
                                    child: Text(
                                      'My Profile',
                                      style: TextStyle(
                                        fontFamily: 'Abril Fatface',
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                        fontSize:
                                            MediaQuery.of(context).size.width *
                                            0.045,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.black,
                                    size:
                                        MediaQuery.of(context).size.width *
                                        0.06,
                                  ),
                                ],
                              ),
                              SizedBox(height: screen.height * 0.01),
                              Padding(
                                padding: EdgeInsets.only(
                                  left:
                                      screen.width * (45 / 375) +
                                      screen.width * 0.06,
                                  right: screen.width * 0.02,
                                ),
                                child: Divider(
                                  color: Colors.black.withOpacity(0.6),
                                  thickness: 1,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screen.height * 0.03),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                height:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFFE0B2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Color(0xFFF19124),
                                    size:
                                        MediaQuery.of(context).size.width *
                                        (28 / 375),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.06,
                              ),
                              Expanded(
                                child: Text(
                                  'My Orders',
                                  style: TextStyle(
                                    fontFamily: 'Abril Fatface',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.045,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.black,
                                size: MediaQuery.of(context).size.width * 0.06,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screen.height * 0.01),
                        Padding(
                          padding: EdgeInsets.only(
                            left:
                                screen.width * (45 / 375) + screen.width * 0.06,
                            right: screen.width * 0.02,
                          ),
                          child: Divider(
                            color: Colors.black.withOpacity(0.6),
                            thickness: 1,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: screen.height * 0.03),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                height:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 247, 160, 131),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.attach_money,
                                    color: Color.fromARGB(255, 226, 75, 25),
                                    size:
                                        MediaQuery.of(context).size.width *
                                        (28 / 375),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.06,
                              ),
                              Expanded(
                                child: Text(
                                  'Refund',
                                  style: TextStyle(
                                    fontFamily: 'Abril Fatface',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.045,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.black,
                                size: MediaQuery.of(context).size.width * 0.06,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screen.height * 0.01),
                              Padding(
                                padding: EdgeInsets.only(
                                  left:
                                      screen.width * (45 / 375) +
                                      screen.width * 0.06,
                                  right: screen.width * 0.02,
                                ),
                                child: Divider(
                                  color: Colors.black.withOpacity(0.6),
                                  thickness: 1,
                                  height: 1,
                                ),
                              ),
                        SizedBox(height: screen.height * 0.03),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                height:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                decoration: BoxDecoration(
                                  color: Color(0XFF98EE81),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.password_rounded,
                                    color: Color.fromARGB(255, 35, 142, 5),
                                    size:
                                        MediaQuery.of(context).size.width *
                                        (28 / 375),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.06,
                              ),
                              Expanded(
                                child: Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontFamily: 'Abril Fatface',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.045,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.black,
                                size: MediaQuery.of(context).size.width * 0.06,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screen.height * 0.03),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                height:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                decoration: BoxDecoration(
                                  color: Color(0XFFC491E2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.payment_outlined,
                                    color: Color.fromARGB(255, 95, 5, 147),
                                    size:
                                        MediaQuery.of(context).size.width *
                                        (28 / 375),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.06,
                              ),
                              Expanded(
                                child: Text(
                                  'Payment Methods',
                                  style: TextStyle(
                                    fontFamily: 'Abril Fatface',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.045,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.black,
                                size: MediaQuery.of(context).size.width * 0.06,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screen.height * 0.03),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                height:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                decoration: BoxDecoration(
                                  color: Color(0XFFF3D8C4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.help_outline_rounded,
                                    color: Color.fromARGB(255, 215, 96, 5),
                                    size:
                                        MediaQuery.of(context).size.width *
                                        (28 / 375),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.06,
                              ),
                              Expanded(
                                child: Text(
                                  'Help & Support',
                                  style: TextStyle(
                                    fontFamily: 'Abril Fatface',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.045,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.black,
                                size: MediaQuery.of(context).size.width * 0.06,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screen.height * 0.03),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                width:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                height:
                                    MediaQuery.of(context).size.width *
                                    (45 / 375),
                                decoration: BoxDecoration(
                                  color: Color(0XFF89E0C4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.logout_rounded,
                                    color: Color.fromARGB(255, 0, 148, 101),
                                    size:
                                        MediaQuery.of(context).size.width *
                                        (28 / 375),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.06,
                              ),
                              Expanded(
                                child: Text(
                                  'Logout Option',
                                  style: TextStyle(
                                    fontFamily: 'Abril Fatface',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                        0.045,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.black,
                                size: MediaQuery.of(context).size.width * 0.06,
                              ),
                            ],
                          ),
                        ),
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
