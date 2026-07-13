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
                            ],
                        ),
                    ),
                ),
            ),
        );
    }
}
