import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'login_page.dart';
import 'splash.dart';

// ─── COLOR PALETTE (matches HTML :root) ─────────────────────────────
class _LpColors {
  static const Color accentRed    = Color(0xFFFF1744);
  static const Color bgDark       = Color(0xFF05060A);
  static const Color cardDark     = Color(0xFF0D1424);
  static const Color borderDark   = Color(0xFF3A1520);
  static const Color deepRed      = Color(0xFF8B0000);
  static const Color softRed      = Color(0xFFE53935);
  static const Color glowRed      = Color(0xFFFF5252);
  static const Color greenAccent  = Color(0xFF69FF9B);
}

// ─── PARTICLE DATA ──────────────────────────────────────────────────
class _Particle {
  final double top;
  final double left;
  final double size;
  final double delayMs; // negative = phase offset for staggered start
  const _Particle({
    required this.top,
    required this.left,
    required this.size,
    required this.delayMs,
  });
}

// Replicate the JS seeded RNG so particle layout matches the HTML exactly.
List<_Particle> _generateParticles(int count) {
  int state = (42 * 9301 + 49297) % 233280;
  double rand() {
    state = (state * 9301 + 49297) % 233280;
    return state / 233280;
  }
  final List<_Particle> out = [];
  for (int i = 0; i < count; i++) {
    final topFraction = rand();
    final leftFraction = rand();
    final size = rand() * 3 + 1;
    out.add(_Particle(
      top: topFraction * 800,
      left: leftFraction * 400,
      size: size,
      delayMs: -(i * 0.3 * 3000),
    ));
  }
  return out;
}

// ─── BG-LAYER PATTERN (replicates the SVG data-uri) ─────────────────
class _BgPatternPainter extends CustomPainter {
  static const double _tileSize = 300;

