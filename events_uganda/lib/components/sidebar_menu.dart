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
                                    child: Row(
                                        children: [
                                            SizedBox(
                                                width: w * 0.12,
                                                height: w * 0.12,
                                                child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient: RadialGradient(
                                                            colors: [
                                                                const Color(0xFFF7DCB0),
                                                                const Color(0xFFF3CA9B),
                                                                const Color(0xFFE8B87E),
                                                            ],
                                                            stops: const [0.0, 0.6, 1.0],
                                                        ),
                                                        border: Border.all(color: Colors.white, width: 2.5),
                                                        boxShadow: [
                                                            BoxShadow(
                                                                color: const Color(0xFFD4A050).withValues(alpha: 0.25),
                                                                blurRadius: 8,
                                                                offset: const Offset(0, 3),
                                                            ),
                                                            BoxShadow(
                                                                color: Colors.black.withValues(alpha: 0.06),
                                                                blurRadius: 4,
                                                                offset: const Offset(0, 1),
                                                            ),
                                                        ],
                                                    ),
                                                    child: Padding(
                                                        padding: EdgeInsets.all(w * 0.022),
                                                        child: FittedBox(
                                                            fit: BoxFit.contain,
                                                            child: Icon(
                                                                Icons.person_rounded,
                                                                color: const Color(0xFF2C1810),
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                            ),
                                            SizedBox(width: w * 0.03),
                                            Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                    Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                            Text(
                                                                'Events Uganda',
                                                                style: TextStyle(
                                                                    fontFamily: 'Montserrat',
                                                                    fontSize: w * 0.038,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: Colors.black,
                                                                ),
                                                            ),
                                                            SizedBox(width: w * 0.015),
                                                            Icon(
                                                                Icons.verified,
                                                                color: const Color(0xFF1DA1F2),
                                                                size: w * 0.032,
                                                            ),
                                                        ],
                                                    ),
                                                    SizedBox(height: h * 0.004),
                                                    Text(
                                                        'Referral Code',
                                                        style: TextStyle(
                                                            fontFamily: 'Montserrat',
                                                            fontSize: w * 0.026,
                                                            color: const Color(0xFFFC8A07),
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
                ),
            ),
        );
    }
}
