import 'package:flutter/material.dart';

/// Responsive bottom navigation bar with a lifted active icon and circular depression effect.
class BottomNavbar extends StatelessWidget {
  const BottomNavbar({
    super.key,
    this.activeIndex = 0,
    required this.onItemSelected,
  });

  /// Zero-based index of the active tab.
  final int activeIndex;

  /// Callback when a tab is tapped.
  final ValueChanged<int> onItemSelected;

  static const _items = <IconData>[
    Icons.home,
    Icons.calendar_month,
    Icons.message,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final barHeight = width * 0.16;
    final iconSize = width * 0.07;
    final activeLift =
        barHeight * 0.05; // Adjust this multiplier: lower = closer to bar
    final activeCircleSize = width * 0.16;
    final indicatorSize = width * 0.02;

    return SizedBox(
      height: barHeight + activeLift,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Bar background with cutout
          CustomPaint(
            size: Size(
              width - width * 0.18,
              barHeight,
            ), // Reduce width: increase the multiplier
            painter: _NavBarPainter(
              barColor: const Color(0xFF7EED27),
              activeIndex: activeIndex,
              itemCount: _items.length,
              cutoutRadius: activeCircleSize / 2 + width * 0.02,
            ),
          ),

          // Icons row
          Positioned(
            bottom: 0,
            left: width * 0.04,
            right: width * 0.04,
            height: barHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_items.length, (index) {
                final isActive = index == activeIndex;
                final itemWidth = index == 3
                    ? width * 0.20
                    : width * 0.18; // Customize width per icon
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onItemSelected(index),
                  child: SizedBox(
                    width: itemWidth,
                    height: barHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (isActive)
                          Transform.translate(
                            offset: Offset(
                              index == 3
                                  ? width * 0.03
                                  : index == 2
                                  ? width *
                                        0.02 // Move right for chat icon
                                  : -width * 0.01,
                              -(activeLift + activeCircleSize / 2),
                            ),
                            child: Container(
                              width: activeCircleSize,
                              height: activeCircleSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF7EED27),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _items[index],
                                color: const Color(0xFF1BCC94),
                                size: iconSize,
                              ),
                            ),
                          )
                        else
                          Icon(
                            _items[index],
                            color: Colors.black,
                            size: iconSize,
                          ),
                        // White dot indicator below active icon
                        if (isActive)
                          Positioned(
                            bottom: barHeight * 0.19,
                            child: Container(
                              width: indicatorSize,
                              height: indicatorSize,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBarPainter extends CustomPainter {
  final Color barColor;
  final int activeIndex;
  final int itemCount;
  final double cutoutRadius;

  _NavBarPainter({
    required this.barColor,
    required this.activeIndex,
    required this.itemCount,
    required this.cutoutRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final path = Path();
    final itemWidth = size.width / itemCount;
    final activeCenter = (activeIndex + 0.5) * itemWidth;

    // Draw shadow
    canvas.drawPath(
      _createBarPath(size, activeCenter, cutoutRadius),
      shadowPaint,
    );

    // Draw bar
    canvas.drawPath(_createBarPath(size, activeCenter, cutoutRadius), paint);
  }

  Path _createBarPath(Size size, double activeCenter, double radius) {
    final path = Path();
    const borderRadius = 30.0;

    path.moveTo(borderRadius, 0);

    // Top edge with cutout
    if (activeCenter - radius > borderRadius) {
      path.lineTo(activeCenter - radius, 0);
    }

    // Cutout arc
    path.arcToPoint(
      Offset(activeCenter + radius, 0),
      radius: Radius.circular(radius),
      clockwise: false,
    );

    // Continue top edge
    if (activeCenter + radius < size.width - borderRadius) {
      path.lineTo(size.width - borderRadius, 0);
    }

    // Top-right corner
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: const Radius.circular(borderRadius),
    );

    // Right edge
    path.lineTo(size.width, size.height - borderRadius);

    // Bottom-right corner
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: const Radius.circular(borderRadius),
    );

    // Bottom edge
    path.lineTo(borderRadius, size.height);

    // Bottom-left corner
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: const Radius.circular(borderRadius),
    );

    // Left edge
    path.lineTo(0, borderRadius);

    // Top-left corner
    path.arcToPoint(
      Offset(borderRadius, 0),
      radius: const Radius.circular(borderRadius),
    );

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_NavBarPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex ||
        oldDelegate.barColor != barColor;
  }
}
