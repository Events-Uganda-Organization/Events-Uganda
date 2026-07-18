import 'package:flutter/material.dart';
import '../Auth/Sign_In_Screen.dart';
import '../Users/FAQsScreen.dart';
import '../Users/Customers/Chat_Screen.dart';
import '../Auth/ReferralShareScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
                return _SidebarTransition(anim: anim, child: child);
            },
        );
    }
}

class _SidebarTransition extends StatefulWidget {
    final Animation<double> anim;
    final Widget child;

    const _SidebarTransition({required this.anim, required this.child});

    @override
    State<_SidebarTransition> createState() => _SidebarTransitionState();
}

class _SidebarTransitionState extends State<_SidebarTransition> {
    late final CurvedAnimation _curve;
    late final Animation<Offset> _slideAnimation;

    @override
    void initState() {
        super.initState();
        _curve = CurvedAnimation(
            parent: widget.anim,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
        );
        _slideAnimation = Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
        ).animate(_curve);
    }

    @override
    void dispose() {
        _curve.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        return Stack(
            children: [
                GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: FadeTransition(
                        opacity: widget.anim,
                        child: Container(color: Colors.transparent),
                    ),
                ),
                SlideTransition(
                    position: _slideAnimation,
                    child: widget.child,
                ),
            ],
        );
    }
}

class _SidebarPanel extends StatefulWidget {
    const _SidebarPanel();

    @override
    State<_SidebarPanel> createState() => _SidebarPanelState();
}

class _SidebarPanelState extends State<_SidebarPanel> {
    final TextEditingController _searchCtrl = TextEditingController();
    final FocusNode _searchFocus = FocusNode();

