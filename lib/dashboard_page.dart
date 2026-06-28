import 'dart:async';
import 'dart:convert';
import 'dart:math' as dart_math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

import 'owner_page.dart';
import 'login_page.dart';
import 'device_dashboard.dart';
import 'tqto.dart';
import 'chat.dart';

// ─── METALLIC RED THEME COLORS ──────────────────────────────────────
class AppColors {
  static const bg            = Color(0xFF0A0A0A);
  static const surface       = Color(0xFF1A0A0A);
  static const surfaceLight  = Color(0xFF2D1111);
  static const surface2      = Color(0xFF3D1818);
  static const cardDark      = Color(0xFF0D0505);
  
  // Metallic Red Gradient
  static const red1          = Color(0xFFFF1744);
  static const red2          = Color(0xFFD50000);
  static const red3          = Color(0xFFB71C1C);
  static const red4          = Color(0xFF880E4F);
  
  // Metallic Accents
  static const gold          = Color(0xFFC0C0C0);
  static const silver        = Color(0xFFC0C0C0);
  static const chrome        = Color(0xFFE8E8E8);
  
  static const accent1       = Color(0xFFFF1744);
  static const accent2       = Color(0xFFD50000);
  static const accent3       = Color(0xFFB71C1C);
  static const success       = Color(0xFF4CAF50);
  static const warning       = Color(0xFFFFAB40);
  static const error         = Color(0xFFFF1744);
  
  static const textPrimary   = Color(0xFFFFF5F5);
  static const textSec       = Color(0xFFFFCDD2);
  static const textMuted     = Color(0xFF8B3A3A);
  
  static const shadow        = Color(0x40000000);
  static const shadowHeavy   = Color(0x80000000);
}

// ─── SHADOW UTILITIES ─────────────────────────────────────────────
class ShadowUtils {
  static List<BoxShadow> get soft {
    return const [
      BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
      BoxShadow(color: AppColors.shadowHeavy, blurRadius: 2, offset: Offset(0, 1)),
    ];
  }
  
  static List<BoxShadow> get medium {
    return const [
      BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4)),
      BoxShadow(color: AppColors.shadowHeavy, blurRadius: 4, offset: Offset(0, 2)),
    ];
  }
  
  static List<BoxShadow> get heavy {
    return const [
      BoxShadow(color: AppColors.shadow, blurRadius: 24, offset: Offset(0, 8)),
      BoxShadow(color: AppColors.shadowHeavy, blurRadius: 8, offset: Offset(0, 4)),
      BoxShadow(color: AppColors.shadowHeavy, blurRadius: 2, offset: Offset(0, 1)),
    ];
  }
  
  static List<BoxShadow> get card {
    return const [
      BoxShadow(color: AppColors.shadowHeavy, blurRadius: 20, offset: Offset(0, 10)),
      BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2)),
    ];
  }
}

// ─── ENHANCED GLASS CARD ──────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? borderColor;
  final Color? bgColor;
  final List<Color>? gradient;
  final bool hasShadow;
  final VoidCallback? onTap;

  const _GlassCard({
    required this.child,
    this.padding,
    this.radius = 24,
    this.borderColor,
    this.bgColor,
    this.gradient,
    this.hasShadow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget container = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient != null
            ? LinearGradient(colors: gradient!, begin: Alignment.topLeft, end: Alignment.bottomRight)
            : LinearGradient(
                colors: [AppColors.surface2, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        border: Border.all(
          color: borderColor ?? AppColors.red1.withOpacity(0.15),
          width: 0.5,
        ),
        boxShadow: hasShadow ? ShadowUtils.card : null,
      ),
      child: child,
    );
    
    if (onTap != null) {
      return _AnimatedCard(
        onTap: onTap!,
        child: container,
      );
    }
    
    return container;
  }
}

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedCard({required this.child, required this.onTap});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.98 : 1.0,
        child: widget.child,
      ),
    );
  }
}

