import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';

import 'config/app_config.dart';
import 'screens/home/home_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/detail/detail_screen.dart';
import 'screens/watchlist/watchlist_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/supabase_service.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen())),
          GoRoute(path: '/search', pageBuilder: (context, state) => const NoTransitionPage(child: SearchScreen())),
          GoRoute(path: '/watchlist', pageBuilder: (context, state) => const NoTransitionPage(child: WatchlistScreen())),
          GoRoute(path: '/profile', pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen())),
        ],
      ),
      GoRoute(
        path: '/movie/:movieId',
        pageBuilder: (context, state) {
          final movieId = int.parse(state.pathParameters['movieId']!);
          return CustomTransitionPage(
            key: state.pageKey,
            child: MovieDetailScreen(movieId: movieId),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
  await dotenv.load();
  await AppConfig.init();
  final supabaseService = SupabaseService();
  try { await supabaseService.initSupabase(); } catch (_) {}
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
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5C518),
          secondary: Color(0xFF5799EF),
          surface: Color(0xFF141414),
          onSurface: Color(0xFFFFFFFF),
          onPrimary: Color(0xFF000000),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          headlineLarge: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
          headlineMedium: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          titleMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge: const TextStyle(fontSize: 15, color: Color(0xFFB3B3B3)),
          bodyMedium: const TextStyle(fontSize: 13, color: Color(0xFF808080)),
          labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        }),
      ),
      routerConfig: router,
    );
  }
}

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
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
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF1F1F1F), width: 0.5))),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MobileNavItem(icon: Icons.home_rounded, label: 'Home', active: currentPath == '/', onTap: () => context.go('/')),
                _MobileNavItem(icon: Icons.search_rounded, label: 'Search', active: currentPath.startsWith('/search'), onTap: () => context.go('/search')),
                _MobileNavItem(icon: Icons.bookmark_rounded, label: 'Saved', active: currentPath.startsWith('/watchlist'), onTap: () => context.go('/watchlist')),
                _MobileNavItem(icon: Icons.person_rounded, label: 'Profile', active: currentPath.startsWith('/profile'), onTap: () => context.go('/profile')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _MobileNavItem({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF5C518).withAlpha(18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: active ? const Color(0xFFF5C518) : const Color(0xFF666666)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? const Color(0xFFF5C518) : const Color(0xFF666666))),
        ]),
      ),
    );
  }
}

// ── Web Shell ──
class _WebShell extends StatelessWidget {
  final Widget child;
  const _WebShell({required this.child});
  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: Row(children: [
        Container(
          width: 200,
          color: const Color(0xFF0A0A0A),
          child: Column(children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.go('/'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text('CineFlix', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w900, color: const Color(0xFFF5C518))),
              ),
            ),
            const SizedBox(height: 24),
            _SidebarItem(icon: Icons.home_rounded, label: 'Home', active: currentPath == '/', onTap: () => context.go('/')),
            _SidebarItem(icon: Icons.search_rounded, label: 'Search', active: currentPath.startsWith('/search'), onTap: () => context.go('/search')),
            _SidebarItem(icon: Icons.bookmark_rounded, label: 'Watchlist', active: currentPath.startsWith('/watchlist'), onTap: () => context.go('/watchlist')),
            const Spacer(),
            _SidebarItem(icon: Icons.person_rounded, label: 'Profile', active: currentPath.startsWith('/profile'), onTap: () => context.go('/profile')),
            const SizedBox(height: 16),
          ]),
        ),
        Expanded(child: child),
      ]),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon; final String label; final bool active; final VoidCallback onTap;
  const _SidebarItem({required this.icon, required this.label, required this.active, required this.onTap});
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
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: widget.active ? const Color(0xFFF5C518).withAlpha(22) : (_hovered ? Colors.white.withAlpha(8) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(widget.icon, size: 18, color: widget.active ? const Color(0xFFF5C518) : const Color(0xFF888888)),
            const SizedBox(width: 10),
            Text(widget.label, style: TextStyle(fontSize: 13, fontWeight: widget.active ? FontWeight.w600 : FontWeight.w400, color: widget.active ? Colors.white : const Color(0xFF888888))),
          ]),
        ),
      ),
    );
  }
}
