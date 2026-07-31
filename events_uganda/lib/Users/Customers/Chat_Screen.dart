import 'package:flutter/material.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:events_uganda/Users/Customers/Customer_Profile_Screen.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';
import 'package:events_uganda/components/Bottom_Navbar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  int _currentNavIndex = 2;
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchFocused = false;
  static const List<String> _names = [
    'Aisha',
    'Brian',
    'Cathy',
    'David',
    'Emma',
    'Grace',
    'Hassan',
  ];
  static const List<Map<String, String>> _conversations = [
    {
      'name': 'Gregory',
      'message': 'You  Hey, mate please add me to the group...',
      'time': '10:32 AM',
    },
    {
      'name': 'Sarah',
      'message': 'You  Sounds good, see you there!',
      'time': 'Yesterday',
    },
    {
      'name': 'Brian',
      'message': 'You  Can we reschedule the meeting?',
      'time': 'Mon',
    },
    {'name': 'Aisha', 'message': 'You  Thanks for the invite', 'time': 'Sun'},
    {
      'name': 'David',
      'message': 'You  I\'ll send the photos soon',
      'time': '2:15 PM',
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocus.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
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
                      Icons.more_vert,
                      color: Colors.black,
                      size: screenWidth * 0.07,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.035,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Messages',
                  style: TextStyle(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.035,
              left: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: screenWidth * 0.128,
                  height: screenWidth * 0.128,
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
              top: screenHeight * 0.13,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: Container(
                height: screenWidth * 0.12,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isSearchFocused
                        ? const Color(0xFFCC471B)
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(2, 7),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.04),
                      child: Icon(
                        Icons.search,
                        color: Colors.black.withValues(alpha: 0.5),
                        size: screenWidth * 0.06,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: TextField(
                        focusNode: _searchFocus,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: screenWidth * 0.04,
                          fontFamily: 'Montserrat',
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for messages here...',
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.5),
                            fontSize: screenWidth * 0.035,
                            fontFamily: 'Montserrat',
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: screenWidth * 0.055,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                      ),
                      child: Icon(
                        Icons.mic,
                        color: Colors.black,
                        size: screenWidth * 0.055,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top:
                  screenHeight * 0.13 +
                  screenWidth * 0.12 +
                  screenHeight * 0.015,
              right: screenWidth * 0.04,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: screenWidth * 0.128,
                  height: screenWidth * 0.128,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8C2B0),
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
            ),
            Positioned(
              top: screenHeight * 0.16 + screenWidth * 0.248,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              child: SizedBox(
                height: screenWidth * 0.146 + screenHeight * 0.04,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(
                      7,
                      (index) => Container(
                        width: screenWidth * 0.2,
                        margin: EdgeInsets.only(right: screenWidth * 0.06),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: screenWidth * 0.146,
                              height: screenWidth * 0.146,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                      size: screenWidth * 0.07,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: screenWidth * 0.04,
                                      height: screenWidth * 0.04,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4CAF50),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            Text(
                              _names[index],
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.028,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenHeight * 0.215 + screenWidth * 0.394,
              left: screenWidth * 0.04,
              right: screenWidth * 0.04,
              bottom: screenHeight * 0.20,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final conv = _conversations[index];
                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: screenWidth * 0.13,
                            height: screenWidth * 0.13,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.08),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.black,
                                    size: screenWidth * 0.07,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: screenWidth * 0.036,
                                    height: screenWidth * 0.036,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  conv['name']!,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: screenWidth * 0.038,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.004),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        conv['message']!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.black.withValues(
                                            alpha: 0.55,
                                          ),
                                          fontSize: screenWidth * 0.03,
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.02),
                                    Text(
                                      conv['time']!,
                                      style: TextStyle(
                                        color: Colors.black.withValues(
                                          alpha: 0.4,
                                        ),
                                        fontSize: screenWidth * 0.026,
                                        fontFamily: 'Montserrat',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (index != _conversations.length - 1)
                        Divider(
                          color: Colors.black.withValues(alpha: 0.08),
                          height: screenHeight * 0.03,
                          thickness: 1,
                        ),
                    ],
                  );
                },
              ),
            ),
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerHomeScreen(),
                        ),
                      );
                    }
                    if (index == 3) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerProfileScreen(),
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
