import 'dart:ui';
import 'dart:async';

import 'package:flutter/material.dart';
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

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SearchScreen()),
          ),
          GoRoute(
            path: '/watchlist',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WatchlistScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/movie/:movieId',
        pageBuilder: (context, state) {
          final movieId = int.parse(state.pathParameters['movieId']!);
          return CustomTransitionPage(
            key: state.pageKey,
            child: MovieDetailScreen(movieId: movieId),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
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
class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});
  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: CinePalette.surface.withAlpha(176),
                border: Border.all(color: CinePalette.stroke.withAlpha(130)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MobileNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    active: currentPath == '/',
                    onTap: () => context.go('/'),
                  ),
                  _MobileNavItem(
                    icon: Icons.search_rounded,
                    label: 'Search',
                    active: currentPath.startsWith('/search'),
                    onTap: () => context.go('/search'),
                  ),
                  _MobileNavItem(
                    icon: Icons.bookmark_rounded,
                    label: 'Saved',
                    active: currentPath.startsWith('/watchlist'),
                    onTap: () => context.go('/watchlist'),
                  ),
                  _MobileNavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    active: currentPath.startsWith('/profile'),
                    onTap: () => context.go('/profile'),
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

class _MobileNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 230),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [
                    CinePalette.accent.withAlpha(240),
                    const Color(0xFFFFC561),
                  ],
                )
              : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: active ? const Color(0xFF231801) : CinePalette.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? const Color(0xFF231801) : CinePalette.textMuted,
              ),
            ),
          ],
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
      child: GestureDetector(
        onTap: widget.onTap,
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
