import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/movie.dart';
import '../../providers/movie_providers.dart';
import '../../theme/cine_theme.dart';
import '../../theme/motion_tokens.dart';
import '../../widgets/loading/movie_grid_skeleton.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/motion/fade_slide_in.dart';
import '../../widgets/motion/staggered_reveal.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  static const _suggestions = [
    'Cyberpunk',
    'Mind-bending',
    'Space opera',
    'Dark comedy',
    'Coming of age',
    'Heist thrillers',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  void _runQuickSearch(String value) {
    _searchController.text = value;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: value.length),
    );
    setState(() => _query = value.trim());
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CinematicBackdrop(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: FadeSlideIn(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search',
                            style: GoogleFonts.dmSerifDisplay(
                              fontSize: 34,
                              color: CinePalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find movies by title, mood, or genre.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_query.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearSearch,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Clear'),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FadeSlideIn(
                delay: const Duration(milliseconds: 45),
                child: CineGlassPanel(
                  borderRadius: BorderRadius.circular(18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: CinePalette.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Try: Inception, comedy, animation...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: _runQuickSearch,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: CineMotion.resolveDuration(
                  context,
                  CineMotion.normal,
                ),
                switchInCurve: CineMotion.resolveCurve(
                  context,
                  Curves.easeOutCubic,
                ),
                switchOutCurve: CineMotion.resolveCurve(
                  context,
                  Curves.easeInCubic,
                ),
                transitionBuilder: (child, animation) {
                  final reduceMotion = CineMotion.reduceMotion(context);
                  final slide = Tween<Offset>(
                    begin: reduceMotion
                        ? Offset.zero
                        : const Offset(0.01, 0.01),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: _query.isEmpty
                    ? _buildDiscovery(ref)
                    : _buildSearchResults(ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscovery(WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);

    return genresAsync.when(
      data: (genres) {
        return ListView(
          key: const ValueKey('discovery'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            StaggeredReveal(
              index: 0,
              child: CineGlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jump In Fast',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap a vibe to start exploring instantly.',
                      style: TextStyle(color: CinePalette.textMuted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List<Widget>.generate(_suggestions.length, (
                        index,
                      ) {
                        final suggestion = _suggestions[index];
                        return StaggeredReveal(
                          index: index,
                          step: const Duration(milliseconds: 40),
                          beginOffset: const Offset(0, 0.01),
                          child: _SuggestionChip(
                            label: suggestion,
                            onTap: () => _runQuickSearch(suggestion),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            StaggeredReveal(
              index: 1,
              child: Text(
                'Browse by Genre',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            StaggeredReveal(
              index: 2,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width > 900
                      ? 4
                      : width > 620
                      ? 3
                      : 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: genres.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: 2.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (_, index) {
                      return _GenreChip(genre: genres[index]);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const MovieGridSkeleton(itemCount: 10),
      error: (error, _) => _InlineSearchState(
        title: 'Genres unavailable',
        subtitle: error.toString(),
        icon: Icons.error_outline_rounded,
      ),
    );
  }

  Widget _buildSearchResults(WidgetRef ref) {
    final results = ref.watch(pagedSearchMoviesProvider(_query));

    if (results.isLoadingInitial && results.movies.isEmpty) {
      return const MovieGridSkeleton(itemCount: 12);
    }

    if (results.error != null && results.movies.isEmpty) {
      return _InlineSearchState(
        title: 'Search failed',
        subtitle: results.error!,
        icon: Icons.wifi_off_rounded,
      );
    }

    if (results.movies.isEmpty) {
      return _InlineSearchState(
        title: 'No matches for "$_query"',
        subtitle: 'Try a shorter phrase or another mood.',
        icon: Icons.search_off_rounded,
      );
    }

    return _ResponsiveMovieGrid(
      key: const ValueKey('results'),
      movies: results.movies,
      topPadding: 6,
      hasNextPage: results.hasNextPage,
      isLoadingMore: results.isLoadingMore,
      onLoadMore: () =>
          ref.read(pagedSearchMoviesProvider(_query).notifier).loadMore(),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [
              CinePalette.surface.withAlpha(220),
              CinePalette.surfaceAlt.withAlpha(190),
            ],
          ),
          border: Border.all(color: CinePalette.stroke.withAlpha(150)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: CinePalette.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _GenreChip extends ConsumerWidget {
  final Genre genre;

  const _GenreChip({required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder<void>(
              transitionDuration: CineMotion.resolveDuration(
                context,
                CineMotion.medium,
              ),
              reverseTransitionDuration: CineMotion.resolveDuration(
                context,
                CineMotion.normal,
              ),
              pageBuilder: (context, animation, secondaryAnimation) =>
                  _GenreMoviesScreen(genre: genre),
              transitionsBuilder: (context, animation, secondary, child) {
                final reduceMotion = CineMotion.reduceMotion(context);
                final slide = Tween<Offset>(
                  begin: reduceMotion ? Offset.zero : const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation);

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF30CFCB).withAlpha(235),
                const Color(0xFFFFC45E).withAlpha(238),
              ],
            ),
            border: Border.all(color: const Color(0xFFFFFFFF).withAlpha(42)),
            boxShadow: [
              BoxShadow(
                color: CinePalette.accentAlt.withAlpha(55),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                genre.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF04111A),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreMoviesScreen extends ConsumerWidget {
  final Genre genre;

  const _GenreMoviesScreen({required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(pagedGenreMoviesProvider(genre.id));

    return Scaffold(
      appBar: AppBar(title: Text(genre.name)),
      body: CinematicBackdrop(
        topSafeArea: false,
        child: _buildGenreBody(context, ref, movies),
      ),
    );
  }

  Widget _buildGenreBody(
    BuildContext context,
    WidgetRef ref,
    PagedMovieCollectionState movies,
  ) {
    if (movies.isLoadingInitial && movies.movies.isEmpty) {
      return const MovieGridSkeleton(itemCount: 10);
    }

    if (movies.error != null && movies.movies.isEmpty) {
      return _InlineSearchState(
        title: 'Could not load this genre',
        subtitle: movies.error!,
        icon: Icons.warning_amber_rounded,
      );
    }

    if (movies.movies.isEmpty) {
      return const _InlineSearchState(
        title: 'No movies found',
        subtitle: 'This genre has no entries right now.',
        icon: Icons.movie_filter_outlined,
      );
    }

    return _ResponsiveMovieGrid(
      movies: movies.movies,
      hasNextPage: movies.hasNextPage,
      isLoadingMore: movies.isLoadingMore,
      onLoadMore: () =>
          ref.read(pagedGenreMoviesProvider(genre.id).notifier).loadMore(),
    );
  }
}

class _ResponsiveMovieGrid extends StatelessWidget {
  final List<Movie> movies;
  final double topPadding;
  final bool hasNextPage;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const _ResponsiveMovieGrid({
    super.key,
    required this.movies,
    this.topPadding = 0,
    this.hasNextPage = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1450
            ? 7
            : width > 1200
            ? 6
            : width > 980
            ? 5
            : width > 740
            ? 4
            : 2;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (onLoadMore == null ||
                notification.metrics.axis != Axis.vertical) {
              return false;
            }
            final remaining =
                notification.metrics.maxScrollExtent -
                notification.metrics.pixels;
            if (remaining < 520) {
              onLoadMore!();
            }
            return false;
          },
          child: GridView.builder(
            key: key,
            padding: EdgeInsets.fromLTRB(16, topPadding, 16, 100),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 0.57,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
            ),
            itemCount: movies.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (_, index) {
              if (index >= movies.length) {
                return const _GridLoaderCard();
              }

              if (hasNextPage &&
                  !isLoadingMore &&
                  onLoadMore != null &&
                  index >= movies.length - 4) {
                Future.microtask(onLoadMore!);
              }

              final movie = movies[index];
              return MovieCard(
                movie: movie,
                heroTag: 'search-grid-$index-${movie.id}',
              );
            },
          ),
        );
      },
    );
  }
}

class _GridLoaderCard extends StatelessWidget {
  const _GridLoaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CinePalette.surface.withAlpha(175),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CinePalette.stroke.withAlpha(130)),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}

class _InlineSearchState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InlineSearchState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: CineGlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: CinePalette.accent, size: 34),
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
    );
  }
}
