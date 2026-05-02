import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

class MoviesPage extends StatefulWidget {
  const MoviesPage({
    super.key,
    required this.feed,
    required this.initialCategory,
    required this.initialGenreId,
    required this.onMovieSelected,
  });

  final HomeFeed feed;
  final MovieCategoryTab initialCategory;
  final int? initialGenreId;
  final ValueChanged<Movie> onMovieSelected;

  @override
  State<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends State<MoviesPage> {
  late MovieCategoryTab _selectedCategory;
  int? _selectedGenreId;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedGenreId = widget.initialGenreId;
  }

  @override
  void didUpdateWidget(covariant MoviesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory ||
        oldWidget.initialGenreId != widget.initialGenreId) {
      setState(() {
        _selectedCategory = widget.initialCategory;
        _selectedGenreId = widget.initialGenreId;
      });
    }
  }

  List<Movie> get _filteredMovies {
    final base = switch (_selectedCategory) {
      MovieCategoryTab.all => widget.feed.allMovies,
      MovieCategoryTab.nowPlaying => widget.feed.nowPlaying,
      MovieCategoryTab.upcoming => widget.feed.upcoming,
    };

    if (_selectedGenreId == null) {
      return base;
    }

    return base
        .where((movie) => movie.genreIds.contains(_selectedGenreId))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final movies = _filteredMovies;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Movies', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Discover what\'s showing near you',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 26),
            SegmentedCategorySelector(
              selectedCategory: _selectedCategory,
              onSelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: popularGenres.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterChipPill(
                      label: 'All',
                      selected: _selectedGenreId == null,
                      onTap: () {
                        setState(() {
                          _selectedGenreId = null;
                        });
                      },
                    );
                  }

                  final genre = popularGenres[index - 1];
                  return FilterChipPill(
                    label: genre.label,
                    selected: _selectedGenreId == genre.id,
                    onTap: () {
                      setState(() {
                        _selectedGenreId = genre.id;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '${movies.length} movies found',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            if (movies.isEmpty)
              const EmptyCollectionCard(
                title: 'No movies found',
                subtitle:
                    'Try another category or genre to see more TMDB results.',
              )
            else
              for (final movie in movies.take(12))
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: MovieListCard(
                    movie: movie,
                    badge: widget.feed.badgeFor(movie),
                    onTap: () => widget.onMovieSelected(movie),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
