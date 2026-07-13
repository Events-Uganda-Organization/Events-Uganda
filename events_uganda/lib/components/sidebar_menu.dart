import 'package:flutter/material.dart';

class SidebarMenu {
  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Sidebar',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) => _SidebarPanel(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return Stack(
          children: [
            AnimatedBuilder(
              animation: anim,
              builder: (context, child) {
                return Opacity(
                  opacity: anim.value,
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(),
                    child: Container(color: Colors.transparent),
                  ),
                );
              },
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

class _SidebarPanel extends StatefulWidget {
  @override
  State<_SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<_SidebarPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnim = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.easeOutBack,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _bounceController.forward();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final panelWidth = w * 0.78;

    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: panelWidth,
        height: MediaQuery.of(context).size.height,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16213E),
                const Color(0xFF0F3460),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(5, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(w),
                _buildReferralCode(w),
                _buildSearch(w),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncyScrollPhysics(),
                    padding: EdgeInsets.only(bottom: w * 0.04),
                    child: Column(
                      children: [
                        _buildNavSection(
                          w,
                          'Main Navigation',
                          [
                            _MenuItem(Icons.home_rounded, 'Home', () {}),
                            _MenuItem(Icons.calendar_month_rounded, 'My Bookings', () {}),
                            _MenuItem(Icons.favorite_rounded, 'My Favorites', () {}),
                            _MenuItem(Icons.chat_rounded, 'Messages', () {}),
                          ],
                        ),
                        _buildNavSection(
                          w,
                          'Event Management',
                          [
                            _MenuItem(Icons.event_rounded, 'My Events', () {}),
                            _MenuItem(Icons.checklist_rounded, 'Event Checklist', () {}),
                          ],
                        ),
                        _buildNavSection(
                          w,
                          'Support',
                          [
                            _MenuItem(Icons.headset_mic_rounded, 'Contact Support', () {}),
                            _MenuItem(Icons.quiz_rounded, 'FAQs', () {}),
                            _MenuItem(Icons.flag_rounded, 'Report a Problem', () {}),
                          ],
                        ),
                        SizedBox(height: w * 0.04),
                        _buildLogout(w),
                        SizedBox(height: w * 0.06),
                        _buildInviteCard(w),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double w) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - _bounceAnim.value)),
          child: Opacity(
            opacity: _bounceAnim.value,
            child: Container(
              padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.04),
              child: Row(
                children: [
                  Container(
                    width: w * 0.12,
                    height: w * 0.12,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF3CA9B), Color(0xFFD4A050)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.event_rounded,
                        color: const Color(0xFF1A1A2E),
                        size: w * 0.065,
                      ),
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Events',
                        style: TextStyle(
                          fontFamily: 'Abril Fatface',
                          fontSize: w * 0.055,
                          color: const Color(0xFFF3CA9B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Uganda',
                        style: TextStyle(
                          fontFamily: 'Abril Fatface',
                          fontSize: w * 0.04,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReferralCode(double w) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -15 * (1 - _bounceAnim.value)),
          child: Opacity(
            opacity: _bounceAnim.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: w * 0.05),
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.035,
                vertical: w * 0.025,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF3CA9B).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: w * 0.07,
                    height: w * 0.07,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3CA9B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.discount_rounded,
                      color: const Color(0xFFF3CA9B),
                      size: w * 0.04,
                    ),
                  ),
                  SizedBox(width: w * 0.025),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referral Code',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: w * 0.022,
                          color: Colors.white38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: w * 0.003),
                      Text(
                        'EVT-UG-2XK9M',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: w * 0.03,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: w * 0.08,
                    height: w * 0.08,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3CA9B).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      color: const Color(0xFFF3CA9B),
                      size: w * 0.04,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearch(double w) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -10 * (1 - _bounceAnim.value)),
          child: Opacity(
            opacity: _bounceAnim.value,
            child: Container(
              margin: EdgeInsets.fromLTRB(w * 0.05, w * 0.025, w * 0.05, w * 0.025),
              padding: EdgeInsets.symmetric(horizontal: w * 0.035),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: Colors.white38,
                    size: w * 0.05,
                  ),
                  SizedBox(width: w * 0.025),
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: w * 0.032,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: w * 0.032,
                          color: Colors.white30,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: w * 0.035),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavSection(double w, String title, List<_MenuItem> items) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _bounceAnim.value,
          child: Padding(
            padding: EdgeInsets.only(top: w * 0.015),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: w * 0.05),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: w * 0.024,
                      color: Colors.white30,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: w * 0.015),
                ...items.map((item) => _buildMenuItem(w, item)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(double w, _MenuItem item) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.003),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: item.onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.02,
              vertical: w * 0.03,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: w * 0.09,
                  height: w * 0.09,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.white70,
                    size: w * 0.045,
                  ),
                ),
                SizedBox(width: w * 0.03),
                Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: w * 0.032,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white24,
                  size: w * 0.045,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogout(double w) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _bounceAnim.value,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.035),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.02,
                    vertical: w * 0.03,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFFFF5F5F).withValues(alpha: 0.1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: w * 0.09,
                        height: w * 0.09,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5F5F).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: const Color(0xFFFF5F5F),
                          size: w * 0.045,
                        ),
                      ),
                      SizedBox(width: w * 0.03),
                      Text(
                        'Log Out',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: w * 0.032,
                          color: const Color(0xFFFF5F5F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInviteCard(double w) {
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (context, child) {
        return Opacity(
          opacity: _bounceAnim.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: w * 0.05),
            padding: EdgeInsets.all(w * 0.04),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF3CA9B).withValues(alpha: 0.15),
                  const Color(0xFFD4A050).withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF3CA9B).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: w * 0.1,
                  height: w * 0.1,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3CA9B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    color: const Color(0xFFF3CA9B),
                    size: w * 0.05,
                  ),
                ),
                SizedBox(width: w * 0.025),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite Friends',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: w * 0.03,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: w * 0.005),
                      Text(
                        'Earn rewards when your friends book.',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: w * 0.022,
                          color: Colors.white54,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: w * 0.015),
                Text(
                  'Learn more',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: w * 0.024,
                    color: const Color(0xFFF3CA9B),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _MenuItem(this.icon, this.label, this.onTap);
}