    @override
    void dispose() {
        _searchCtrl.dispose();
        _searchFocus.dispose();
        super.dispose();
    }

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
                        child: ListView(
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
                                                    overflow: TextOverflow.ellipsis,
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
                                                                    overflow: TextOverflow.ellipsis,
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
                                                                    size: w * 0.042,
                                                                ),
                                                            ],
                                                        ),
                                                        SizedBox(height: h * 0.004),
                                                        FutureBuilder<String>(
                                                            future: _getReferralCode(),
                                                            builder: (context, snapshot) {
                                                                final code = snapshot.data ?? '';
                                                                return Text(
                                                                    code,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: TextStyle(
                                                                        fontFamily: 'Montserrat',
                                                                        fontSize: w * 0.026,
                                                                        color: const Color(0xFFFC8A07),
                                                                    ),
                                                                );
                                                            },
                                                        ),
                                                    ],
                                                ),
                                            ],
                                        ),
                                    ),
                                    SizedBox(height: h * 0.02),
                                    Padding(
                                        padding: EdgeInsets.only(left: w * 0.046, right: w * 0.046),
                                        child: Container(
                                            height: h * 0.045,
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(30),
                                                border: Border.all(
                                                    color: const Color(0xFFCD7C20),
                                                    width: 1.5,
                                                ),
                                                boxShadow: [
                                                    BoxShadow(
                                                        color: const Color(0xFFCD7C20).withValues(alpha: 0.2),
                                                        blurRadius: 6,
                                                        offset: const Offset(0, 3),
                                                    ),
                                                ],
                                            ),
                                            child: TextField(
                                                controller: _searchCtrl,
                                                focusNode: _searchFocus,
                                                style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: w * 0.028,
                                                    color: Colors.black,
                                                ),
                                                decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: w * 0.025),
                                                    prefixIcon: Icon(
                                                        Icons.search,
                                                        color: Colors.black,
                                                        size: w * 0.035,
                                                    ),
                                                    hintText: 'Search...',
                                                    hintStyle: TextStyle(
                                                        fontFamily: 'Montserrat',
                                                        fontSize: w * 0.028,
                                                        color: const Color(0xFFCD7C20),
                                                    ),
                                                    suffixIcon: _searchCtrl.text.isNotEmpty
                                                        ? GestureDetector(
                                                            onTap: () {
                                                                _searchCtrl.clear();
                                                                _searchFocus.unfocus();
                                                                setState(() {});
                                                            },
                                                            child: Icon(
                                                                Icons.close,
                                                                color: Colors.black54,
                                                                size: w * 0.035,
                                                            ),
                                                        )
                                                        : null,
                                                ),
                                                onChanged: (_) => setState(() {}),
                                                onSubmitted: (value) {
                                                    if (value.trim().isNotEmpty) {
                                                        _searchFocus.unfocus();
                                                        Navigator.of(context).pop();
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text('Searching for "$value"...')),
                                                        );
                                                    }
                                                },
                                            ),
                                        ),
                                    ),
                                    SizedBox(height: h * 0.02),
                                    Padding(
                                        padding: EdgeInsets.symmetric(horizontal: w * 0.046),
                                        child: Row(
                                            children: [
                                                const Expanded(
                                                    child: Divider(
                                                        color: Colors.grey,
                                                        thickness: 0.8,
                                                    ),
                                                ),
                                                Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: w * 0.025),
                                                    child: Text(
                                                        'Main Navigation',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                            color: Colors.black87,
                                                            fontSize: w * 0.03,
                                                            fontFamily: 'Epunda Slab',
                                                            fontWeight: FontWeight.w400,
                                                        ),
                                                    ),
                                                ),
                                                const Expanded(
                                                    child: Divider(
                                                        color: Colors.grey,
                                                        thickness: 0.8,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                    SizedBox(height: h * 0.015),
                                    Padding(
                                        padding: EdgeInsets.symmetric(horizontal: w * 0.046),
                                        child: Column(
                                            children: [
                                                _NavItem(
                                                    icon: Icons.home_rounded,
                                                    label: 'Home',
                                                    isActive: true,
                                                    w: w,
                                                    h: h,
                                                ),
                                                SizedBox(height: h * 0.006),
                                                _NavItem(
                                                    icon: Icons.calendar_month_rounded,
                                                    label: 'My Bookings',
                                                    w: w,
                                                    h: h,
                                                ),
                                                SizedBox(height: h * 0.006),
                                                _NavItem(
                                                    icon: Icons.favorite_rounded,
                                                    label: 'My Favorites',
                                                    w: w,
                                                    h: h,
                                                ),
                                                SizedBox(height: h * 0.006),
                                                _NavItem(
                                                    icon: Icons.chat_rounded,
                                                    label: 'Messages',
                                                    w: w,
                                                    h: h,
                                                    onTap: () {
                                                        Navigator.of(context).pop();
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(builder: (ctx) => const ChatScreen()),
                                                        );
                                                    },
                                                ),
                                                SizedBox(height: h * 0.006),
                                                _NavItem(
                                                    icon: Icons.card_giftcard,
                                                    label: 'Share Referral Code',
                                                    w: w,
                                                    h: h,
                                                    iconColor: const Color(0xFFE94560),
                                                    onTap: () {
                                                        Navigator.of(context).pop();
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(builder: (ctx) => const ReferralShareScreen()),
                                                        );
                                                    },
                                                ),
                                            ],
                                        ),
                                    ),
                                    SizedBox(height: h * 0.02),
                                    Padding(
                                        padding: EdgeInsets.symmetric(horizontal: w * 0.046),
                                        child: Row(
                                            children: [
                                                const Expanded(
                                                    child: Divider(
                                                        color: Colors.grey,
                                                        thickness: 0.8,
                                                    ),
                                                ),
                                                Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: w * 0.025),
                                                    child: Text(
                                                        'Event Management',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                            color: Colors.black87,
                                                            fontSize: w * 0.03,
                                                            fontFamily: 'Epunda Slab',
                                                            fontWeight: FontWeight.w400,
                                                        ),
                                                    ),
                                                ),
                                                const Expanded(
                                                    child: Divider(
                                                        color: Colors.grey,
                                                        thickness: 0.8,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                    SizedBox(height: h * 0.015),
                                    Padding(
                                        padding: EdgeInsets.symmetric(horizontal: w * 0.046),
                                        child: Column(
                                            children: [
                                                _NavItem(
                                                    icon: Icons.event_rounded,
                                                    label: 'My Events',
                                                    w: w,
                                                    h: h,
                                                ),
                                                SizedBox(height: h * 0.006),
                                                _NavItem(
                                                    icon: Icons.checklist_rounded,
                                                    label: 'Event Checklist',
                                                    w: w,
                                                    h: h,
                                                ),
                                            ],
                                        ),
                                    ),
                                    SizedBox(height: h * 0.02),
                                    Padding(
                                        padding: EdgeInsets.symmetric(horizontal: w * 0.046),
                                        child: Row(
                                            children: [
                                                const Expanded(
                                                    child: Divider(
                                                        color: Colors.grey,
                                                        thickness: 0.8,
                                                    ),
                                                ),
                                                Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: w * 0.025),
                                                    child: Text(
                                                        'Support',
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                            color: Colors.black87,
                                                            fontSize: w * 0.03,
                                                            fontFamily: 'Epunda Slab',
                                                            fontWeight: FontWeight.w400,
                                                        ),
                                                    ),
                                                ),
                                                const Expanded(
                                                    child: Divider(
                                                        color: Colors.grey,
                                                        thickness: 0.8,
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                    SizedBox(height: h * 0.015),
                                    Padding(
                                        padding: EdgeInsets.symmetric(horizontal: w * 0.046),
                                        child: Column(
                                            children: [
                                                _NavItem(
                                                    icon: Icons.headset_mic_rounded,
                                                    label: 'Contact Support',
                                                    w: w,
                                                    h: h,
                                                ),
                                                SizedBox(height: h * 0.006),
                                                _NavItem(
                                                    icon: Icons.quiz_rounded,
                                                    label: 'FAQs',
                                                    w: w,
                                                    h: h,
                                                    onTap: () {
                                                        Navigator.of(context).pop();
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(builder: (ctx) => const FAQsScreen()),
                                                        );
                                                    },
                                                ),
                                                SizedBox(height: h * 0.006),
                                                _NavItem(
                                                    icon: Icons.flag_rounded,
                                                    label: 'Report a Problem',
                                                    w: w,
                                                    h: h,
                                                ),
                                                SizedBox(height: h * 0.015),
                                                Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: w * 0.0),
                                                    child: Material(
                                                        color: Colors.transparent,
                                                        borderRadius: BorderRadius.circular(14),
                                                        child: InkWell(
                                                            borderRadius: BorderRadius.circular(14),
                                                            onTap: () {
                                                                Navigator.of(context).pop();
                                                                Navigator.pushAndRemoveUntil(
                                                                    context,
                                                                    MaterialPageRoute(builder: (ctx) => const SignInScreen()),
                                                                    (route) => false,
                                                                );
                                                            },
                                                            child: Container(
                                                                padding: EdgeInsets.symmetric(
                                                                    horizontal: w * 0.03,
                                                                    vertical: h * 0.015,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                    borderRadius: BorderRadius.circular(14),
                                                                    color: const Color(0xFFFF5F5F).withValues(alpha: 0.08),
                                                                ),
                                                                child: Row(
                                                                    children: [
                                                                        Icon(
                                                                            Icons.logout_rounded,
                                                                            color: const Color(0xFFFF5F5F),
                                                                            size: w * 0.045,
                                                                        ),
                                                                        SizedBox(width: w * 0.03),
                                                                        Text(
                                                                            'Log Out',
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style: TextStyle(
                                                                                fontFamily: 'Montserrat',
                                                                                fontSize: w * 0.034,
                                                                                fontWeight: FontWeight.w600,
                                                                                color: const Color(0xFFFF5F5F),
                                                                            ),
                                                                        ),
                                                                    ],
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                    SizedBox(height: h * 0.025),
                                    _AnimatedInviteCard(w: w, h: h),
                                ],
                        ),
                    ),
                ),
            ),
        );
    }
}

Future<String> _getReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userReferralCode') ?? '';
}

