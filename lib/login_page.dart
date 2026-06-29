import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'splash.dart';

const String baseUrl = 'http://szxennofficial.qoupayid.xyz:3591';

// ─── COLOR PALETTE (matches HTML :root) ─────────────────────────────
class _LpColors {
  static const Color bgDark       = Color(0xFF05060A);
  static const Color bgSecondary  = Color(0xFF0D1424);
  static const Color accentRed    = Color(0xFFFF1744);
  static const Color accentSoft   = Color(0xFFFF5252);
  static const Color accentDeep   = Color(0xFF8B0000);
  static const Color borderDark   = Color(0xFF3A1520);
  static const Color glassBorder  = Color(0x40FF1744); // rgba(255,23,68,0.25)
  static const Color textDim      = Color(0x85FFFFFF); // rgba(255,255,255,0.52)
}

// ─── PARTICLE DATA ──────────────────────────────────────────────────
class _Particle {
  final double top;
  final double left;
  final double size;
  const _Particle({required this.top, required this.left, required this.size});
}

List<_Particle> _generateParticles(int count) {
  int state = (42 * 9301 + 49297) % 233280;
  double rand() {
    state = (state * 9301 + 49297) % 233280;
    return state / 233280;
  }
  final out = <_Particle>[];
  for (int i = 0; i < count; i++) {
    final topFraction = rand();
    final leftFraction = rand();
    final size = rand() * 3 + 1;
    out.add(_Particle(
      top: topFraction * 800,
      left: leftFraction * 400,
      size: size,
    ));
  }
  return out;
}

// ─── BG-LAYER PATTERN (same SVG as landing) ─────────────────────────
class _BgPatternPainter extends CustomPainter {
  static const double _tileSize = 300;

