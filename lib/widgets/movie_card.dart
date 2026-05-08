import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/cine_theme.dart';

class MovieCard extends StatefulWidget {
  final Movie movie;
  final bool isLarge;
  final String? heroTag;

  const MovieCard({
    super.key,
    required this.movie,
    this.isLarge = false,
    this.heroTag,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final width = widget.isLarge ? 190.0 : 142.0;
    final height = widget.isLarge ? 282.0 : 212.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          final heroTag = widget.heroTag;
          final route = (heroTag == null || heroTag.isEmpty)
              ? '/movie/${widget.movie.id}'
              : '/movie/${widget.movie.id}?heroTag=${Uri.encodeComponent(heroTag)}';
          context.push(route);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: width,
          margin: const EdgeInsets.only(right: 12),
          transform: Matrix4.translationValues(0, _hovered ? -4.0 : 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CinePalette.stroke.withAlpha(130)),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: CinePalette.accent.withAlpha(38),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                child: SizedBox(
                  height: height,
                  width: width,
                  child: _buildPoster(),
                ),
              ),
              Container(
                width: width,
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                decoration: BoxDecoration(
                  color: CinePalette.surface.withAlpha(175),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.isLarge ? 14 : 12,
                        fontWeight: FontWeight.w700,
                        color: CinePalette.textPrimary,
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
                          widget.movie.voteAverage.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: CinePalette.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.movie.releaseDate?.split('-').first ??
                                'Unknown',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: CinePalette.textMuted,
                            ),
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

  Widget _buildPoster() {
    Widget poster;

    if (widget.movie.posterPath == null || widget.movie.posterUrl == null) {
      poster = Container(
        color: CinePalette.surfaceAlt,
        child: const Center(
          child: Icon(
            Icons.movie_creation_outlined,
            color: CinePalette.textMuted,
          ),
        ),
      );
    } else {
      poster = CachedNetworkImage(
        imageUrl: widget.movie.posterUrl!,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          color: CinePalette.surfaceAlt,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: CinePalette.surfaceAlt,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: CinePalette.textMuted,
            ),
          ),
        ),
      );
    }

    final heroTag = widget.heroTag;
    if (heroTag == null || heroTag.isEmpty) {
      return poster;
    }

    return Hero(tag: heroTag, child: poster);
  }
}
