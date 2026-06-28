import 'dart:math' as dart_math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dashboard_page.dart';

const String baseUrl = "http://szxennofficial.qoupayid.xyz:3591";

// ─── METALLIC RED THEME COLORS ──────────────────────────────────────────────
class _C {
  static const bg          = Color(0xFF0A0A0A);
  static const surface     = Color(0xFF1A1A1A);
  static const surface2    = Color(0xFF262626);
  static const surface3    = Color(0xFF2D2D2D);
  
  // Metallic Red Gradient Colors
  static const red1        = Color(0xFFFF1744);  // Bright Red
  static const red2        = Color(0xFFD50000);  // Deep Red
  static const red3        = Color(0xFFB71C1C);  // Dark Red
  static const red4        = Color(0xFF880E4F);  // Burgundy
  
  // Metallic accents
  static const gold        = Color(0xFFFFD700);
  static const silver      = Color(0xFFC0C0C0);
  static const chrome      = Color(0xFFE8E8E8);
  
  static const error       = Color(0xFFFF1744);
  static const warning     = Color(0xFFFFAB40);
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSec     = Color(0xFFB0B0B0);
  static const textMuted   = Color(0xFF707070);
  static const shadow      = Color(0x40000000);
  static const shadowHeavy = Color(0x80000000);
}

// ─── METALLIC HEX BACKGROUND PAINTER ──────────────────────────────────────
class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Metallic radial gradients
    final g1 = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.red1.withOpacity(0.12), 
          _C.red3.withOpacity(0.05), 
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.65));
    canvas.drawCircle(Offset.zero, size.width * 0.65, g1);

    final g2 = Paint()
      ..shader = RadialGradient(
        colors: [
          _C.red4.withOpacity(0.10), 
          Colors.transparent
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: size.width * 0.55));
    canvas.drawCircle(Offset(size.width, size.height), size.width * 0.55, g2);

    // Metallic hex grid
    const hexW = 60.0;
    final hexH = hexW * dart_math.sqrt(3) / 2;
    final cols = (size.width / hexW).ceil() + 2;
    final rows = (size.height / hexH).ceil() + 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _C.red1.withOpacity(0.04);

    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final x = col * hexW + (row % 2) * hexW / 2;
        final y = row * hexH * 0.75;
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = i * dart_math.pi * 2 / 6;
          final px = x + hexW / 2 + dart_math.cos(angle) * hexW / 2;
          final py = y + hexH / 2 + dart_math.sin(angle) * hexH / 2;
          if (i == 0) path.moveTo(px, py); else path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override bool shouldRepaint(covariant CustomPainter _) => false;
}