class _NavItem extends StatelessWidget {
    final IconData icon;
    final String label;
    final bool isActive;
    final double w;
    final double h;
    final VoidCallback? onTap;
    final Color? iconColor;

    const _NavItem({
        required this.icon,
        required this.label,
        this.isActive = false,
        required this.w,
        required this.h,
        this.onTap,
        this.iconColor,
    });

    @override
    Widget build(BuildContext context) {
        return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap ?? () {},
                child: Container(
                    padding: EdgeInsets.only(
                        left: isActive ? w * 0.0 : w * 0.03,
                        right: w * 0.03,
                        top: h * 0.013,
                        bottom: h * 0.013,
                    ),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: isActive ? const Color(0xFFF3CA9B).withValues(alpha: 0.12) : Colors.transparent,
                    ),
                    child: isActive
                        ? Stack(
                            children: [
                                Row(
                                    children: [
                                        SizedBox(width: w * 0.03),
                                        Icon(
                                            icon,
                                            color: iconColor ?? const Color(0xFFD4A050),
                                            size: w * 0.045,
                                        ),
                                        SizedBox(width: w * 0.03),
                                        Text(
                                            label,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontFamily: 'Montserrat',
                                                fontSize: w * 0.032,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1A1A2E),
                                            ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                            Icons.chevron_right_rounded,
                                            color: (iconColor ?? const Color(0xFFD4A050)).withValues(alpha: 0.5),
                                            size: w * 0.04,
                                        ),
                                    ],
                                ),
                                Positioned(
                                    left: 0,
                                    top: h * 0.004,
                                    bottom: h * 0.004,
                                    child: Container(
                                        width: 3,
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFD4A050),
                                            borderRadius: BorderRadius.circular(3),
                                        ),
                                    ),
                                ),
                            ],
                        )
                        : Row(
                            children: [
                                Icon(
                                    icon,
                                    color: iconColor ?? Colors.black54,
                                    size: w * 0.045,
                                ),
                                SizedBox(width: w * 0.03),
                                Text(
                                    label,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontFamily: 'Montserrat',
                                        fontSize: w * 0.032,
                                        fontWeight: FontWeight.w500,
                                        color: iconColor ?? Colors.black54,
                                    ),
                                ),
                                const Spacer(),
                                Icon(
                                    Icons.chevron_right_rounded,
                                    color: (iconColor ?? Colors.grey[300])!.withValues(alpha: 0.5),
                                    size: w * 0.04,
                                ),
                            ],
                        ),
                ),
            ),
        );
    }
}

