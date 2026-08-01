import 'package:flutter/material.dart';

class SnackbarHelper {
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? backgroundColor,
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 2),
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: EdgeInsets.all(screenWidth * 0.015),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: screenWidth * 0.045,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: screenWidth * 0.035,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: duration,
        margin: EdgeInsets.fromLTRB(
          screenWidth * 0.04,
          0,
          screenWidth * 0.04,
          bottomInset + screenHeight * 0.08,
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF1A1A2E),
        elevation: 12,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenWidth * 0.025,
        ),
      ),
    );
  }
}
