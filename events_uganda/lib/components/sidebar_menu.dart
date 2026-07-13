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
        padding: EdgeInsets.only(left: 5, top: 5, bottom: 5),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(w * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: h * 0.02),
                      Row(
                        children: [
                          Container(
                            width: w * 0.13,
                            height: w * 0.13,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF3CA9B), Color(0xFFD4A050)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.event_rounded, color: Color(0xFF1A1A2E)),
                          ),
                          SizedBox(width: w * 0.03),
                          Text(
                            'Events Uganda',
                            style: TextStyle(
                              fontFamily: 'Abril Fatface',
                              fontSize: w * 0.05,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: h * 0.025),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.03,
                          vertical: w * 0.025,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3CA9B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.discount_rounded, color: Color(0xFFD4A050), size: 20),
                            SizedBox(width: w * 0.02),
                            Text(
                              'Referral Code: EVT-UG-2XK9M',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: w * 0.03,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: h * 0.02),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: w * 0.03,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            hintStyle: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: w * 0.03,
                              color: Colors.grey[400],
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: w * 0.035),
                          ),
                        ),
                      ),
                      SizedBox(height: h * 0.03),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionTitle(w, 'MAIN NAVIGATION'),
                              _MenuItem(Icons.home_rounded, 'Home', w),
                              _MenuItem(Icons.calendar_month_rounded, 'My Bookings', w),
                              _MenuItem(Icons.favorite_rounded, 'My Favorites', w),
                              _MenuItem(Icons.chat_rounded, 'Messages', w),
                              SizedBox(height: h * 0.025),
                              _SectionTitle(w, 'EVENT MANAGEMENT'),
                              _MenuItem(Icons.event_rounded, 'My Events', w),
                              _MenuItem(Icons.checklist_rounded, 'Event Checklist', w),
                              SizedBox(height: h * 0.025),
                              _SectionTitle(w, 'SUPPORT'),
                              _MenuItem(Icons.headset_mic_rounded, 'Contact Support', w),
                              _MenuItem(Icons.quiz_rounded, 'FAQs', w),
                              _MenuItem(Icons.flag_rounded, 'Report a Problem', w),
                              SizedBox(height: h * 0.03),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: w * 0.025,
                                  vertical: w * 0.03,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5F5F).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout_rounded, color: Color(0xFFFF5F5F), size: 22),
                                    SizedBox(width: w * 0.025),
                                    Text(
                                      'Log Out',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: w * 0.035,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFFF5F5F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: h * 0.025),
                              Container(
                                padding: EdgeInsets.all(w * 0.04),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF3CA9B).withValues(alpha: 0.15),
                                      const Color(0xFFD4A050).withValues(alpha: 0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFF3CA9B).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_add_rounded, color: Color(0xFFD4A050), size: 22),
                                    SizedBox(width: w * 0.025),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Invite Friends',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: w * 0.032,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Earn rewards when your friends book.',
                                            style: TextStyle(
                                              fontFamily: 'Montserrat',
                                              fontSize: w * 0.024,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Learn more',
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: w * 0.024,
                                        color: const Color(0xFFD4A050),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
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
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final double w;
  final String title;
  const _SectionTitle(this.w, this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: w * 0.01, bottom: w * 0.025, top: w * 0.015),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: w * 0.026,
          color: Colors.grey[500],
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double w;

  const _MenuItem(this.icon, this.label, this.w);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.008),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {},
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.025,
              vertical: w * 0.032,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.black87, size: 22),
                SizedBox(width: w * 0.035),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: w * 0.034,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