class _AnimatedInviteCard extends StatefulWidget {
    final double w;
    final double h;

    const _AnimatedInviteCard({required this.w, required this.h});

    @override
    State<_AnimatedInviteCard> createState() => _AnimatedInviteCardState();
}

class _AnimatedInviteCardState extends State<_AnimatedInviteCard> with SingleTickerProviderStateMixin {
    late AnimationController _controller;
    late Animation<Color?> _animation;

    static const _colors = [
        Color(0xFFCD7C20),
        Color(0xFF283ED0),
        Color(0xFF8715C9),
    ];

    static const _texts = [
        ('Invite Friends', 'Earn rewards when your friends book'),
        ('Share Events', 'Get 500 points for every referral'),
        ('Review & Rate', 'Earn 200 points per event review'),
    ];

    int get _currentSegment => (_controller.value * 3).floor() % 3;

    @override
    void initState() {
        super.initState();
        _controller = AnimationController(
            duration: const Duration(seconds: 5),
            vsync: this,
        )..repeat();

        _animation = TweenSequence<Color?>([
            TweenSequenceItem(
                weight: 1,
                tween: ColorTween(begin: _colors[0], end: _colors[1]),
            ),
            TweenSequenceItem(
                weight: 1,
                tween: ColorTween(begin: _colors[1], end: _colors[2]),
            ),
            TweenSequenceItem(
                weight: 1,
                tween: ColorTween(begin: _colors[2], end: _colors[0]),
            ),
        ]).animate(_controller);
    }

