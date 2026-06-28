import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'login_page.dart';
import 'splash.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  // --- WARNA BARU (Hitam, Abu-abu, Merah Gelap) ---
  final Color bgBlack = Colors.black;
  final Color greyDark = Colors.grey[800]!;
  final Color greyLight = Colors.grey[500]!;
  final Color redDark = const Color(0xFFB71C1C);

  final Color glassBorder = Colors.white.withOpacity(0.15);
  final Color cardBg = Colors.white.withOpacity(0.08);

  int _currentPage = 0;
  late AnimationController _indicatorAnimController;
  late Animation<double> _indicatorAnimation;
  final PageController _pageController = PageController();
  bool _isCheckingAuth = true;

  // Base URL
  static const String _baseUrl = 'http://szxennofficial.qoupayid.xyz:3591';

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();

    _indicatorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _indicatorAnimation = Tween<double>(begin: 6.0, end: 18.0).animate(
      CurvedAnimation(parent: _indicatorAnimController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString("username");
    final savedPass = prefs.getString("password");
    final savedKey = prefs.getString("key");

    if (savedUser == null || savedPass == null || savedKey == null) {
      setState(() => _isCheckingAuth = false);
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final androidId = android.id ?? "unknown_device";

      final uri = Uri.parse("$_baseUrl/myInfo?username=$savedUser&password=$savedPass&androidId=$androidId&key=$savedKey");
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
              listBug: (data['listBug'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
              listDoos: (data['listDDoS'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
              news: (data['news'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
            ),
          ),
        );
      } else {
        setState(() => _isCheckingAuth = false);
      }
    } catch (e) {
      setState(() => _isCheckingAuth = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _indicatorAnimController.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception("Could not launch $uri");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: bgBlack,
        body: const Center(child: CircularProgressIndicator(color: Colors.grey)),
      );
    }

    return Scaffold(
      backgroundColor: bgBlack,
      body: Stack(
        children: [
          // PageView untuk swipe up
          PageView(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() => _currentPage = page);
            },
            children: [
              // PAGE 1: WELCOME
              const Center(
                child: Text(
                  ".WELCOME.",
                  style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),

              // PAGE 2: DESKRIPSI (BAHASA INDONESIA)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Selamat Datang", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    Text(
                      "Selamat datang di komunitas kami! Kami sangat berterima kasih atas kehadiran Anda. Di sini, Anda dapat menikmati kenyamanan sambil memanfaatkan teknologi terbaru dan berbagai alat yang berguna. Jika Anda memiliki pertanyaan atau kendala, jangan ragu untuk menghubungi tim dukungan kami. Selamat menikmati pengalaman Anda!",
                      style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                    ),
                  ],
                ),
              ),

              // PAGE 3: LANDING ASLI (LOGIN + BUY)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      greyDark.withOpacity(0.5),
                      bgBlack,
                      Colors.black,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // LOGO menggunakan assets/images/logo.png
                        Container(
                          width: 320,
                          height: 400,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  "assets/images/executor.png",
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.all(8.0),
                                      alignment: Alignment.center,
                                      child: Text(
                                        "ERROR:\n${error.toString()}",
                                        style: const TextStyle(color: Colors.red, fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [greyLight, Colors.white],
                                      ).createShader(bounds),
                                      child: const Text(
                                        "Silakan Login atau Beli Akses untuk melanjutkan",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 4,
                                              color: Colors.black,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // TOMBOL SIGN IN (MERAH GELAP)
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [redDark, Colors.red.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: redDark.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // TOMBOL BUY ACCESS (MERAH GELAP, BORDER SAJA)
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: redDark.withOpacity(0.7), width: 1.5),
                          ),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _openUrl("https://t.me/hafz_reals"),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag,
                                  color: redDark,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Beli Akses ke Owner",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: redDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Tombol Telegram Channel (abu-abu terang)
                        Row(
                          children: [
                            Expanded(
                              child: _buildContactButton(
                                icon: FontAwesomeIcons.telegram,
                                label: "Telegram Channel",
                                url: "https://t.me/NetheriteProject",
                                color: greyLight,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),
                        const Text("© 2026 Vanguard of Your Rising Empire", style: TextStyle(color: Colors.white38, fontSize: 11)),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // HEADER TETAP 
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("Netherite Executor", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(width: 5),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text("Version 1.0", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ),

          // FOOTER SWIPE (HILANG DI PAGE 3)
          Positioned(
            bottom: 30, left: 0, right: 0,
            child: Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _currentPage == 2 ? 0.0 : 1.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22, height: 45,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.topCenter,
                      child: AnimatedBuilder(
                        animation: _indicatorAnimation,
                        builder: (context, child) => Padding(
                          padding: EdgeInsets.only(top: _indicatorAnimation.value),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white54,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Geser ke atas untuk melanjutkan",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String url,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _openUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: cardBg,
          border: Border.all(color: glassBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}