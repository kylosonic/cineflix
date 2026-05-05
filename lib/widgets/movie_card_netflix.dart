import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';

class MovieCardNetflix extends StatelessWidget {
  final Movie movie;
  const MovieCardNetflix({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/movie/${movie.id}'),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              movie.posterPath != null
                  ? Image.network(
                      movie.posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: const Color(0xFF2A2A2A),
                        child: const Icon(Icons.movie, color: Colors.grey, size: 30),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.movie, color: Colors.grey, size: 30),
                    ),
              // Bottom gradient overlay
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withAlpha(200),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Rating badge
              Positioned(
                top: 6, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5C518),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(movie.voteAverage.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      )),
                ),
              ),
              // Title
              Positioned(
                bottom: 8, left: 8, right: 8,
                child: Text(movie.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
