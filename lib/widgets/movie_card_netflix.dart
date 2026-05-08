import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/cine_theme.dart';
import '../models/movie.dart';

class MovieCardNetflix extends StatefulWidget {
  final Movie movie;
  final String? heroTag;

  const MovieCardNetflix({super.key, required this.movie, this.heroTag});
  @override
  State<MovieCardNetflix> createState() => _MovieCardNetflixState();
}

class _MovieCardNetflixState extends State<MovieCardNetflix> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          final heroTag = widget.heroTag;
          final route = (heroTag == null || heroTag.isEmpty)
              ? '/movie/${widget.movie.id}'
              : '/movie/${widget.movie.id}?heroTag=${Uri.encodeComponent(heroTag)}';
          context.push(route);
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          scale: _pressed ? 0.97 : (_hovered ? 1.03 : 1.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 126,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CinePalette.stroke.withAlpha(140)),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        blurRadius: 16,
                        color: CinePalette.accent.withAlpha(45),
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PosterWithHero(
                    posterPath: widget.movie.posterPath,
                    posterUrl: widget.movie.posterUrl,
                    heroTag: widget.heroTag,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 66,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(215),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 7,
                    left: 7,
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
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF261A01),
                        ),
                      ),
                    ),
                  ),
                  if (_hovered || _pressed)
                    const Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Color(0xFFEDEFF7),
                        size: 38,
                      ),
                    ),
                  Positioned(
                    bottom: 10,
                    left: 8,
                    right: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.movie.releaseDate?.split('-').first ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFFCBD2E6),
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
      ),
    );
  }
}

class _PosterWithHero extends StatelessWidget {
  final String? posterPath;
  final String? posterUrl;
  final String? heroTag;

  const _PosterWithHero({
    required this.posterPath,
    required this.posterUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final image = posterPath != null && posterUrl != null
        ? CachedNetworkImage(
            imageUrl: posterUrl!,
            fit: BoxFit.cover,
            memCacheWidth: 300,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (context, url) =>
                Container(color: CinePalette.surface),
            errorWidget: (context, url, error) =>
                Container(color: CinePalette.surface),
          )
        : Container(color: CinePalette.surface);

    final normalizedTag = heroTag?.trim();
    if (normalizedTag == null || normalizedTag.isEmpty) {
      return image;
    }

    return Hero(tag: normalizedTag, child: image);
  }
}
