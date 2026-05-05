import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/movie.dart';
import '../../providers/movie_providers.dart';
import '../../widgets/movie_card.dart';
import '../../widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CineFlix',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(popularMoviesProvider(1));
          ref.invalidate(topRatedMoviesProvider(1));
          ref.invalidate(nowPlayingMoviesProvider(1));
        },
        child: ListView(
          children: [
            const SizedBox(height: 8),
            _buildSection('🔥 Trending Now', ref.watch(trendingMoviesProvider), ref, true),
            _buildSection('⭐ Top Rated', ref.watch(topRatedMoviesProvider(1)), ref, false),
            _buildSection('🎬 Now Playing', ref.watch(nowPlayingMoviesProvider(1)), ref, false),
            _buildSection('📈 Popular', ref.watch(popularMoviesProvider(1)), ref, false),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, AsyncValue<List<Movie>> asyncMovies,
      WidgetRef ref, bool isLarge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: isLarge ? 280 : 200,
          child: asyncMovies.when(
            data: (movies) {
              final list = movies.where((m) => m.posterPath != null).toList();
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return MovieCard(
                    movie: list[index],
                    isLarge: isLarge,
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(
              child: Text('Error: $e', style: const TextStyle(color: Colors.grey)),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
