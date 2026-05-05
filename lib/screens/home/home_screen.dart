import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/movie.dart';
import '../../providers/movie_providers.dart';
import '../../widgets/movie_card_netflix.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _activeTab = 'trending';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return isWide ? _buildWebLayout() : _buildNetflixLayout();
  }

  // ──────────────────────────────────────────
  //  Netflix Mobile — Hero + horizontal rows
  // ──────────────────────────────────────────

  Widget _buildNetflixLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('CineFlix',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFF5C518),
              letterSpacing: 1,
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFF5C518)),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFF5C518),
        onRefresh: () async {
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(popularMoviesProvider(1));
          ref.invalidate(topRatedMoviesProvider(1));
          ref.invalidate(nowPlayingMoviesProvider(1));
        },
        child: ListView(
          children: [
            // Hero Section - Large featured movie
            _NetflixHero(ref: ref),
            const SizedBox(height: 8),
            // Trending Row
            _NetflixRow(
              title: 'Trending Now',
              moviesAsync: ref.watch(trendingMoviesProvider),
            ),
            // Top Rated Row
            _NetflixRow(
              title: 'Top Rated',
              moviesAsync: ref.watch(topRatedMoviesProvider(1)),
            ),
            // Now Playing Row
            _NetflixRow(
              title: 'Now Playing',
              moviesAsync: ref.watch(nowPlayingMoviesProvider(1)),
            ),
            // Popular Row
            _NetflixRow(
              title: 'Popular on CineFlix',
              moviesAsync: ref.watch(popularMoviesProvider(1)),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  IMDb Web — Dense grid + sidebar filters
  // ──────────────────────────────────────────

  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Row(
          children: [
            Text('CineFlix',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFF5C518),
                )),
            const SizedBox(width: 32),
            _WebTabButton(
              label: 'Trending',
              icon: Icons.local_fire_department,
              isActive: _activeTab == 'trending',
              onTap: () => setState(() => _activeTab = 'trending'),
            ),
            const SizedBox(width: 8),
            _WebTabButton(
              label: 'Top Rated',
              icon: Icons.star,
              isActive: _activeTab == 'toprated',
              onTap: () => setState(() => _activeTab = 'toprated'),
            ),
            const SizedBox(width: 8),
            _WebTabButton(
              label: 'Now Playing',
              icon: Icons.movie,
              isActive: _activeTab == 'nowplaying',
              onTap: () => setState(() => _activeTab = 'nowplaying'),
            ),
            const SizedBox(width: 8),
            _WebTabButton(
              label: 'Popular',
              icon: Icons.trending_up,
              isActive: _activeTab == 'popular',
              onTap: () => setState(() => _activeTab = 'popular'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF999999)),
            onPressed: () => context.go('/search'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _buildWebGrid(),
    );
  }

  Widget _buildWebGrid() {
    final provider = switch (_activeTab) {
      'trending' => ref.watch(trendingMoviesProvider),
      'toprated' => ref.watch(topRatedMoviesProvider(1)),
      'nowplaying' => ref.watch(nowPlayingMoviesProvider(1)),
      'popular' => ref.watch(popularMoviesProvider(1)),
      _ => ref.watch(trendingMoviesProvider),
    };

    return provider.when(
      data: (movies) {
        final filtered = movies.where((m) => m.posterPath != null).toList();
        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.68,
            crossAxisSpacing: 16,
            mainAxisSpacing: 20,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _WebMovieCard(movie: filtered[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF5C518))),
      error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.grey))),
    );
  }
}

// ──────────────────────────────────────────
//  Netflix Hero Widget
// ──────────────────────────────────────────

class _NetflixHero extends ConsumerWidget {
  final WidgetRef ref;
  const _NetflixHero({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingMoviesProvider);

    return trendingAsync.when(
      data: (movies) {
        if (movies.isEmpty) return const SizedBox.shrink();
        final hero = movies.firstWhere((m) => m.backdropPath != null,
            orElse: () => movies.first);
        return GestureDetector(
          onTap: () => context.push('/movie/${hero.id}'),
          child: Container(
            height: 450,
            decoration: BoxDecoration(
              image: hero.backdropUrl != null
                  ? DecorationImage(
                      image: NetworkImage(hero.backdropUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(200),
                    const Color(0xFF121212),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 60,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hero.title,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            )),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5C518),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.black),
                                  const SizedBox(width: 4),
                                  Text(hero.voteAverage.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      )),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                            const Text('Play Trailer',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        height: 450,
        color: const Color(0xFF1A1A1A),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFF5C518))),
      ),
      error: (e, _) => Container(
        height: 450,
        color: const Color(0xFF1A1A1A),
        child: Center(child: Text('Error: $e', style: const TextStyle(color: Colors.grey))),
      ),
    );
  }
}

// ──────────────────────────────────────────
//  Netflix Row Widget
// ──────────────────────────────────────────

class _NetflixRow extends StatelessWidget {
  final String title;
  final AsyncValue<List<Movie>> moviesAsync;

  const _NetflixRow({required this.title, required this.moviesAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Text(title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
        ),
        SizedBox(
          height: 180,
          child: moviesAsync.when(
            data: (movies) {
              final list = movies.where((m) => m.posterPath != null).toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return MovieCardNetflix(movie: list[index]);
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFFF5C518)),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: Colors.grey)),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────
//  Web Tab Button
// ──────────────────────────────────────────

class _WebTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _WebTabButton({
    required this.label, required this.icon,
    required this.isActive, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF5C518).withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isActive
              ? Border.all(color: const Color(0xFFF5C518).withAlpha(80))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: isActive ? const Color(0xFFF5C518) : const Color(0xFF999999)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? const Color(0xFFF5C518) : const Color(0xFF999999),
            )),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────
//  Web Movie Card (IMDb style)
// ──────────────────────────────────────────

class _WebMovieCard extends StatelessWidget {
  final Movie movie;
  const _WebMovieCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movie/${movie.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  movie.posterPath != null
                      ? Image.network(movie.posterUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: const Color(0xFF2A2A2A),
                                  child: const Icon(Icons.movie, color: Colors.grey)))
                      : Container(color: const Color(0xFF2A2A2A),
                          child: const Icon(Icons.movie, color: Colors.grey)),
                  // Rating badge
                  Positioned(
                    top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(180),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 11, color: Color(0xFFF5C518)),
                          const SizedBox(width: 3),
                          Text(movie.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: Color(0xFFF5C518),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(movie.title,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
          const SizedBox(height: 2),
          Text(movie.releaseDate ?? '',
              style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
        ],
      ),
    );
  }
}
