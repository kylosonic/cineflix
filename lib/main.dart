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
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
          GoRoute(path: '/watchlist', builder: (context, state) => const WatchlistScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/movie/:movieId',
        builder: (context, state) {
          final movieId = int.parse(state.pathParameters['movieId']!);
          return MovieDetailScreen(movieId: movieId);
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
  try {
    await supabaseService.initSupabase();
  } catch (_) {}

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
          primary: Color(0xFFF5C518),        // IMDb gold
          secondary: Color(0xFF5799EF),       // IMDb blue
          surface: Color(0xFF1A1A1A),         // Dark surface
          onSurface: Color(0xFFFFFFFF),
          onPrimary: Color(0xFF000000),
          error: Color(0xFFE50914),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          headlineLarge: GoogleFonts.playfairDisplay(
            fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white,
          ),
          headlineMedium: GoogleFonts.playfairDisplay(
            fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white,
          ),
          titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
          titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
          bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFFCCCCCC)),
          bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        ),
        useMaterial3: true,
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

    if (isWide) {
      return _WebShell(child: child);
    }
    return _MobileShell(child: child);
  }
}

// ──────────────────────────────────────────
//  Mobile Shell — Netflix-style bottom nav
// ──────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          backgroundColor: const Color(0xFF0A0A0A),
          indicatorColor: const Color(0xF5C518).withAlpha(40),
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, size: 24),
              selectedIcon: Icon(Icons.home, size: 24, color: Color(0xFFF5C518)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined, size: 24),
              selectedIcon: Icon(Icons.search, size: 24, color: Color(0xFFF5C518)),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline, size: 24),
              selectedIcon: Icon(Icons.bookmark, size: 24, color: Color(0xFFF5C518)),
              label: 'Watchlist',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, size: 24),
              selectedIcon: Icon(Icons.person, size: 24, color: Color(0xFFF5C518)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/watchlist')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/');
      case 1: context.go('/search');
      case 2: context.go('/watchlist');
      case 3: context.go('/profile');
    }
  }
}

// ──────────────────────────────────────────
//  Web Shell — IMDb-style sidebar + top bar
// ──────────────────────────────────────────

class _WebShell extends StatelessWidget {
  final Widget child;
  const _WebShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: const Color(0xFF0A0A0A),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: GestureDetector(
                    onTap: () => context.go('/'),
                    child: Text('CineFlix',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF5C518),
                        )),
                  ),
                ),
                const SizedBox(height: 32),
                _SidebarItem(icon: Icons.home, label: 'Home', path: '/', currentPath: GoRouterState.of(context).uri.path),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Color(0xFF2A2A2A)),
                ),
                const SizedBox(height: 16),
                _SidebarItem(icon: Icons.search, label: 'Search', path: '/search', currentPath: GoRouterState.of(context).uri.path),
                _SidebarItem(icon: Icons.bookmark, label: 'Watchlist', path: '/watchlist', currentPath: GoRouterState.of(context).uri.path),
                _SidebarItem(icon: Icons.person, label: 'Profile', path: '/profile', currentPath: GoRouterState.of(context).uri.path),
              ],
            ),
          ),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;

  const _SidebarItem({
    required this.icon, required this.label,
    required this.path, required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentPath == path ||
        (path.contains('?tab=') && currentPath == '/');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isActive ? const Color(0xFFF5C518).withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (path.contains('?tab=')) {
              context.go(path);
            } else {
              context.go(path);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon, size: 20,
                    color: isActive ? const Color(0xFFF5C518) : const Color(0xFF999999)),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : const Color(0xFF999999),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
