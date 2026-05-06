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
import '../../widgets/movie_card_netflix.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _activeTab = 'trending';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(trendingMoviesProvider.future);
      ref.read(nowPlayingMoviesProvider(1).future);
      ref.read(topRatedMoviesProvider(1).future);
      ref.read(popularMoviesProvider(1).future);
    });
  }

  Future<void> _refreshAll() async {
    ref.invalidate(trendingMoviesProvider);
    ref.invalidate(popularMoviesProvider(1));
    ref.invalidate(topRatedMoviesProvider(1));
    ref.invalidate(nowPlayingMoviesProvider(1));

    await Future.wait([
      ref.read(trendingMoviesProvider.future),
      ref.read(popularMoviesProvider(1).future),
      ref.read(topRatedMoviesProvider(1).future),
      ref.read(nowPlayingMoviesProvider(1).future),
    ]);
  }

  AsyncValue<List<Movie>> _activeCollection() {
    return switch (_activeTab) {
      'trending' => ref.watch(trendingMoviesProvider),
      'toprated' => ref.watch(topRatedMoviesProvider(1)),
      'nowplaying' => ref.watch(nowPlayingMoviesProvider(1)),
      'popular' => ref.watch(popularMoviesProvider(1)),
      _ => ref.watch(trendingMoviesProvider),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 1200;
    return isWide ? _buildWebLayout(context) : _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
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
                child: _HomeHeader(
                  title: 'Tonight\'s Picks',
                  subtitle: 'Fresh stories, bold worlds, one tap away.',
                  onSearch: () => context.go('/search'),
                ),
              ),
              SliverToBoxAdapter(
                child: _FeaturedHero(
                  asyncMovies: ref.watch(trendingMoviesProvider),
                ),
              ),
              SliverToBoxAdapter(
                child: _CategoryTabs(
                  activeTab: _activeTab,
                  onSelected: (next) => setState(() => _activeTab = next),
                ),
              ),
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Trending Heat',
                  subtitle: 'What everyone is watching now',
                  asyncMovies: ref.watch(trendingMoviesProvider),
                ),
              ),
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Now in Theaters',
                  subtitle: 'Fresh releases worth a night out',
                  asyncMovies: ref.watch(nowPlayingMoviesProvider(1)),
                ),
              ),
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Top Rated Gems',
                  subtitle: 'Critics and fans can\'t stop talking about these',
                  asyncMovies: ref.watch(topRatedMoviesProvider(1)),
                ),
              ),
              SliverToBoxAdapter(
                child: _RowSection(
                  title: 'Popular Right Now',
                  subtitle: 'Massive audience favorites',
                  asyncMovies: ref.watch(popularMoviesProvider(1)),
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
    return Scaffold(
      body: CinematicBackdrop(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
        child: RefreshIndicator(
          color: CinePalette.accent,
          onRefresh: _refreshAll,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _HomeHeader(
                  title: 'Discover Stories That Stick',
                  subtitle:
                      'Curated collections and cinematic picks that feel alive on every screen.',
                  onSearch: () => context.go('/search'),
                  isWide: true,
                ),
              ),
              SliverToBoxAdapter(
                child: _WebHeroBand(
                  trending: ref.watch(trendingMoviesProvider),
                  nowPlaying: ref.watch(nowPlayingMoviesProvider(1)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: _WebDownloadStrip()),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              SliverToBoxAdapter(
                child: _CategoryTabs(
                  activeTab: _activeTab,
                  onSelected: (next) => setState(() => _activeTab = next),
                  isWide: true,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 14)),
              SliverToBoxAdapter(child: _buildWebGrid(_activeCollection())),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebGrid(AsyncValue<List<Movie>> asyncMovies) {
    return asyncMovies.when(
      data: (movies) {
        final visible = movies.where((m) => m.posterPath != null).toList();
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
            final columns = width > 1500
                ? 6
                : width > 1300
                ? 5
                : 4;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visible.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                childAspectRatio: 0.62,
                mainAxisSpacing: 16,
                crossAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                return _WebPosterCard(movie: visible[index]);
              },
            );
          },
        );
      },
      loading: () => const _ShimmerGrid(),
      error: (error, _) => _InlineStateCard(
        title: 'Could not load this collection',
        subtitle: error.toString(),
        icon: Icons.wifi_off_rounded,
      ),
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
  final AsyncValue<List<Movie>> asyncMovies;

  const _FeaturedHero({required this.asyncMovies});

  @override
  Widget build(BuildContext context) {
    return asyncMovies.when(
      data: (movies) {
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
            onTap: () => context.push('/movie/${hero.id}'),
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
                    CachedNetworkImage(
                      imageUrl: hero.backdropUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 1600,
                      fadeInDuration: const Duration(milliseconds: 140),
                      placeholder: (context, url) =>
                          const ColoredBox(color: CinePalette.surface),
                      errorWidget: (context, url, error) =>
                          const ColoredBox(color: CinePalette.surface),
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
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _FeaturedSkeleton(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: _InlineStateCard(
          title: 'Featured section unavailable',
          subtitle: error.toString(),
          icon: Icons.error_outline_rounded,
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
      ('trending', 'Trending'),
      ('toprated', 'Top Rated'),
      ('nowplaying', 'Now Playing'),
      ('popular', 'Popular'),
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
                  child: ChoiceChip(
                    selected: activeTab == tab.$1,
                    label: Text(tab.$2),
                    onSelected: (_) => onSelected(tab.$1),
                    selectedColor: CinePalette.accent.withAlpha(230),
                    labelStyle: TextStyle(
                      color: activeTab == tab.$1
                          ? const Color(0xFF2A1900)
                          : CinePalette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(
                        color: activeTab == tab.$1
                            ? Colors.transparent
                            : CinePalette.stroke.withAlpha(140),
                      ),
                    ),
                    backgroundColor: CinePalette.surface.withAlpha(180),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _RowSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final AsyncValue<List<Movie>> asyncMovies;

  const _RowSection({
    required this.title,
    required this.subtitle,
    required this.asyncMovies,
  });

  @override
  Widget build(BuildContext context) {
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
            child: asyncMovies.when(
              data: (movies) {
                final visible = movies
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

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    return MovieCardNetflix(movie: visible[index]);
                  },
                );
              },
              loading: () => const _ShimmerRow(),
              error: (error, stackTrace) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _InlineStateCard(
                  title: 'Could not load this row',
                  subtitle: 'Pull to refresh and try again.',
                  icon: Icons.cloud_off_rounded,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebHeroBand extends StatelessWidget {
  final AsyncValue<List<Movie>> trending;
  final AsyncValue<List<Movie>> nowPlaying;

  const _WebHeroBand({required this.trending, required this.nowPlaying});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _FeaturedHero(asyncMovies: trending)),
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
                nowPlaying.when(
                  data: (movies) {
                    final short = movies.take(4).toList();
                    if (short.isEmpty) {
                      return const _InlineStateCard(
                        title: 'No releases loaded',
                        subtitle: 'Try refreshing in a moment.',
                        icon: Icons.live_tv_rounded,
                      );
                    }

                    return Column(
                      children: short.map((movie) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _MiniMovieRow(movie: movie),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const _MiniMovieRowSkeleton(),
                  error: (error, stackTrace) => const _InlineStateCard(
                    title: 'Unavailable right now',
                    subtitle: 'Could not load current releases.',
                    icon: Icons.warning_amber_rounded,
                  ),
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

  const _MiniMovieRow({required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movie/${movie.id}'),
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
                    : CachedNetworkImage(
                        imageUrl: movie.posterUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 220,
                        fadeInDuration: const Duration(milliseconds: 120),
                        placeholder: (context, url) =>
                            const ColoredBox(color: CinePalette.backgroundSoft),
                        errorWidget: (context, url, error) =>
                            const ColoredBox(color: CinePalette.backgroundSoft),
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

  const _WebPosterCard({required this.movie});

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
        onTap: () => context.push('/movie/${widget.movie.id}'),
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
                  CachedNetworkImage(
                    imageUrl: widget.movie.posterUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 420,
                    fadeInDuration: const Duration(milliseconds: 120),
                    placeholder: (context, url) =>
                        const ColoredBox(color: CinePalette.surface),
                    errorWidget: (context, url, error) =>
                        const ColoredBox(color: CinePalette.surface),
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
