// ============================================================
//  ArchiverZ — Login Page (glassmorphism redesign)
//  Rebranded from PPL V4 → ArchiverZ v4.0.0
// ============================================================
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:ui';
import 'config/app_config.dart';
import 'config/api.dart';
import 'core/design_system.dart';
import 'post_login_splash.dart';

final String baseUrl = Api.api;

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
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    initLogin();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();

    _videoController = VideoPlayerController.asset('assets/videos/login.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoController.setLooping(true);
        _videoController.play();
        _videoController.setVolume(0);
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> initLogin() async {
    androidId = await getAndroidId();

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser != null && savedPass != null && savedKey != null) {
      final uri = Uri.parse(
        "$baseUrl/api/auth/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey",
      );
      try {
        final res = await http.get(uri);
        final data = jsonDecode(res.body);

        if (data['valid'] == true && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PostLoginSplash(
                username: savedUser,
                password: savedPass,
                role: data['role'],
                sessionKey: data['key'],
                expiredDate: data['expiredDate'],
                listBug: List<Map<String, dynamic>>.from(data['listBug'] ?? []),
                listPayload: List<Map<String, dynamic>>.from(data['listPayload'] ?? []),
                listDDoS: List<Map<String, dynamic>>.from(data['listDDoS'] ?? []),
                news: List<Map<String, dynamic>>.from(data['news'] ?? []),
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  Future<String> getAndroidId() async {
    final deviceInfo = DeviceInfoPlugin();
    final android = await deviceInfo.androidInfo;
    return android.id ?? "unknown_device";
  }

  Future<void> login() async {
    final username = userController.text.trim();
    final password = passController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showAlert("Error", "Username and password are required.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final validate = await http.post(
        Uri.parse("$baseUrl/api/auth/validate"),
        body: {
          "username": username,
          "password": password,
          "androidId": androidId ?? "unknown_device",
        },
      );

      final validData = jsonDecode(validate.body);

      if (validData['expired'] == true) {
        _showAlert("Access Expired", "Your access has expired. Please renew it.", showContact: true);
      } else if (validData['valid'] != true) {
        _showAlert("Login Failed", "Invalid username or password.", showContact: true);
      } else {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("username", username);
        prefs.setString("password", password);
        prefs.setString("key", validData['key']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PostLoginSplash(
              username: username,
              password: password,
              role: validData['role'],
              sessionKey: validData['key'],
              expiredDate: validData['expiredDate'],
              listBug: List<Map<String, dynamic>>.from(validData['listBug'] ?? []),
              listPayload: List<Map<String, dynamic>>.from(validData['listPayload'] ?? []),
              listDDoS: List<Map<String, dynamic>>.from(validData['listDDoS'] ?? []),
              news: List<Map<String, dynamic>>.from(validData['news'] ?? []),
            ),
          ),
        );
      }
    } catch (_) {
      _showAlert("Connection Error", "Failed to connect to the server.");
    }

    if (mounted) setState(() => isLoading = false);
  }

  void _showAlert(String title, String msg, {bool showContact = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ArchiverZColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ArchiverZColors.glassFill(opacity: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                title.contains("Error") || title.contains("Failed")
                    ? Icons.error_outline
                    : title.contains("Expired")
                    ? Icons.timer_off
                    : Icons.info_outline,
                color: title.contains("Error") || title.contains("Failed")
                    ? ArchiverZColors.danger
                    : title.contains("Expired")
                    ? Colors.amber
                    : ArchiverZColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: AppConfig.fontDisplay,
              ),
            ),
          ],
        ),
        content: Text(
          msg,
          style: TextStyle(
            color: ArchiverZColors.text.withOpacity(0.8),
            fontSize: 14,
            fontFamily: AppConfig.fontMono,
          ),
        ),
        actions: [
          if (showContact)
            TextButton.icon(
              onPressed: () async {
                await launchUrl(Uri.parse(AppConfig.telegramDev),
                    mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.message, size: 18, color: Colors.white),
              label: const Text(
                "Contact Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppConfig.fontDisplay,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: ArchiverZColors.primary.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CLOSE",
              style: TextStyle(
                color: Colors.white,
                fontFamily: AppConfig.fontDisplay,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: ArchiverZColors.glassFill(opacity: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTelegramBot() async {
    await launchUrl(Uri.parse(AppConfig.buyAccessUrl),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArchiverZColors.bg,
      body: Stack(
        children: [
          // Background video with blur
          SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.cover,
              child: _videoController.value.isInitialized
                  ? SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                          gradient: ArchiverZColors.brandGradient)),
            ),
          ),
          // Deep Space Glass gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ArchiverZColors.bg.withOpacity(0.7),
                  ArchiverZColors.bg.withOpacity(0.85),
                  ArchiverZColors.bg.withOpacity(0.95),
                ],
              ),
            ),
          ),
          // Login form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tendou Kei brand mark
                      Hero(
                        tag: 'brand-mark',
                        child: const ArchiverBrandMark(size: 110),
                      ),
                      const SizedBox(height: 24),

                      // App name + tagline
                      const ArchiverHeroTitle(
                        text: AppConfig.appName,
                        fontSize: 32,
                        letterSpacing: 3,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConfig.appTagline.toUpperCase(),
                        style: TextStyle(
                          color: ArchiverZColors.textDim,
                          fontSize: 11,
                          letterSpacing: 3,
                          fontFamily: AppConfig.fontMono,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Login form glass card
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        shadows: [
                          BoxShadow(
                            color: ArchiverZColors.primary.withOpacity(0.15),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        child: Column(
                          children: [
                            _glassInput("Username", userController, Icons.person),
                            const SizedBox(height: 16),
                            _glassInput("Password", passController, Icons.lock,
                                isPassword: true),
                            const SizedBox(height: 24),

                            // Login button (glow)
                            SizedBox(
                              width: double.infinity,
                              child: GlowButton(
                                label: "LOGIN",
                                icon: Icons.login_rounded,
                                onPressed: isLoading ? () {} : login,
                              ),
                            ),
                            if (isLoading) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: ArchiverZColors.primary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Buy account (outlined glow)
                      SizedBox(
                        width: double.infinity,
                        child: GlowButton(
                          label: "Buy Account",
                          icon: Icons.shopping_bag_outlined,
                          outlined: true,
                          onPressed: _openTelegramBot,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer
                      Text(
                        AppConfig.copyrightLine,
                        style: TextStyle(
                          color: ArchiverZColors.textDim,
                          fontSize: 10,
                          fontFamily: AppConfig.fontMono,
                        ),
                        textAlign: TextAlign.center,
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

  Widget _glassInput(String hint, TextEditingController controller, IconData icon,
      {bool isPassword = false}) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 12,
      blurSigma: 8,
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono, fontSize: 14),
        cursorColor: ArchiverZColors.primary,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: ArchiverZColors.primary, size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: ArchiverZColors.textDim,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(
            color: ArchiverZColors.textDim,
            fontFamily: AppConfig.fontMono,
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}
