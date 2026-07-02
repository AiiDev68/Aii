// ============================================================
//  ArchiverZ — Splash Screen (skippable, glassmorphism)
// ============================================================
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'config/app_config.dart';
import 'core/design_system.dart';
import 'login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late AnimationController _brandPulse;
  bool _fadeOutStarted = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _brandPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _videoController =
        VideoPlayerController.asset(AppConfig.splashVideoAsset)
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() {});
            _videoController.setLooping(false);
            _videoController.play();

            _videoController.addListener(() {
              final position = _videoController.value.position;
              final duration = _videoController.value.duration;
              if (duration != Duration.zero &&
                  position >= duration - const Duration(milliseconds: 700) &&
                  !_fadeOutStarted) {
                _fadeOutStarted = true;
                _fadeController.forward();
              }
              if (position >= duration) {
                _navigateToLogin();
              }
            });
          });

    // Fallback: if video fails to load, auto-advance after 3s
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_videoController.value.isInitialized && !_navigated) {
        _navigateToLogin();
      }
    });
  }

  void _navigateToLogin() {
    if (_navigated) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    _brandPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArchiverZColors.bg,
      body: Stack(
        children: [
          if (_videoController.value.isInitialized)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width,
                  height: _videoController.value.size.height,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          else
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                    gradient: ArchiverZColors.brandGradient),
                child: Center(
                  child: CircularProgressIndicator(
                    color: ArchiverZColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ArchiverZColors.bg.withOpacity(0.55),
                    Colors.transparent,
                    ArchiverZColors.bg.withOpacity(0.85),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Skip button (glassmorphism)
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, right: 16),
                child: GlassCard(
                  radius: 24,
                  padding: EdgeInsets.zero,
                  blurSigma: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        _videoController.pause();
                        _navigateToLogin();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.skip_next_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('SKIP', style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.5,
                              fontFamily: AppConfig.fontDisplay,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Hero branding
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 1.0, end: 1.08)
                          .animate(CurvedAnimation(
                        parent: _brandPulse,
                        curve: Curves.easeInOut,
                      )),
                      child: const ArchiverBrandMark(size: 92),
                    ),
                    const SizedBox(height: 22),
                    const ArchiverHeroTitle(
                      text: AppConfig.appName,
                      fontSize: 40,
                      letterSpacing: 4,
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
                  ],
                ),
              ),
            ),
          ),

          if (_fadeOutStarted)
            FadeTransition(
              opacity: _fadeController.drive(Tween(begin: 1.0, end: 0.0)),
              child: Container(color: ArchiverZColors.bg),
            ),
        ],
      ),
    );
  }
}
