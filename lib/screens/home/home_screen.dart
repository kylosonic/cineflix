import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../models/movie.dart';
import '../../providers/movie_providers.dart';
import '../../theme/cine_theme.dart';
import '../../theme/motion_tokens.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/movie_card_netflix.dart';
import '../../widgets/motion/fade_slide_in.dart';
import '../../widgets/motion/staggered_reveal.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _activeTab = 'trending';

  MovieFeedType get _activeFeedType {
    return switch (_activeTab) {
      'trending' => MovieFeedType.trending,
      'toprated' => MovieFeedType.topRated,
      'nowplaying' => MovieFeedType.nowPlaying,
      'popular' => MovieFeedType.popular,
      _ => MovieFeedType.trending,
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pagedMoviesProvider(MovieFeedType.trending));
      ref.read(pagedMoviesProvider(MovieFeedType.nowPlaying));
      ref.read(pagedMoviesProvider(MovieFeedType.topRated));
      ref.read(pagedMoviesProvider(MovieFeedType.popular));
      ref.read(genresProvider.future);
    });
  }

  Future<void> _refreshAll() async {
    ref.invalidate(genresProvider);

    await Future.wait([
      ref.read(pagedMoviesProvider(MovieFeedType.trending).notifier).refresh(),
      ref.read(pagedMoviesProvider(MovieFeedType.popular).notifier).refresh(),
      ref.read(pagedMoviesProvider(MovieFeedType.topRated).notifier).refresh(),
      ref
          .read(pagedMoviesProvider(MovieFeedType.nowPlaying).notifier)
          .refresh(),
      ref.read(genresProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1200;
    return isWide ? _buildWebLayout(context) : _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    final trendingState = ref.watch(
      pagedMoviesProvider(MovieFeedType.trending),
    );

    return Scaffold(
      body: CinematicBackdrop(
        child: RefreshIndicator(
          color: CinePalette.accent,
          onRefresh: _refreshAll,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: StaggeredReveal(
                  index: 0,
                  child: _HomeHeader(
                    title: 'Tonight\'s Picks',
                    subtitle: 'Fresh stories, bold worlds, one tap away.',
                    onSearch: () => context.go('/search'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggeredReveal(
                  index: 1,
                  child: _FeaturedHero(
                    movies: trendingState.movies,
                    isLoading: trendingState.isLoadingInitial,
                    error: trendingState.error,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggeredReveal(
                  index: 2,
                  child: _CategoryTabs(
                    activeTab: _activeTab,
                    onSelected: (next) => setState(() => _activeTab = next),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: StaggeredReveal(index: 3, child: _GenreScroller()),
              ),
              SliverToBoxAdapter(
                child: StaggeredReveal(
                  index: 4,
                  child: _PagedRowSection(
                    title: 'Trending Heat',
                    subtitle: 'What everyone is watching now',
                    feedType: MovieFeedType.trending,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggeredReveal(
                  index: 5,
                  child: _PagedRowSection(
                    title: 'Now in Theaters',
                    subtitle: 'Fresh releases worth a night out',
                    feedType: MovieFeedType.nowPlaying,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggeredReveal(
                  index: 6,
                  child: _PagedRowSection(
                    title: 'Top Rated Gems',
                    subtitle:
                        'Critics and fans can\'t stop talking about these',
                    feedType: MovieFeedType.topRated,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: StaggeredReveal(
                  index: 7,
                  child: _PagedRowSection(
                    title: 'Popular Right Now',
                    subtitle: 'Massive audience favorites',
                    feedType: MovieFeedType.popular,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 115)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    final activeFeedType = _activeFeedType;
    final activeCollection = ref.watch(pagedMoviesProvider(activeFeedType));
    final trendingState = ref.watch(
      pagedMoviesProvider(MovieFeedType.trending),
    );
    final nowPlayingState = ref.watch(
      pagedMoviesProvider(MovieFeedType.nowPlaying),
    );

    return Scaffold(
      body: CinematicBackdrop(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
        child: RefreshIndicator(
          color: CinePalette.accent,
          onRefresh: _refreshAll,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis != Axis.vertical) return false;
              final remaining =
                  notification.metrics.maxScrollExtent -
                  notification.metrics.pixels;
              if (remaining < 720) {
                ref
                    .read(pagedMoviesProvider(activeFeedType).notifier)
                    .loadMore();
              }
              return false;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: StaggeredReveal(
                    index: 0,
                    beginOffset: const Offset(0, 0.02),
                    child: _HomeHeader(
                      title: 'Discover Stories That Stick',
                      subtitle:
                          'Curated collections and cinematic picks that feel alive on every screen.',
                      onSearch: () => context.go('/search'),
                      isWide: true,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: StaggeredReveal(
                    index: 1,
                    beginOffset: const Offset(0, 0.02),
                    child: _WebHeroBand(
                      trending: trendingState,
                      nowPlaying: nowPlayingState,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(
                  child: StaggeredReveal(index: 2, child: _WebDownloadStrip()),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: StaggeredReveal(
                    index: 3,
                    child: _CategoryTabs(
                      activeTab: _activeTab,
                      onSelected: (next) => setState(() => _activeTab = next),
                      isWide: true,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                const SliverToBoxAdapter(
                  child: StaggeredReveal(
                    index: 4,
                    child: _GenreScroller(isWide: true),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: FadeSlideIn(
                    key: ValueKey('web-grid-$_activeTab'),
                    delay: CineMotion.fast,
                    beginOffset: const Offset(0, 0.018),
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
                              : const Offset(0.012, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey(activeFeedType.name),
                        child: _buildWebGrid(activeCollection, activeFeedType),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebGrid(
    PagedMovieCollectionState collection,
    MovieFeedType feedType,
  ) {
    if (collection.isLoadingInitial && collection.movies.isEmpty) {
      return const _ShimmerGrid();
    }

    if (collection.error != null && collection.movies.isEmpty) {
      return _InlineStateCard(
        title: 'Could not load this collection',
        subtitle: collection.error!,
        icon: Icons.wifi_off_rounded,
      );
    }

    final visible = collection.movies
        .where((m) => m.posterPath != null)
        .toList();
    if (visible.isEmpty) {
      return const _InlineStateCard(
        title: 'No titles available yet',
        subtitle: 'Try a different collection or pull to refresh.',
        icon: Icons.hourglass_empty_rounded,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1700
            ? 7
            : width > 1500
            ? 6
            : width > 1300
            ? 5
            : 4;

        final itemCount = visible.length + (collection.isLoadingMore ? 1 : 0);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            childAspectRatio: 0.62,
            mainAxisSpacing: 16,
            crossAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            if (index >= visible.length) {
              return const _GridLoadingCard();
            }

            if (collection.hasNextPage &&
                !collection.isLoadingMore &&
                index >= visible.length - 4) {
              Future.microtask(
                () =>
                    ref.read(pagedMoviesProvider(feedType).notifier).loadMore(),
              );
            }

            final movie = visible[index];
            return _WebPosterCard(
              movie: movie,
              heroTag: 'home-web-${feedType.name}-$index-${movie.id}',
            );
          },
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onSearch;
  final bool isWide;

  const _HomeHeader({
    required this.title,
    required this.subtitle,
    required this.onSearch,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 2 : 16, 8, isWide ? 2 : 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: isWide
                      ? Theme.of(context).textTheme.headlineLarge
                      : GoogleFonts.dmSerifDisplay(
                          fontSize: 30,
                          color: CinePalette.textPrimary,
                          height: 1.05,
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: CinePalette.textMuted.withAlpha(220),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CineGlassPanel(
            padding: const EdgeInsets.all(4),
            borderRadius: BorderRadius.circular(16),
            child: IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search movies',
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedHero extends StatelessWidget {
  final List<Movie> movies;
  final bool isLoading;
  final String? error;

  const _FeaturedHero({
    required this.movies,
    required this.isLoading,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && movies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _FeaturedSkeleton(),
      );
    }

    if (error != null && movies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _InlineStateCard(
          title: 'Featured section unavailable',
          subtitle: error!,
          icon: Icons.error_outline_rounded,
        ),
      );
    }

    final hero =
        movies
            .where((movie) => movie.backdropPath != null)
            .cast<Movie?>()
            .firstOrNull ??
        movies.firstOrNull;

    if (hero == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _InlineStateCard(
          title: 'No featured movie available',
          subtitle: 'Pull to refresh and try again.',
          icon: Icons.theaters_outlined,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () {
          final heroTag = 'home-featured-${hero.id}';
          context.push(
            '/movie/${hero.id}?heroTag=${Uri.encodeComponent(heroTag)}',
          );
        },
        child: Container(
          height: 268,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: CinePalette.stroke.withAlpha(130)),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 14),
                color: Colors.black.withAlpha(90),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hero.backdropUrl != null)
                Hero(
                  tag: 'home-featured-${hero.id}',
                  child: CachedNetworkImage(
                    imageUrl: hero.backdropUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 1600,
                    fadeInDuration: const Duration(milliseconds: 140),
                    placeholder: (context, url) =>
                        const ColoredBox(color: CinePalette.surface),
                    errorWidget: (context, url, error) =>
                        const ColoredBox(color: CinePalette.surface),
                  ),
                )
              else
                const ColoredBox(color: CinePalette.surface),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(20),
                      Colors.black.withAlpha(60),
                      Colors.black.withAlpha(215),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 16,
                child: CineGlassPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: CinePalette.accent,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Featured Tonight',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hero.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 30,
                        color: CinePalette.textPrimary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hero.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE7EAF4),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CinePalette.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${hero.voteAverage.toStringAsFixed(1)} rating',
                            style: const TextStyle(
                              color: Color(0xFF251900),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hero.releaseDate != null &&
                            hero.releaseDate!.length >= 4)
                          Text(
                            hero.releaseDate!.substring(0, 4),
                            style: const TextStyle(
                              color: Color(0xFFD8DFF0),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
}

class _CategoryTabs extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onSelected;
  final bool isWide;

  const _CategoryTabs({
    required this.activeTab,
    required this.onSelected,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('trending', 'Trending', Icons.local_fire_department_rounded),
      ('toprated', 'Top Rated', Icons.workspace_premium_rounded),
      ('nowplaying', 'Now Playing', Icons.movie_filter_rounded),
      ('popular', 'Popular', Icons.trending_up_rounded),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 0 : 16, 4, isWide ? 0 : 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs
              .map(
                (tab) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _CategoryTabPill(
                    active: activeTab == tab.$1,
                    icon: tab.$3,
                    label: tab.$2,
                    onTap: () => onSelected(tab.$1),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _CategoryTabPill extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CategoryTabPill({
    required this.active,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: active
              ? LinearGradient(
                  colors: [
                    CinePalette.accent.withAlpha(245),
                    const Color(0xFFFFCF79),
                  ],
                )
              : LinearGradient(
                  colors: [
                    CinePalette.surface.withAlpha(210),
                    CinePalette.surfaceAlt.withAlpha(180),
                  ],
                ),
          border: Border.all(
            color: active
                ? Colors.transparent
                : CinePalette.stroke.withAlpha(170),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: CinePalette.accent.withAlpha(62),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? const Color(0xFF2A1900) : CinePalette.textPrimary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF2A1900)
                    : CinePalette.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenreScroller extends ConsumerWidget {
  final bool isWide;

  const _GenreScroller({this.isWide = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genresAsync = ref.watch(genresProvider);

    return genresAsync.when(
      data: (genres) {
        if (genres.isEmpty) {
          return const SizedBox.shrink();
        }

        final visibleGenres = genres.take(isWide ? 16 : 10).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: isWide ? 0 : 16),
              child: Text(
                'Browse Categories',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: isWide ? 0 : 16, right: 16),
                itemCount: visibleGenres.length,
                itemBuilder: (context, index) {
                  final genre = visibleGenres[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                _HomeGenreMoviesScreen(genre: genre),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [
                              CinePalette.accentAlt.withAlpha(198),
                              CinePalette.accent.withAlpha(195),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CinePalette.accentAlt.withAlpha(45),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          genre.name,
                          style: const TextStyle(
                            color: Color(0xFF0D1725),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(left: isWide ? 0 : 16, right: 16),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            width: 92,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: CinePalette.surface.withAlpha(160),
              border: Border.all(color: CinePalette.stroke.withAlpha(120)),
            ),
          ),
        ),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _HomeGenreMoviesScreen extends ConsumerWidget {
  final Genre genre;

  const _HomeGenreMoviesScreen({required this.genre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(pagedGenreMoviesProvider(genre.id));

    return Scaffold(
      appBar: AppBar(title: Text(genre.name)),
      body: CinematicBackdrop(
        topSafeArea: false,
        child: _buildGenreBody(context, ref, collection),
      ),
    );
  }

  Widget _buildGenreBody(
    BuildContext context,
    WidgetRef ref,
    PagedMovieCollectionState collection,
  ) {
    if (collection.isLoadingInitial && collection.movies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (collection.error != null && collection.movies.isEmpty) {
      return _InlineStateCard(
        title: 'Could not load this category',
        subtitle: collection.error!,
        icon: Icons.error_outline_rounded,
      );
    }

    if (collection.movies.isEmpty) {
      return const _InlineStateCard(
        title: 'No movies found',
        subtitle: 'This category has no available movies right now.',
        icon: Icons.movie_filter_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 1400
            ? 6
            : width > 1200
            ? 5
            : width > 900
            ? 4
            : width > 680
            ? 3
            : 2;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis != Axis.vertical) return false;
            final remaining =
                notification.metrics.maxScrollExtent -
                notification.metrics.pixels;
            if (remaining < 480) {
              ref.read(pagedGenreMoviesProvider(genre.id).notifier).loadMore();
            }
            return false;
          },
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
            itemCount:
                collection.movies.length + (collection.isLoadingMore ? 1 : 0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 0.57,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              if (index >= collection.movies.length) {
                return const _GridLoadingCard();
              }

              if (collection.hasNextPage &&
                  !collection.isLoadingMore &&
                  index >= collection.movies.length - 4) {
                Future.microtask(
                  () => ref
                      .read(pagedGenreMoviesProvider(genre.id).notifier)
                      .loadMore(),
                );
              }

              final movie = collection.movies[index];
              return MovieCard(
                movie: movie,
                heroTag: 'home-genre-${genre.id}-$index-${movie.id}',
              );
            },
          ),
        );
      },
    );
  }
}

class _PagedRowSection extends ConsumerWidget {
  final String title;
  final String subtitle;
  final MovieFeedType feedType;

  const _PagedRowSection({
    required this.title,
    required this.subtitle,
    required this.feedType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(pagedMoviesProvider(feedType));

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CinePalette.textMuted.withAlpha(220),
              ),
            ),
          ),
          SizedBox(
            height: 192,
            child: _buildRowContent(context, ref, collection),
          ),
        ],
      ),
    );
  }

  Widget _buildRowContent(
    BuildContext context,
    WidgetRef ref,
    PagedMovieCollectionState collection,
  ) {
    if (collection.isLoadingInitial && collection.movies.isEmpty) {
      return const _ShimmerRow();
    }

    if (collection.error != null && collection.movies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _InlineStateCard(
          title: 'Could not load this row',
          subtitle: collection.error!,
          icon: Icons.cloud_off_rounded,
        ),
      );
    }

    final visible = collection.movies
        .where((movie) => movie.posterPath != null)
        .toList();

    if (visible.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _InlineStateCard(
          title: 'Nothing here yet',
          subtitle: 'This row will populate as data arrives.',
          icon: Icons.movie_filter_outlined,
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.horizontal) return false;
        final remaining =
            notification.metrics.maxScrollExtent - notification.metrics.pixels;
        if (remaining < 320) {
          ref.read(pagedMoviesProvider(feedType).notifier).loadMore();
        }
        return false;
      },
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: visible.length + (collection.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= visible.length) {
            return const _RowLoadingItem();
          }

          if (collection.hasNextPage &&
              !collection.isLoadingMore &&
              index >= visible.length - 3) {
            Future.microtask(
              () => ref.read(pagedMoviesProvider(feedType).notifier).loadMore(),
            );
          }

          final movie = visible[index];
          return MovieCardNetflix(
            movie: movie,
            heroTag: 'home-${feedType.name}-$index-${movie.id}',
          );
        },
      ),
    );
  }
}

class _WebHeroBand extends StatelessWidget {
  final PagedMovieCollectionState trending;
  final PagedMovieCollectionState nowPlaying;

  const _WebHeroBand({required this.trending, required this.nowPlaying});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FeaturedHero(
            movies: trending.movies,
            isLoading: trending.isLoadingInitial,
            error: trending.error,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: CineGlassPanel(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Now Playing Radar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Quick-launch into fresh releases.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CinePalette.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                if (nowPlaying.isLoadingInitial && nowPlaying.movies.isEmpty)
                  const _MiniMovieRowSkeleton()
                else if (nowPlaying.error != null && nowPlaying.movies.isEmpty)
                  _InlineStateCard(
                    title: 'Unavailable right now',
                    subtitle: nowPlaying.error!,
                    icon: Icons.warning_amber_rounded,
                  )
                else if (nowPlaying.movies.isEmpty)
                  const _InlineStateCard(
                    title: 'No releases loaded',
                    subtitle: 'Try refreshing in a moment.',
                    icon: Icons.live_tv_rounded,
                  )
                else
                  Column(
                    children: nowPlaying.movies
                        .take(4)
                        .toList()
                        .asMap()
                        .entries
                        .map((entry) {
                          final index = entry.key;
                          final movie = entry.value;
                          final heroTag = 'home-nowplaying-$index-${movie.id}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _MiniMovieRow(
                              movie: movie,
                              heroTag: heroTag,
                            ),
                          );
                        })
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WebDownloadStrip extends StatelessWidget {
  const _WebDownloadStrip();

  Future<void> _openReleaseUrl(String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  @override
  Widget build(BuildContext context) {
    return CineGlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Install On Mobile',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          const Text(
            'Grab the latest unsigned APK and IPA from GitHub Releases.',
            style: TextStyle(color: CinePalette.textMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openReleaseUrl(AppConfig.androidDownloadUrl),
                icon: const Icon(Icons.android_rounded, size: 18),
                label: const Text('Android APK'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openReleaseUrl(AppConfig.iosDownloadUrl),
                icon: const Icon(Icons.phone_iphone_rounded, size: 18),
                label: const Text('iOS IPA'),
              ),
              TextButton(
                onPressed: () =>
                    _openReleaseUrl(AppConfig.githubReleasePageUrl),
                child: const Text('All Releases'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMovieRow extends StatelessWidget {
  final Movie movie;
  final String? heroTag;

  const _MiniMovieRow({required this.movie, this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final route = (heroTag == null || heroTag!.isEmpty)
            ? '/movie/${movie.id}'
            : '/movie/${movie.id}?heroTag=${Uri.encodeComponent(heroTag!)}';
        context.push(route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: CinePalette.surface.withAlpha(160),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CinePalette.stroke.withAlpha(130)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
              child: SizedBox(
                width: 70,
                height: 92,
                child: movie.posterUrl == null
                    ? const ColoredBox(color: CinePalette.backgroundSoft)
                    : Hero(
                        tag: heroTag ?? 'home-mini-${movie.id}',
                        child: CachedNetworkImage(
                          imageUrl: movie.posterUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 220,
                          fadeInDuration: const Duration(milliseconds: 120),
                          placeholder: (context, url) => const ColoredBox(
                            color: CinePalette.backgroundSoft,
                          ),
                          errorWidget: (context, url, error) =>
                              const ColoredBox(
                                color: CinePalette.backgroundSoft,
                              ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CinePalette.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: CinePalette.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            color: CinePalette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (movie.releaseDate != null &&
                            movie.releaseDate!.length >= 4)
                          Text(
                            movie.releaseDate!.substring(0, 4),
                            style: const TextStyle(
                              color: CinePalette.textMuted,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebPosterCard extends StatefulWidget {
  final Movie movie;
  final String? heroTag;

  const _WebPosterCard({required this.movie, this.heroTag});

  @override
  State<_WebPosterCard> createState() => _WebPosterCardState();
}

class _WebPosterCardState extends State<_WebPosterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          final route = (widget.heroTag == null || widget.heroTag!.isEmpty)
              ? '/movie/${widget.movie.id}'
              : '/movie/${widget.movie.id}?heroTag=${Uri.encodeComponent(widget.heroTag!)}';
          context.push(route);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 190),
          transform: Matrix4.translationValues(0, _hovered ? -6.0 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CinePalette.stroke.withAlpha(130)),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: CinePalette.accent.withAlpha(45),
                      blurRadius: 18,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.movie.posterUrl != null)
                  Hero(
                    tag: widget.heroTag ?? 'home-web-${widget.movie.id}',
                    child: CachedNetworkImage(
                      imageUrl: widget.movie.posterUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 420,
                      fadeInDuration: const Duration(milliseconds: 120),
                      placeholder: (context, url) =>
                          const ColoredBox(color: CinePalette.surface),
                      errorWidget: (context, url, error) =>
                          const ColoredBox(color: CinePalette.surface),
                    ),
                  )
                else
                  const ColoredBox(color: CinePalette.surface),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(10),
                        Colors.black.withAlpha(180),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CinePalette.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.movie.voteAverage.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFF2A1900),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.movie.releaseDate?.split('-').first ??
                            'Release year unknown',
                        style: const TextStyle(
                          color: Color(0xFFCFD5E6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
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

class _InlineStateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _InlineStateCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CineGlassPanel(
      child: Row(
        children: [
          Icon(icon, color: CinePalette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: CinePalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CinePalette.textMuted,
                    fontSize: 12,
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

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CinePalette.surface,
      highlightColor: CinePalette.surfaceAlt,
      child: Container(
        height: 268,
        decoration: BoxDecoration(
          color: CinePalette.surface,
          borderRadius: BorderRadius.circular(22),
        ),
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  const _ShimmerRow();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CinePalette.surface,
      highlightColor: CinePalette.surfaceAlt,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            width: 126,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: CinePalette.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerGrid extends StatelessWidget {
  const _ShimmerGrid();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CinePalette.surface,
      highlightColor: CinePalette.surfaceAlt,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.62,
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
        ),
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: CinePalette.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _RowLoadingItem extends StatelessWidget {
  const _RowLoadingItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: CinePalette.surface.withAlpha(180),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CinePalette.stroke.withAlpha(140)),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _GridLoadingCard extends StatelessWidget {
  const _GridLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CinePalette.surface.withAlpha(170),
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

class _MiniMovieRowSkeleton extends StatelessWidget {
  const _MiniMovieRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: CinePalette.surface,
      highlightColor: CinePalette.surfaceAlt,
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 92,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: CinePalette.surface,
            ),
          ),
        ),
      ),
    );
  }
}
