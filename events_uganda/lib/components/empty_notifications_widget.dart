import 'package:flutter/material.dart';

class EmptyNotificationsWidget extends StatefulWidget {
  const EmptyNotificationsWidget({super.key});

  @override
  State<EmptyNotificationsWidget> createState() => _EmptyNotificationsWidgetState();
}

class _EmptyNotificationsWidgetState extends State<EmptyNotificationsWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bellSwing;
  late final Animation<double> _breathe;
  late final Animation<double> _zzz1;
  late final Animation<double> _zzz2;
  late final Animation<double> _zzz3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _bellSwing = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _breathe = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.5, curve: Curves.easeInOutSine)),
    );

    _zzz1 = Tween<double>(begin: 0, end: -1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4, curve: Curves.easeOut)),
    );
    _zzz2 = Tween<double>(begin: 0, end: -1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );
    _zzz3 = Tween<double>(begin: 0, end: -1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: screenWidth * 0.4,
              height: screenWidth * 0.4,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _bellSwing.value,
                    child: Transform.scale(
                      scale: _breathe.value,
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.35,
                      height: screenWidth * 0.35,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCC471B).withValues(alpha: 0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.notifications_off_outlined,
                        size: screenWidth * 0.14,
                        color: const Color(0xFFCC471B),
                      ),
                    ),
                    _buildZzz(screenWidth, _zzz1, 0.35, -0.38),
                    _buildZzz(screenWidth, _zzz2, 0.42, -0.30),
                    _buildZzz(screenWidth, _zzz3, 0.48, -0.22),
                    Positioned(
                      top: screenWidth * -0.02,
                      right: screenWidth * 0.02,
                      child: Icon(
                        Icons.nightlight_round,
                        size: screenWidth * 0.05,
                        color: const Color(0xFFF4A261),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenWidth * 0.08),
            Text(
              'No notifications yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
                fontSize: screenWidth * 0.055,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              'You\'re all caught up!\nWhen you get notifications, they\'ll show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w400,
                fontSize: screenWidth * 0.035,
                color: Colors.black45,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZzz(double screenWidth, Animation<double> anim, double dx, double dy) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        return Positioned(
          right: screenWidth * (dx + anim.value * 0.06),
          top: screenWidth * (dy + anim.value * 0.08),
          child: Opacity(
            opacity: (1 + anim.value).clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, anim.value * screenWidth * 0.06),
              child: Text(
                'Z',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: screenWidth * (0.035 + anim.value.abs() * 0.01),
                  color: const Color(0xFFF4A261).withValues(alpha: (1 + anim.value).clamp(0, 1)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