  @override
  void paint(Canvas canvas, Size size) {
    // Outer diamond: M150 0 L300 150 L150 300 L0 150 Z, stroke #FF1744 0.5
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _LpColors.accentRed.withOpacity(0.5);

    // Inner diamond: M150 60 L240 150 L150 240 L60 150 Z, stroke #8B0000 0.7
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _LpColors.deepRed.withOpacity(0.7);

    // Cross: M150 60 L150 240 M60 150 L240 150, stroke #FF5252 0.4
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _LpColors.glowRed.withOpacity(0.4);

    // Corners: stroke #3A1520 0.9
    final cornerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _LpColors.borderDark.withOpacity(0.9);

    final cols = (size.width / _tileSize).ceil() + 1;
    final rows = (size.height / _tileSize).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final ox = col * _tileSize;
        final oy = row * _tileSize;

        // Outer diamond
        final outerPath = Path()
          ..moveTo(ox + 150, oy + 0)
          ..lineTo(ox + 300, oy + 150)
          ..lineTo(ox + 150, oy + 300)
          ..lineTo(ox + 0, oy + 150)
          ..close();
        canvas.drawPath(outerPath, outerPaint);

        // Inner diamond
        final innerPath = Path()
          ..moveTo(ox + 150, oy + 60)
          ..lineTo(ox + 240, oy + 150)
          ..lineTo(ox + 150, oy + 240)
          ..lineTo(ox + 60, oy + 150)
          ..close();
        canvas.drawPath(innerPath, innerPaint);

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

// ─── LANDING PAGE ───────────────────────────────────────────────────
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  int _currentPage = 0;
  bool _isLoadingVisible = true;
  bool _entranceStarted = false;
  final PageController _pageController = PageController();

  // Looping animation controllers
  late final AnimationController _shimmerCtrl;   // title shimmer 3s
  late final AnimationController _particleCtrl;  // particles 3s
  late final AnimationController _pulseCtrl;     // logo border pulse 2.2s
  late final AnimationController _swipeCtrl;     // swipe dot 1s

  // One-shot entrance controller (page 3 reveal sequence, ~2.0s)
  late final AnimationController _entranceCtrl;

  static const String _baseUrl = 'http://szxennofficial.qoupayid.xyz:3591';
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles(15);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _swipeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Hide loading screen after 1200ms (matches HTML setTimeout)
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _isLoadingVisible = false);
    });

    // Kick off the auto-login check in parallel; navigation happens if valid
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser == null || savedPass == null || savedKey == null) {
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final androidId = android.id ?? "unknown_device";

      final uri = Uri.parse(
        "$_baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey",
      );
      final res = await http.get(uri);
      final data = jsonDecode(res.body);

      if (data['valid'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SplashScreen(
              username: savedUser,
              password: savedPass,
              role: data['role']?.toString() ?? '',
              expiredDate: data['expiredDate']?.toString() ?? '',
              sessionKey: data['key']?.toString() ?? savedKey,
              listBug: (data['listBug'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
              listDoos: (data['listDDoS'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
              news: (data['news'] as List? ?? [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
            ),
          ),
        );
      }
    } catch (_) {
      // stay on landing
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _onSignIn() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _onBuyAccess() {
    HapticFeedback.lightImpact();
    _openUrl('https://t.me/AiiSigma');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _swipeCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ─── ENTRANCE ANIMATIONS (page 3 reveal sequence) ─────────────────
  // Total duration 2000ms. Intervals derived from CSS keyframe delays.
  Animation<double> _entranceInterval(double start, double end, Curve curve) {
    return CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(start, end, curve: curve),
    );
  }

  // top-row: 0 → 0.63s, curve cubic-bezier(0.33, 1, 0.68, 1)
  Animation<double> get _topRowAnim => _entranceInterval(
        0.0, 0.315, const Cubic(0.33, 1, 0.68, 1));

  // profile-card: 0.18 → 0.684s
  Animation<double> get _profileCardAnim => _entranceInterval(
        0.09, 0.342, const Cubic(0.33, 1, 0.68, 1));

  // welcome-outer: 0.396 → 1.044s
  Animation<double> get _welcomeOuterAnim => _entranceInterval(
        0.198, 0.522, const Cubic(0.33, 1, 0.68, 1));

  // buttons-outer: 0.72 → 1.404s
  Animation<double> get _buttonsOuterAnim => _entranceInterval(
        0.36, 0.702, const Cubic(0.33, 1, 0.68, 1));

  // buttons-inner: 1.08 → 1.8s, scale with bounce
  Animation<double> get _buttonsInnerAnim => _entranceInterval(
        0.54, 0.9, const Cubic(0.68, -0.55, 0.27, 1.55));

  // footer: 0.9 → 1.53s
  Animation<double> get _footerAnim => _entranceInterval(
        0.45, 0.765, const Cubic(0.33, 1, 0.68, 1));

  // ─── BUILD ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 3-page PageView (vertical scroll-snap)
          PageView(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (p) {
              setState(() => _currentPage = p);
              if (p == 2 && !_entranceStarted) {
                _entranceStarted = true;
                _entranceCtrl.forward();
              }
            },
            children: [
              _buildWelcomePage(),
              _buildDescPage(),
              _buildExecutorPage(),
            ],
          ),

          // Fixed header (hidden on page 3)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: AnimatedOpacity(
                opacity: _currentPage >= 2 ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: _currentPage >= 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(height: 20),
                      Text(
                        'Netherite Executor',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Version 1.0',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Swipe indicator (hidden on page 3)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _currentPage >= 2 ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: AnimatedBuilder(
                        animation: _swipeCtrl,
                        builder: (context, _) {
                          // 6 → 18 (alternate)
                          final top = 6.0 + (_swipeCtrl.value * 12.0);
                          return Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(top: top),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white54,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Geser ke atas untuk melanjutkan',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Loading screen overlay (fades after 1200ms)
          AnimatedOpacity(
            opacity: _isLoadingVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_isLoadingVisible,
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9E9E9E)),
                      backgroundColor: Color(0x4D9E9E9E),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PAGE 1: WELCOME ──────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: const Text(
        '.WELCOME.',
        style: TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }

  // ─── PAGE 2: DESCRIPTION ──────────────────────────────────────────
  Widget _buildDescPage() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Selamat Datang',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Selamat datang di komunitas kami! Kami sangat berterima kasih atas kehadiran Anda. Di sini, Anda dapat menikmati kenyamanan sambil memanfaatkan teknologi terbaru dan berbagai alat yang berguna. Jika Anda memiliki pertanyaan atau kendala, jangan ragu untuk menghubungi tim dukungan kami. Selamat menikmati pengalaman Anda!',
              style: TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PAGE 3: UI EXECUTOR ──────────────────────────────────────────
  Widget _buildExecutorPage() {
    return Container(
      color: Colors.black,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Stack(
            children: [
              // bg-layer (pattern + radial gradient)
              Positioned.fill(child: _buildBgLayer()),
              // overlay (4-stop gradient)
              Positioned.fill(child: _buildOverlay()),
              // particles
              Positioned.fill(child: _buildParticles()),
              // safe-area content
              Positioned.fill(child: _buildSafeArea()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBgLayer() {
    return Stack(
      children: [
        // SVG pattern
        Positioned.fill(
          child: CustomPaint(painter: _BgPatternPainter()),
        ),
        // radial gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2), // 50% 40%
                radius: 0.65,
                colors: [
                  _LpColors.deepRed.withOpacity(0.3),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlay() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _LpColors.bgDark.withOpacity(0.75),
            _LpColors.bgDark.withOpacity(0.30),
            _LpColors.bgDark.withOpacity(0.65),
            _LpColors.bgDark.withOpacity(0.98),
          ],
          stops: const [0.0, 0.28, 0.65, 1.0],
        ),
      ),
    );
  }

  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleCtrl,
      builder: (context, _) {
        // particleAnim: 0→0.177 (translateY 0→15) → 0.25 (translateY 0) → 0.177 (translateY -15) → 0 (translateY 0)
        final t = _particleCtrl.value; // 0..1, alternating
        // We need to map t to the keyframe:
        // 0.0 → opacity 0, y 0
        // 0.25 → opacity 0.177, y 15
        // 0.5 → opacity 0.25, y 0
        // 0.75 → opacity 0.177, y -15
        // 1.0 → opacity 0, y 0
        double opacity, dy;
        if (t < 0.25) {
          final k = t / 0.25;
          opacity = 0.0 + k * 0.177;
          dy = 0.0 + k * 15.0;
        } else if (t < 0.5) {
          final k = (t - 0.25) / 0.25;
          opacity = 0.177 + k * (0.25 - 0.177);
          dy = 15.0 - k * 15.0;
        } else if (t < 0.75) {
          final k = (t - 0.5) / 0.25;
          opacity = 0.25 - k * (0.25 - 0.177);
          dy = 0.0 - k * 15.0;
        } else {
          final k = (t - 0.75) / 0.25;
          opacity = 0.177 - k * 0.177;
          dy = -15.0 + k * 15.0;
        }
        return Stack(
          children: _particles.map((p) {
            return Positioned(
              top: p.top + dy,
              left: p.left,
              child: Container(
                width: p.size,
                height: p.size,
                decoration: BoxDecoration(
                  color: _LpColors.glowRed.withOpacity(opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _LpColors.glowRed.withOpacity(0.3),
                      blurRadius: p.size * 3,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSafeArea() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // top-row: brand-badge + gallery-panel
            _buildTopRow(),
            // profile-card
            _buildProfileCard(),
            // spacer
            const Spacer(),
            // welcome-outer
            _buildWelcomeOuter(),
            const SizedBox(height: 24),
            // buttons-outer
            _buildButtonsOuter(),
            // footer
            _buildFooter(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return AnimatedBuilder(
      animation: _topRowAnim,
      builder: (context, child) {
        final t = _topRowAnim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, -25 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // brand-badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_LpColors.deepRed, _LpColors.accentRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _LpColors.accentRed.withOpacity(0.5),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              'Netherite Executor',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          // gallery-panel
          _buildGalleryPanel(),
        ],
      ),
    );
  }

  Widget _buildGalleryPanel() {
    final galleryItems = [
      {'img': 'https://files.catbox.moe/imgd04.jpg', 'url': 'https://t.me/NetheriteProject'},
      {'img': 'https://files.catbox.moe/kn5t2b.jpg', 'url': 'https://t.me/juragaans'},
      {'img': 'https://files.catbox.moe/su98nt.jpg', 'url': 'https://t.me/AiiSigma'},
    ];
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LpColors.borderDark.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: _LpColors.accentRed.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_LpColors.deepRed, _LpColors.accentRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Gallery',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          for (final item in galleryItems) ...[
            _GalleryThumb(
              imageUrl: item['img']!,
              onTap: () => _openUrl(item['url']!),
            ),
            if (item != galleryItems.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return AnimatedBuilder(
      animation: _profileCardAnim,
      builder: (context, child) {
        final t = _profileCardAnim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(-40 * (1 - t), 0),
            child: child,
          ),
        );
      },
      child: Container(
        width: 215,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.50),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _LpColors.borderDark.withOpacity(0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: _LpColors.accentRed.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // profile-tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
              ),
              child: const Text(
                'Profile',
                style: TextStyle(
                  color: Color(0x8CFFFFFF),
                  fontSize: 8.5,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Netherite-X',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _profileRow('Theme: ', 'Netherite X', Colors.white),
            _profileRow('Node: ', 'Premium', Colors.white),
            _profileRow('Status: ', 'Online', _LpColors.greenAccent, bold: true),
            _profileRow('Version: ', 'v2.0.0', Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String key, String val, Color valColor, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, height: 1.6),
          children: [
            TextSpan(text: key, style: const TextStyle(color: Color(0x8CFFFFFF))),
            TextSpan(
              text: val,
              style: TextStyle(
                color: valColor,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeOuter() {
    return AnimatedBuilder(
      animation: _welcomeOuterAnim,
      builder: (context, child) {
        final t = _welcomeOuterAnim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 60 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'WELCOME TO',
              style: TextStyle(
                color: Color(0x99FFFFFF),
                fontSize: 11,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // logo-circle with pulse
                _buildLogoCircle(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerTitle(),
                      const SizedBox(height: 3),
                      const Text(
                        'Netherite-X · Premium Access',
                        style: TextStyle(
                          color: Color(0x80FFFFFF),
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoCircle() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        final t = _pulseCtrl.value; // 0..1 alternating
        // 0%: border-color rgba(255,82,82,0.24), shadow rgba(255,82,82,0.14)
        // 50%: border-color rgba(255,82,82,0.6), shadow rgba(255,82,82,0.35)
        final borderAlpha = 0.24 + t * (0.6 - 0.24);
        final shadowAlpha = 0.14 + t * (0.35 - 0.14);
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _LpColors.glowRed.withOpacity(borderAlpha), width: 2.5),
            color: _LpColors.cardDark,
            boxShadow: [
              BoxShadow(
                color: _LpColors.glowRed.withOpacity(shadowAlpha),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: 'https://files.catbox.moe/imgd04.jpg',
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: _LpColors.cardDark),
              errorWidget: (_, __, ___) => Container(color: _LpColors.cardDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerTitle() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, child) {
        final t = _shimmerCtrl.value; // 0..1 linear
        // Slide gradient from right (200%) to left (-100%) over the text bounds.
        // begin/end Alignment.x: at t=0 we want gradient to the right (+1..+3),
        // at t=1 we want it to the left (-3..-1).
        final begin = 1.0 - t * 4.0;
        final end = 3.0 - t * 4.0;
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(begin, 0),
              end: Alignment(end, 0),
              colors: [
                Colors.white,
                _LpColors.glowRed,
                _LpColors.accentRed,
                Colors.white,
                _LpColors.softRed,
                Colors.white,
                Colors.white,
              ],
              stops: const [0, 0.16, 0.33, 0.5, 0.66, 0.83, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: const Text(
        'Netherite Executor',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildButtonsOuter() {
    return AnimatedBuilder(
      animation: _buttonsOuterAnim,
      builder: (context, child) {
        final t = _buttonsOuterAnim.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 80 * (1 - t)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: AnimatedBuilder(
          animation: _buttonsInnerAnim,
          builder: (context, child) {
            final t = _buttonsInnerAnim.value;
            // Scale 0.82 → 1.0 with bounce (handled by the cubic curve).
            // We map t (0..1 from the Interval) to scale via the curve.
            // The curve Cubic(0.68, -0.55, 0.27, 1.55) already produces overshoot.
            final scale = 0.82 + t * (1.0 - 0.82);
            return Transform.scale(scale: scale, child: child);
          },
          child: Column(
            children: [
              _buildButton(
                label: 'Sign-in Using Username',
                gradientColors: [_LpColors.deepRed, _LpColors.accentRed],
                shadowColor: _LpColors.accentRed.withOpacity(0.45),
                icon: Icons.person,
                onTap: _onSignIn,
              ),
              const SizedBox(height: 12),
              _buildButton(
                label: 'Beli Akses Ke Owner',
                gradientColors: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                shadowColor: const Color(0xFF42A5F5).withOpacity(0.45),
                icon: Icons.send_rounded,
                onTap: _onBuyAccess,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required List<Color> gradientColors,
    required Color shadowColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 14, spreadRadius: 1),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _footerAnim,
      builder: (context, child) {
        return Opacity(opacity: _footerAnim.value, child: child);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _LpColors.accentRed.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _LpColors.accentRed.withOpacity(0.25), width: 1),
          boxShadow: [
            const BoxShadow(color: Color(0x66000000), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.warning_amber_rounded, color: _LpColors.accentRed, size: 16),
                SizedBox(width: 8),
                Text(
                  'DISCLAIMER',
                  style: TextStyle(
                    color: _LpColors.accentRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Use at your own risk. We are not responsible for any bans or damages. By proceeding, you agree to our terms.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0x8CFFFFFF),
                fontSize: 10,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '© 2026 Netherite Executor',
              style: TextStyle(
                color: Color(0x61FFFFFF),
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── GALLERY THUMBNAIL ──────────────────────────────────────────────
class _GalleryThumb extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;
  const _GalleryThumb({required this.imageUrl, required this.onTap});

  @override
  State<_GalleryThumb> createState() => _GalleryThumbState();
}

class _GalleryThumbState extends State<_GalleryThumb> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Container(
            width: 64,
            height: 50,
            decoration: BoxDecoration(
              color: _LpColors.cardDark,
              border: Border.all(color: _LpColors.borderDark.withOpacity(0.5), width: 1),
            ),
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox(),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(Icons.image_outlined, color: Color(0x3DFFFFFF), size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
