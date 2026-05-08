import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/app_config.dart';
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/detail/detail_screen.dart';
import 'screens/watchlist/watchlist_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/supabase_service.dart';
import 'theme/cine_theme.dart';
import 'theme/motion_tokens.dart';
import 'widgets/motion/pressable_scale.dart';

CustomTransitionPage<void> _buildShellTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: CineMotion.medium,
    reverseTransitionDuration: CineMotion.normal,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final reduceMotion = CineMotion.reduceMotion(context);
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slide = Tween<Offset>(
        begin: reduceMotion ? Offset.zero : const Offset(0.015, 0),
        end: Offset.zero,
      ).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => _buildShellTransitionPage(
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => _buildShellTransitionPage(
              state: state,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/watchlist',
            pageBuilder: (context, state) => _buildShellTransitionPage(
              state: state,
              child: const WatchlistScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _buildShellTransitionPage(
              state: state,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/movie/:movieId',
        pageBuilder: (context, state) {
          final movieId = int.parse(state.pathParameters['movieId']!);
          final heroTag = state.uri.queryParameters['heroTag'];
          return CustomTransitionPage(
            key: state.pageKey,
            transitionDuration: CineMotion.slow,
            reverseTransitionDuration: CineMotion.medium,
            child: MovieDetailScreen(movieId: movieId, heroTag: heroTag),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final reduceMotion = CineMotion.reduceMotion(context);
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );

                  final slide = Tween<Offset>(
                    begin: reduceMotion ? Offset.zero : const Offset(0, 0.035),
                    end: Offset.zero,
                  ).animate(curved);

                  final scale = Tween<double>(
                    begin: reduceMotion ? 1.0 : 0.985,
                    end: 1.0,
                  ).animate(curved);

                  return FadeTransition(
                    opacity: curved,
                    child: SlideTransition(
                      position: slide,
                      child: ScaleTransition(scale: scale, child: child),
                    ),
                  );
                },
          );
        },
      ),
    ],
  );
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();

  final cache = PaintingBinding.instance.imageCache;
  cache.maximumSize = 400;
  cache.maximumSizeBytes = 256 << 20;

  final supabaseService = SupabaseService();
  unawaited(
    Future<void>(() async {
      try {
        await supabaseService.ensureInitialized();
      } catch (_) {
        // Do not block app startup on optional auth backend initialization.
      }
    }),
  );

  runApp(const ProviderScope(child: CineFlixApp()));
}

class CineFlixApp extends ConsumerWidget {
  const CineFlixApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'CineFlix',
      debugShowCheckedModeBanner: false,
      theme: CineTheme.darkTheme,
      routerConfig: router,
    );
  }
}

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1040;
    return isWide ? _WebShell(child: child) : _MobileShell(child: child);
  }
}