// ─── ENHANCED HEXAGON BACKGROUND ───────────────────────────────────
class _HexBackground extends StatelessWidget {
  final Widget child;
  const _HexBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HexPainter(),
      child: child,
    );
  }
}

class _HexPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.red1.withOpacity(0.12), AppColors.red3.withOpacity(0.05), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: size.width * 0.6));
    canvas.drawCircle(Offset.zero, size.width * 0.6, glowPaint);
    
    final glowPaint2 = Paint()
      ..shader = RadialGradient(
        colors: [AppColors.red4.withOpacity(0.1), Colors.transparent],
      ).createShader(Rect.fromCircle(center: Offset(size.width, size.height), radius: size.width * 0.5));
    canvas.drawCircle(Offset(size.width, size.height), size.width * 0.5, glowPaint2);
    
    final hexWidth = 60.0;
    final hexHeight = hexWidth * dart_math.sqrt(3) / 2;
    final cols = (size.width / hexWidth).ceil() + 2;
    final rows = (size.height / hexHeight).ceil() + 2;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = AppColors.red1.withOpacity(0.03);
    
    for (int row = -1; row < rows; row++) {
      for (int col = -1; col < cols; col++) {
        final x = col * hexWidth + (row % 2) * hexWidth / 2;
        final y = row * hexHeight * 0.75;
        
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final angle = i * dart_math.pi * 2 / 6;
          final px = x + hexWidth / 2 + dart_math.cos(angle) * hexWidth / 2;
          final py = y + hexHeight / 2 + dart_math.sin(angle) * hexHeight / 2;
          if (i == 0) path.moveTo(px, py);
          else path.lineTo(px, py);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── PULSE DOT ────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _a = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withOpacity(_a.value),
        boxShadow: [BoxShadow(color: widget.color.withOpacity(0.5), blurRadius: 6)],
      ),
    ),
  );
}

// ─── TYPEWRITER TEXT ───────────────────────────────────────────────
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _TypewriterText({required this.text, required this.style});
  @override State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _charAnim;
  late Timer _restartTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: widget.text.length * 70));
    _charAnim = IntTween(begin: 0, end: widget.text.length).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
    _restartTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) { _ctrl.reset(); _ctrl.forward(); }
    });
  }
  @override void dispose() { _ctrl.dispose(); _restartTimer.cancel(); super.dispose(); }
  
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _charAnim,
      builder: (_, __) {
        final displayed = widget.text.substring(0, _charAnim.value);
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Text(displayed, style: widget.style),
          if (_charAnim.value < widget.text.length)
            Text('|', style: widget.style.copyWith(color: AppColors.red1)),
        ]);
      },
    );
  }
}

// ─── BANNER CAROUSEL ──────────────────────────────────────────────
class _BannerCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late PageController _pageCtrl;
  int _current = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    if (widget.banners.isNotEmpty) {
      _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        final next = (_current + 1) % widget.banners.length;
        _pageCtrl.animateToPage(next, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _autoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox();
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              final banner = widget.banners[i];
              final imagePath = banner['image'] ?? '';
              final text = banner['text'] ?? '';
              final subtext = banner['subtext'] ?? '';
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.red1.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.surface2,
                          child: const Icon(Icons.image_rounded, color: Colors.grey),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                shadows: [
                                  Shadow(color: Colors.black45, blurRadius: 4),
                                ],
                              ),
                            ),
                            if (subtext.isNotEmpty)
                              Text(
                                subtext,
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(color: Colors.black45, blurRadius: 4),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (di) => AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: di == _current ? 24 : 6,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: di == _current ? AppColors.gold : AppColors.textMuted.withOpacity(0.3),
              boxShadow: di == _current ? [BoxShadow(color: AppColors.gold.withOpacity(0.5), blurRadius: 4)] : null,
            ),
          )),
        ),
      ],
    );
  }
}

