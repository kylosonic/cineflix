import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final bool isLarge;

  const MovieCard({super.key, required this.movie, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    final width = isLarge ? 180.0 : 130.0;
    final height = isLarge ? 270.0 : 195.0;

    return GestureDetector(
      onTap: () => context.push('/movie/${movie.id}'),
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: height,
                width: width,
                child: movie.posterPath != null
                    ? CachedNetworkImage(
                        imageUrl: movie.posterUrl!,
                        fit: BoxFit.cover,
                        placeholder: (c, s) => Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(Icons.movie, color: Colors.grey),
                          ),
                        ),
                        errorWidget: (c, s, e) => Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: const Center(
                          child: Icon(Icons.movie, color: Colors.grey),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isLarge ? 14 : 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(
                  movie.voteAverage.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
