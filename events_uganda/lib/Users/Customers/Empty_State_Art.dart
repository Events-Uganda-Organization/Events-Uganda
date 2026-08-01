import 'dart:math' as math;

import 'package:flutter/material.dart';

const Color kEmptyAccent = Color(0xFFCD7C20);
const Color kEmptyYellow = Color(0xFFFFC107);
const Color kEmptyYellowText = Color(0xFF5A5A00);
const Color kEmptyCream = Color(0xFFFFE0B2);

class CartoonEye extends StatelessWidget {
  const CartoonEye({
    super.key,
    required this.sw,
    required this.blinking,
    this.lookDown = false,
  });

  final double sw;
  final bool blinking;
  final bool lookDown;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      width: sw * 0.09,
      height: sw * (blinking ? 0.016 : 0.09),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      alignment: Alignment(0, lookDown ? 0.7 : 0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: sw * 0.035,
        height: sw * (blinking ? 0.012 : 0.035),
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class SmilePainter extends CustomPainter {
  const SmilePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;
    final Rect rect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.2,
      size.width * 0.8,
      size.height,
    );
    canvas.drawArc(rect, 0.15 * math.pi, 0.7 * math.pi, false, paint);
  }

  @override
  bool shouldRepaint(SmilePainter oldDelegate) =>
      oldDelegate.color != color;
}

class ChatCharacterBubble extends StatelessWidget {
  const ChatCharacterBubble({
    super.key,
    required this.sw,
    required this.blinking,
    this.lookDown = false,
    this.widthFactor = 0.46,
    this.heightFactor = 0.4,
  });

  final double sw;
  final bool blinking;
  final bool lookDown;
  final double widthFactor;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final Color outline = Colors.black.withValues(alpha: 0.08);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: -sw * 0.018,
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: sw * 0.1,
              height: sw * 0.1,
              decoration: BoxDecoration(
                color: kEmptyCream,
                borderRadius: BorderRadius.circular(sw * 0.02),
              ),
            ),
          ),
        ),
        Container(
          width: sw * widthFactor,
          height: sw * heightFactor,
          decoration: BoxDecoration(
            color: kEmptyCream,
            borderRadius: BorderRadius.circular(sw * 0.13),
            border: Border.all(color: outline, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CartoonEye(sw: sw, blinking: blinking, lookDown: lookDown),
                  SizedBox(width: sw * 0.045),
                  CartoonEye(sw: sw, blinking: blinking, lookDown: lookDown),
                ],
              ),
              SizedBox(height: sw * 0.025),
              CustomPaint(
                size: Size(sw * 0.16, sw * 0.07),
                painter: const SmilePainter(color: Colors.black),
              ),
              SizedBox(height: sw * 0.012),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: sw * 0.045,
                    height: sw * 0.022,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB3C1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  SizedBox(width: sw * 0.02),
                  Container(
                    width: sw * 0.045,
                    height: sw * 0.022,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB3C1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TypingDotsBubble extends StatelessWidget {
  const TypingDotsBubble({
    super.key,
    required this.sw,
    required this.t,
    this.phase = 0,
  });

  final double sw;
  final double t;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sw * 0.022,
        vertical: sw * 0.024,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final double cycle = (t + phase + i * 0.15) % 1.0;
          final double scale = 0.55 + 0.45 * math.sin(cycle * math.pi * 2);
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.009),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: sw * 0.02,
                height: sw * 0.02,
                decoration: const BoxDecoration(
                  color: kEmptyAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class StarPainter extends CustomPainter {
  const StarPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double rOuter = size.width * 0.5;
    final double rInner = size.width * 0.18;
    final Path path = Path();
    for (int i = 0; i < 8; i++) {
      final double angle = i * math.pi / 4 - math.pi / 2;
      final double r = i.isEven ? rOuter : rInner;
      final double x = cx + math.cos(angle) * r;
      final double y = cy + math.sin(angle) * r;
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
  bool shouldRepaint(StarPainter oldDelegate) => oldDelegate.color != color;
}
