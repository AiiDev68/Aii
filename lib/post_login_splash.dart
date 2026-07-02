// ============================================================
//  ArchiverZ — Post-Login Splash
//  Shows after successful login, before dashboard.
//  - Tendou Kei brand mark with cyan-purple glow ring
//  - Pulsing animation + particle background
//  - Auto-advances to dashboard after 2.5s
//  - User can tap to skip
// ============================================================
import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'core/design_system.dart';
import 'loader_page.dart';

class PostLoginSplash extends StatefulWidget {
  final String username;
  final String password;
  final String role;
  final String sessionKey;
  final String expiredDate;
  final List<Map<String, dynamic>> listBug;
  final List<Map<String, dynamic>> listPayload;
  final List<Map<String, dynamic>> listDDoS;
  final List<Map<String, dynamic>> news;

  const PostLoginSplash({
    super.key,
    required this.username,
    required this.password,
    required this.role,
    required this.sessionKey,
    required this.expiredDate,
    required this.listBug,
    required this.listPayload,
    required this.listDDoS,
    required this.news,
  });

  @override
  State<PostLoginSplash> createState() => _PostLoginSplashState();
}

class _PostLoginSplashState extends State<PostLoginSplash>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulse;
  late Animation<double> _fade;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();

    // Auto-advance after 2.5s
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _navigateToDashboard();
    });
  }

  void _navigateToDashboard() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DashboardPage(
          username: widget.username,
          password: widget.password,
          role: widget.role,
          sessionKey: widget.sessionKey,
          expiredDate: widget.expiredDate,
          listBug: widget.listBug,
          listPayload: widget.listPayload,
          listDDoS: widget.listDDoS,
          news: widget.news,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArchiverZColors.bg,
      body: GestureDetector(
        onTap: _navigateToDashboard,
        child: AnimatedArchiverBackground(
          child: SafeArea(
            child: Stack(
              children: [
                // Skip hint (top right)
                Positioned(
                  top: 16,
                  right: 16,
                  child: GlassCard(
                    radius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    blurSigma: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, color: ArchiverZColors.neonCyan, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'TAP TO SKIP',
                          style: TextStyle(
                            color: ArchiverZColors.textDim,
                            fontSize: 10,
                            fontFamily: AppConfig.fontMono,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center hero
                Center(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Greeting
                        Text(
                          'WELCOME, COMMANDER',
                          style: TextStyle(
                            color: ArchiverZColors.neonPurple,
                            fontSize: 11,
                            fontFamily: AppConfig.fontDisplay,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Pulsing brand mark with cyan-purple ring
                        ScaleTransition(
                          scale: _pulse,
                          child: const ArchiverBrandMark(size: 130),
                        ),
                        const SizedBox(height: 24),

                        // Username
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              ArchiverZColors.accentGradient.createShader(bounds),
                          child: Text(
                            widget.username.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: AppConfig.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: ArchiverZColors.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: ArchiverZColors.neonCyan.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.role.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: AppConfig.fontDisplay,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // App name + tagline
                        const ArchiverHeroTitle(
                          text: AppConfig.appName,
                          fontSize: 36,
                          letterSpacing: 5,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppConfig.appTagline.toUpperCase(),
                          style: TextStyle(
                            color: ArchiverZColors.textDim,
                            fontSize: 11,
                            letterSpacing: 3,
                            fontFamily: AppConfig.fontMono,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Loading indicator
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: ArchiverZColors.neonCyan,
                            strokeWidth: 2.5,
                            backgroundColor: ArchiverZColors.neonPurple.withOpacity(0.2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'INITIALIZING SYSTEM...',
                          style: TextStyle(
                            color: ArchiverZColors.textDim,
                            fontSize: 9,
                            letterSpacing: 2,
                            fontFamily: AppConfig.fontMono,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom footer
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      AppConfig.copyrightLine,
                      style: TextStyle(
                        color: ArchiverZColors.textDim,
                        fontSize: 10,
                        fontFamily: AppConfig.fontMono,
                      ),
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