// ── Mobile Shell ──
class _MobileShell extends StatefulWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  final GlobalKey _contentRepaintKey = GlobalKey();
  final Set<Timer> _pendingSampleTimers = <Timer>{};
  Timer? _dockTintPollingTimer;
  bool _isSamplingTint = false;
  bool _pendingResample = false;
  String? _lastObservedPath;
  Color _adaptiveDockTint = CinePalette.accent;

  static const List<_MobileNavDestination> _destinations = [
    _MobileNavDestination(icon: Icons.home_rounded, label: 'Home', path: '/'),
    _MobileNavDestination(
      icon: Icons.search_rounded,
      label: 'Search',
      path: '/search',
    ),
    _MobileNavDestination(
      icon: Icons.bookmark_rounded,
      label: 'Saved',
      path: '/watchlist',
    ),
    _MobileNavDestination(
      icon: Icons.person_rounded,
      label: 'Profile',
      path: '/profile',
    ),
  ];

  int _resolveCurrentIndex(String path) {
    if (path == '/') return 0;
    if (path.startsWith('/search')) return 1;
    if (path.startsWith('/watchlist')) return 2;
    if (path.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _dockTintPollingTimer = Timer.periodic(
      const Duration(milliseconds: 1400),
      (_) => _scheduleDockTintSample(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleDockTintSample();
    });
  }

  @override
  void didUpdateWidget(covariant _MobileShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      _scheduleDockTintSample(delay: const Duration(milliseconds: 140));
    }
  }

  @override
  void dispose() {
    _dockTintPollingTimer?.cancel();
    for (final timer in _pendingSampleTimers) {
      timer.cancel();
    }
    _pendingSampleTimers.clear();
    super.dispose();
  }

  void _scheduleDockTintSample({Duration delay = Duration.zero}) {
    if (!mounted) return;

    void runSample() {
      if (!mounted) return;
      unawaited(_sampleDockTintFromContent());
    }

    if (delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        runSample();
      });
      return;
    }

    late final Timer timer;
    timer = Timer(delay, () {
      _pendingSampleTimers.remove(timer);
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        runSample();
      });
    });
    _pendingSampleTimers.add(timer);
  }

  Future<void> _sampleDockTintFromContent() async {
    if (_isSamplingTint) {
      _pendingResample = true;
      return;
    }

    final renderObject = _contentRepaintKey.currentContext?.findRenderObject();
    final boundary = renderObject is RenderRepaintBoundary
        ? renderObject
        : null;

    if (boundary == null || boundary.debugNeedsPaint) return;

    _isSamplingTint = true;
    try {
      final image = await boundary.toImage(pixelRatio: 0.09);
      final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
      final width = image.width;
      final height = image.height;
      image.dispose();

      if (byteData == null || width <= 2 || height <= 2) {
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final xStart = (width * 0.12).round().clamp(0, width - 1);
      final xEnd = (width * 0.88).round().clamp(1, width);
      final yStart = (height * 0.67).round().clamp(0, height - 1);
      final yEnd = (height * 0.96).round().clamp(1, height);

      double red = 0;
      double green = 0;
      double blue = 0;
      double weightSum = 0;

      // Sample a low-res strip where the dock overlays content and build a weighted average.
      for (var y = yStart; y < yEnd; y += 2) {
        for (var x = xStart; x < xEnd; x += 2) {
          final index = ((y * width) + x) * 4;
          final r = bytes[index];
          final g = bytes[index + 1];
          final b = bytes[index + 2];
          final a = bytes[index + 3];

          if (a < 28) continue;

          final luminance = ((0.2126 * r) + (0.7152 * g) + (0.0722 * b)) / 255;
          final weight = (1 - (luminance - 0.48).abs()).clamp(0.25, 1.0);

          red += r * weight;
          green += g * weight;
          blue += b * weight;
          weightSum += weight;
        }
      }

      if (weightSum <= 0.1) return;

      int toByte(double value) => value.round().clamp(0, 255).toInt();

      final sampled = Color.fromARGB(
        255,
        toByte(red / weightSum),
        toByte(green / weightSum),
        toByte(blue / weightSum),
      );

      final hsl = HSLColor.fromColor(sampled);
      final tuned = hsl
          .withSaturation((hsl.saturation * 1.18).clamp(0.24, 0.76))
          .withLightness((hsl.lightness * 0.84).clamp(0.24, 0.56))
          .toColor();

      final cinematicTint =
          Color.lerp(const Color(0xFF1B1208), tuned, 0.86) ?? tuned;

      if (!mounted ||
          cinematicTint.toARGB32() == _adaptiveDockTint.toARGB32()) {
        return;
      }

      setState(() {
        _adaptiveDockTint = cinematicTint;
      });
    } catch (_) {
      // Fail silently to avoid disrupting navigation if sampling is unavailable.
    } finally {
      _isSamplingTint = false;
      if (_pendingResample) {
        _pendingResample = false;
        _scheduleDockTintSample(delay: const Duration(milliseconds: 90));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final currentIndex = _resolveCurrentIndex(currentPath);
    final routeChanged = _lastObservedPath != currentPath;

    if (routeChanged) {
      _lastObservedPath = currentPath;
      _scheduleDockTintSample();
      _scheduleDockTintSample(
        delay: CineMotion.resolveDuration(
          context,
          const Duration(milliseconds: 440),
          reduced: const Duration(milliseconds: 120),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: RepaintBoundary(key: _contentRepaintKey, child: widget.child),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: _LiquidGlassDock(
          destinations: _destinations,
          currentIndex: currentIndex,
          adaptiveTint: _adaptiveDockTint,
          onSelect: (index) {
            if (index == currentIndex) return;
            context.go(_destinations[index].path);
          },
        ),
      ),
    );
  }
}

class _MobileNavDestination {
  final IconData icon;
  final String label;
  final String path;

  const _MobileNavDestination({
    required this.icon,
    required this.label,
    required this.path,
  });
}

class _LiquidGlassDock extends StatelessWidget {
  final List<_MobileNavDestination> destinations;
  final int currentIndex;
  final Color adaptiveTint;
  final ValueChanged<int> onSelect;

  const _LiquidGlassDock({
    required this.destinations,
    required this.currentIndex,
    required this.adaptiveTint,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final reduceMotion = CineMotion.reduceMotion(context);
    final highContrast = media.highContrast;

    final animationDuration = CineMotion.resolveDuration(
      context,
      CineMotion.medium,
      reduced: const Duration(milliseconds: 90),
    );
    final animationCurve = CineMotion.resolveCurve(
      context,
      Curves.easeOutCubic,
    );

    final blurSigma = highContrast ? 8.0 : 24.0;
    final baseFill = highContrast
        ? CinePalette.surface.withAlpha(238)
        : CinePalette.surface.withAlpha(150);

    return TweenAnimationBuilder<Color?>(
      duration: animationDuration,
      curve: animationCurve,
      tween: ColorTween(end: adaptiveTint),
      builder: (context, animatedTint, _) {
        final tint = animatedTint ?? adaptiveTint;
        final tintHsl = HSLColor.fromColor(tint);
        final capsulePrimary = highContrast
            ? CinePalette.accent
            : tintHsl
                  .withSaturation((tintHsl.saturation + 0.18).clamp(0.35, 0.9))
                  .withLightness((tintHsl.lightness * 0.88).clamp(0.33, 0.62))
                  .toColor();
        final capsulePrimaryHsl = HSLColor.fromColor(capsulePrimary);
        final capsuleSecondary = highContrast
            ? const Color(0xFFFFD787)
            : capsulePrimaryHsl
                  .withLightness(
                    (capsulePrimaryHsl.lightness + 0.14).clamp(0.45, 0.78),
                  )
                  .toColor();
        final activeForeground =
            ThemeData.estimateBrightnessForColor(capsulePrimary) ==
                Brightness.dark
            ? Colors.white.withAlpha(245)
            : const Color(0xFF130A00);
        final inactiveForeground = highContrast
            ? Colors.white.withAlpha(250)
            : Color.lerp(
                CinePalette.textMuted.withAlpha(235),
                tint,
                0.08,
              )!.withAlpha(236);

        final tintOverlay = highContrast
            ? Colors.transparent
            : tint.withAlpha(58);
        final secondaryFill =
            Color.lerp(baseFill, tintOverlay, 0.24) ?? tintOverlay;
        final borderColor = highContrast
            ? Colors.white.withAlpha(170)
            : Color.lerp(
                    Colors.white.withAlpha(86),
                    tint.withAlpha(136),
                    0.22,
                  ) ??
                  Colors.white.withAlpha(86);

        return RepaintBoundary(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slotWidth = constraints.maxWidth / destinations.length;
              final capsuleWidth = (slotWidth - 12).clamp(54.0, 104.0);

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(105),
                      blurRadius: 28,
                      spreadRadius: -3,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(70),
                      blurRadius: 14,
                      spreadRadius: -5,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: blurSigma,
                      sigmaY: blurSigma,
                    ),
                    child: Container(
                      height: 82,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [baseFill, secondaryFill],
                        ),
                        border: Border.all(color: borderColor),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: 27,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withAlpha(
                                        highContrast ? 62 : 44,
                                      ),
                                      Colors.white.withAlpha(8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: animationDuration,
                            curve: animationCurve,
                            left:
                                6 +
                                (slotWidth * currentIndex) +
                                (slotWidth - capsuleWidth) / 2,
                            top: 7,
                            width: capsuleWidth,
                            height: 60,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [capsulePrimary, capsuleSecondary],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(
                                      highContrast ? 230 : 150,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: capsulePrimary.withAlpha(110),
                                      blurRadius: 20,
                                      spreadRadius: -2,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < destinations.length; i++)
                                Expanded(
                                  child: _LiquidDockItem(
                                    destination: destinations[i],
                                    active: i == currentIndex,
                                    activeColor: activeForeground,
                                    inactiveColor: inactiveForeground,
                                    onTap: () => onSelect(i),
                                    animationDuration: animationDuration,
                                    animationCurve: animationCurve,
                                    reduceMotion: reduceMotion,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _LiquidDockItem extends StatelessWidget {
  final _MobileNavDestination destination;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool reduceMotion;

  const _LiquidDockItem({
    required this.destination,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
    required this.animationDuration,
    required this.animationCurve,
    required this.reduceMotion,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: active,
      button: true,
      label: destination.label,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: PressableScale(
            onTap: onTap,
            hoveredScale: 1,
            pressedScale: 0.95,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: AnimatedSlide(
                duration: animationDuration,
                curve: animationCurve,
                offset: active || reduceMotion
                    ? Offset.zero
                    : const Offset(0, 0.02),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedScale(
                      duration: animationDuration,
                      curve: animationCurve,
                      scale: active && !reduceMotion ? 1.06 : 1,
                      child: Icon(
                        destination.icon,
                        size: 22,
                        color: active ? activeColor : inactiveColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: animationDuration,
                      curve: animationCurve,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: active ? activeColor : inactiveColor,
                        letterSpacing: 0.1,
                      ),
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
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

// ── Web Shell ──
class _WebShell extends StatelessWidget {
  final Widget child;
  const _WebShell({required this.child});

  Future<void> _openReleaseUrl(String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 250,
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CinePalette.backgroundSoft.withAlpha(240),
                  CinePalette.background.withAlpha(240),
                ],
              ),
              border: Border(
                right: BorderSide(color: CinePalette.stroke.withAlpha(130)),
              ),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CineFlix',
                          style: GoogleFonts.dmSerifDisplay(
                            fontSize: 34,
                            color: CinePalette.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Find your next obsession',
                          style: TextStyle(
                            color: CinePalette.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SidebarItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  active: currentPath == '/',
                  onTap: () => context.go('/'),
                ),
                _SidebarItem(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  active: currentPath.startsWith('/search'),
                  onTap: () => context.go('/search'),
                ),
                _SidebarItem(
                  icon: Icons.bookmark_rounded,
                  label: 'My Lists',
                  active: currentPath.startsWith('/watchlist'),
                  onTap: () => context.go('/watchlist'),
                ),
                const SizedBox(height: 8),
                CineGlassPanel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Get Mobile App',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Download the latest unsigned Android APK or iOS IPA from GitHub Releases.',
                        style: TextStyle(
                          color: CinePalette.textMuted,
                          height: 1.4,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openReleaseUrl(AppConfig.androidDownloadUrl),
                          icon: const Icon(Icons.android_rounded, size: 18),
                          label: const Text('Download Android APK'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openReleaseUrl(AppConfig.iosDownloadUrl),
                          icon: const Icon(
                            Icons.phone_iphone_rounded,
                            size: 18,
                          ),
                          label: const Text('Download iOS IPA'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () =>
                              _openReleaseUrl(AppConfig.githubReleasePageUrl),
                          child: const Text('Open all releases'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CineGlassPanel(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tonight',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Use Search to explore by genre, then save the best picks to your list.',
                        style: TextStyle(
                          color: CinePalette.textMuted,
                          height: 1.4,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SidebarItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  active: currentPath.startsWith('/profile'),
                  onTap: () => context.go('/profile'),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PressableScale(
        onTap: widget.onTap,
        hoveredScale: 1.01,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.active
                ? LinearGradient(
                    colors: [
                      CinePalette.accent.withAlpha(235),
                      const Color(0xFFFFCA6A),
                    ],
                  )
                : null,
            color: widget.active
                ? null
                : (_hovered
                      ? CinePalette.surface.withAlpha(160)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.active
                  ? Colors.transparent
                  : CinePalette.stroke.withAlpha(_hovered ? 150 : 90),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 19,
                color: widget.active
                    ? const Color(0xFF211500)
                    : CinePalette.textMuted,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                  color: widget.active
                      ? const Color(0xFF211500)
                      : CinePalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
