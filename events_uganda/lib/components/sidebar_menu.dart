import 'dart:math' as math;
import 'package:flutter/material.dart';

class SidebarMenu {
    static void show(BuildContext context) {
        showGeneralDialog(
            context: context,
            barrierDismissible: true,
            barrierLabel: 'Sidebar',
            barrierColor: Colors.black.withValues(alpha: 0.35),
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (ctx, anim1, anim2) => const _SidebarPanel(),
            transitionBuilder: (ctx, anim, secondaryAnim, child) {
                return Stack(
                    children: [
                        GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: FadeTransition(
                                opacity: anim,
                                child: Container(color: Colors.transparent),
                            ),
                        ),
                        SlideTransition(
                            position: Tween<Offset>(
                                begin: const Offset(-1, 0),
                                end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic,
                                reverseCurve: Curves.easeInCubic,
                            )),
                            child: child,
                        ),
                    ],
                );
            },
        );
    }
}

class _SidebarPanel extends StatelessWidget {
    const _SidebarPanel();

    @override
    Widget build(BuildContext context) {
        final w = MediaQuery.of(context).size.width;
        final h = MediaQuery.of(context).size.height;
        final panelWidth = w * 0.78;

        return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
                padding: const EdgeInsets.only(left: 5, top: 5, bottom: 5),
                child: SizedBox(
                    width: panelWidth,
                    height: h - 10,
                    child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 30,
                                    offset: const Offset(5, 0),
                                ),
                            ],
                        ),
                        child: Column(
                            children: [
                                SizedBox(height: h * 0.025),
                                Center(
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                            Image.asset(
                                                'assets/vectors/logo.png',
                                                width: w * 0.08,
                                                height: w * 0.08,
                                                fit: BoxFit.contain,
                                            ),
                                            SizedBox(width: w * 0.02),
                                            Text(
                                                'Events Uganda',
                                                style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: w * 0.045,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFF1A1A2E),
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                                SizedBox(height: h * 0.025),
                                Padding(
                                    padding: EdgeInsets.only(left: w * 0.046),
                                    child: const _CartoonAvatar(),
                                ),
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}

class _CartoonAvatar extends StatefulWidget {
    const _CartoonAvatar();

    @override
    State<_CartoonAvatar> createState() => _CartoonAvatarState();
}

class _CartoonAvatarState extends State<_CartoonAvatar>
    with SingleTickerProviderStateMixin {
    late AnimationController _controller;

    @override
    void initState() {
        super.initState();
        _controller = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 2500),
        )..repeat(reverse: true);
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final w = MediaQuery.of(context).size.width;
        final size = w * 0.12;

        return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
                final breathe = _controller.value * 2.0 - 1.0;
                final scale = 1.0 + breathe * 0.015;

                return Transform.scale(
                    scale: scale,
                    child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF3CA9B),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFD4A050).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                ),
                            ],
                        ),
                        child: ClipOVal(
                            child: CustomPaint(
                                painter: _CartoonPersonPainter(),
                            ),
                        ),
                    ),
                );
            },
        );
    }
}

class _CartoonPersonPainter extends CustomPainter {
    @override
    void paint(Canvas canvas, Size size) {
        final cx = size.width / 2;
        final cy = size.height / 2;
        final r = size.width / 2;

        // Hair
        final hairPaint = Paint()..color = const Color(0xFF2C1810);
        canvas.drawArc(
            Rect.fromCircle(center: Offset(cx, cy - r * 0.15), radius: r * 0.75),
            math.pi,
            math.pi,
            false,
            hairPaint..style = PaintingStyle.fill,
        );
        canvas.drawCircle(Offset(cx, cy - r * 0.55), r * 0.45, hairPaint);

        // Head
        final skinPaint = Paint()..color = const Color(0xFFFAD5B5);
        canvas.drawCircle(Offset(cx, cy), r * 0.5, skinPaint);

        // Eyes - white
        final eyeWhite = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(cx - r * 0.18, cy - r * 0.08), r * 0.12, eyeWhite);
        canvas.drawCircle(Offset(cx + r * 0.18, cy - r * 0.08), r * 0.12, eyeWhite);

        // Pupils
        final pupil = Paint()..color = const Color(0xFF2C1810);
        canvas.drawCircle(Offset(cx - r * 0.16, cy - r * 0.06), r * 0.06, pupil);
        canvas.drawCircle(Offset(cx + r * 0.20, cy - r * 0.06), r * 0.06, pupil);

        // Eye shine
        final shine = Paint()..color = Colors.white;
        canvas.drawCircle(Offset(cx - r * 0.14, cy - r * 0.10), r * 0.025, shine);
        canvas.drawCircle(Offset(cx + r * 0.22, cy - r * 0.10), r * 0.025, shine);

        // Eyebrows
        final browPaint = Paint()
            ..color = const Color(0xFF2C1810)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.025
            ..strokeCap = StrokeCap.round;
        canvas.drawArc(
            Rect.fromCenter(center: Offset(cx - r * 0.18, cy - r * 0.20), width: r * 0.22, height: r * 0.08),
            math.pi * 1.1,
            math.pi * 0.8,
            false,
            browPaint,
        );
        canvas.drawArc(
            Rect.fromCenter(center: Offset(cx + r * 0.18, cy - r * 0.20), width: r * 0.22, height: r * 0.08),
            math.pi * 0.1,
            math.pi * 0.8,
            false,
            browPaint,
        );

        // Smile
        final smilePaint = Paint()
            ..color = const Color(0xFFD4785C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.035
            ..strokeCap = StrokeCap.round;
        canvas.drawArc(
            Rect.fromCenter(center: Offset(cx, cy + r * 0.15), width: r * 0.4, height: r * 0.22),
            0.15,
            math.pi - 0.3,
            false,
            smilePaint,
        );

        // Blush
        final blushPaint = Paint()..color = const Color(0xFFF5A0A0).withValues(alpha: 0.35);
        canvas.drawCircle(Offset(cx - r * 0.30, cy + r * 0.10), r * 0.08, blushPaint);
        canvas.drawCircle(Offset(cx + r * 0.30, cy + r * 0.10), r * 0.08, blushPaint);
    }

    @override
    bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