// ─── VIDEO BANNER WIDGET ──────────────────────────────────────────
class _VideoBanner extends StatefulWidget {
  final String videoPath;
  const _VideoBanner({required this.videoPath});

  @override
  State<_VideoBanner> createState() => _VideoBannerState();
}

class _VideoBannerState extends State<_VideoBanner> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoPath)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
      }).catchError((error) {
        debugPrint('Error loading video: $error');
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.red1.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: AppColors.red3.withOpacity(0.1),
            blurRadius: 15,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _isInitialized && _controller.value.isInitialized
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    // Tombol Play/Pause
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.gold.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    // Progress bar sederhana
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        color: Colors.black.withOpacity(0.3),
                        child: FractionallySizedBox(
                          widthFactor: _controller.value.isInitialized
                              ? _controller.value.position.inMilliseconds /
                                  _controller.value.duration.inMilliseconds
                              : 0,
                          child: Container(
                            color: AppColors.red1,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Container(
                  color: AppColors.surface2,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.red1,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Loading video...',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── ENHANCED THANKS TO WIDGET ─────────────────────────────────────
class _ThanksToWidget extends StatelessWidget {
  const _ThanksToWidget();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 20,
      borderColor: AppColors.gold.withOpacity(0.3),
      gradient: [AppColors.surface2.withOpacity(0.95), AppColors.cardDark.withOpacity(0.95)],
      onTap: () => Navigator.push(context, _createRoute(const ThanksToPage())),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.red1, AppColors.red3]),
              borderRadius: BorderRadius.circular(14),
              boxShadow: ShadowUtils.soft,
              border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 0.5),
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Thanks To', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Orang orang yang berkontribusi', style: TextStyle(color: AppColors.textSec, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gold, size: 14),
        ],
      ),
    );
  }
}

// ─── SELECT DEVICES WIDGET ─────────────────────────────────────
class _SelectDevicesWidget extends StatefulWidget {
  final String sessionKey;
  const _SelectDevicesWidget({required this.sessionKey});

  @override
  State<_SelectDevicesWidget> createState() => _SelectDevicesWidgetState();
}

class _SelectDevicesWidgetState extends State<_SelectDevicesWidget> {
  List<dynamic> _devices = [];
  bool _loading = true;
  static const String _kBase = 'http://szxennofficial.qoupayid.xyz:3591';

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final response = await http.get(
        Uri.parse('$_kBase/rat/my-devices?key=${widget.sessionKey}'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['valid'] == true) {
          setState(() {
            _devices = body['devices'] ?? [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 20,
      borderColor: AppColors.red1.withOpacity(0.2),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.red1, AppColors.red3]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.devices_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'SELECT DEVICES',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '${_devices.length} devices',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.red1))
          else if (_devices.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Belum ada device terhubung',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _devices.length,
                itemBuilder: (ctx, i) {
                  final d = _devices[i];
                  final isOnline = d['online'] == true;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.red1.withOpacity(0.1) : AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOnline ? AppColors.red1.withOpacity(0.3) : AppColors.textMuted.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phone_android_rounded,
                          color: isOnline ? AppColors.red1 : AppColors.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          d['model']?.toString() ?? 'Unknown',
                          style: TextStyle(
                            color: isOnline ? AppColors.textPrimary : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isOnline ? AppColors.success : AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── TELEGRAM COMMUNITY WIDGET ────────────────────────────────────
class _TelegramCommunityWidget extends StatelessWidget {
  const _TelegramCommunityWidget();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 20,
      borderColor: AppColors.gold.withOpacity(0.3),
      gradient: [AppColors.surface2.withOpacity(0.95), AppColors.cardDark.withOpacity(0.95)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.red1, AppColors.red3]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: ShadowUtils.soft,
                  border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 0.5),
                ),
                child: const Icon(FontAwesomeIcons.telegram, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telegram Community',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'Gabung ke grup telegram kami untuk mendapatkan berita terbaru, bantuan support dari admin, serta berdiskusi bersama anggota lainnya secara langsung.',
                      style: TextStyle(color: AppColors.textSec, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse('https://t.me/NetheriteProject');
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.red1, AppColors.red3]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: ShadowUtils.soft,
                border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 0.5),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.telegram, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Join Community',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MAIN DASHBOARD PAGE ───────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  final String username, password, role, expiredDate, sessionKey;
  final List<Map<String, dynamic>> listBug, listDoos;
  final List<dynamic> news;

  const DashboardPage({super.key, required this.username, required this.password, required this.role,
    required this.expiredDate, required this.listBug, required this.listDoos, required this.sessionKey, required this.news});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

const String _kBase = 'http://szxennofficial.qoupayid.xyz:3591';

Route _createRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const curve = Curves.easeOutCubic;
      var tween = Tween(begin: const Offset(0.03, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);
      var fadeTween = Tween(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: curve));
      var fadeAnimation = animation.drive(fadeTween);
      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: offsetAnimation,
          child: child,
        ),
      );
    },
  );
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late WebSocketChannel channel;
  late String sessionKey, username, role, expiredDate;
  String androidId = "unknown";
  int _bottomNavIndex = 0;
  Widget _selectedPage = const SizedBox();