// ─── LOGIN PAGE ──────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final userController = TextEditingController();
  final passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  bool _obscurePassword = true;
  String? androidId;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    initLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    userController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> initLogin() async {
    androidId = await _getAndroidId();
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey  = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse("$baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");
      try {
        final res  = await http.get(uri);
        final data = jsonDecode(res.body);
        if (data['valid'] == true) {
          Navigator.pushReplacement(context, _fadeRoute(SplashScreen(
            username: savedUser, password: savedPass,
            role: (data['role'] ?? '').toString(),
            sessionKey: data['key'], expiredDate: data['expiredDate'],
            listBug:  (data['listBug']   as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            listDoos: (data['listDDoS']  as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            news:     (data['news']      as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          )));
        }
      } catch (_) {}
    }
  }

  Future<String> _getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  PageRouteBuilder _fadeRoute(Widget page) => PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic))), child: child),
  );

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    final username = userController.text.trim();
    final password = passController.text.trim();
    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/validate"),
        body: {"username": username, "password": password, "androidId": androidId ?? "unknown_device"},
      );
      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showPopup(title: "⏳ Access Expired", message: "Your access has expired.\nPlease renew it.", color: _C.warning, showContact: true);
      } else if (validData['valid'] != true) {
        _showPopup(title: "Login Failed", message: "Invalid username or password.", color: _C.red1);
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);
        Navigator.pushReplacement(context, _fadeRoute(SplashScreen(
          username: username, password: password,
          role: (validData['role'] ?? '').toString(),
          sessionKey: validData['key'], expiredDate: validData['expiredDate'],
          listBug:  (validData['listBug']   as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          listDoos: (validData['listDDoS']  as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
          news:     (validData['news']      as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        )));
      }
    } catch (_) {
      _showPopup(title: "Connection Error", message: "Failed to connect to the server.\nPlease check your internet connection.", color: _C.error);
    }

    setState(() => isLoading = false);
  }

  void _showPopup({required String title, required String message, Color color = _C.red1, bool showContact = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
        ),
        title: Text(
          title, 
          style: TextStyle(
            color: color, 
            fontWeight: FontWeight.bold, 
            fontSize: 18,
          )
        ),
        content: Text(
          message, 
          style: const TextStyle(color: _C.textSec, fontSize: 14),
        ),
        actions: [
          if (showContact)
            TextButton(
              onPressed: () async => await launchUrl(Uri.parse("https://t.me/hafz_reals"), mode: LaunchMode.externalApplication),
              child: Text(
                "Contact Admin", 
                style: TextStyle(color: _C.red1),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Close", 
              style: TextStyle(color: _C.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: Stack(
        children: [
          // Hex background
          CustomPaint(
            size: Size.infinite,
            painter: _HexPainter(),
            child: const SizedBox.expand(),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo with Metallic Effect ──
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.5, end: 1.0),
                        curve: Curves.easeOutBack,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [_C.red1, _C.red4, _C.red2],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: _C.red1.withOpacity(0.4), blurRadius: 30, spreadRadius: 4),
                              BoxShadow(color: _C.red4.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                              BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15),
                            ],
                            border: Border.all(
                              color: _C.gold.withOpacity(0.3), 
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.asset('assets/images/logo.jpg', fit: BoxFit.cover),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Metallic Title ──
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 600),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
                        ),
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [_C.gold, _C.red1, _C.gold],
                                stops: [0.0, 0.5, 1.0],
                              ).createShader(bounds),
                              child: const Text(
                                "Netherite Executor",
                                style: TextStyle(
                                  fontSize: 26, 
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white, 
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_C.red1.withOpacity(0.1), _C.red4.withOpacity(0.1)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _C.red1.withOpacity(0.2), width: 1),
                              ),
                              child: const Text(
                                "SIGN IN TO CONTINUE",
                                style: TextStyle(
                                  color: _C.textSec, 
                                  fontSize: 12, 
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Metallic Form Card ──
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 700),
                        tween: Tween(begin: 0.9, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, child) => Transform.scale(scale: v, child: child),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _C.surface,
                                _C.surface2,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _C.red1.withOpacity(0.15), 
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(color: _C.red1.withOpacity(0.08), blurRadius: 30, spreadRadius: 2),
                              BoxShadow(color: _C.red4.withOpacity(0.05), blurRadius: 20),
                              const BoxShadow(color: _C.shadowHeavy, blurRadius: 15, offset: Offset(0, 8)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: userController,
                                  label: "Username",
                                  icon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: passController,
                                  label: "Password",
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  isPassword: true,
                                ),
                                const SizedBox(height: 24),

                                // ── Metallic Login Button ──
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: _AnimatedLoginButton(
                                    isLoading: isLoading,
                                    onPressed: login,
                                    gradient: const LinearGradient(
                                      colors: [_C.red1, _C.red3, _C.red4],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Metallic Footer ──
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _C.red1.withOpacity(0.1), width: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Netherite PRODUCER",
                          style: TextStyle(
                            color: _C.textMuted, 
                            fontSize: 10,
                            letterSpacing: 4, 
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.85, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Transform.scale(scale: v, child: child),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: _C.textPrimary, 
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: _C.textSec, 
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: _C.red1, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      key: ValueKey(_obscurePassword),
                      color: _C.textMuted,
                      size: 22,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                )
              : null,
          filled: true,
          fillColor: _C.surface2.withOpacity(0.6),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: _C.red1.withOpacity(0.15), 
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: _C.red1, 
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _C.error, width: 2),
          ),
          errorStyle: const TextStyle(
            color: _C.error, 
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Please enter $label" : null,
      ),
    );
  }
}

// ─── ANIMATED METALLIC LOGIN BUTTON ──────────────────────────────────────
class _AnimatedLoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final Gradient gradient;

  const _AnimatedLoginButton({
    required this.isLoading,
    required this.onPressed,
    required this.gradient,
  });

  @override State<_AnimatedLoginButton> createState() => _AnimatedLoginButtonState();
}

class _AnimatedLoginButtonState extends State<_AnimatedLoginButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glow;

  @override void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _glowCtrl.dispose(); super.dispose(); }

  void _handleTap() {
    if (widget.isLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _isPressed = false);
      widget.onPressed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => GestureDetector(
        onTap: _handleTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _isPressed ? 0.97 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _C.red1.withOpacity(0.35 * _glow.value), 
                  blurRadius: 25, 
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: _C.red3.withOpacity(0.20 * _glow.value), 
                  blurRadius: 15, 
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: _C.gold.withOpacity(0.05 * _glow.value),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 0),
                ),
              ],
              border: Border.all(
                color: _C.gold.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24, 
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5, 
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "SIGN IN",
                      style: TextStyle(
                        fontSize: 15, 
                        fontWeight: FontWeight.w900,
                        color: Colors.white, 
                        letterSpacing: 3,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1)),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}