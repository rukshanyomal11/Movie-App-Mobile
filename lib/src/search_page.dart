import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'repository.dart';
import 'widgets.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.repository,
    required this.onMovieSelected,
  });

  final MovieRepository repository;
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
  int? _selectedGenreId;

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

    _debounce = Timer(const Duration(milliseconds: 450), () {
      _search(trimmed);
    });
  }

  Future<void> _search(String query) async {
    final token = ++_requestToken;
    setState(() {
      _isLoading = true;
      _selectedGenreId = null;
      _errorMessage = null;
      _resultLabel = 'Search results';
    });

    try {
      final results = await widget.repository.searchMovies(query);
      if (!mounted || token != _requestToken) {
        return;
      }

      setState(() {
        _isLoading = false;
        _results = results;
      });
    } catch (error) {
      if (!mounted || token != _requestToken) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _searchByGenre(GenreOption genre) async {
    final token = ++_requestToken;
    _controller.clear();

    setState(() {
      _selectedGenreId = genre.id;
      _isLoading = true;
      _errorMessage = null;
      _resultLabel = '${genre.label} picks';
    });

    try {
      final results = await widget.repository.discoverMoviesByGenre(genre.id);
      if (!mounted || token != _requestToken) {
        return;
      }

      setState(() {
        _isLoading = false;
        _results = results;
      });
    } catch (error) {
      if (!mounted || token != _requestToken) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            ),
            const SizedBox(height: 26),
            Text(
              'Popular Genres',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
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
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFF51C5B)),
                ),
              )
            else if (_errorMessage != null)
              ErrorInlineCard(message: _errorMessage!)
            else if (_resultLabel != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    _resultLabel!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
}
