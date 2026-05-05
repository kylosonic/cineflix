import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../providers/movie_providers.dart';
import '../../providers/auth_providers.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final watchlistState = ref.watch(watchlistProvider);
    final ratingsState = ref.watch(ratingsProvider);
    final favoritesState = ref.watch(favoritesProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Lists')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Sign in to manage your watchlist',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Lists'),
          bottom: const TabBar(
            labelColor: Color(0xFFE50914),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFE50914),
            tabs: [
              Tab(text: 'Watchlist'),
              Tab(text: 'Rated'),
              Tab(text: 'Favorites'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMovieGrid(context, watchlistState.movies, 'watchlist'),
            _buildRatedList(ratingsState.ratings),
            _buildMovieGrid(context, favoritesState.movies, 'favorites'),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieGrid(BuildContext context, List<Map<String, dynamic>> movies, String type) {
    if (movies.isEmpty) {
      return Center(
        child: Text(
          type == 'watchlist'
              ? 'No movies in your watchlist'
              : 'No favorites yet',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return _StoredMovieCard(data: movies[index]);
      },
    );
  }

  Widget _buildRatedList(Map<int, double> rated) {
    if (rated.isEmpty) {
      return const Center(
        child: Text('No ratings yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rated.length,
      itemBuilder: (context, index) {
        final entry = rated.entries.elementAt(index);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.amber,
            child: Text(
              entry.value.toStringAsFixed(0),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text('Movie #${entry.key}',
              style: const TextStyle(color: Colors.white)),
          trailing: RatingBarIndicator(
            rating: entry.value / 2,
            itemSize: 20,
            itemBuilder: (_, __) =>
                const Icon(Icons.star, color: Colors.amber),
          ),
        );
      },
    );
  }
}

class _StoredMovieCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StoredMovieCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = data['title']?.toString() ?? 'Unknown';
    final posterPath = data['poster_path']?.toString();
    final voteAverage =
        double.tryParse(data['vote_average']?.toString() ?? '0') ?? 0;
    final movieId = int.tryParse(data['id']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () {
        if (movieId > 0) {
          Navigator.of(context).pushNamed('/movie/$movieId');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 195,
              width: double.infinity,
              color: Colors.grey[900],
              child: posterPath != null
                  ? Image.network(
                      'https://image.tmdb.org/t/p/w500$posterPath',
                      fit: BoxFit.cover,
errorBuilder: (ctx, url, err) => 
                          const Icon(Icons.movie, color: Colors.grey),
                    )
                  : const Icon(Icons.movie, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 6),
          Text(title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white)),
          Row(
            children: [
              const Icon(Icons.star, size: 14, color: Colors.amber),
              const SizedBox(width: 2),
              Text(voteAverage.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}
