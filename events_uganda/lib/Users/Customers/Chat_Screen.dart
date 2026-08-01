import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:events_uganda/Users/Customers/Customer_Home_Screen.dart';
import 'package:events_uganda/Users/Customers/Customer_Profile_Screen.dart';
import 'package:events_uganda/Users/Customers/Empty_State_Art.dart';
import 'package:events_uganda/Users/NotificationScreen.dart';
import 'package:events_uganda/Users/Customers/Message_Screen.dart';
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
  static const List<Color> _circleColors = [
    Color(0xFF7EED27),
    Color(0xFFFF6B6B),
    Color(0xFF4D96FF),
    Color(0xFFFFA94D),
    Color(0xFFB197FC),
    Color(0xFF63E6BE),
    Color(0xFFF783AC),
  ];

  static Color _colorFor(String name) {
    const colors = {'Gregory': Color(0xFF20C997), 'Sarah': Color(0xFFFFD43B)};
    final index = _names.indexOf(name);
    if (index != -1) return _circleColors[index];
    return colors[name] ?? const Color(0xFF7EED27);
  }

  final List<Map<String, String>> _conversations = [];

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
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search for messages here...',
                          hintStyle: TextStyle(
                            color: Colors.black.withValues(alpha: 0.5),
                            fontSize: screenWidth * 0.035,
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
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessageScreen(
                                      name: _names[index],
                                      color: _circleColors[index],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: screenWidth * 0.146,
                                height: screenWidth * 0.146,
                                decoration: BoxDecoration(
                                  color: _circleColors[index],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Center(
                                      child: Text(
                                        _names[index][0],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.06,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                            ),
                            SizedBox(height: screenHeight * 0.006),
                            Text(
                              _names[index],
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: screenWidth * 0.028,
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
              bottom:
                  screenHeight * 0.02 +
                  screenWidth * 0.168 +
                  screenHeight * 0.01,
              child: _conversations.isEmpty
                  ? _ChatEmptyState(
                      screenWidth: screenWidth,
                      screenHeight: screenHeight,
                      onBrowseServices: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerHomeScreen(),
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                  final conv = _conversations[index];
                  return Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageScreen(
                                name: conv['name'],
                                color: _colorFor(conv['name']!),
                                status: conv['status'],
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: screenWidth * 0.13,
                              height: screenWidth * 0.13,
                              decoration: BoxDecoration(
                                color: _colorFor(conv['name']!),
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
                                    child: Text(
                                      conv['name']![0],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.055,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

class _ChatEmptyState extends StatefulWidget {
  const _ChatEmptyState({
    required this.screenWidth,
    required this.screenHeight,
    required this.onBrowseServices,
  });

  final double screenWidth;
  final double screenHeight;
  final VoidCallback onBrowseServices;

  @override
  State<_ChatEmptyState> createState() => _ChatEmptyStateState();
}

class _ChatEmptyStateState extends State<_ChatEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sw = widget.screenWidth;
    final double sh = widget.screenHeight;
    final Animation<double> fadeIn = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    return Center(
      child: FadeTransition(
        opacity: fadeIn,
        child: Transform.translate(
          offset: Offset(0, sw * 0.02 * (1 - fadeIn.value)),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.06),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ChatEmptyScene(
                  sw: sw,
                  controller: _controller,
                  entrance: _entrance,
                ),
            SizedBox(height: sh * 0.015),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: Colors.black,
                fontSize: sw * 0.05,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: sh * 0.008),
            Text(
              'Tap the yellow Message button on a service\u2019s details page '
              'to start a chat with a vendor.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black.withValues(alpha: 0.55),
                fontSize: sw * 0.032,
              ),
            ),
            SizedBox(height: sh * 0.018),
            GestureDetector(
              onTap: widget.onBrowseServices,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.05,
                  vertical: sw * 0.028,
                ),
                decoration: BoxDecoration(
                  color: kEmptyAccent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: kEmptyAccent.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      color: Colors.white,
                      size: sw * 0.045,
                    ),
                    SizedBox(width: sw * 0.02),
                    Text(
                      'Browse services',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: sw * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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

class _ChatEmptyScene extends StatelessWidget {
  const _ChatEmptyScene({
    required this.sw,
    required this.controller,
    required this.entrance,
  });

  final double sw;
  final Animation<double> controller;
  final Animation<double> entrance;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: sw * 0.64,
      height: sw * 0.62,
      child: AnimatedBuilder(
        animation: Listenable.merge([controller, entrance]),
        builder: (context, _) {
          final double t = controller.value;
          final double et = entrance.value;
          final double bob = math.sin(t * math.pi * 2) * sw * 0.011 +
              math.sin(t * math.pi * 4) * sw * 0.004;
          final bool blinking = (t > 0.42 && t < 0.5) || (t > 0.9 && t < 0.98);
          final double tilt = math.sin(t * math.pi * 2 * 0.5) * 0.035;

          final double charScale =
              Curves.elasticOut.transform(Interval(0.02, 0.7).transform(et));
          final double phoneScale =
              Curves.easeOutBack.transform(Interval(0.22, 0.82).transform(et));
          final double phoneFade = Interval(0.22, 0.5).transform(et);
          final double dotsFade = Interval(0.4, 0.65).transform(et);
          final double fingerScale =
              Curves.elasticOut.transform(Interval(0.55, 0.95).transform(et));
          final double fingerFade = Interval(0.55, 0.75).transform(et);
          final double glow =
              (0.6 + 0.4 * math.sin(t * math.pi * 2)) * Interval(0, 0.4).transform(et);

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: glow,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          kEmptyYellow.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.1,
                size: sw * 0.035,
                left: sw * 0.015,
                top: sw * 0.015,
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.45,
                size: sw * 0.045,
                left: sw * 0.56,
                top: sw * 0.04,
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.7,
                size: sw * 0.028,
                left: sw * 0.02,
                top: sw * 0.47,
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.3,
                size: sw * 0.038,
                left: sw * 0.57,
                top: sw * 0.42,
              ),
              _TwinkleStar(
                sw: sw,
                t: t,
                phase: 0.85,
                size: sw * 0.04,
                left: sw * 0.28,
                top: 0,
              ),
              Positioned(
                left: 0,
                top: sw * 0.02 + bob,
                child: Opacity(
                  opacity: dotsFade,
                  child: TypingDotsBubble(sw: sw, t: t, phase: 0.2),
                ),
              ),
              Positioned(
                right: sw * 0.02,
                top: sw * 0.18 - bob,
                child: Opacity(
                  opacity: dotsFade,
                  child: TypingDotsBubble(sw: sw, t: t, phase: 0.7),
                ),
              ),
              Transform.scale(
                scale: charScale,
                child: Transform.translate(
                  offset: Offset(0, bob + (1 - charScale) * sw * 0.03),
                  child: Transform.rotate(
                    angle: tilt,
                    child: ChatCharacterBubble(
                      sw: sw,
                      blinking: blinking,
                      lookDown: true,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                child: Opacity(
                  opacity: phoneFade,
                  child: Transform.translate(
                    offset: Offset(0, (1 - phoneScale) * sw * 0.06),
                    child: Transform.scale(
                      scale: phoneScale,
                      child: Transform.translate(
                        offset: Offset(0, -bob * 0.5),
                        child: _PhoneCard(sw: sw, pulse: t),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: sw * 0.08,
                right: 0,
                child: Opacity(
                  opacity: fingerFade,
                  child: Transform.scale(
                    scale: fingerScale,
                    child: _PointingFinger(sw: sw, t: t),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TwinkleStar extends StatelessWidget {
  const _TwinkleStar({
    required this.sw,
    required this.t,
    required this.phase,
    required this.size,
    required this.left,
    required this.top,
  });

  final double sw;
  final double t;
  final double phase;
  final double size;
  final double left;
  final double top;

  @override
  Widget build(BuildContext context) {
    final double float = math.sin((t + phase) * math.pi * 2) * sw * 0.01;
    final double twinkle =
        0.3 + 0.7 * (0.5 + 0.5 * math.sin((t * 2 + phase) * math.pi * 2));
    return Positioned(
      left: left,
      top: top + float,
      child: Opacity(
        opacity: twinkle,
        child: Transform.rotate(
          angle: (t + phase) * math.pi * 0.5,
          child: CustomPaint(
            size: Size(size, size),
            painter: StarPainter(color: const Color(0xFFF6B93B)),
          ),
        ),
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.sw, required this.pulse});

  final double sw;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final double ripple = 0.06 * sw + 0.09 * sw * pulse;
    return Container(
      width: sw * 0.22,
      height: sw * 0.36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.08),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: sw * 0.03),
          Container(
            width: sw * 0.08,
            height: sw * 0.012,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: sw * 0.02),
          Container(
            margin: EdgeInsets.symmetric(horizontal: sw * 0.03),
            height: sw * 0.03,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: sw * 0.008),
          Container(
            margin: EdgeInsets.symmetric(horizontal: sw * 0.05),
            height: sw * 0.022,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(height: sw * 0.02),
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: ripple,
                height: ripple,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kEmptyYellow.withValues(alpha: 1 - pulse),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: sw * 0.16,
                height: sw * 0.05,
                decoration: BoxDecoration(
                  color: kEmptyYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message,
                      color: kEmptyYellowText,
                      size: sw * 0.026,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Message',
                      style: TextStyle(
                        color: kEmptyYellowText,
                        fontWeight: FontWeight.bold,
                        fontSize: sw * 0.023,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PointingFinger extends StatelessWidget {
  const _PointingFinger({required this.sw, required this.t});

  final double sw;
  final double t;

  @override
  Widget build(BuildContext context) {
    final double press = math.sin(t * math.pi * 2);
    final double dy = press * sw * 0.02;
    final Color skin = kEmptyCream;
    final Color outline = Colors.black.withValues(alpha: 0.15);
    return Transform.translate(
      offset: Offset(0, dy),
      child: Transform.rotate(
        angle: -0.62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: sw * 0.05,
              height: sw * 0.05,
              decoration: BoxDecoration(
                color: skin,
                shape: BoxShape.circle,
                border: Border.all(color: outline, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            Container(
              width: sw * 0.045,
              height: sw * 0.1,
              decoration: BoxDecoration(
                color: skin,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: outline, width: 2),
              ),
            ),
            Container(
              width: sw * 0.09,
              height: sw * 0.08,
              decoration: BoxDecoration(
                color: skin,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: outline, width: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
