import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'repository.dart';
import 'theme.dart';
import 'widgets.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.repository,
    required this.catalog,
    required this.onMovieSelected,
  });

  final MovieRepository repository;
  final List<Movie> catalog;
  final ValueChanged<Movie> onMovieSelected;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  int _requestToken = 0;
  bool _isLoading = false;
  String? _errorMessage;
  String? _resultLabel;
  List<Movie> _results = const <Movie>[];
  List<Movie> _savedResults = const <Movie>[];
  int? _selectedGenreId;
  String _savedQuery = '';
  String? _savedErrorMessage;
  String? _savedResultLabel;

  GenreOption? get _selectedGenre {
    for (final genre in popularGenres) {
      if (genre.id == _selectedGenreId) {
        return genre;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
        _resultLabel = null;
        _results = const <Movie>[];
        _selectedGenreId = null;
      });
      return;
    }

    final localMatches = _searchCatalog(trimmed);
    setState(() {
      _selectedGenreId = null;
      _isLoading = trimmed.length >= 2;
      _errorMessage = null;
      _resultLabel = 'Top matches';
      _results = localMatches;
    });

    if (trimmed.length < 2) {
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query) async {
    final token = ++_requestToken;
    final localMatches = _searchCatalog(query);

    setState(() {
      _isLoading = true;
      _selectedGenreId = null;
      _errorMessage = null;
      _resultLabel = 'Results for "$query"';
      _results = localMatches;
    });

    try {
      final remoteResults = await widget.repository.searchMovies(query);
      if (!mounted || token != _requestToken) {
        return;
      }

      setState(() {
        _isLoading = false;
        _results = _mergeMovies(localMatches, remoteResults);
      });
    } catch (error) {
      if (!mounted || token != _requestToken) {
        return;
      }

      setState(() {
        _isLoading = false;
        _results = localMatches;
        _errorMessage = localMatches.isEmpty
            ? error.toString()
            : 'Showing local matches while TMDB search is unavailable.';
      });
    }
  }

  Future<void> _searchByGenre(GenreOption genre) async {
    _debounce?.cancel();
    _savedQuery = _controller.text;
    _savedResults = List<Movie>.from(_results);
    _savedErrorMessage = _errorMessage;
    _savedResultLabel = _resultLabel;
    _controller.clear();

    final localMatches = widget.catalog
        .where((m) => m.genreIds.contains(genre.id))
        .toList();

    setState(() {
      _selectedGenreId = genre.id;
      _isLoading = false;
      _errorMessage = null;
      _resultLabel = '${genre.label} picks';
      _results = localMatches;
    });
  }

  void _clearGenreSelection() {
    _debounce?.cancel();
    _requestToken++;
    final restoredQuery = _savedQuery;

    _controller.value = TextEditingValue(
      text: restoredQuery,
      selection: TextSelection.collapsed(offset: restoredQuery.length),
    );

    setState(() {
      _selectedGenreId = null;
      _isLoading = false;
      _errorMessage = _savedErrorMessage;
      _resultLabel = _savedResultLabel;
      _results = List<Movie>.from(_savedResults);
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedGenre = _selectedGenre;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Search', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 22),
            SearchInputField(
              controller: _controller,
              onChanged: _onQueryChanged,
              showClear: _controller.text.isNotEmpty,
              onClear: () {
                _controller.clear();
                _onQueryChanged('');
              },
            ),
            const SizedBox(height: 26),
            if (_controller.text.isEmpty) ...<Widget>[
              Text(
                'Trending Tonight',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 238,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.catalog.take(6).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final movie = widget.catalog[index];
                    return SizedBox(
                      width: 132,
                      child: GestureDetector(
                        onTap: () => widget.onMovieSelected(movie),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: NetworkArtwork(
                                  imageUrl: movie.posterUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              movie.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              movie.primaryGenre,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
            ],
            Text(
              'Popular Genres',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            if (selectedGenre != null)
              _SelectedGenreRow(
                genreLabel: selectedGenre.label,
                onBack: _clearGenreSelection,
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: popularGenres.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.7,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemBuilder: (context, index) {
                  final genre = popularGenres[index];
                  return GenreTile(
                    label: genre.label,
                    selected: _selectedGenreId == genre.id,
                    onTap: () => _searchByGenre(genre),
                  );
                },
              ),
            const SizedBox(height: 26),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 12, bottom: 12),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Color(0xFFF51C5B),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Searching TMDB...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null && _results.isEmpty)
              ErrorInlineCard(message: _errorMessage!)
            else if (_resultLabel != null || _results.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_resultLabel != null)
                    Text(
                      _resultLabel!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  if (_errorMessage != null && _results.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    ErrorInlineCard(message: _errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  if (_results.isEmpty)
                    const EmptyCollectionCard(
                      title: 'No results yet',
                      subtitle:
                          'Try another movie title or tap a different genre.',
                    )
                  else
                    for (final movie in _results.take(10))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: MovieListCard(
                          movie: movie,
                          onTap: () => widget.onMovieSelected(movie),
                        ),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Movie> _searchCatalog(String query) {
    final normalized = query.toLowerCase().trim();
    if (normalized.isEmpty) {
      return const <Movie>[];
    }

    final ranked = <({Movie movie, int score})>[];

    for (final movie in widget.catalog) {
      final title = movie.title.toLowerCase();
      final genres = movie.genres.join(' ').toLowerCase();
      final overview = movie.overview.toLowerCase();
      var score = 0;

      if (title == normalized) {
        score += 120;
      }
      if (title.startsWith(normalized)) {
        score += 80;
      }
      if (title.contains(normalized)) {
        score += 60;
      }
      if (genres.contains(normalized)) {
        score += 35;
      }
      if (overview.contains(normalized)) {
        score += 20;
      }
      if (movie.yearLabel.contains(query)) {
        score += 10;
      }

      if (score > 0) {
        ranked.add((movie: movie, score: score));
      }
    }

    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked.map((entry) => entry.movie).take(8).toList();
  }

  List<Movie> _mergeMovies(List<Movie> primary, List<Movie> secondary) {
    final merged = <Movie>[];
    final seen = <int>{};

    for (final movie in <Movie>[...primary, ...secondary]) {
      if (seen.add(movie.id)) {
        merged.add(movie);
      }
    }

    return merged;
  }
}

class _SelectedGenreRow extends StatelessWidget {
  const _SelectedGenreRow({
    required this.genreLabel,
    required this.onBack,
  });

  final String genreLabel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.stroke),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 14,
                ),
                SizedBox(width: 8),
                Text(
                  'Back',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        FilterChipPill(
          label: genreLabel,
          selected: true,
          onTap: onBack,
        ),
      ],
    );
  }
}
