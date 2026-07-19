import 'dart:math' as math;
import 'package:flutter/material.dart';

class ArchivedEmptyAnimation extends StatefulWidget {
  const ArchivedEmptyAnimation({super.key});

  @override
  State<ArchivedEmptyAnimation> createState() => _ArchivedEmptyAnimationState();
}

class _ArchivedEmptyAnimationState extends State<ArchivedEmptyAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _breathe;
  late final Animation<double> _lidAngle;
  late final Animation<double> _lidBounce;
  late final Animation<double> _sparkle1;
  late final Animation<double> _sparkle2;
  late final Animation<double> _sparkle3;
  late final Animation<double> _sparkle4;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _breathe = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _lidAngle = Tween<double>(begin: -0.04, end: 0.04).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOutSine),
      ),
    );

    _lidBounce = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack),
      ),
    );

    _sparkle1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _sparkle2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.65, curve: Curves.easeOut),
      ),
    );
    _sparkle3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.85, curve: Curves.easeOut),
      ),
    );
    _sparkle4 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
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
    final boxSize = screenWidth * 0.38;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: boxSize * 1.4,
          height: boxSize * 1.15,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _breathe.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _Sparkle(
                      anim: _sparkle1,
                      dx: -0.38,
                      dy: -0.3,
                      size: screenWidth * 0.035,
                      color: const Color(0xFFF3CA9B),
                    ),
                    _Sparkle(
                      anim: _sparkle2,
                      dx: 0.35,
                      dy: -0.35,
                      size: screenWidth * 0.028,
                      color: const Color(0xFFFFD700),
                    ),
                    _Sparkle(
                      anim: _sparkle3,
                      dx: -0.25,
                      dy: -0.45,
                      size: screenWidth * 0.022,
                      color: const Color(0xFFF4A261),
                    ),
                    _Sparkle(
                      anim: _sparkle4,
                      dx: 0.42,
                      dy: -0.25,
                      size: screenWidth * 0.03,
                      color: const Color(0xFFFFB347),
                    ),
                    CustomPaint(
                      size: Size(boxSize, boxSize * 0.95),
                      painter: _BoxBodyPainter(
                        lidAngle: _lidAngle.value,
                        lidBounce: _lidBounce.value,
                        breathe: _breathe.value,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: screenWidth * 0.08),
        Text(
          'No archived notifications',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w700,
            fontSize: screenWidth * 0.05,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: screenWidth * 0.02),
        Text(
          'Your archived notifications will\nrest peacefully here',
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
        final offsetY = -progress * 40;
        final scale = 0.5 + progress * 0.8;
        return Positioned(
          left: (1 + dx) / 2 * 100,
          top: (1 + dy) / 2 * 100,
          child: Transform.translate(
            offset: Offset(0, offsetY),
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

class _BoxBodyPainter extends CustomPainter {
  final double lidAngle;
  final double lidBounce;
  final double breathe;

  _BoxBodyPainter({
    required this.lidAngle,
    required this.lidBounce,
    required this.breathe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF8B6B4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final facePaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final blushPaint = Paint()
      ..color = const Color(0xFFE8AFAF).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final lidOffset = lidAngle * w * 0.15;
    final bounceOffset = (1 - lidBounce) * h * 0.03;

    canvas.save();

    final bodyRect = Rect.fromLTWH(w * 0.1, h * 0.35, w * 0.8, h * 0.58);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, const Radius.circular(12));

    canvas.drawRRect(bodyRRect, bodyPaint);
    canvas.drawRRect(bodyRRect, strokePaint);

    final highlightRect = Rect.fromLTWH(w * 0.15, h * 0.4, w * 0.2, h * 0.08);
    final highlightPaint = Paint()
      ..color = const Color(0xFFE8C9A0).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(6)),
      highlightPaint,
    );

    final tapePaint = Paint()
      ..color = const Color(0xFFE8C9A0).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(w * 0.28, h * 0.33, w * 0.08, h * 0.62), tapePaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.64, h * 0.33, w * 0.08, h * 0.62), tapePaint);

    canvas.save();
    canvas.translate(w * 0.5, h * 0.35 + bounceOffset);
    canvas.rotate(lidAngle * 0.3);

    final lidPath = Path()
      ..moveTo(-w * 0.42, 0)
      ..lineTo(-w * 0.35, -h * 0.2 + lidOffset)
      ..lineTo(w * 0.35, -h * 0.2 + lidOffset)
      ..lineTo(w * 0.42, 0)
      ..close();

    canvas.drawPath(lidPath, bodyPaint);
    canvas.drawPath(lidPath, strokePaint);

    final lidInnerPaint = Paint()
      ..color = const Color(0xFFB8845A)
      ..style = PaintingStyle.fill;
    final lidInnerPath = Path()
      ..moveTo(-w * 0.35, -h * 0.01)
      ..lineTo(-w * 0.30, -h * 0.15 + lidOffset * 0.7)
      ..lineTo(w * 0.30, -h * 0.15 + lidOffset * 0.7)
      ..lineTo(w * 0.35, -h * 0.01)
      ..close();
    canvas.drawPath(lidInnerPath, lidInnerPaint);

    final tabPaint = Paint()
      ..color = const Color(0xFFC49565)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, h * 0.3 + h * 0.12), width: w * 0.12, height: h * 0.06),
        const Radius.circular(4),
      ),
      tabPaint,
    );

    canvas.restore();

    final leftEyeCenter = Offset(w * 0.33, h * 0.55);
    final rightEyeCenter = Offset(w * 0.67, h * 0.55);

    canvas.drawCircle(leftEyeCenter, w * 0.04, facePaint);
    canvas.drawCircle(rightEyeCenter, w * 0.04, facePaint);

    final eyeInnerPaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(leftEyeCenter.dx + w * 0.008, leftEyeCenter.dy + w * 0.008),
      w * 0.02,
      eyeInnerPaint,
    );
    canvas.drawCircle(
      Offset(rightEyeCenter.dx + w * 0.008, rightEyeCenter.dy + w * 0.008),
      w * 0.02,
      eyeInnerPaint,
    );

    canvas.drawCircle(
      Offset(leftEyeCenter.dx - w * 0.005, leftEyeCenter.dy - w * 0.005),
      w * 0.007,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(rightEyeCenter.dx - w * 0.005, rightEyeCenter.dy - w * 0.005),
      w * 0.007,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      Offset(leftEyeCenter.dx + w * 0.1, leftEyeCenter.dy + w * 0.06),
      w * 0.045,
      blushPaint,
    );
    canvas.drawCircle(
      Offset(rightEyeCenter.dx - w * 0.1, rightEyeCenter.dy + w * 0.06),
      w * 0.045,
      blushPaint,
    );

    final mouthPath = Path()
      ..moveTo(w * 0.42, h * 0.63)
      ..quadraticBezierTo(w * 0.5, h * 0.65, w * 0.58, h * 0.63);

    final mouthPaint = Paint()
      ..color = const Color(0xFF3D2B1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(mouthPath, mouthPaint);

    final zzzPaint = Paint()
      ..color = const Color(0xFFF4A261).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final zzzPath1 = Path()
      ..moveTo(w * 0.78, h * 0.28)
      ..lineTo(w * 0.84, h * 0.26)
      ..lineTo(w * 0.78, h * 0.24);

    final zzzPath2 = Path()
      ..moveTo(w * 0.85, h * 0.22)
      ..lineTo(w * 0.92, h * 0.19)
      ..lineTo(w * 0.85, h * 0.17);

    canvas.drawPath(zzzPath1, zzzPaint);
    canvas.drawPath(zzzPath2, zzzPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoxBodyPainter oldDelegate) {
    return oldDelegate.lidAngle != lidAngle ||
        oldDelegate.lidBounce != lidBounce ||
        oldDelegate.breathe != breathe;
  }
}
