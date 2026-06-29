import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'owner_page.dart';
import 'login_page.dart';
import 'device_dashboard.dart';
import 'tqto.dart';
import 'chat.dart';

// ─── NETHERITE BLOOD RED THEME ──────────────────────────────────────
// Mirrors the CSS variables in the reference HTML exactly.
class NetherColors {
  static const Color bgMain       = Color(0xFF050507);
  static const Color bgCard       = Color(0xFF0C0C10);
  static const Color bgCardInner  = Color(0xFF14141A);
  static const Color border       = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color borderActive = Color(0x80D90429); // rgba(217,4,41,0.5)

  static const Color textMain  = Color(0xFFFFFFFF);
  static const Color textSec   = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF52525B);

  // Deep Blood Red Palette
  static const Color redPrimary = Color(0xFFD90429);
  static const Color redDeep    = Color(0xFF8B0000);
  static const Color redGlow    = Color(0x33D90429); // 0.2
  static const Color redSoftBg  = Color(0x14D90429); // 0.08

  // Glass red helpers
  static const Color glassRedStart  = Color(0x33D90429); // rgba(217,4,41,0.2)
  static const Color glassRedEnd    = Color(0x99140005); // rgba(20,0,5,0.6)
  static const Color glassRedBorder = Color(0x80D90429); // rgba(217,4,41,0.5)

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFFAB40);
  static const Color error   = Color(0xFFD90429);
}

const String _kBase = 'http://szxennofficial.qoupayid.xyz:3591';

Route _createRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;
      final tween = Tween(begin: const Offset(0.03, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: curve));
      final offsetAnim = animation.drive(tween);
      final fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: curve));
      final fadeAnim = animation.drive(fadeTween);
      return FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(position: offsetAnim, child: child),
      );
    },
  );
}

// ─── GLASS RED HELPERS ──────────────────────────────────────────────
LinearGradient _glassRedGradient() => const LinearGradient(
      colors: [NetherColors.glassRedStart, NetherColors.glassRedEnd],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

List<BoxShadow> _glassRedShadow() => const [
      BoxShadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 4)),
      BoxShadow(color: Color(0x0DFFFFFF), blurRadius: 0, offset: Offset(0, 1)),
    ];

// ─── DASHBOARD BG PATTERN (diamond lines, same as landing/login) ────
// Draws the geometric red diamond pattern behind the dashboard content.
// Visible through the glass cards via BackdropFilter blur.
class _DashBgPainter extends CustomPainter {
  static const double _tileSize = 300;