  @override
  void initState() {
    super.initState();
    sessionKey = widget.sessionKey; username = widget.username; role = widget.role;
    expiredDate = widget.expiredDate;
    
    _fadeCtrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic);
    _fadeCtrl.forward();
    
    _selectedPage = _buildDashboardHome();
    _initAndroidIdAndConnect();
  }

  Future<void> _initAndroidIdAndConnect() async {
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    androidId = deviceInfo.id;
    _connectWebSocket();
  }

  void _connectWebSocket() {
    channel = WebSocketChannel.connect(Uri.parse('wss://ws:papi.queen-official.com:5021:4000'));
    channel.sink.add(jsonEncode({"type": "validate", "key": sessionKey, "androidId": androidId}));
    channel.stream.listen((event) {
      final data = jsonDecode(event);
      if (data['type'] == 'myInfo' && data['valid'] == false) _showSessionExpired();
    });
  }

  void _showSessionExpired() async {
    await SharedPreferences.getInstance().then((p) => p.clear());
    if (!mounted) return;
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _GlassCard(radius: 24,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.error, AppColors.red3]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            const Text("Session Expired", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text("Silakan login kembali", style: TextStyle(color: AppColors.textSec)),
            const SizedBox(height: 16),
            _AnimatedDialogButton(
              text: "OK",
              onTap: () => Navigator.pushAndRemoveUntil(context, _createRoute(const LoginPage()), (r) => false),
            ),
          ]),
        ),
      ),
    );
  }

  void _onNavTapped(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _bottomNavIndex = index;
      if (index == 0) {
        _selectedPage = _buildDashboardHome();
      } else if (index == 1) {
        _selectedPage = ChatPage(
          username: username,
          sessionKey: sessionKey,
        );
      } else if (index == 2) {
        _selectedPage = DeviceDashboardPage(username: username, role: role, sessionKey: sessionKey);
      }
    });
  }

  void _navigateToOwner() => Navigator.push(context, _createRoute(OwnerPage(sessionKey: sessionKey, username: username)));
  void _showAccountSheet() => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (_) => _AccountSheet(username: username, role: role, expiredDate: expiredDate, onLogout: _showLogoutDialog));

  Widget _buildDashboardHome() {
    return _HexBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        physics: const BouncingScrollPhysics(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Main Banner Video - FIXED
          const _VideoBanner(
            videoPath: 'assets/videos/flux.mp4',
          ),
          const SizedBox(height: 16),
          const _ThanksToWidget(),
          const SizedBox(height: 16),
          // Banner Carousel
          _BannerCarousel(banners: const [
            {'image': 'assets/images/p.jpg', 'text': 'Netherite Executor'},
          ]),
          const SizedBox(height: 16),
          _SelectDevicesWidget(sessionKey: sessionKey),
          const SizedBox(height: 16),
          const _TelegramCommunityWidget(),
        ]),
      ),
    );
  }

  // ─── FLOATING PILL BOTTOM NAVIGATION ────────────────────────────────────
  Widget _buildBottomNav() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.red1.withOpacity(0.25),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.red1.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _FloatingNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Dashboard',
                isActive: _bottomNavIndex == 0,
                onTap: () => _onNavTapped(0),
              ),
              _FloatingNavItem(
                icon: Icons.devices_outlined,
                activeIcon: Icons.devices_rounded,
                label: 'Device',
                isActive: _bottomNavIndex == 2,
                onTap: () => _onNavTapped(2),
              ),
              _FloatingNavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Chat',
                isActive: _bottomNavIndex == 1,
                onTap: () => _onNavTapped(1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      toolbarHeight: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Builder(
          builder: (ctx) => IconButton(
            icon: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: 18, height: 2, color: AppColors.gold),
              const SizedBox(height: 4),
              Container(width: 12, height: 2, color: AppColors.gold.withOpacity(0.6)),
              const SizedBox(height: 4),
              Container(width: 8, height: 2, color: AppColors.gold.withOpacity(0.3)),
            ]),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      title: const _TypewriterText(
        text: 'Netherite Executor', 
        style: TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 17, 
          letterSpacing: 3,
          color: Colors.white,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _ProfileAvatar(onTap: _showAccountSheet),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.red1, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surface,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.red1, AppColors.red3], begin: Alignment.topLeft, end: Alignment.bottomRight),
            border: Border(bottom: BorderSide(color: AppColors.gold.withOpacity(0.2))),
          ),
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 500),
                tween: Tween<double>(begin: 0.8, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Transform.scale(scale: value, child: child),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: ShadowUtils.heavy,
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.transparent,
                    child: Icon(Icons.person_outline, color: Colors.white, size: 40),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(username, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                ),
                child: Text(role.toUpperCase(), style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [
            if (role.toLowerCase() == 'owner')
              _DrawerItem(icon: Icons.storefront_rounded, title: 'Owner Page', onTap: () { Navigator.pop(context); _navigateToOwner(); }),
            const SizedBox(height: 8),
            Divider(color: AppColors.surface2),
            const SizedBox(height: 8),
            _DrawerItem(icon: Icons.logout_rounded, title: 'Logout', color: AppColors.error, onTap: () { Navigator.pop(context); _showLogoutDialog(); }),
            const SizedBox(height: 20),
            const Center(child: Text("POWERED BY HAFZ DAN AIISIGMA", style: TextStyle(color: AppColors.textMuted, fontSize: 9, letterSpacing: 2))),
          ]),
        ),
      ]),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: _GlassCard(radius: 24,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.warning, AppColors.red3]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            const Text("Konfirmasi Logout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text("Yakin ingin logout?", style: TextStyle(color: AppColors.textSec)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
              const SizedBox(width: 8),
              _AnimatedDialogButton(
                text: "Logout",
                onTap: () async {
                  Navigator.pop(context);
                  await SharedPreferences.getInstance().then((p) => p.clear());
                  if (mounted) Navigator.pushAndRemoveUntil(context, _createRoute(const LoginPage()), (r) => false);
                },
                isError: true,
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      extendBody: true,
      body: FadeTransition(opacity: _fadeAnim, child: _selectedPage),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  @override void dispose() {
    channel.sink.close(status.goingAway);
    _fadeCtrl.dispose();
    super.dispose();
  }
}

// ─── FLOATING NAV ITEM ──────────────────────────────────────────────
class _FloatingNavItem extends StatefulWidget {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FloatingNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_FloatingNavItem> createState() => _FloatingNavItemState();
}

class _FloatingNavItemState extends State<_FloatingNavItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: _isPressed ? 0.94 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              decoration: widget.isActive
                  ? BoxDecoration(
                      color: AppColors.surface2.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.gold.withOpacity(0.5),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.red1.withOpacity(0.2),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                child: Row(
                  mainAxisAlignment: widget.isActive
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.isActive
                            ? (widget.activeIcon ?? widget.icon)
                            : widget.icon,
                        key: ValueKey(widget.isActive),
                        color: widget.isActive
                            ? AppColors.gold
                            : AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                    if (widget.isActive) ...[
                      const SizedBox(width: 8),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: widget.isActive ? 1.0 : 0.0,
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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

class _ProfileAvatar extends StatefulWidget {
  final VoidCallback onTap;

  const _ProfileAvatar({required this.onTap});

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.92 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [AppColors.red1, AppColors.red3]),
            boxShadow: ShadowUtils.soft,
            border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1),
          ),
          child: const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.transparent,
            child: Icon(Icons.person_outline, color: Colors.white, size: 16),
          ),
        ),
      ),
    );
  }
}

