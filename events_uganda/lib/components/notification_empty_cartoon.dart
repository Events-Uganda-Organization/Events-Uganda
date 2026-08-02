import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Hand-drawn animated cartoon: a sleepy notification-bell mascot.
class NotificationEmptyCartoon extends StatefulWidget {
  const NotificationEmptyCartoon({super.key});

  @override
  State<NotificationEmptyCartoon> createState() =>
      _NotificationEmptyCartoonState();
}

class _NotificationEmptyCartoonState extends State<NotificationEmptyCartoon>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _swing;
  late final Animation<double> _breathe;
  late final Animation<double> _zzz1;
  late final Animation<double> _zzz2;
  late final Animation<double> _zzz3;
  late final Animation<double> _sparkle1;
  late final Animation<double> _sparkle2;
  late final Animation<double> _sparkle3;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _swing = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _breathe = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.5, curve: Curves.easeInOutSine),
      ),
    );

    _zzz1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4, curve: Curves.easeOut)),
    );
    _zzz2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)),
    );
    _zzz3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)),
    );

    _sparkle1 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.55, curve: Curves.easeOut)),
    );
    _sparkle2 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.8, curve: Curves.easeOut)),
    );
    _sparkle3 = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
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
    final size = screenWidth * 0.42;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size * 1.5,
          height: size * 1.3,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _swing.value,
                child: Transform.scale(
                  scale: _breathe.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _Sparkle(
                        anim: _sparkle1,
                        dx: -0.4,
                        dy: -0.28,
                        size: screenWidth * 0.03,
                        color: const Color(0xFFF3CA9B),
                      ),
                      _Sparkle(
                        anim: _sparkle2,
                        dx: 0.36,
                        dy: -0.34,
                        size: screenWidth * 0.026,
                        color: const Color(0xFFFFD700),
                      ),
                      _Sparkle(
                        anim: _sparkle3,
                        dx: 0.02,
                        dy: -0.42,
                        size: screenWidth * 0.022,
                        color: const Color(0xFFF4A261),
                      ),
                      _FloatingZ(
                        anim: _zzz1,
                        dx: 0.3,
                        dy: -0.48,
                        size: screenWidth * 0.045,
                      ),
                      _FloatingZ(
                        anim: _zzz2,
                        dx: 0.38,
                        dy: -0.36,
                        size: screenWidth * 0.055,
                      ),
                      _FloatingZ(
                        anim: _zzz3,
                        dx: 0.46,
                        dy: -0.24,
                        size: screenWidth * 0.065,
                      ),
                      CustomPaint(
                        size: Size(size, size * 1.02),
                        painter: _BellPainter(breathe: _breathe.value),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: screenWidth * 0.07),
        Text(
          'No notifications yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: screenWidth * 0.05,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          'You\'re all caught up!\nWhen you get notifications, they\'ll show up here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: screenWidth * 0.035,
            color: Colors.black45,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Sparkle extends StatelessWidget {
  final Animation<double> anim;
  final double dx;
  final double dy;
  final double size;
  final Color color;

  const _Sparkle({
    required this.anim,
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final progress = anim.value;
        final opacity = (1 - progress).clamp(0.0, 1.0);
        final scale = 0.5 + progress * 0.8;
        return Positioned(
          left: (1 + dx) / 2 * 100,
          top: (1 + dy) / 2 * 100,
          child: Transform.translate(
            offset: Offset(0, -progress * 36),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _StarPainter(color: color),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  _StarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2;
    const spikes = 4;
    final outerR = r;
    final innerR = r * 0.4;

    final path = Path();
    for (int i = 0; i < spikes * 2; i++) {
      final angle = -math.pi / 2 + (math.pi * i) / spikes;
      final radius = i.isEven ? outerR : innerR;
      final x = cx + radius * math.cos(angle);
      final y = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FloatingZ extends StatelessWidget {
  final Animation<double> anim;
  final double dx;
  final double dy;
  final double size;

  const _FloatingZ({
    required this.anim,
    required this.dx,
    required this.dy,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        final progress = anim.value;
        final opacity = (1 - progress).clamp(0.0, 1.0);
        return Positioned(
          left: (1 + dx) / 2 * 100,
          top: (1 + dy) / 2 * 100,
          child: Transform.translate(
            offset: Offset(0, -progress * size * 1.6),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: 0.7 + progress * 0.5,
                child: Text(
                  'Z',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: size,
                    color: const Color(0xFFF4A261),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BellPainter extends CustomPainter {
  final double breathe;

  _BellPainter({required this.breathe});

  static const Color _body = Color(0xFFF3CA9B);
  static const Color _stroke = Color(0xFFCB471B);
  static const Color _dark = Color(0xFF7A4A2A);
  static const Color _accent = Color(0xFFE8A75A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = _body..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = _stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final facePaint = Paint()
      ..color = _dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final blushPaint = Paint()
      ..color = const Color(0xFFE8AFAF).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    final accentPaint = Paint()
      ..color = _accent
      ..style = PaintingStyle.fill;

    // Top knob
    canvas.drawCircle(Offset(w * 0.5, h * 0.07), w * 0.045, accentPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.07), w * 0.045, strokePaint);

    // Bell body
    final bodyPath = Path()
      ..moveTo(w * 0.2, h * 0.6)
      ..lineTo(w * 0.2, h * 0.38)
      ..quadraticBezierTo(w * 0.2, h * 0.1, w * 0.5, h * 0.1)
      ..quadraticBezierTo(w * 0.8, h * 0.1, w * 0.8, h * 0.38)
      ..lineTo(w * 0.8, h * 0.6)
      ..quadraticBezierTo(w * 0.8, h * 0.68, w * 0.7, h * 0.66)
      ..lineTo(w * 0.3, h * 0.66)
      ..quadraticBezierTo(w * 0.2, h * 0.68, w * 0.2, h * 0.6)
      ..close();

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // Body highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    final highlightPath = Path()
      ..moveTo(w * 0.29, h * 0.2)
      ..quadraticBezierTo(w * 0.31, h * 0.13, w * 0.38, h * 0.13)
      ..quadraticBezierTo(w * 0.33, h * 0.17, w * 0.33, h * 0.24)
      ..close();
    canvas.drawPath(highlightPath, highlightPaint);

    // Clapper
    canvas.drawCircle(Offset(w * 0.5, h * 0.74), w * 0.07, accentPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.74), w * 0.07, strokePaint);

    // Sleepy closed eyes
    final leftEye = Offset(w * 0.36, h * 0.4);
    final rightEye = Offset(w * 0.64, h * 0.4);
    final eyeR = w * 0.055;

    final leftEyePath = Path()
      ..moveTo(leftEye.dx - eyeR, leftEye.dy)
      ..quadraticBezierTo(leftEye.dx, leftEye.dy + eyeR * 0.8, leftEye.dx + eyeR, leftEye.dy);
    final rightEyePath = Path()
      ..moveTo(rightEye.dx - eyeR, rightEye.dy)
      ..quadraticBezierTo(rightEye.dx, rightEye.dy + eyeR * 0.8, rightEye.dx + eyeR, rightEye.dy);

    canvas.drawPath(leftEyePath, facePaint);
    canvas.drawPath(rightEyePath, facePaint);

    // Eyelashes
    final lashPaint = Paint()
      ..color = _dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(leftEye.dx - eyeR * 0.9, leftEye.dy - eyeR * 0.25),
      Offset(leftEye.dx - eyeR * 0.6, leftEye.dy - eyeR * 0.6),
      lashPaint,
    );
    canvas.drawLine(
      Offset(rightEye.dx + eyeR * 0.9, rightEye.dy - eyeR * 0.25),
      Offset(rightEye.dx + eyeR * 0.6, rightEye.dy - eyeR * 0.6),
      lashPaint,
    );

    // Blush
    canvas.drawCircle(Offset(w * 0.27, h * 0.49), w * 0.045, blushPaint);
    canvas.drawCircle(Offset(w * 0.73, h * 0.49), w * 0.045, blushPaint);

    // Little smile
    final mouthPath = Path()
      ..moveTo(w * 0.45, h * 0.5)
      ..quadraticBezierTo(w * 0.5, h * 0.54, w * 0.55, h * 0.5);
    canvas.drawPath(mouthPath, facePaint);
  }

  @override
  bool shouldRepaint(covariant _BellPainter oldDelegate) {
    return oldDelegate.breathe != breathe;
  }
}
