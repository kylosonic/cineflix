import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../models/movie.dart';
import '../../providers/auth_providers.dart';
import '../../providers/movie_providers.dart';
import '../../theme/cine_theme.dart';
import '../../widgets/movie_card.dart';

class MovieDetailScreen extends ConsumerWidget {
  final int movieId;

  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(movieDetailProvider(movieId));

    return detailAsync.when(
      data: (detail) => _MovieDetailContent(movieId: movieId, detail: detail),
      loading: () => const _DetailStateScaffold(
        icon: Icons.hourglass_top_rounded,
        title: 'Loading movie details',
        subtitle: 'Fetching cast, trailer, and where-to-watch data.',
        showProgress: true,
      ),
      error: (error, _) => _DetailStateScaffold(
        icon: Icons.wifi_off_rounded,
        title: 'Unable to load this movie',
        subtitle: error.toString(),
      ),
    );
  }
}

class _MovieDetailContent extends ConsumerWidget {
  final int movieId;
  final MovieDetail detail;

  const _MovieDetailContent({required this.movieId, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailer = detail.videos?.results
        .where((video) => video.type == 'Trailer' && video.site == 'YouTube')
        .firstOrNull;

    return Scaffold(
      body: CinematicBackdrop(
        topSafeArea: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 370,
              pinned: true,
              backgroundColor: CinePalette.background.withAlpha(150),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.fromSTEB(
                  16,
                  0,
                  16,
                  16,
                ),
                title: Text(
                  detail.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSerifDisplay(
                    color: CinePalette.textPrimary,
                    fontSize: 24,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (detail.backdropUrl != null)
                      CachedNetworkImage(
                        imageUrl: detail.backdropUrl!,
                        fit: BoxFit.cover,
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
                            Colors.black.withAlpha(35),
                            Colors.black.withAlpha(80),
                            CinePalette.background.withAlpha(240),
                            CinePalette.background,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 72,
                      child: Row(
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
                              '${detail.voteAverage.toStringAsFixed(1)} / 10',
                              style: const TextStyle(
                                color: Color(0xFF261A01),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (detail.releaseDate != null &&
                              detail.releaseDate!.length >= 4)
                            Text(
                              detail.releaseDate!.substring(0, 4),
                              style: const TextStyle(
                                color: Color(0xFFE2E8F8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detail.tagline?.trim().isNotEmpty == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '"${detail.tagline!.trim()}"',
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: CinePalette.textMuted,
                          ),
                        ),
                      ),
                    _SectionCard(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: Icons.timer_outlined,
                            label: detail.runtime != null
                                ? '${detail.runtime} min'
                                : 'Runtime unknown',
                          ),
                          _InfoPill(
                            icon: Icons.how_to_vote_rounded,
                            label: '${detail.voteCount} votes',
                          ),
                          if (detail.status?.trim().isNotEmpty == true)
                            _InfoPill(
                              icon: Icons.verified_rounded,
                              label: detail.status!,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (trailer != null)
                            _ActionButton(
                              icon: Icons.play_arrow_rounded,
                              label: 'Watch Trailer',
                              onTap: () => _showTrailer(context, trailer.key),
                            ),
                          _WatchlistButton(movieId: movieId, detail: detail),
                          _RateButton(movieId: movieId),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle(title: 'Overview'),
                    _SectionCard(
                      child: Text(
                        detail.overview.trim().isEmpty
                            ? 'No overview available for this title.'
                            : detail.overview,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: CinePalette.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (detail.genres.isNotEmpty) ...[
                      const _SectionTitle(title: 'Genres'),
                      _SectionCard(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: detail.genres
                              .map((genre) => Chip(label: Text(genre.name)))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (detail.credits?.cast.isNotEmpty == true) ...[
                      const _SectionTitle(title: 'Top Cast'),
                      SizedBox(
                        height: 178,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: detail.credits!.cast.take(12).length,
                          itemBuilder: (_, index) =>
                              _CastCard(member: detail.credits!.cast[index]),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (detail.watchProviders != null) ...[
                      const _SectionTitle(title: 'Where to Watch'),
                      _SectionCard(
                        child: _WatchProvidersSection(
                          providers: detail.watchProviders!,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (detail.similar?.results.isNotEmpty == true) ...[
                      const _SectionTitle(title: 'Similar Movies'),
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: detail.similar!.results.length,
                          itemBuilder: (_, index) {
                            return MovieCard(
                              movie: detail.similar!.results[index],
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrailer(BuildContext context, String key) {
    final controller = YoutubePlayerController(
      initialVideoId: key,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideThumbnail: true,
      ),
    );

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: CinePalette.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(controller: controller),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    controller.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return CineGlassPanel(
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: CinePalette.surface.withAlpha(170),
        border: Border.all(color: CinePalette.stroke.withAlpha(120)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CinePalette.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CinePalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _WatchlistButton extends ConsumerWidget {
  final int movieId;
  final MovieDetail detail;

  const _WatchlistButton({required this.movieId, required this.detail});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final watchlistState = ref.watch(watchlistProvider);
    final isInWatchlist = watchlistState.movies.any((movieRow) {
      final nested = movieRow['movie_data'];
      final dynamic candidate = nested is Map
          ? nested['id'] ?? movieRow['movie_id']
          : movieRow['id'];
      return int.tryParse(candidate?.toString() ?? '') == movieId;
    });

    return ElevatedButton.icon(
      onPressed: user == null
          ? null
          : () {
              if (isInWatchlist) {
                ref
                    .read(watchlistProvider.notifier)
                    .removeFromWatchlist(movieId);
              } else {
                ref
                    .read(watchlistProvider.notifier)
                    .addToWatchlist(
                      movieId: movieId,
                      movieData: detail.toJson(),
                    );
              }
            },
      icon: Icon(
        isInWatchlist ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        size: 18,
      ),
      label: Text(isInWatchlist ? 'Saved' : 'Add Watchlist'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isInWatchlist
            ? CinePalette.accentAlt.withAlpha(220)
            : null,
        foregroundColor: isInWatchlist ? const Color(0xFF052420) : null,
      ),
    );
  }
}

class _RateButton extends ConsumerStatefulWidget {
  final int movieId;

  const _RateButton({required this.movieId});

  @override
  ConsumerState<_RateButton> createState() => _RateButtonState();
}

class _RateButtonState extends ConsumerState<_RateButton> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final ratingsState = ref.watch(ratingsProvider);
    final userRating = ratingsState.ratings[widget.movieId];

    return OutlinedButton.icon(
      onPressed: user == null ? null : () => _showRatingDialog(context),
      icon: Icon(
        userRating != null ? Icons.star_rounded : Icons.star_border_rounded,
        size: 18,
        color: userRating != null
            ? CinePalette.accent
            : CinePalette.textPrimary,
      ),
      label: Text(
        userRating != null ? '${userRating.toStringAsFixed(0)}/10' : 'Rate',
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    double tempRating = 0;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CinePalette.backgroundSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Rate this movie',
          style: TextStyle(color: CinePalette.textPrimary),
        ),
        content: RatingBar.builder(
          initialRating: 0,
          minRating: 1,
          direction: Axis.horizontal,
          itemCount: 5,
          itemSize: 38,
          itemBuilder: (context, index) =>
              const Icon(Icons.star, color: CinePalette.accent),
          onRatingUpdate: (rating) => tempRating = rating * 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(ratingsProvider.notifier)
                  .rateMovie(movieId: widget.movieId, rating: tempRating);
              Navigator.pop(context);
            },
            child: const Text('Save Rating'),
          ),
        ],
      ),
    );
  }
}

class _CastCard extends StatelessWidget {
  final CastMember member;

  const _CastCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 122,
      margin: const EdgeInsets.only(right: 10),
      child: CineGlassPanel(
        borderRadius: BorderRadius.circular(14),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: member.profileUrl != null
                  ? CachedNetworkImage(
                      imageUrl: member.profileUrl!,
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const ColoredBox(color: CinePalette.surfaceAlt),
                      errorWidget: (context, url, error) =>
                          const ColoredBox(color: CinePalette.surfaceAlt),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: CinePalette.surfaceAlt,
                      child: const Icon(
                        Icons.person,
                        color: CinePalette.textMuted,
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              member.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CinePalette.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              member.character,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CinePalette.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchProvidersSection extends StatelessWidget {
  final WatchProviders providers;

  const _WatchProvidersSection({required this.providers});

  @override
  Widget build(BuildContext context) {
    final country =
        providers.results?['US'] ?? providers.results?.values.firstOrNull;

    if (country == null) {
      return const Text(
        'No provider data available.',
        style: TextStyle(color: CinePalette.textMuted),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (country.flatrate != null && country.flatrate!.isNotEmpty)
          _ProviderCategory(title: 'Streaming', entries: country.flatrate!),
        if (country.rent != null && country.rent!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ProviderCategory(title: 'Rent', entries: country.rent!),
        ],
        if (country.buy != null && country.buy!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _ProviderCategory(title: 'Buy', entries: country.buy!),
        ],
      ],
    );
  }
}

class _ProviderCategory extends StatelessWidget {
  final String title;
  final List<ProviderInfo> entries;

  const _ProviderCategory({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: CinePalette.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: entries
              .map((entry) => _ProviderChip(provider: entry))
              .toList(),
        ),
      ],
    );
  }
}

class _ProviderChip extends StatelessWidget {
  final ProviderInfo provider;

  const _ProviderChip({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: CinePalette.surface.withAlpha(170),
        border: Border.all(color: CinePalette.stroke.withAlpha(130)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.logoPath.isNotEmpty)
            CachedNetworkImage(
              imageUrl: provider.logoPath,
              width: 22,
              height: 22,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          if (provider.logoPath.isNotEmpty) const SizedBox(width: 7),
          Text(
            provider.providerName,
            style: const TextStyle(
              color: CinePalette.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailStateScaffold extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool showProgress;

  const _DetailStateScaffold({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CinematicBackdrop(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: CineGlassPanel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: CinePalette.accent, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
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
                  if (showProgress) ...[
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
