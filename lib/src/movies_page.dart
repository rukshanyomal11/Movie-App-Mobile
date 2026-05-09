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
  static const int _pageSize = 6;

  late MovieCategoryTab _selectedCategory;
  late final ScrollController _scrollController;
  int? _selectedGenreId;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedGenreId = widget.initialGenreId;
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant MoviesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory ||
        oldWidget.initialGenreId != widget.initialGenreId) {
      setState(() {
        _selectedCategory = widget.initialCategory;
        _selectedGenreId = widget.initialGenreId;
        _currentPage = 0;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movies = _filteredMovies;
    final pageCount = movies.isEmpty ? 1 : (movies.length / _pageSize).ceil();
    final currentPage = _currentPage.clamp(0, pageCount - 1) as int;
    final startIndex = currentPage * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, movies.length) as int;
    final visibleMovies = movies.sublist(startIndex, endIndex);
    final hasPreviousPage = currentPage > 0;
    final hasNextPage = currentPage < pageCount - 1;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        controller: _scrollController,
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
                  _currentPage = 0;
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
                          _currentPage = 0;
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
                        _currentPage = 0;
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
              ...<Widget>[
                for (final movie in visibleMovies)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MovieListCard(
                      movie: movie,
                      badge: widget.feed.badgeFor(movie),
                      onTap: () => widget.onMovieSelected(movie),
                    ),
                  ),
                if (pageCount > 1) ...<Widget>[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.stroke),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Page ${currentPage + 1} of $pageCount',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Showing ${startIndex + 1}-$endIndex of ${movies.length} movies',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            _PaginationArrowButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              enabled: hasPreviousPage,
                              onTap: () => _goToPage(currentPage - 1),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List<Widget>.generate(
                                    pageCount,
                                    (index) => Padding(
                                      padding: EdgeInsets.only(
                                        right: index == pageCount - 1 ? 0 : 10,
                                      ),
                                      child: _PageNumberChip(
                                        label: '${index + 1}',
                                        selected: index == currentPage,
                                        onTap: () => _goToPage(index),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            _PaginationArrowButton(
                              icon: Icons.arrow_forward_ios_rounded,
                              enabled: hasNextPage,
                              onTap: () => _goToPage(currentPage + 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
          ],
        ),
      ),
    );
  }
}

class _PaginationArrowButton extends StatelessWidget {
  const _PaginationArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: enabled ? AppColors.accent : AppColors.accent.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
          size: 22,
        ),
      ),
    );
  }
}

class _PageNumberChip extends StatelessWidget {
  const _PageNumberChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.stroke,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
