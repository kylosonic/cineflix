import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';

class MovieCardNetflix extends StatefulWidget {
  final Movie movie;
  const MovieCardNetflix({super.key, required this.movie});
  @override
  State<MovieCardNetflix> createState() => _MovieCardNetflixState();
}

class _MovieCardNetflixState extends State<MovieCardNetflix> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); context.push('/movie/${widget.movie.id}'); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _pressed ? 0.8 : 1.0,
        child: Container(
          width: 118,
          margin: const EdgeInsets.only(right: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(fit: StackFit.expand, children: [
              widget.movie.posterPath != null
                  ? Image.network(widget.movie.posterUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF1F1F1F)))
                  : Container(color: const Color(0xFF1F1F1F)),
              Positioned(bottom: 0, left: 0, right: 0, child: Container(
                height: 50,
                decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withAlpha(180), Colors.transparent])),
              )),
              Positioned(top: 5, left: 5, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFF5C518), borderRadius: BorderRadius.circular(3)),
                child: Text(widget.movie.voteAverage.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black)),
              )),
              Positioned(bottom: 6, left: 6, right: 6, child: Text(widget.movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white))),
            ]),
          ),
        ),
      ),
    );
  }
}