  @override
  void paint(Canvas canvas, Size size) {
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _LpColors.accentRed.withOpacity(0.5);
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _LpColors.accentDeep.withOpacity(0.7);
    final crossPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _LpColors.accentSoft.withOpacity(0.4);
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

// ─── STAGGER HELPER ─────────────────────────────────────────────────
class _Stagger extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;
  const _Stagger({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - t)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

// ─── LOGIN PAGE ─────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  // Entrance controller (2250ms total — covers bg, hero, sheet, all staggers)
  late final AnimationController _entranceCtrl;
  // Looping controllers
  late final AnimationController _particleCtrl; // 3s
  late final AnimationController _dotLoaderCtrl; // 1.1s
  late final AnimationController _sweepCtrl; // 4s (button sweep)

  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _particles = _generateParticles(15);

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2250),
    )..forward();

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _dotLoaderCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initLogin();
  }

  // ─── ENTRANCE INTERVALS ───────────────────────────────────────────
  Animation<double> _interval(double start, double end, Curve curve) {
    return CurvedAnimation(
      parent: _entranceCtrl,
      curve: Interval(start, end, curve: curve),
    );
  }

  // bg-layer fade-in: 0 → 1.5s (ease)
  Animation<double> get _bgFadeAnim =>
      _interval(0.0, 0.667, Curves.ease);
  // hero zoom-in: 0.2s → 1.7s (cubic 0.16,1,0.3,1)
  Animation<double> get _heroAnim =>
      _interval(0.089, 0.756, const Cubic(0.16, 1, 0.3, 1));
  // glow line: 1.2s → 2.2s (ease)
  Animation<double> get _lineGlowAnim =>
      _interval(0.533, 0.978, Curves.ease);
  // sheet slide-up: 0.4s → 1.4s (cubic 0.16,1,0.3,1)
  Animation<double> get _sheetAnim =>
      _interval(0.178, 0.622, const Cubic(0.16, 1, 0.3, 1));
  // staggers (each 0.8s, curve 0.33,1,0.68,1)
  Animation<double> get _stagger1 =>
      _interval(0.444, 0.800, const Cubic(0.33, 1, 0.68, 1));
  Animation<double> get _stagger2 =>
      _interval(0.511, 0.867, const Cubic(0.33, 1, 0.68, 1));
  Animation<double> get _stagger3 =>
      _interval(0.578, 0.933, const Cubic(0.33, 1, 0.68, 1));
  Animation<double> get _stagger4 =>
      _interval(0.644, 1.0, const Cubic(0.33, 1, 0.68, 1));

  // ─── AUTH LOGIC (preserved from original) ─────────────────────────
  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? 'unknown_device';
  }

  Future<void> _initLogin() async {
    androidId = await getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('username');
    final savedPass = prefs.getString('password');
    final savedKey = prefs.getString('key');

    if (savedUser == null || savedPass == null || savedKey == null) return;

    try {
      final uri = Uri.parse(
        '$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey',
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
              sessionKey: data['key']?.toString() ?? savedKey,
              expiredDate: data['expiredDate']?.toString() ?? '',
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
    } catch (_) {}
  }

  Future<void> _login() async {
    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showPopup(
        title: 'Login Gagal',
        message: 'Username dan password harus diisi.',
      );
      return;
    }

    setState(() => isLoading = true);
    _dotLoaderCtrl.repeat();

    try {
      final validate = await http.post(
        Uri.parse('$baseUrl/validate'),
        body: {
          'username': username,
          'password': password,
          'androidId': androidId ?? 'unknown_device',
        },
      );

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showPopup(
          title: 'Access Expired',
          message: 'Masa akses Anda telah habis.\nSilakan perpanjang akses.',
          showContact: true,
        );
      } else if (validData['valid'] != true) {
        final String errorMsg = (validData['message'] ?? '').toLowerCase();
        if (errorMsg.contains('perangkat') ||
            errorMsg.contains('device') ||
            errorMsg.contains('another')) {
          _showPopup(
            title: 'Sesi Aktif',
            message:
                'Akun ini sedang login di perangkat lain.\nSilakan logout terlebih dahulu di perangkat lama.',
          );
        } else {
          _showPopup(
            title: 'Login Gagal',
            message: 'Username atau password salah.',
          );
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('username', username);
        prefs.setString('password', password);
        prefs.setString('key', validData['key']);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SplashScreen(
                username: username,
                password: password,
                role: validData['role']?.toString() ?? '',
                sessionKey: validData['key']?.toString() ?? '',
                expiredDate: validData['expiredDate']?.toString() ?? '',
                listBug: (validData['listBug'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                listDoos: (validData['listDDoS'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
                news: (validData['news'] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
              ),
            ),
          );
        }
      }
    } catch (_) {
      _showPopup(
        title: 'Connection Error',
        message: 'Gagal terhubung ke server.\nPeriksa koneksi internet Anda.',
      );
    }

    if (mounted) {
      setState(() => isLoading = false);
      _dotLoaderCtrl.stop();
    }
  }

  void _showPopup({
    required String title,
    required String message,
    bool showContact = false,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Error Modal',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 200),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ErrorModal(
          title: title,
          message: message,
          showContact: showContact,
          onContact: () async {
            Navigator.of(context).pop();
            await launchUrl(Uri.parse('https://t.me/hafz_reals'),
                mode: LaunchMode.externalApplication);
          },
          onClose: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _particleCtrl.dispose();
    _dotLoaderCtrl.dispose();
    _sweepCtrl.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final spacerHeight =
        (screenHeight * 0.45 - 26 + topPadding).clamp(0.0, screenHeight);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. bg-layer (pattern + radial gradient)
          Positioned.fill(child: _buildBgLayer()),
          // 2. particles
          Positioned.fill(child: _buildParticles()),
          // 3. hero image (top 50%)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.5,
            child: _buildHero(),
          ),
          // 4. content (spacer + glass sheet)
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: spacerHeight),
                Expanded(child: _buildSheet(bottomPadding)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── BG-LAYER ─────────────────────────────────────────────────────
  Widget _buildBgLayer() {
    return AnimatedBuilder(
      animation: _bgFadeAnim,
      builder: (context, _) {
        return Opacity(
          opacity: _bgFadeAnim.value,
          child: Stack(
            children: [
              // SVG pattern
              Positioned.fill(child: CustomPaint(painter: _BgPatternPainter())),
              // Radial gradient at 50% 10%
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.8), // 50% 10%
                      radius: 0.6,
                      colors: [
                        _LpColors.accentDeep.withOpacity(0.45),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── PARTICLES ────────────────────────────────────────────────────
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleCtrl,
      builder: (context, _) {
        final t = _particleCtrl.value; // 0..1 alternating
        // Login keyframe: 0→0.25(15)→0.3(0)→0.25(-15)→0(0)
        double opacity, dy;
        if (t < 0.25) {
          final k = t / 0.25;
          opacity = k * 0.25;
          dy = k * 15.0;
        } else if (t < 0.5) {
          final k = (t - 0.25) / 0.25;
          opacity = 0.25 + k * (0.3 - 0.25);
          dy = 15.0 - k * 15.0;
        } else if (t < 0.75) {
          final k = (t - 0.5) / 0.25;
          opacity = 0.3 - k * (0.3 - 0.25);
          dy = 0.0 - k * 15.0;
        } else {
          final k = (t - 0.75) / 0.25;
          opacity = 0.25 - k * 0.25;
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
                  color: _LpColors.accentSoft.withOpacity(opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _LpColors.accentSoft.withOpacity(0.3),
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

  // ─── HERO ─────────────────────────────────────────────────────────
  Widget _buildHero() {
    return AnimatedBuilder(
      animation: _heroAnim,
      builder: (context, child) {
        final t = _heroAnim.value;
        final scale = 1.15 - 0.15 * t; // 1.15 → 1.0
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with brightness/saturation/contrast approximation
          CachedNetworkImage(
            imageUrl: 'https://files.catbox.moe/ial4tu.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.25), // brightness 0.75
            colorBlendMode: BlendMode.darken,
            placeholder: (_, __) => Container(color: _LpColors.bgDark),
            errorWidget: (_, __, ___) => Container(color: _LpColors.bgDark),
          ),
          // Bottom gradient fade: rgba(5,6,10,0.2) 10% → bg-dark 96%
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _LpColors.bgDark.withOpacity(0.2),
                  _LpColors.bgDark,
                ],
                stops: const [0.1, 0.96],
              ),
            ),
          ),
          // Glow line at bottom (left 10% right 10%)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _lineGlowAnim,
              builder: (context, _) {
                return Opacity(
                  opacity: _lineGlowAnim.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.1 * 0), // 10% margins via fractional
                    child: FractionallySizedBox(
                      widthFactor: 0.8,
                      child: Center(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                _LpColors.accentRed,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _LpColors.accentRed,
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── GLASS BOTTOM SHEET ───────────────────────────────────────────
  Widget _buildSheet(double bottomPadding) {
    return AnimatedBuilder(
      animation: _sheetAnim,
      builder: (context, child) {
        final t = _sheetAnim.value;
        return Transform.translate(
          offset: Offset(0, (1 - t) * MediaQuery.of(context).size.height * 0.6),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0, 0),
                end: const Alignment(0, 1),
                colors: [
                  const Color(0xD914050A), // rgba(20,5,10,0.85)
                  const Color(0xF205060A), // rgba(5,6,10,0.95)
                ],
              ),
              border: Border(
                top: BorderSide(color: _LpColors.glassBorder, width: 1),
                left: BorderSide(color: _LpColors.glassBorder, width: 1),
                right: BorderSide(color: _LpColors.glassBorder, width: 1),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 50,
                  offset: const Offset(0, -20),
                ),
                BoxShadow(
                  color: _LpColors.accentDeep.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(30, 18, 30, 28 + bottomPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _LpColors.accentRed.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Title
                  _Stagger(
                    animation: _stagger1,
                    child: Text(
                      'Netherite Executor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: _LpColors.accentRed.withOpacity(0.5),
                            blurRadius: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Badge
                  _Stagger(
                    animation: _stagger1,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _LpColors.accentRed.withOpacity(0.1),
                        border: Border.all(color: _LpColors.accentRed.withOpacity(0.3), width: 1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Silahkan login terlebih dahulu',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10.5,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Form
                  _Stagger(
                    animation: _stagger2,
                    child: _LoginInput(
                      controller: userController,
                      label: 'USERNAME',
                      icon: Icons.person_outline_rounded,
                      placeholder: 'Masukkan username',
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Stagger(
                    animation: _stagger3,
                    child: _LoginInput(
                      controller: passController,
                      label: 'PASSWORD',
                      icon: Icons.lock_outline_rounded,
                      placeholder: 'Masukkan password',
                      isPassword: true,
                      obscurePassword: _obscurePassword,
                      onTogglePassword: () {
                        HapticFeedback.lightImpact();
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Stagger(
                    animation: _stagger4,
                    child: _buildLoginButton(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── LOGIN BUTTON ─────────────────────────────────────────────────
  Widget _buildLoginButton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: isLoading ? null : _login,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            width: isLoading ? 54.0 : constraints.maxWidth,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_LpColors.accentDeep, _LpColors.accentRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isLoading ? 27 : 18),
              boxShadow: [
                BoxShadow(
                  color: _LpColors.accentRed.withOpacity(isLoading ? 0.2 : 0.35),
                  blurRadius: isLoading ? 20 : 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Sweep light (only when not loading)
                if (!isLoading)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AnimatedBuilder(
                        animation: _sweepCtrl,
                        builder: (context, _) {
                          final t = _sweepCtrl.value; // 0..1
                          // Sweep from left to right
                          final sweepWidth = 80.0;
                          final totalWidth = constraints.maxWidth;
                          final x = -sweepWidth + t * (totalWidth + sweepWidth);
                          return Stack(
                            children: [
                              Positioned(
                                left: x,
                                top: 0,
                                bottom: 0,
                                width: sweepWidth,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withOpacity(0.15),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                // Content
                if (isLoading)
                  _buildDotLoader()
                else
                  const Text(
                    'Masuk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── 3-DOT LOADER ─────────────────────────────────────────────────
  Widget _buildDotLoader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _dotLoaderCtrl,
          builder: (context, _) {
            // dotPulse: 0%, 80%, 100% → scale 0.6, opacity 0.4
            //            40% → scale 1, opacity 1
            // With delays: 0, 0.15s, 0.3s (on 1.1s period)
            final delay = i * 0.15 / 1.1; // as fraction of period
            double t = (_dotLoaderCtrl.value - delay) % 1.0;
            if (t < 0) t += 1.0;
            double scale, opacity;
            if (t < 0.4) {
              final k = t / 0.4;
              scale = 0.6 + k * 0.4; // 0.6 → 1.0
              opacity = 0.4 + k * 0.6; // 0.4 → 1.0
            } else if (t < 0.8) {
              final k = (t - 0.4) / 0.4;
              scale = 1.0 - k * 0.4; // 1.0 → 0.6
              opacity = 1.0 - k * 0.6; // 1.0 → 0.4
            } else {
              scale = 0.6;
              opacity = 0.4;
            }
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ─── LOGIN INPUT (focus-aware) ──────────────────────────────────────
class _LoginInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String placeholder;
  final bool isPassword;
  final bool obscurePassword;
  final VoidCallback? onTogglePassword;

  const _LoginInput({
    required this.controller,
    required this.label,
    required this.icon,
    required this.placeholder,
    this.isPassword = false,
    this.obscurePassword = true,
    this.onTogglePassword,
  });

  @override
  State<_LoginInput> createState() => _LoginInputState();
}

class _LoginInputState extends State<_LoginInput> {
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: _LpColors.textDim,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hasFocus
                ? _LpColors.accentRed.withOpacity(0.05)
                : Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hasFocus
                  ? _LpColors.accentRed.withOpacity(0.6)
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: _LpColors.accentRed.withOpacity(0.1),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: _hasFocus
                    ? _LpColors.accentSoft
                    : _LpColors.textDim,
                size: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: widget.isPassword ? widget.obscurePassword : false,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                  cursorColor: _LpColors.accentSoft,
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.28)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.isPassword)
                GestureDetector(
                  onTap: widget.onTogglePassword,
                  child: Icon(
                    widget.obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: _LpColors.textDim,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── ERROR MODAL (shake-in glass card) ──────────────────────────────
class _ErrorModal extends StatefulWidget {
  final String title;
  final String message;
  final bool showContact;
  final VoidCallback? onContact;
  final VoidCallback onClose;

  const _ErrorModal({
    required this.title,
    required this.message,
    this.showContact = false,
    this.onContact,
    required this.onClose,
  });

  @override
  State<_ErrorModal> createState() => _ErrorModalState();
}

class _ErrorModalState extends State<_ErrorModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // shakeIn: scale 0.8→1 in first 20%, opacity 0→1 in first 20%
    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.2, curve: Curves.easeOut)),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.2)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // shakeIn translateX keyframes:
  // 20%: -10, 40%: 10, 60%: -5, 80%: 5, 100%: 0
  double get _translateX {
    final t = _ctrl.value;
    if (t < 0.2) return 0;
    if (t < 0.4) return -10 + (t - 0.2) / 0.2 * 20;
    if (t < 0.6) return 10 - (t - 0.4) / 0.2 * 15;
    if (t < 0.8) return -5 + (t - 0.6) / 0.2 * 10;
    return 5 - (t - 0.8) / 0.2 * 5;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_translateX, 0),
              child: Transform.scale(
                scale: _scale.value,
                child: Opacity(opacity: _opacity.value, child: child),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xE614050A), // rgba(20,5,10,0.9)
                  const Color(0xF205060A), // rgba(5,6,10,0.95)
                ],
              ),
              border: Border.all(color: _LpColors.glassBorder, width: 1),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _LpColors.accentRed.withOpacity(0.15),
                    border: Border.all(
                      color: _LpColors.accentRed.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: _LpColors.accentSoft,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.showContact) ...[
                      _ModalButton(
                        label: 'Contact Admin',
                        isPrimary: false,
                        onTap: widget.onContact ?? () {},
                      ),
                      const SizedBox(width: 8),
                    ],
                    _ModalButton(
                      label: 'Tutup',
                      isPrimary: true,
                      onTap: widget.onClose,
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

// ─── MODAL BUTTON ───────────────────────────────────────────────────
class _ModalButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ModalButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_ModalButton> createState() => _ModalButtonState();
}

class _ModalButtonState extends State<_ModalButton> {
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
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: widget.isPrimary
              ? BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_LpColors.accentDeep, _LpColors.accentRed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                )
              : BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.isPrimary
                  ? Colors.white
                  : Colors.white.withOpacity(0.7),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
