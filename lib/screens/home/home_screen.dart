import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/movie.dart';
import '../../providers/movie_providers.dart';
import '../../widgets/movie_card_netflix.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _activeTab = 'trending';

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return isWide ? _buildWebLayout() : _buildMobileLayout();
  }

  // ── Mobile ──
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('CineFlix', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w900, color: const Color(0xFFF5C518))),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: Color(0xFFCCCCCC)), onPressed: () => context.go('/search')),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFF5C518),
        onRefresh: () async {
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(popularMoviesProvider(1));
          ref.invalidate(topRatedMoviesProvider(1));
          ref.invalidate(nowPlayingMoviesProvider(1));
        },
        child: ListView(children: [
          _MobileHero(ref: ref),
          const SizedBox(height: 4),
          _RowSection(title: 'Trending Now', asyncMovies: ref.watch(trendingMoviesProvider)),
          _RowSection(title: 'Top Rated', asyncMovies: ref.watch(topRatedMoviesProvider(1))),
          _RowSection(title: 'Now Playing', asyncMovies: ref.watch(nowPlayingMoviesProvider(1))),
          _RowSection(title: 'Popular', asyncMovies: ref.watch(popularMoviesProvider(1))),
          const SizedBox(height: 90),
        ]),
      ),
    );
  }

  // ── Web ──
  Widget _buildWebLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        titleSpacing: 20,
        title: Row(children: [
          Text('CineFlix', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w900, color: const Color(0xFFF5C518))),
          const SizedBox(width: 28),
          _WebTab('Trending', _activeTab == 'trending', () => setState(() => _activeTab = 'trending')),
          const SizedBox(width: 4),
          _WebTab('Top Rated', _activeTab == 'toprated', () => setState(() => _activeTab = 'toprated')),
          const SizedBox(width: 4),
          _WebTab('Now Playing', _activeTab == 'nowplaying', () => setState(() => _activeTab = 'nowplaying')),
          const SizedBox(width: 4),
          _WebTab('Popular', _activeTab == 'popular', () => setState(() => _activeTab = 'popular')),
        ]),
        actions: [IconButton(icon: const Icon(Icons.search_rounded, color: Color(0xFF999999)), onPressed: () => context.go('/search')), const SizedBox(width: 12)],
      ),
      body: _buildWebGrid(),
    );
  }

  Widget _buildWebGrid() {
    final asyncMovies = switch (_activeTab) {
      'trending' => ref.watch(trendingMoviesProvider),
      'toprated' => ref.watch(topRatedMoviesProvider(1)),
      'nowplaying' => ref.watch(nowPlayingMoviesProvider(1)),
      'popular' => ref.watch(popularMoviesProvider(1)),
      _ => ref.watch(trendingMoviesProvider),
    };
    return asyncMovies.when(
      data: (movies) {
        final list = movies.where((m) => m.posterPath != null).toList();
        return GridView.builder(
          padding: const EdgeInsets.all(18),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.68, crossAxisSpacing: 14, mainAxisSpacing: 18),
          itemCount: list.length,
          itemBuilder: (_, i) => _WebMovieCard(movie: list[i]),
        );
      },
      loading: () => _ShimmerGrid(),
      error: (e, _) => Center(child: Text('Failed to load', style: TextStyle(color: Colors.grey[600]))),
    );
  }
}

// ── Mobile Hero ──
class _MobileHero extends ConsumerWidget {
  final WidgetRef ref;
  const _MobileHero({required this.ref});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMovies = ref.watch(trendingMoviesProvider);
    return asyncMovies.when(
      data: (movies) {
        final hero = movies.cast<Movie?>().firstWhere((m) => m?.backdropPath != null, orElse: () => movies.firstOrNull);
        if (hero == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => context.push('/movie/${hero.id}'),
          child: Container(
            height: 240,
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(image: NetworkImage(hero.backdropUrl!), fit: BoxFit.cover),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withAlpha(220)]),
              ),
              child: Stack(children: [
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(hero.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFF5C518), borderRadius: BorderRadius.circular(4)),
                        child: Text(hero.voteAverage.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black)),
                      ),
                      const SizedBox(width: 10),
                      Text(hero.releaseDate?.substring(0, 4) ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
                    ]),
                  ]),
                ),
              ]),
            ),
          ),
        );
      },
      loading: () => Container(height: 240, margin: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFF1A1A1A))),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

// ── Row Section ──
class _RowSection extends StatelessWidget {
  final String title;
  final AsyncValue<List<Movie>> asyncMovies;
  const _RowSection({required this.title, required this.asyncMovies});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 8),
        child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      SizedBox(
        height: 148,
        child: asyncMovies.when(
          data: (movies) {
            final list = movies.where((m) => m.posterPath != null).toList();
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: list.length,
              itemBuilder: (_, i) => MovieCardNetflix(movie: list[i]),
            );
          },
          loading: () => _ShimmerRow(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    ]);
  }
}

// ── Web Tab ──
class _WebTab extends StatelessWidget {
  final String label; final bool active; final VoidCallback onTap;
  const _WebTab(this.label, this.active, this.onTap);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF5C518).withAlpha(18) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? const Color(0xFFF5C518) : const Color(0xFF999999))),
      ),
    );
  }
}

// ── Web Movie Card ──
class _WebMovieCard extends StatefulWidget {
  final Movie movie;
  const _WebMovieCard({required this.movie});
  @override
  State<_WebMovieCard> createState() => _WebMovieCardState();
}

class _WebMovieCardState extends State<_WebMovieCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/movie/${widget.movie.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(top: _hovered ? 0 : 4, bottom: _hovered ? 4 : 0),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), boxShadow: _hovered ? [BoxShadow(color: const Color(0xFFF5C518).withAlpha(25), blurRadius: 10, offset: const Offset(0, 3))] : null),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(fit: StackFit.expand, children: [
                  widget.movie.posterPath != null
                      ? Image.network(widget.movie.posterUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF1F1F1F)))
                      : Container(color: const Color(0xFF1F1F1F)),
                  Positioned(top: 6, left: 6, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFF5C518), borderRadius: BorderRadius.circular(3)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star_rounded, size: 10, color: Colors.black),
                      const SizedBox(width: 2),
                      Text(widget.movie.voteAverage.toStringAsFixed(1), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black)),
                    ]),
                  )),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Text(widget.movie.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(height: 2),
            Text(widget.movie.releaseDate?.substring(0, 4) ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
          ]),
        ),
      ),
    );
  }
}

// ── Shimmer Loading ──
class _ShimmerGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A1A),
      highlightColor: const Color(0xFF2A2A2A),
      child: GridView.builder(
        padding: const EdgeInsets.all(18),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, childAspectRatio: 0.68, crossAxisSpacing: 14, mainAxisSpacing: 18),
        itemCount: 15,
        itemBuilder: (_, __) => Container(decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8))),
      ),
    );
  }
}

class _ShimmerRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF1A1A1A),
      highlightColor: const Color(0xFF2A2A2A),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 8,
        itemBuilder: (_, __) => Container(width: 120, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8))),
      ),
    );
  }
}
