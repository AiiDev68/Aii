// ============================================================
//  ArchiverZ — Design System v2
//  Futuristic glassmorphism — cyan + purple vivid theme.
//  All pages should use these primitives for visual consistency.
// ============================================================
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_config.dart';

// ---------------------------------------------------------------------------
//  COLOR PALETTE — Cyan + Purple Vivid
// ---------------------------------------------------------------------------

class ArchiverZColors {
  ArchiverZColors._();

  // Aliases re-exported from AppConfig.
  static const Color bg        = AppConfig.colorBg;
  static const Color bgSurface = AppConfig.colorBgSurface;
  static const Color primary   = AppConfig.colorPrimary;   // cyan
  static const Color secondary = AppConfig.colorSecondary; // violet
  static const Color accent    = AppConfig.colorAccent;
  static const Color text      = AppConfig.colorText;
  static const Color textDim   = AppConfig.colorTextDim;
  static const Color danger    = AppConfig.colorDanger;
  static const Color success   = AppConfig.colorSuccess;

  // Vivid neon accents used for glows + icons
  static const Color neonCyan    = Color(0xFF00F0FF);
  static const Color neonPurple  = Color(0xFFB14CFF);
  static const Color neonPink    = Color(0xFFFF3CAC);
  static const Color neonBlue    = Color(0xFF3D9BFF);

  // Glass tints
  static Color glassFill({double opacity = 0.08}) =>
      Colors.white.withOpacity(opacity);
  static Color glassBorder({double opacity = 0.18}) =>
      Colors.white.withOpacity(opacity);
  static Color glassCyanTint({double opacity = 0.10}) =>
      neonCyan.withOpacity(opacity);
  static Color glassPurpleTint({double opacity = 0.10}) =>
      neonPurple.withOpacity(opacity);

  // Primary brand gradient — cyan → purple diagonal (signature)
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF050818),
      Color(0xFF0A0F2E),
      Color(0xFF14123A),
    ],
  );

  // Accent gradient — neon cyan → neon purple (for CTAs, hero text, glow rings)
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF00F0FF),  // neonCyan
      Color(0xFFB14CFF),  // neonPurple
    ],
  );

  // Diagonal accent (for top corners / ambient glows)
  static const LinearGradient accentDiagonal = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00F0FF),
      Color(0xFF3D9BFF),
      Color(0xFFB14CFF),
    ],
  );

  // Hero text shimmer (cool shimmer)
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
    colors: [
      Color(0xFF8B95B8),
      Color(0xFFFFFFFF),
      Color(0xFF8B95B8),
    ],
  );

  // Card glow gradient (for ambient edges)
  static const LinearGradient cardGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x3300F0FF),  // 20% cyan
      Color(0x33B14CFF),  // 20% purple
    ],
  );
}

// ---------------------------------------------------------------------------
//  GLASS CARD
// ---------------------------------------------------------------------------

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final Color? borderColor;
  final double blurSigma;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final bool enableGlowBorder;  // cyan-purple edge glow

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius,
    this.borderColor,
    this.blurSigma = AppConfig.glassBlurSigma,
    this.shadows,
    this.onTap,
    this.gradient,
    this.enableGlowBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppConfig.glassCardRadius;
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: gradient == null
                  ? ArchiverZColors.glassFill(opacity: 0.06)
                  : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(r),
              border: enableGlowBorder
                  ? Border.all(
                      color: ArchiverZColors.neonCyan.withOpacity(0.35),
                      width: 0.8,
                    )
                  : Border.all(
                      color: borderColor ?? ArchiverZColors.glassBorder(),
                      width: AppConfig.glassBorderWidth,
                    ),
              boxShadow: shadows,
            ),
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  GLOW BUTTON — primary CTA with cyan-purple gradient + neon glow
// ---------------------------------------------------------------------------

class GlowButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool outlined;
  final double height;
  final double? width;
  final Gradient? gradient;
  final Color? glowColor;
  final bool disabled;

  const GlowButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.height = 55,
    this.width,
    this.gradient,
    this.glowColor,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final grad = gradient ?? ArchiverZColors.accentGradient;
    final glow = glowColor ?? ArchiverZColors.neonCyan.withOpacity(0.45);

    if (disabled) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: ArchiverZColors.glassFill(opacity: 0.04),
          borderRadius: BorderRadius.circular(AppConfig.glassButtonRadius),
          border: Border.all(
            color: ArchiverZColors.glassBorder(opacity: 0.08),
            width: 0.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: ArchiverZColors.textDim, size: 18),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: TextStyle(
                  color: ArchiverZColors.textDim,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.4,
                  fontFamily: AppConfig.fontDisplay,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (outlined) {
      return _OutlinedGlow(
        label: label,
        icon: icon,
        onPressed: onPressed,
        height: height,
        width: width,
        grad: grad,
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: grad,
        borderRadius: BorderRadius.circular(AppConfig.glassButtonRadius),
        boxShadow: [
          BoxShadow(
            color: glow,
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConfig.glassButtonRadius),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.5,
                    fontFamily: AppConfig.fontDisplay,
                    shadows: [
                      Shadow(
                        color: Color(0x80000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
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

class _OutlinedGlow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final double height;
  final double? width;
  final Gradient grad;

  const _OutlinedGlow({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.height,
    required this.width,
    required this.grad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ArchiverZColors.glassFill(opacity: 0.05),
        borderRadius: BorderRadius.circular(AppConfig.glassButtonRadius),
        border: Border.all(
          color: ArchiverZColors.neonCyan.withOpacity(0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ArchiverZColors.neonCyan.withOpacity(0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConfig.glassButtonRadius),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: ArchiverZColors.neonCyan, size: 20),
                  const SizedBox(width: 10),
                ],
                ShaderMask(
                  shaderCallback: (bounds) => grad.createShader(bounds),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                      fontFamily: AppConfig.fontDisplay,
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

// ---------------------------------------------------------------------------
//  GLOW ICON BUTTON — circular icon button with neon ring
// ---------------------------------------------------------------------------

class GlowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? glowColor;
  final Color? iconColor;
  final Gradient? ringGradient;

  const GlowIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.glowColor,
    this.iconColor,
    this.ringGradient,
  });

  @override
  Widget build(BuildContext context) {
    final ring = ringGradient ?? ArchiverZColors.accentGradient;
    final glow = glowColor ?? ArchiverZColors.neonCyan.withOpacity(0.4);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ring,
        boxShadow: [BoxShadow(color: glow, blurRadius: 14, spreadRadius: 0)],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ArchiverZColors.bg.withOpacity(0.85),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(size),
            onTap: onPressed,
            child: Center(
              child: Icon(icon, color: iconColor ?? ArchiverZColors.neonCyan, size: size * 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  ANIMATED BACKGROUND — gradient + floating particles + corner glows
// ---------------------------------------------------------------------------

class AnimatedArchiverBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final bool showCornerGlows;
  final int particleCount;

  const AnimatedArchiverBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showCornerGlows = true,
    this.particleCount = 32,
  });

  @override
  State<AnimatedArchiverBackground> createState() =>
      _AnimatedArchiverBackgroundState();
}

class _AnimatedArchiverBackgroundState
    extends State<AnimatedArchiverBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    final rng = math.Random(42);
    _particles = List.generate(widget.particleCount, (_) => _Particle(rng));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: ArchiverZColors.brandGradient),
      child: Stack(
        children: [
          // Corner glows
          if (widget.showCornerGlows) ...[
            Positioned(
              top: -120, left: -120,
              child: Container(
                width: 300, height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ArchiverZColors.neonCyan.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150, right: -150,
              child: Container(
                width: 360, height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      ArchiverZColors.neonPurple.withOpacity(0.20),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
          // Particles
          if (widget.showParticles)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ParticlePainter(_particles, _ctrl.value),
                  );
                },
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double r;
  final double speed;
  final double drift;
  final int colorIdx;  // 0 = cyan, 1 = purple, 2 = pink
  _Particle(math.Random rng)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        r = 0.6 + rng.nextDouble() * 2.0,
        speed = 0.04 + rng.nextDouble() * 0.12,
        drift = rng.nextDouble() * math.pi * 2,
        colorIdx = rng.nextInt(3);
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y - t * p.speed) % 1.0;
      final dx = p.x + 0.02 * math.sin(t * 2 * math.pi + p.drift);
      final cx = dx * size.width;
      final cy = dy * size.height;
      final color = p.colorIdx == 0
          ? ArchiverZColors.neonCyan.withOpacity(0.55)
          : p.colorIdx == 1
              ? ArchiverZColors.neonPurple.withOpacity(0.45)
              : ArchiverZColors.neonPink.withOpacity(0.35);
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(cx, cy), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
//  APP BRAND MARK — Tendou Kei circular avatar with cyan-purple ring
// ---------------------------------------------------------------------------

class ArchiverBrandMark extends StatelessWidget {
  final double size;
  final bool withRing;
  final double ringWidth;
  const ArchiverBrandMark({
    super.key,
    this.size = 96,
    this.withRing = true,
    this.ringWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: withRing
          ? BoxDecoration(
              shape: BoxShape.circle,
              gradient: ArchiverZColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: ArchiverZColors.neonCyan.withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: ArchiverZColors.neonPurple.withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 0,
                ),
              ],
            )
          : null,
      padding: withRing ? EdgeInsets.all(ringWidth) : EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: ArchiverZColors.glassBorder(opacity: 0.3), width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          AppConfig.mascotAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: ArchiverZColors.bgSurface,
            child: Icon(Icons.person, color: ArchiverZColors.neonCyan, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  HERO TITLE — gradient cyan-purple wordmark with neon glow
// ---------------------------------------------------------------------------

class ArchiverHeroTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  final double letterSpacing;
  const ArchiverHeroTitle({
    super.key,
    required this.text,
    this.fontSize = 42,
    this.letterSpacing = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          ArchiverZColors.accentGradient.createShader(bounds),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: letterSpacing,
          fontFamily: AppConfig.fontDisplay,
          shadows: [
            Shadow(
              color: ArchiverZColors.neonCyan.withOpacity(0.5),
              blurRadius: 18,
            ),
            Shadow(
              color: ArchiverZColors.neonPurple.withOpacity(0.3),
              blurRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  SECTION HEADER — for grouping content on a page
// ---------------------------------------------------------------------------

class ArchiverSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  const ArchiverSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ArchiverZColors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: ArchiverZColors.neonCyan.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
        ],
        ShaderMask(
          shaderCallback: (bounds) =>
              ArchiverZColors.accentGradient.createShader(bounds),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontFamily: AppConfig.fontDisplay,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 2,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
//  STAT CHIP — small data indicator
// ---------------------------------------------------------------------------

class ArchiverStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  const ArchiverStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? ArchiverZColors.neonCyan.withOpacity(0.12)
            : ArchiverZColors.glassFill(opacity: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? ArchiverZColors.neonCyan.withOpacity(0.5)
              : ArchiverZColors.glassBorder(opacity: 0.12),
          width: 0.6,
        ),
        boxShadow: highlight
            ? [BoxShadow(
                color: ArchiverZColors.neonCyan.withOpacity(0.15),
                blurRadius: 8,
              )]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12,
              color: highlight ? ArchiverZColors.neonCyan : ArchiverZColors.textDim),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: TextStyle(
              color: highlight ? ArchiverZColors.text : ArchiverZColors.textDim,
              fontSize: 10,
              fontFamily: AppConfig.fontMono,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  THEME — canonical ThemeData
// ---------------------------------------------------------------------------

ThemeData archiverZTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: ArchiverZColors.bg,
    colorScheme: base.colorScheme.copyWith(
      primary: ArchiverZColors.neonCyan,
      secondary: ArchiverZColors.neonPurple,
      surface: ArchiverZColors.bgSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: ArchiverZColors.text,
    ),
    textTheme: base.textTheme.copyWith(
      bodyLarge:  TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono),
      bodyMedium: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontMono),
      bodySmall:  TextStyle(color: ArchiverZColors.textDim, fontFamily: AppConfig.fontMono),
      titleLarge: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontDisplay, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: ArchiverZColors.text, fontFamily: AppConfig.fontDisplay, fontWeight: FontWeight.bold),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: ArchiverZColors.text,
        fontFamily: AppConfig.fontDisplay,
        fontWeight: FontWeight.bold,
        fontSize: 18,
        letterSpacing: 1.2,
      ),
      iconTheme: IconThemeData(color: ArchiverZColors.neonCyan),
    ),
    iconTheme: IconThemeData(color: ArchiverZColors.neonCyan),
    dividerColor: ArchiverZColors.glassBorder(),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ArchiverZColors.glassFill(opacity: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ArchiverZColors.glassBorder(opacity: 0.15)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ArchiverZColors.glassBorder(opacity: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: ArchiverZColors.neonCyan, width: 1.2),
      ),
      labelStyle: TextStyle(color: ArchiverZColors.textDim, fontFamily: AppConfig.fontMono),
      hintStyle: TextStyle(color: ArchiverZColors.textDim, fontFamily: AppConfig.fontMono),
    ),
  );
}
