import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../models/movie.dart';
import '../../providers/movie_providers.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/movie_card.dart';

class MovieDetailScreen extends ConsumerWidget {
  final int movieId;
  const MovieDetailScreen({super.key, required this.movieId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(movieDetailProvider(movieId));

    return detailAsync.when(
      data: (detail) => _MovieDetailContent(movieId: movieId, detail: detail),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
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
        .where((v) => v.type == 'Trailer' && v.site == 'YouTube')
        .firstOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (detail.backdropUrl != null)
                    CachedNetworkImage(
                      imageUrl: detail.backdropUrl!,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => Container(color: Colors.grey[900]),
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.grey[900]),
                    )
                  else
                    Container(color: Colors.grey[900]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F0F0F).withAlpha(230),
                          const Color(0xFF0F0F0F),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail.title,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('${detail.voteAverage.toStringAsFixed(1)} / 10',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(width: 16),
                      if (detail.runtime != null)
                        Text('${detail.runtime} min',
                            style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      if (detail.releaseDate != null)
                        Text(detail.releaseDate!,
                            style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: detail.genres
                        .map((g) => Chip(
                              label: Text(g.name),
                              backgroundColor: Colors.red.withAlpha(50),
                              labelStyle: const TextStyle(fontSize: 12),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      if (trailer != null)
                        _ActionButton(
                          icon: Icons.play_arrow,
                          label: 'Trailer',
                          onTap: () => _showTrailer(context, trailer.key),
                        ),
                      const SizedBox(width: 12),
                      _WatchlistButton(movieId: movieId, detail: detail),
                      const SizedBox(width: 12),
                      _RateButton(movieId: movieId),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Overview
                  const Text('Overview',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(detail.overview,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.grey, height: 1.5)),
                  const SizedBox(height: 24),

                  // Cast
                  if (detail.credits?.cast.isNotEmpty == true) ...[
                    const Text('Cast',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            detail.credits!.cast.take(15).length,
                        itemBuilder: (context, index) {
                          final member =
                              detail.credits!.cast.elementAt(index);
                          return _CastCard(member: member);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Watch Providers
                  if (detail.watchProviders != null) ...[
                    const Text('Where to Watch',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _WatchProvidersSection(
                        providers: detail.watchProviders!),
                    const SizedBox(height: 24),
                  ],

                  // Similar Movies
                  if (detail.similar?.results.isNotEmpty == true) ...[
                    const Text('Similar Movies',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: detail.similar!.results.length,
                        itemBuilder: (context, index) {
                          return MovieCard(
                              movie: detail.similar!.results[index]);
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
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
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(controller: controller),
            ),
            TextButton(
              onPressed: () {
                controller.dispose();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.withAlpha(180),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
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
    final isInWatchlist =
        watchlistState.movies.any((m) => m['id'] == movieId);

    return ElevatedButton.icon(
      onPressed: user == null
          ? null
          : () {
              if (isInWatchlist) {
                ref
                    .read(watchlistProvider.notifier)
                    .removeFromWatchlist(movieId);
              } else {
                ref.read(watchlistProvider.notifier).addToWatchlist(
                      movieId: movieId,
                      movieData: detail.toJson(),
                    );
              }
            },
      icon: Icon(
          isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
          size: 20),
      label: Text(isInWatchlist ? 'Saved' : 'Watchlist'),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isInWatchlist ? Colors.red.withAlpha(180) : Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

    return ElevatedButton.icon(
      onPressed: user == null
          ? null
          : () => _showRatingDialog(context),
      icon: Icon(
        userRating != null ? Icons.star : Icons.star_border,
        size: 20,
        color: userRating != null ? Colors.amber : Colors.white,
      ),
      label: Text(userRating != null
          ? '${userRating.toStringAsFixed(0)}/10'
          : 'Rate'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  void _showRatingDialog(BuildContext context) {
    double tempRating = 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            const Text('Rate this movie', style: TextStyle(color: Colors.white)),
        content: RatingBar.builder(
          initialRating: 0,
          minRating: 1,
          direction: Axis.horizontal,
          itemCount: 5,
          itemSize: 40,
          itemBuilder: (context, _) =>
              const Icon(Icons.star, color: Colors.amber),
          onRatingUpdate: (rating) {
            tempRating = rating * 2;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(ratingsProvider.notifier).rateMovie(
                    movieId: widget.movieId,
                    rating: tempRating,
                  );
              Navigator.pop(context);
            },
            child: const Text('Rate'),
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
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: member.profileUrl != null
                ? CachedNetworkImage(
                    imageUrl: member.profileUrl!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    errorWidget: (ctx, url, err) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  )
                : Container(
                    height: 100,
                    width: 100,
                    color: Colors.grey[800],
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            member.name,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            member.character,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _WatchProvidersSection extends StatelessWidget {
  final WatchProviders providers;
  const _WatchProvidersSection({required this.providers});

  @override
  Widget build(BuildContext context) {
    final country = providers.results?['US'] ??
        providers.results?.values.firstOrNull;

    if (country == null) {
      return const Text('No watch provider data available',
          style: TextStyle(color: Colors.grey));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (country.flatrate != null && country.flatrate!.isNotEmpty) ...[
          const Text('Streaming:',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: country.flatrate!
                .map((p) => _ProviderChip(provider: p))
                .toList(),
          ),
        ],
        if (country.rent != null && country.rent!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Rent:',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children:
                country.rent!.map((p) => _ProviderChip(provider: p)).toList(),
          ),
        ],
        if (country.buy != null && country.buy!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Buy:',
              style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children:
                country.buy!.map((p) => _ProviderChip(provider: p)).toList(),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (provider.logoPath.isNotEmpty)
            CachedNetworkImage(
              imageUrl: provider.logoPath,
              width: 24,
              height: 24,
            ),
          if (provider.logoPath.isNotEmpty) const SizedBox(width: 8),
          Text(provider.providerName,
              style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
