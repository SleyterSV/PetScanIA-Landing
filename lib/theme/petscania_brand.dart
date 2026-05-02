import 'dart:ui';

import 'package:flutter/material.dart';

class PetScaniaColors {
  static const Color royalBlue = Color(0xFF2854A6);
  static const Color deepBlue = Color(0xFF173E8E);
  static const Color skyBlue = Color(0xFF67B9EE);
  static const Color paleBlue = Color(0xFFBFE7FF);
  static const Color ink = Color(0xFF17315E);
  static const Color mist = Color(0xFFF5FBFF);
  static const Color cloud = Color(0xFFE9F6FF);
  static const Color line = Color(0xFFD5E7F7);
  static const Color rescueCoral = Color(0xFFFF7A6B);
  static const Color warmSun = Color(0xFFFFC857);
  static const Color leaf = Color(0xFF2FBF71);
  static const Color alert = Color(0xFFE94F64);
  static const Color white = Colors.white;
}

class PetScaniaDecor {
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [PetScaniaColors.deepBlue, PetScaniaColors.skyBlue],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F8FF)],
  );

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: PetScaniaColors.ink.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
}

class PetScaniaBackground extends StatelessWidget {
  final Widget child;
  final bool showPaws;

  const PetScaniaBackground({
    super.key,
    required this.child,
    this.showPaws = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: PetScaniaDecor.primaryGradient,
          ),
        ),
        Positioned(
          top: -80,
          left: -30,
          child: _bubble(220, PetScaniaColors.skyBlue.withValues(alpha: 0.18)),
        ),
        Positioned(
          top: 60,
          right: -40,
          child: _bubble(200, Colors.white.withValues(alpha: 0.09)),
        ),
        Positioned(
          bottom: -110,
          left: 20,
          child: _bubble(240, PetScaniaColors.paleBlue.withValues(alpha: 0.16)),
        ),
        Positioned(
          bottom: 40,
          right: -10,
          child: _bubble(130, Colors.white.withValues(alpha: 0.08)),
        ),
        if (showPaws) ...[
          const Positioned(
            top: 78,
            left: 28,
            child: Icon(Icons.pets_rounded, color: Color(0x1FFFFFFF), size: 48),
          ),
          const Positioned(
            top: 200,
            right: 42,
            child: Icon(Icons.pets_rounded, color: Color(0x22FFFFFF), size: 44),
          ),
          const Positioned(
            bottom: 160,
            left: 60,
            child: Icon(Icons.pets_rounded, color: Color(0x1EFFFFFF), size: 42),
          ),
          const Positioned(
            bottom: 74,
            right: 50,
            child: Icon(Icons.pets_rounded, color: Color(0x1BFFFFFF), size: 54),
          ),
        ],
        child,
      ],
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class PetScaniaBrandMark extends StatelessWidget {
  final double size;

  const PetScaniaBrandMark({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/Logo_PetScanIA_mark.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class PetScaniaWordmark extends StatelessWidget {
  final TextAlign textAlign;
  final double fontSize;
  final bool includeTagline;
  final Color primaryTextColor;
  final Color accentTextColor;

  const PetScaniaWordmark({
    super.key,
    this.textAlign = TextAlign.center,
    this.fontSize = 42,
    this.includeTagline = true,
    this.primaryTextColor = Colors.white,
    this.accentTextColor = PetScaniaColors.skyBlue,
  });

  @override
  Widget build(BuildContext context) {
    final taglineColor = primaryTextColor == Colors.white
        ? Colors.white.withValues(alpha: 0.82)
        : PetScaniaColors.ink.withValues(alpha: 0.68);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: textAlign,
          text: TextSpan(
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: 0,
              color: primaryTextColor,
            ),
            children: [
              const TextSpan(text: 'PetScan'),
              TextSpan(
                text: 'IA',
                style: TextStyle(color: accentTextColor),
              ),
            ],
          ),
        ),
        if (includeTagline) ...[
          const SizedBox(height: 10),
          Text(
            'Cuidado veterinario amable y tecnologico',
            textAlign: textAlign,
            style: TextStyle(
              color: taglineColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class PetScaniaLogoLockup extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final bool includeTagline;
  final bool onLightSurface;

  const PetScaniaLogoLockup({
    super.key,
    this.markSize = 96,
    this.fontSize = 40,
    this.includeTagline = true,
    this.onLightSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PetScaniaBrandMark(size: markSize),
        const SizedBox(height: 18),
        PetScaniaWordmark(
          fontSize: fontSize,
          includeTagline: includeTagline,
          primaryTextColor: onLightSurface
              ? PetScaniaColors.royalBlue
              : Colors.white,
          accentTextColor: PetScaniaColors.skyBlue,
        ),
      ],
    );
  }
}

class PetScaniaGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const PetScaniaGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(32);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: radius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.36),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: PetScaniaColors.ink.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class PetScaniaSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? color;

  const PetScaniaSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(28),
        border: Border.all(color: PetScaniaColors.line),
        boxShadow: PetScaniaDecor.softShadow,
      ),
      child: child,
    );
  }
}
