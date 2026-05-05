import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CinePalette {
  const CinePalette._();

  static const Color background = Color(0xFF050913);
  static const Color backgroundSoft = Color(0xFF111A2F);
  static const Color surface = Color(0xFF19243E);
  static const Color surfaceAlt = Color(0xFF253357);
  static const Color stroke = Color(0xFF31446B);
  static const Color accent = Color(0xFFF9A826);
  static const Color accentAlt = Color(0xFF45D3C1);
  static const Color textPrimary = Color(0xFFF6F7FB);
  static const Color textMuted = Color(0xFFB4BDD3);
}

class CineTheme {
  const CineTheme._();

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      CinePalette.background,
      Color(0xFF0C1223),
      Color(0xFF0B1D2C),
      CinePalette.background,
    ],
  );

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: CinePalette.accent,
        secondary: CinePalette.accentAlt,
        surface: CinePalette.surface,
        onPrimary: Color(0xFF1A1100),
        onSurface: CinePalette.textPrimary,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: CinePalette.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
        headlineLarge: GoogleFonts.dmSerifDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: CinePalette.textPrimary,
          letterSpacing: 0.2,
        ),
        headlineMedium: GoogleFonts.dmSerifDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: CinePalette.textPrimary,
        ),
        titleLarge: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: CinePalette.textPrimary,
          letterSpacing: 0.2,
        ),
        titleMedium: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: CinePalette.textPrimary,
        ),
        bodyLarge: const TextStyle(
          fontSize: 15,
          color: CinePalette.textMuted,
          height: 1.45,
        ),
        bodyMedium: const TextStyle(fontSize: 13, color: CinePalette.textMuted),
        labelLarge: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: CinePalette.textPrimary,
        elevation: 0,
      ),
      dividerColor: CinePalette.stroke.withAlpha(100),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: CinePalette.surface.withAlpha(170),
        side: BorderSide(color: CinePalette.stroke.withAlpha(140)),
        labelStyle: const TextStyle(
          color: CinePalette.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: CinePalette.surface.withAlpha(170),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: CinePalette.stroke.withAlpha(100)),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: CinePalette.accent,
        unselectedLabelColor: CinePalette.textMuted,
        indicatorColor: CinePalette.accent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CinePalette.surface.withAlpha(170),
        hintStyle: const TextStyle(color: Color(0xFF9AA5C2)),
        prefixIconColor: CinePalette.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: CinePalette.stroke.withAlpha(130)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: CinePalette.stroke.withAlpha(130)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: CinePalette.accent, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CinePalette.accent,
          foregroundColor: const Color(0xFF241701),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CinePalette.textPrimary,
          side: BorderSide(color: CinePalette.stroke.withAlpha(160)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

class CinematicBackdrop extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool topSafeArea;
  final bool bottomSafeArea;

  const CinematicBackdrop({
    super.key,
    required this.child,
    this.padding,
    this.topSafeArea = true,
    this.bottomSafeArea = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: CineTheme.pageGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _Aura(
            alignment: Alignment(-0.95, -0.85),
            color: Color(0xFFF9A826),
            size: 290,
          ),
          const _Aura(
            alignment: Alignment(1.0, -0.2),
            color: Color(0xFF45D3C1),
            size: 260,
          ),
          const _Aura(
            alignment: Alignment(-0.15, 1.05),
            color: Color(0xFF3D6AF5),
            size: 300,
          ),
          SafeArea(
            top: topSafeArea,
            bottom: bottomSafeArea,
            child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
          ),
        ],
      ),
    );
  }
}

class CineGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CineGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(18);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding ?? const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            color: CinePalette.surface.withAlpha(165),
            border: Border.all(color: CinePalette.stroke.withAlpha(120)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Aura extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;

  const _Aura({
    required this.alignment,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withAlpha(70), color.withAlpha(0)],
            ),
          ),
        ),
      ),
    );
  }
}