  @override
  void paint(Canvas canvas, Size size) {
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = NetherColors.redPrimary.withOpacity(0.5);
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = NetherColors.redDeep.withOpacity(0.7);
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFFF5252).withOpacity(0.4);
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF3A1520).withOpacity(0.9);

    final cols = (size.width / _tileSize).ceil() + 1;
    final rows = (size.height / _tileSize).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final ox = col * _tileSize;
        final oy = row * _tileSize;
        // Outer diamond
        final outer = Path()
          ..moveTo(ox + 150, oy + 0)
          ..lineTo(ox + 300, oy + 150)
          ..lineTo(ox + 150, oy + 300)
          ..lineTo(ox + 0, oy + 150)
          ..close();
        canvas.drawPath(outer, outerPaint);
        // Inner diamond
        final inner = Path()
          ..moveTo(ox + 150, oy + 60)
          ..lineTo(ox + 240, oy + 150)
          ..lineTo(ox + 150, oy + 240)
          ..lineTo(ox + 60, oy + 150)
          ..close();
        canvas.drawPath(inner, innerPaint);
        // Cross
        canvas.drawLine(Offset(ox + 150, oy + 60), Offset(ox + 150, oy + 240), crossPaint);
        canvas.drawLine(Offset(ox + 60, oy + 150), Offset(ox + 240, oy + 150), crossPaint);
        // Corners
        canvas.drawLine(Offset(ox + 0, oy + 0), Offset(ox + 50, oy + 50), cornerPaint);
        canvas.drawLine(Offset(ox + 300, oy + 0), Offset(ox + 250, oy + 50), cornerPaint);
        canvas.drawLine(Offset(ox + 0, oy + 300), Offset(ox + 50, oy + 250), cornerPaint);
        canvas.drawLine(Offset(ox + 300, oy + 300), Offset(ox + 250, oy + 250), cornerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── STAGGERED FADE-IN ──────────────────────────────────────────────
class _Stagger extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _Stagger({required this.child, required this.delay});
  @override
  State<_Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<_Stagger> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: const Cubic(0.16, 1, 0.3, 1)));
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── TOPBAR ─────────────────────────────────────────────────────────
class _Topbar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onBellTap;
  final VoidCallback onProfileTap;
  const _Topbar({
    required this.onMenuTap,
    required this.onBellTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: NetherColors.bgMain,
        border: Border(bottom: BorderSide(color: NetherColors.border, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _IconBtn(icon: Icons.menu, onTap: onMenuTap),
          const Text(
            'NETHERITE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          Row(
            children: [
              _IconBtn(icon: Icons.notifications_none_rounded, onTap: onBellTap),
              const SizedBox(width: 10),
              _IconBtn(icon: Icons.person_outline_rounded, isProfile: true, onTap: onProfileTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final bool isProfile;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, this.isProfile = false, required this.onTap});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) => setState(() => _p = false),
      onTapCancel: () => setState(() => _p = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _p ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 40,
          height: 40,
          decoration: widget.isProfile
              ? BoxDecoration(
                  gradient: _glassRedGradient(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x4DD90429), width: 1),
                  boxShadow: _glassRedShadow(),
                )
              : BoxDecoration(
                  color: NetherColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: NetherColors.border, width: 1),
                ),
          child: Icon(widget.icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ─── HERO BANNER ────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final int deviceCount;
  const _HeroBanner({required this.deviceCount});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://files.catbox.moe/ecbir8.jpg',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: NetherColors.bgCardInner),
              errorWidget: (_, __, ___) => Container(
                color: NetherColors.bgCardInner,
                child: const Icon(Icons.broken_image_outlined, color: Colors.white24, size: 48),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [NetherColors.bgMain, Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: const Alignment(0, -0.6),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$deviceCount',
                  style: TextStyle(
                    color: NetherColors.redPrimary,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    shadows: [Shadow(color: NetherColors.redGlow, blurRadius: 15)],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'TOTAL DEVICES',
                  style: TextStyle(
                    color: NetherColors.textSec,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PROFILE CARD (NXT PROJECT) ─────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final String username;
  final String role;
  final String expiredDate;
  const _ProfileCard({
    required this.username,
    required this.role,
    required this.expiredDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NetherColors.bgCard.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NetherColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
          Center(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Made',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
                children: [
                  TextSpan(text: 'NXT ', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'PROJECT', style: TextStyle(color: NetherColors.redPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Body
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [NetherColors.redPrimary, NetherColors.redDeep]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: NetherColors.redGlow, blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: CachedNetworkImage(
                    imageUrl: 'https://files.catbox.moe/imgd04.jpg',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 72,
                      height: 72,
                      color: NetherColors.bgCardInner,
                      child: const Icon(Icons.person, color: Colors.white54),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: NetherColors.bgCardInner,
                      child: const Icon(Icons.person, color: Colors.white54),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontFamily: 'Made',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.userShield, color: NetherColors.redPrimary, size: 11),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ROLE: ${role.toUpperCase()}',
                            style: const TextStyle(
                              fontFamily: 'Made',
                              color: NetherColors.redPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_busy_outlined, color: NetherColors.textMuted, size: 13),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'EXP: $expiredDate',
                            style: const TextStyle(
                              fontFamily: 'Made',
                              color: NetherColors.textSec,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Bottom
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: NetherColors.border, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.access_time_rounded, color: NetherColors.textMuted, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'SESSION ACTIVE',
                      style: TextStyle(
                        fontFamily: 'Made',
                        color: NetherColors.textSec,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.call_split_rounded, color: NetherColors.textMuted, size: 14),
                    SizedBox(width: 8),
                    Text(
                      'VER',
                      style: TextStyle(
                        fontFamily: 'Made',
                        color: NetherColors.textSec,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '1.0',
                      style: TextStyle(
                        fontFamily: 'Made',
                        color: NetherColors.redPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

// ─── PROMO CAROUSEL ─────────────────────────────────────────────────
// Renders banners from `news` data passed by the parent (sourced from API).
// Each news item shape: { "image": <url>, "title": <string>, "desc": <string> }
class _PromoCarousel extends StatefulWidget {
  final List<dynamic> news;
  const _PromoCarousel({required this.news});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  int _current = 0;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _banners {
    final List<Map<String, String>> out = [];
    for (final raw in widget.news) {
      if (raw is Map) {
        final image = (raw['image'] ?? '').toString();
        final title = (raw['title'] ?? '').toString();
        final desc = (raw['desc'] ?? '').toString();
        if (image.isNotEmpty || title.isNotEmpty) {
          out.add({'image': image, 'title': title, 'subtitle': desc});
        }
      }
    }
    // Fallback so the card never appears empty if API returns no news
    if (out.isEmpty) {
      out.add({
        'image': 'https://files.catbox.moe/aveyk3.jpg',
        'title': 'Netherite Executor',
        'subtitle': 'Developed By hafz & aiisigma',
      });
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final banners = _banners;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NetherColors.bgCard.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NetherColors.border, width: 1),
            ),
            child: Column(
              children: [
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _ctrl,
              itemCount: banners.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final b = banners[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NetherColors.border, width: 1),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (b['image']!.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: b['image']!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: NetherColors.bgCardInner),
                          errorWidget: (_, __, ___) => Container(
                            color: NetherColors.bgCardInner,
                            child: const Icon(Icons.image_outlined, color: Colors.white24),
                          ),
                        )
                      else
                        Container(
                          color: NetherColors.bgCardInner,
                          child: const Icon(Icons.image_outlined, color: Colors.white24),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xE6050507),
                              const Color(0x33050507),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              b['title']!.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Made',
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              b['subtitle']!,
                              style: const TextStyle(
                                fontFamily: 'Made',
                                color: NetherColors.textSec,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Promo dots (only show if more than 1 banner)
          if (banners.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(banners.length, (i) {
                return GestureDetector(
                  onTap: () => _ctrl.animateToPage(i,
                      duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _current ? NetherColors.redPrimary : NetherColors.textMuted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          if (banners.length > 1) const SizedBox(height: 14),
          // Join Telegram button (glass red)
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              final uri = Uri.parse('https://t.me/NetheriteProject');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: _glassRedGradient(),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NetherColors.glassRedBorder, width: 1),
                boxShadow: _glassRedShadow(),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.telegram, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Join Telegram',
                    style: TextStyle(
                      fontFamily: 'Made',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
    );
  }
}

// ─── SELECT DEVICE SECTION ──────────────────────────────────────────
class _SelectDeviceSection extends StatefulWidget {
  final String sessionKey;
  final void Function(int totalDevices) onDevicesLoaded;
  const _SelectDeviceSection({
    required this.sessionKey,
    required this.onDevicesLoaded,
  });

  @override
  State<_SelectDeviceSection> createState() => _SelectDeviceSectionState();
}

class _SelectDeviceSectionState extends State<_SelectDeviceSection> {
  List<dynamic> _devices = [];
  bool _loading = true;
  String _filter = 'ALL';
  int _currentSlide = 0;
  late PageController _slideCtrl;

  @override
  void initState() {
    super.initState();
    _slideCtrl = PageController();
    _loadDevices();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    try {
      final response = await http
          .get(Uri.parse('$_kBase/rat/my-devices?key=${widget.sessionKey}'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['valid'] == true) {
          final devices = body['devices'] ?? [];
          if (mounted) {
            setState(() {
              _devices = devices;
              _loading = false;
            });
            widget.onDevicesLoaded(_devices.length);
          }
          return;
        }
      }
      if (mounted) {
        setState(() => _loading = false);
        widget.onDevicesLoaded(0);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        widget.onDevicesLoaded(0);
      }
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'ALL') return _devices;
    if (_filter == 'ONLINE') return _devices.where((d) => d['online'] == true).toList();
    return _devices.where((d) => d['online'] != true).toList();
  }

  int get _countOnline => _devices.where((d) => d['online'] == true).length;
  int get _countOffline => _devices.where((d) => d['online'] != true).length;

  void _switchFilter(String f) {
    HapticFeedback.lightImpact();
    setState(() {
      _filter = f;
      _currentSlide = 0;
    });
    if (_slideCtrl.hasClients) {
      _slideCtrl.jumpToPage(0);
    }
  }

  int _safeInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: NetherColors.bgCard.withOpacity(0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: NetherColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: NetherColors.redSoftBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_android_rounded, color: NetherColors.redPrimary, size: 16),
              ),
              const SizedBox(width: 12),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Made',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                  children: [
                    TextSpan(text: 'SELECT ', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'DEVICE', style: TextStyle(color: NetherColors.redPrimary)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: NetherColors.bgCardInner,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: NetherColors.border, width: 1),
                ),
                child: const Text(
                  'ID: 5a44cb50',
                  style: TextStyle(
                    color: NetherColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tabs
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: NetherColors.bgCardInner,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NetherColors.border, width: 1),
            ),
            child: Row(
              children: [
                _Tab(
                  label: 'ALL',
                  count: _devices.length,
                  dotColor: null,
                  isActive: _filter == 'ALL',
                  onTap: () => _switchFilter('ALL'),
                ),
                _Tab(
                  label: 'ONLINE',
                  count: _countOnline,
                  dotColor: NetherColors.success,
                  isActive: _filter == 'ONLINE',
                  onTap: () => _switchFilter('ONLINE'),
                ),
                _Tab(
                  label: 'OFFLINE',
                  count: _countOffline,
                  dotColor: NetherColors.redPrimary,
                  isActive: _filter == 'OFFLINE',
                  onTap: () => _switchFilter('OFFLINE'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Device slider
          if (_loading)
            const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator(color: NetherColors.redPrimary)),
            )
          else if (_filtered.isEmpty)
            SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Tidak ada device ${_filter.toLowerCase()}',
                  style: const TextStyle(
                    color: NetherColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 240,
                  child: PageView.builder(
                    controller: _slideCtrl,
                    itemCount: _filtered.length,
                    onPageChanged: (i) => setState(() => _currentSlide = i),
                    itemBuilder: (_, i) {
                      final d = _filtered[i];
                      final isOffline = d['online'] != true;
                      final name = (d['name'] ?? d['model'] ?? 'Unknown Device').toString();
                      final model = (d['model'] ?? '-').toString();
                      return _DeviceSlide(
                        name: name,
                        model: model,
                        isOffline: isOffline,
                        battery: _safeInt(d['battery']),
                        os: (d['os'] ?? '-').toString(),
                        ip: (d['ip'] ?? '-').toString(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_filtered.length, (i) {
                    return GestureDetector(
                      onTap: () => _slideCtrl.animateToPage(i,
                          duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _currentSlide ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _currentSlide ? NetherColors.redPrimary : NetherColors.textMuted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
        ],
      ),
      ),
    ),
  ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final Color? dotColor; // null = white (ALL), success = online, red = offline
  final bool isActive;
  final VoidCallback onTap;
  const _Tab({
    required this.label,
    required this.count,
    required this.dotColor,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeDotColor = dotColor ?? Colors.white;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: const Cubic(0.16, 1, 0.3, 1),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: isActive
              ? BoxDecoration(
                  gradient: _glassRedGradient(),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x66D90429), width: 1),
                  boxShadow: _glassRedShadow(),
                )
              : BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? activeDotColor : Colors.transparent,
                  border: Border.all(
                    color: isActive ? Colors.transparent : NetherColors.textMuted,
                    width: 1,
                  ),
                  boxShadow: isActive && dotColor != null
                      ? [BoxShadow(color: dotColor!, blurRadius: 6)]
                      : (isActive && dotColor == null
                          ? [const BoxShadow(color: Colors.white, blurRadius: 6)]
                          : null),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$label ($count)',
                style: TextStyle(
                  color: isActive ? Colors.white : NetherColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceSlide extends StatelessWidget {
  final String name;
  final String model;
  final bool isOffline;
  final int battery;
  final String os;
  final String ip;
  const _DeviceSlide({
    required this.name,
    required this.model,
    required this.isOffline,
    required this.battery,
    required this.os,
    required this.ip,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isOffline ? NetherColors.redPrimary : NetherColors.success;
    final statusLabel = isOffline ? 'OFFLINE' : 'ONLINE';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NetherColors.bgCardInner,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NetherColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Device icon with status dot
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: NetherColors.bgMain,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: NetherColors.border, width: 1),
                          ),
                          child: const Icon(Icons.phone_android_rounded, color: NetherColors.redPrimary, size: 22),
                        ),
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                              border: Border.all(color: NetherColors.bgCardInner, width: 3),
                              boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 8)],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model,
                            style: const TextStyle(
                              color: NetherColors.textSec,
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOffline ? NetherColors.redSoftBg : const Color(0x1A34D399),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOffline ? const Color(0x33D90429) : const Color(0x334D399),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                        boxShadow: isOffline ? null : [BoxShadow(color: statusColor, blurRadius: 4)],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Battery section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NetherColors.bgMain,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: NetherColors.bgCardInner,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isOffline ? Icons.battery_alert_outlined : Icons.battery_charging_full,
                        color: statusColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'BATTERY LEVEL',
                      style: TextStyle(
                        color: NetherColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$battery%',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: battery == 0 ? 0.0 : battery / 100.0,
                    minHeight: 4,
                    backgroundColor: const Color(0x0DFFFFFF),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // OS and IP grid
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NetherColors.bgMain,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: NetherColors.bgCardInner,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(FontAwesomeIcons.android, color: NetherColors.success, size: 12),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'OS',
                            style: TextStyle(
                              color: NetherColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        os,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NetherColors.bgMain,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: NetherColors.bgCardInner,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.wifi_rounded, color: NetherColors.redPrimary, size: 12),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'IP ADDRESS',
                            style: TextStyle(
                              color: NetherColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── FLOATING BOTTOM NAV ────────────────────────────────────────────
class _FloatingBottomNav extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;
  const _FloatingBottomNav({required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: NetherColors.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NetherColors.border, width: 1),
            boxShadow: const [
              BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 15)),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'HOME',
                isActive: activeIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.phone_android_rounded,
                label: 'DEVICE',
                isActive: activeIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'CHAT',
                isActive: activeIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.isActive ? 3 : 2,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _p = true),
        onTapUp: (_) => setState(() => _p = false),
        onTapCancel: () => setState(() => _p = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _p ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: const Cubic(0.16, 1, 0.3, 1),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: widget.isActive
                ? BoxDecoration(
                    gradient: _glassRedGradient(),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x66D90429), width: 1),
                    boxShadow: _glassRedShadow(),
                  )
                : BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isActive ? Colors.white : NetherColors.textMuted,
                  size: 18,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: const Cubic(0.16, 1, 0.3, 1),
                  child: widget.isActive
                      ? Row(
                          children: [
                            const SizedBox(width: 8),
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox(width: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── MAIN DASHBOARD PAGE ────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey;
  final List<Map<String, dynamic>> listBug, listDoos;
  final List<dynamic> news;

  const DashboardPage({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.expiredDate,
    required this.listBug,
    required this.listDoos,
    required this.sessionKey,
    required this.news,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  WebSocketChannel? channel;
  late String sessionKey, username, role, expiredDate;
  String androidId = "unknown";
  int _bottomNavIndex = 0;
  int _deviceCount = 0;

  // Key so the topbar hamburger menu can open the drawer from anywhere
  // (Scaffold.of(context) doesn't work when context is above the Scaffold).
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Cached pages so the bottom nav persists across tab switches.
  // IndexedStack keeps all three pages alive — state, scroll position, and
  // WebSocket connections are preserved when switching tabs.
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey;
    username = widget.username;
    role = widget.role;
    expiredDate = widget.expiredDate;

    _pages = [
      // Tab 0: Home (built fresh so it can reference _deviceCount via setState)
      _buildHomeContent(),
      // Tab 1: Device — wrapped in bottom padding so the floating nav
      // doesn't overlap the owner permission button at bottom-left.
      Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: DeviceDashboardPage(
          username: username,
          role: role,
          sessionKey: sessionKey,
        ),
      ),
      // Tab 2: Chat — same bottom padding treatment.
      Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: ChatPage(
          username: username,
          sessionKey: sessionKey,
        ),
      ),
    ];

    _initAndroidIdAndConnect();
  }

  Future<void> _initAndroidIdAndConnect() async {
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      androidId = deviceInfo.id;
    } catch (_) {
      // keep default "unknown"
    }
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      channel = WebSocketChannel.connect(
        Uri.parse('wss://ws:papi.queen-official.com:5021:4000'),
      );
      channel!.sink.add(jsonEncode({
        "type": "validate",
        "key": sessionKey,
        "androidId": androidId,
      }));
      channel!.stream.listen(
        (event) {
          try {
            final data = jsonDecode(event);
            if (data is Map &&
                data['type'] == 'myInfo' &&
                data['valid'] == false) {
              _showSessionExpired();
            }
          } catch (_) {}
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void _showSessionExpired() async {
    await SharedPreferences.getInstance().then((p) => p.clear());
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NetherColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: NetherColors.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _glassRedGradient(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NetherColors.glassRedBorder, width: 1),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              const Text("Session Expired",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text("Silakan login kembali",
                  style: TextStyle(color: NetherColors.textSec)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pushAndRemoveUntil(
                    context, _createRoute(const LoginPage()), (r) => false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: _glassRedGradient(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NetherColors.glassRedBorder, width: 1),
                  ),
                  child: const Text("OK",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() => _bottomNavIndex = index);
  }

  void _navigateToOwner() =>
      Navigator.push(context, _createRoute(OwnerPage(sessionKey: sessionKey, username: username)));
  void _navigateToTqto() =>
      Navigator.push(context, _createRoute(const ThanksToPage()));
  void _navigateToChat() =>
      Navigator.push(context, _createRoute(ChatPage(username: username, sessionKey: sessionKey)));

  void _showAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: NetherColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: NetherColors.border, width: 1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: NetherColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [NetherColors.redPrimary, NetherColors.redDeep]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: NetherColors.redGlow, blurRadius: 20)],
              ),
              child: const CircleAvatar(
                radius: 38,
                backgroundColor: NetherColors.bgCard,
                child: Icon(Icons.person, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: 12),
            Text(username,
                style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: NetherColors.redSoftBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33D90429), width: 1),
              ),
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(
                    color: NetherColors.redPrimary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup",
                        style: TextStyle(color: NetherColors.textMuted)),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _glassRedGradient(),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: NetherColors.glassRedBorder, width: 1),
                      ),
                      child: const Center(
                        child: Text("Logout",
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NetherColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: NetherColors.border, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: _glassRedGradient(),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: NetherColors.glassRedBorder, width: 1),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              const Text("Konfirmasi Logout",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text("Yakin ingin logout?",
                  style: TextStyle(color: NetherColors.textSec)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Batal", style: TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await SharedPreferences.getInstance().then((p) => p.clear());
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                            context, _createRoute(const LoginPage()), (r) => false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: _glassRedGradient(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: NetherColors.glassRedBorder, width: 1),
                      ),
                      child: const Text("Logout",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        // Topbar only on Home tab — Device & Chat have their own AppBars.
        SafeArea(
          bottom: false,
          child: _Topbar(
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onBellTap: () {},
            onProfileTap: _showAccountSheet,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroBanner(deviceCount: _deviceCount),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Stagger(
                        delay: const Duration(milliseconds: 50),
                        child: _ProfileCard(
                          username: username,
                          role: role,
                          expiredDate: expiredDate,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Stagger(
                        delay: const Duration(milliseconds: 150),
                        child: _PromoCarousel(news: widget.news),
                      ),
                      const SizedBox(height: 16),
                      _Stagger(
                        delay: const Duration(milliseconds: 250),
                        child: _SelectDeviceSection(
                          sessionKey: sessionKey,
                          onDevicesLoaded: (count) {
                            if (mounted) setState(() => _deviceCount = count);
                          },
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
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: NetherColors.bgCard,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: _glassRedGradient(),
              border: const Border(
                  bottom: BorderSide(color: NetherColors.border, width: 1)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: NetherColors.bgCard,
                    child: Icon(Icons.person_outline, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: NetherColors.redSoftBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x33D90429), width: 1),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: const TextStyle(
                          color: NetherColors.redPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (role.toLowerCase() == 'owner')
                  _DrawerItem(
                    icon: Icons.storefront_rounded,
                    title: 'Owner Page',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToOwner();
                    },
                  ),
                _DrawerItem(
                  icon: Icons.favorite_outline_rounded,
                  title: 'Thanks To',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToTqto();
                  },
                ),
                _DrawerItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Chat',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToChat();
                  },
                ),
                const SizedBox(height: 8),
                const Divider(color: NetherColors.bgCardInner),
                const SizedBox(height: 8),
                _DrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  color: NetherColors.redPrimary,
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog();
                  },
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'POWERED BY HAFZ DAN AIISIGMA',
                    style: TextStyle(
                        color: NetherColors.textMuted,
                        fontSize: 9,
                        letterSpacing: 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: NetherColors.bgMain,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          // Background pattern (diamond lines + radial glow).
          // Only visible on the Home tab — Device & Chat pages have their
          // own opaque Scaffold backgrounds that cover this.
          Positioned.fill(
            child: Stack(
              children: [
                CustomPaint(painter: _DashBgPainter()),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.4),
                      radius: 0.8,
                      colors: [
                        NetherColors.redDeep.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // IndexedStack keeps all three pages mounted so the bottom nav
          // persists across Home / Device / Chat tabs without pushing a
          // new route.
          IndexedStack(
            index: _bottomNavIndex,
            children: _pages,
          ),
          // Floating bottom nav (persistent across all tabs)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingBottomNav(
              activeIndex: _bottomNavIndex,
              onTap: _onNavTapped,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    try {
      channel?.sink.close(ws_status.goingAway);
    } catch (_) {}
    super.dispose();
  }
}

// ─── DRAWER ITEM ────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;
  const _DrawerItem({
    required this.icon,
    required this.title,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: NetherColors.bgCardInner,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NetherColors.border, width: 1),
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: TextStyle(
            color: color ?? Colors.white, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}