    @override
    void dispose() {
        _controller.dispose();
        super.dispose();
    }

    @override
    Widget build(BuildContext context) {
        final w = widget.w;
        final h = widget.h;
        return Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.046),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                        final color = _animation.value ?? _colors[0];
                        final t = _texts[_currentSegment];
                        return SizedBox(
                            height: h * 0.23,
                            child: Stack(
                                children: [
                                    Container(
                                        height: h * 0.23,
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [color, Colors.white],
                                                stops: const [0.0, 0.9],
                                            ),
                                        ),
                                    ),
                                    Align(
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                            padding: EdgeInsets.only(top: h * 0.01),
                                            child: Container(
                                                width: w * 0.1,
                                                height: w * 0.1,
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                    Icons.card_giftcard,
                                                    color: const Color(0xFFDC8520),
                                                    size: w * 0.06,
                                                ),
                                            ),
                                        ),
                                    ),
                                    Align(
                                        alignment: Alignment.topCenter,
                                        child: Padding(
                                            padding: EdgeInsets.only(top: h * 0.09),
                                            child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                    Text(
                                                        t.$1,
                                                        textAlign: TextAlign.center,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                            fontFamily: 'Montserrat',
                                                            fontSize: w * 0.032,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                        ),
                                                    ),
                                                    SizedBox(height: h * 0.004),
                                                    Text(
                                                        t.$2,
                                                        textAlign: TextAlign.center,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                            fontFamily: 'Montserrat',
                                                            fontSize: w * 0.022,
                                                            color: Colors.white,
                                                        ),
                                                    ),
                                                    SizedBox(height: h * 0.015),
                                                    Material(
                                                        color: Colors.transparent,
                                                        borderRadius: BorderRadius.circular(15),
                                                        child: InkWell(
                                                            borderRadius: BorderRadius.circular(15),
                                                            onTap: () {},
                                                            child: Container(
                                                                width: w * 0.4,
                                                                padding: EdgeInsets.symmetric(vertical: h * 0.012),
                                                                decoration: BoxDecoration(
                                                                    color: Colors.white,
                                                                    borderRadius: BorderRadius.circular(15),
                                                                ),
                                                                child: Text(
                                                                    'Get Started',
                                                                    textAlign: TextAlign.center,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: TextStyle(
                                                                        fontFamily: 'Montserrat',
                                                                        fontSize: w * 0.028,
                                                                        fontWeight: FontWeight.w600,
                                                                        color: const Color(0xFFCD7C20),
                                                                    ),
                                                                ),
                                                            ),
                                                        ),
                                                    ),
                                                ],
                                            ),
                                        ),
                                    ),
                                    Positioned(
                                        top: -h * 0.025,
                                        right: -w * 0.02,
                                        child: Container(
                                            width: w * 0.22,
                                            height: w * 0.22,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFFD9D9D9).withValues(alpha: 0.15),
                                            ),
                                        ),
                                    ),
                                    Positioned(
                                        bottom: -h * 0.015,
                                        left: -w * 0.01,
                                        child: Container(
                                            width: w * 0.14,
                                            height: w * 0.14,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFFD9D9D9).withValues(alpha: 0.12),
                                            ),
                                        ),
                                    ),
                                    Positioned(
                                        top: h * 0.015,
                                        right: w * 0.12,
                                        child: Container(
                                            width: w * 0.07,
                                            height: w * 0.07,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFFD9D9D9).withValues(alpha: 0.18),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        );
                    },
                ),
            ),
        );
    }
}