// ─── DRAWER ITEM ────────────────────────────────────────────────────
class _DrawerItem extends StatefulWidget {
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
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.98 : 1.0,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red1.withOpacity(0.2)),
            ),
            child: Icon(widget.icon, color: widget.color ?? AppColors.gold, size: 18),
          ),
          title: Text(widget.title, style: TextStyle(color: widget.color ?? Colors.white, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

// ─── ANIMATED DIALOG BUTTON ─────────────────────────────────────────
class _AnimatedDialogButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isError;

  const _AnimatedDialogButton({
    required this.text,
    required this.onTap,
    this.isError = false,
  });

  @override
  State<_AnimatedDialogButton> createState() => _AnimatedDialogButtonState();
}

class _AnimatedDialogButtonState extends State<_AnimatedDialogButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.95 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.isError
                ? const LinearGradient(colors: [AppColors.error, AppColors.red3])
                : const LinearGradient(colors: [AppColors.red1, AppColors.red3]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withOpacity(0.2)),
          ),
          child: Text(
            widget.text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ─── ACCOUNT BOTTOM SHEET ───────────────────────────────────────────
class _AccountSheet extends StatelessWidget {
  final String username, role, expiredDate;
  final VoidCallback onLogout;
  const _AccountSheet({required this.username, required this.role, required this.expiredDate, required this.onLogout});

  @override Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: ShadowUtils.heavy,
        border: Border(top: BorderSide(color: AppColors.gold.withOpacity(0.2))),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.red1, AppColors.red3]),
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(height: 16),
        TweenAnimationBuilder(
          duration: const Duration(milliseconds: 400),
          tween: Tween<double>(begin: 0.8, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [AppColors.red1, AppColors.red3]),
              boxShadow: ShadowUtils.medium,
              border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 2),
            ),
            child: const CircleAvatar(
              radius: 35,
              backgroundColor: Colors.transparent,
              child: Icon(Icons.person_outline, color: Colors.white, size: 35),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(username, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Text(role.toUpperCase(), style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tutup", style: TextStyle(color: Colors.grey)))),
          Expanded(
            child: _AnimatedSheetButton(
              text: "Logout",
              onTap: () { Navigator.pop(context); onLogout(); },
              isError: true,
            ),
          ),
        ]),
      ]),
    );
  }
}

class _AnimatedSheetButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final bool isError;

  const _AnimatedSheetButton({
    required this.text,
    required this.onTap,
    this.isError = false,
  });

  @override
  State<_AnimatedSheetButton> createState() => _AnimatedSheetButtonState();
}

class _AnimatedSheetButtonState extends State<_AnimatedSheetButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: _isPressed ? 0.97 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.isError
                ? const LinearGradient(colors: [AppColors.error, AppColors.red3])
                : const LinearGradient(colors: [AppColors.red1, AppColors.red3]),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withOpacity(0.2)),
          ),
          child: TextButton(
            onPressed: null,
            child: Text(
              widget.text,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}