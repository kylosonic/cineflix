import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../providers/movie_providers.dart';
import '../../theme/cine_theme.dart';
import '../../widgets/loading/movie_grid_skeleton.dart';
import '../../widgets/motion/fade_slide_in.dart';
import '../../widgets/motion/staggered_reveal.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final watchlistState = ref.watch(watchlistProvider);
    final favoritesState = ref.watch(favoritesProvider);
    final ratingsState = ref.watch(ratingsProvider);

    if (user == null) {
      return Scaffold(
        body: CinematicBackdrop(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeSlideIn(
                child: CineGlassPanel(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 56,
                        color: CinePalette.accent,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sign in to unlock your lists',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Track favorites, save watchlist picks, and keep your ratings in one place.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CinePalette.textMuted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/profile'),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Go to Sign In'),
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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: CinematicBackdrop(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: StaggeredReveal(
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Lists',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Everything you saved, loved, and rated.',
                        style: TextStyle(color: CinePalette.textMuted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Watchlist',
                              value: watchlistState.movies.length,
                              icon: Icons.bookmark_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatTile(
                              label: 'Favorites',
                              value: favoritesState.movies.length,
                              icon: Icons.favorite_rounded,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatTile(
                              label: 'Rated',
                              value: ratingsState.ratings.length,
                              icon: Icons.star_rounded,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CineGlassPanel(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        borderRadius: BorderRadius.circular(14),
                        child: const TabBar(
                          tabs: [
                            Tab(text: 'Watchlist'),
                            Tab(text: 'Rated'),
                            Tab(text: 'Favorites'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    FadeSlideIn(
                      key: const ValueKey('watchlist-tab-watchlist'),
                      child: _MovieCollectionGrid(
                        rows: watchlistState.movies,
                        isLoading: watchlistState.isLoading,
                        heroPrefix: 'watchlist-saved',
                        emptyTitle: 'Your watchlist is empty',
                        emptySubtitle:
                            'Add titles from Home or Detail to plan your next movie night.',
                      ),
                    ),
                    FadeSlideIn(
                      key: const ValueKey('watchlist-tab-rated'),
                      child: _RatedMoviesList(
                        ratingsMap: ratingsState.ratings,
                        ratedRows: ratingsState.ratedMovies,
                        isLoading: ratingsState.isLoading,
                      ),
                    ),
                    FadeSlideIn(
                      key: const ValueKey('watchlist-tab-favorites'),
                      child: _MovieCollectionGrid(
                        rows: favoritesState.movies,
                        isLoading: favoritesState.isLoading,
                        heroPrefix: 'watchlist-favorites',
                        emptyTitle: 'No favorites yet',
                        emptySubtitle:
                            'Tap the heart-worthy titles and keep them close.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CineGlassPanel(
      borderRadius: BorderRadius.circular(14),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: CinePalette.accent, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: CinePalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: CinePalette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieCollectionGrid extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final bool isLoading;
  final String heroPrefix;
  final String emptyTitle;
  final String emptySubtitle;

  const _MovieCollectionGrid({
    required this.rows,
    required this.isLoading,
    required this.heroPrefix,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const MovieGridSkeleton(itemCount: 10);
    }

    if (rows.isEmpty) {
      return _ListEmptyState(title: emptyTitle, subtitle: emptySubtitle);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1350
            ? 6
            : width > 1100
            ? 5
            : width > 880
            ? 4
            : width > 620
            ? 3
            : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.58,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
          ),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            return _StoredMovieCard(
              row: rows[index],
              heroTag: '$heroPrefix-$index',
            );
          },
        );
      },
    );
  }
}

class _StoredMovieCard extends StatelessWidget {
  final Map<String, dynamic> row;
  final String heroTag;

  const _StoredMovieCard({required this.row, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    final payload = _extractPayload(row);
    final title = payload['title']?.toString() ?? 'Unknown title';
    final voteAverage =
        double.tryParse(payload['vote_average']?.toString() ?? '0') ?? 0;
    final posterPath = payload['poster_path']?.toString();
    final releaseYear =
        payload['release_date']?.toString().split('-').first ?? '';
    final movieId =
        int.tryParse(
          payload['id']?.toString() ?? row['movie_id']?.toString() ?? '0',
        ) ??
        0;

    return GestureDetector(
      onTap: movieId > 0
          ? () => context.push(
              '/movie/$movieId?heroTag=${Uri.encodeComponent('$heroTag-$movieId')}',
            )
          : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CinePalette.stroke.withAlpha(130)),
          color: CinePalette.surface.withAlpha(170),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: posterPath == null
                      ? const ColoredBox(color: CinePalette.surfaceAlt)
                      : Hero(
                          tag: '$heroTag-$movieId',
                          child: Image.network(
                            _posterUrl(posterPath),
                            fit: BoxFit.cover,
                            errorBuilder: (context, url, error) =>
                                const ColoredBox(color: CinePalette.surfaceAlt),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CinePalette.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: CinePalette.accent,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: CinePalette.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (releaseYear.isNotEmpty)
                          Text(
                            releaseYear,
                            style: const TextStyle(
                              color: CinePalette.textMuted,
                              fontSize: 11,
                            ),
                          ),
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
  }

  Map<String, dynamic> _extractPayload(Map<String, dynamic> source) {
    final nested = source['movie_data'];
    if (nested is Map<String, dynamic>) return nested;
    if (nested is Map) return Map<String, dynamic>.from(nested);
    return source;
  }

  String _posterUrl(String posterPath) {
    if (posterPath.startsWith('http://') || posterPath.startsWith('https://')) {
      return posterPath;
    }
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }
}

class _RatedMoviesList extends StatelessWidget {
  final Map<int, double> ratingsMap;
  final List<Map<String, dynamic>> ratedRows;
  final bool isLoading;

  const _RatedMoviesList({
    required this.ratingsMap,
    required this.ratedRows,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _RatedListSkeleton();
    }

    if (ratingsMap.isEmpty && ratedRows.isEmpty) {
      return const _ListEmptyState(
        title: 'No ratings yet',
        subtitle:
            'Rate titles from the detail page to build your taste profile.',
      );
    }

    final rows = ratedRows.isNotEmpty
        ? ratedRows
        : ratingsMap.entries
              .map((entry) => {'movie_id': entry.key, 'rating': entry.value})
              .toList();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemBuilder: (_, index) {
        final row = rows[index];
        final movieId = int.tryParse(row['movie_id']?.toString() ?? '0') ?? 0;
        final rating = double.tryParse(row['rating']?.toString() ?? '0') ?? 0;

        return CineGlassPanel(
          borderRadius: BorderRadius.circular(14),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: CinePalette.accent,
                    ),
                    child: Center(
                      child: Text(
                        rating.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Color(0xFF261A01),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Movie #$movieId',
                      style: const TextStyle(
                        color: CinePalette.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: movieId > 0
                        ? () => context.push('/movie/$movieId')
                        : null,
                    child: const Text('Open'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (rating / 10).clamp(0, 1),
                  minHeight: 7,
                  color: CinePalette.accent,
                  backgroundColor: CinePalette.surfaceAlt.withAlpha(170),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your score: ${rating.toStringAsFixed(1)} / 10',
                style: const TextStyle(
                  color: CinePalette.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: rows.length,
    );
  }
}

class _ListEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ListEmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: CineGlassPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.movie_filter_outlined,
                  size: 42,
                  color: CinePalette.accent,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CinePalette.textMuted,
                    height: 1.45,
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

class _RatedListSkeleton extends StatelessWidget {
  const _RatedListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemBuilder: (context, index) {
        return CineGlassPanel(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 120,
                decoration: BoxDecoration(
                  color: CinePalette.surfaceAlt.withAlpha(180),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 0.5,
                  minHeight: 7,
                  color: CinePalette.accent.withAlpha(210),
                  backgroundColor: CinePalette.surfaceAlt.withAlpha(170),
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemCount: 6,
    );
  }
}
