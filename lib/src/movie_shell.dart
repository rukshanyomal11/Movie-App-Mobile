import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'home_page.dart';
import 'models.dart';
import 'movie_details_page.dart';
import 'movies_page.dart';
import 'repository.dart';
import 'search_page.dart';
import 'seat_selection_page.dart';
import 'tickets_page.dart';
import 'utils.dart';
import 'widgets.dart';

class MovieShell extends StatefulWidget {
  const MovieShell({
    super.key,
    required this.displayName,
    required this.onLogout,
  });

  final String displayName;
  final VoidCallback onLogout;

  @override
  State<MovieShell> createState() => _MovieShellState();
}

class _MovieShellState extends State<MovieShell> {
  AppTab _currentTab = AppTab.home;
  MovieCategoryTab _moviesCategory = MovieCategoryTab.all;
  int? _moviesGenreId;
  final List<BookedTicket> _tickets = <BookedTicket>[];
  Movie? _selectedMovie;
  Future<MovieDetail>? _selectedMovieDetailFuture;
  String? _selectedMovieBadge;
  ShowtimeSlot? _selectedShowtime;

  MovieRepository? _repository;
  Future<HomeFeed>? _feedFuture;
  String? _setupMessage;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _repository?.dispose();
    super.dispose();
  }

  void _bootstrap() {
    final apiKey =
        (dotenv.env['VITE_TMDB_API_KEY'] ?? dotenv.env['TMDB_API_KEY'] ?? '')
            .trim();

    if (apiKey.isEmpty) {
      setState(() {
        _setupMessage =
            'Add VITE_TMDB_API_KEY to .env so the app can load TMDB movies.';
      });
      return;
    }

    _repository?.dispose();
    final repository = MovieRepository(apiKey: apiKey);

    setState(() {
      _setupMessage = null;
      _repository = repository;
      _feedFuture = repository.fetchHomeFeed();
    });
  }

  void _reloadFeed() {
    if (_repository == null) {
      return;
    }

    setState(() {
      _feedFuture = _repository!.fetchHomeFeed();
    });
  }

  void _selectTab(AppTab tab) {
    setState(() {
      _currentTab = tab;
      _selectedMovie = null;
      _selectedMovieDetailFuture = null;
      _selectedMovieBadge = null;
      _selectedShowtime = null;
    });
  }

  void _openMovies({
    MovieCategoryTab category = MovieCategoryTab.all,
    int? genreId,
  }) {
    setState(() {
      _currentTab = AppTab.movies;
      _moviesCategory = category;
      _moviesGenreId = genreId;
      _selectedMovie = null;
      _selectedMovieDetailFuture = null;
      _selectedMovieBadge = null;
      _selectedShowtime = null;
    });
  }

  void _bookMovie(Movie movie) {
    final order = _tickets.length + 1;
    final ticket = BookedTicket(
      movie: movie,
      bookedAt: DateTime.now().add(Duration(days: order.isEven ? 1 : 0)),
      price: (10 + movie.rating).clamp(12, 24).toDouble(),
      seatLabel: buildSeatLabel(movie, order),
    );

    setState(() {
      _tickets.insert(0, ticket);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${movie.title} added to My Tickets'),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              if (!mounted) {
                return;
              }
              setState(() {
                _currentTab = AppTab.tickets;
                _selectedMovie = null;
                _selectedMovieDetailFuture = null;
                _selectedMovieBadge = null;
                _selectedShowtime = null;
              });
            },
          ),
        ),
      );
  }

  void _showMovieDetails(Movie movie, {String? badge}) {
    if (_repository == null) {
      return;
    }

    setState(() {
      _selectedMovie = movie;
      _selectedMovieBadge = badge;
      _selectedMovieDetailFuture = _repository!.fetchMovieDetail(movie.id);
      _selectedShowtime = null;
    });
  }

  void _confirmSeatBooking(List<String> seats, double total) {
    if (_selectedMovie == null || _selectedShowtime == null) {
      return;
    }

    final slot = _selectedShowtime!;
    final ticket = BookedTicket(
      movie: _selectedMovie!,
      bookedAt: slot.date,
      price: total,
      seatLabel: '${slot.timeLabel} | ${slot.hall} | ${seats.join(', ')}',
    );

    setState(() {
      _tickets.insert(0, ticket);
      _currentTab = AppTab.tickets;
      _selectedMovie = null;
      _selectedMovieDetailFuture = null;
      _selectedMovieBadge = null;
      _selectedShowtime = null;
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${ticket.movie.title} booked for ${slot.timeLabel}'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_setupMessage != null) {
      return Scaffold(
        body: SafeArea(
          child: SetupStateView(message: _setupMessage!, onRetry: _bootstrap),
        ),
      );
    }

    if (_repository == null || _feedFuture == null) {
      return const Scaffold(
        body: SafeArea(
          child: LoadingStateView(
            title: 'Preparing CineBook',
            subtitle: 'Warming up the theater lights...',
          ),
        ),
      );
    }

    return FutureBuilder<HomeFeed>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: SafeArea(
              child: LoadingStateView(
                title: 'Loading Movies',
                subtitle: 'Pulling the latest showtimes from TMDB...',
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: SafeArea(
              child: ErrorStateView(
                message: snapshot.error?.toString() ??
                    'We could not load movies right now.',
                onRetry: _reloadFeed,
              ),
            ),
          );
        }

        final feed = snapshot.data!;

        final body = _selectedMovie != null && _selectedShowtime != null
            ? SeatSelectionPage(
                movie: _selectedMovie!,
                showtime: _selectedShowtime!,
                onBack: () {
                  setState(() {
                    _selectedShowtime = null;
                  });
                },
                onContinue: _confirmSeatBooking,
              )
            : _selectedMovie != null && _selectedMovieDetailFuture != null
                ? MovieDetailsPage(
                    movie: _selectedMovie!,
                    detailFuture: _selectedMovieDetailFuture!,
                    badge: _selectedMovieBadge,
                    onBack: () {
                      setState(() {
                        _selectedMovie = null;
                        _selectedMovieDetailFuture = null;
                        _selectedMovieBadge = null;
                        _selectedShowtime = null;
                      });
                    },
                    onBook: _bookMovie,
                    onSelectShowtime: (slot) {
                      setState(() {
                        _selectedShowtime = slot;
                      });
                    },
                  )
                : IndexedStack(
                index: _currentTab.index,
                children: <Widget>[
                  HomePage(
                    displayName: widget.displayName,
                    feed: feed,
                    onBook: _bookMovie,
                    onMovieSelected: (movie) {
                      _showMovieDetails(movie, badge: feed.badgeFor(movie));
                    },
                    onOpenMovies: _openMovies,
                  ),
                  MoviesPage(
                    feed: feed,
                    initialCategory: _moviesCategory,
                    initialGenreId: _moviesGenreId,
                    onMovieSelected: (movie) {
                      _showMovieDetails(movie, badge: feed.badgeFor(movie));
                    },
                  ),
              SearchPage(
                repository: _repository!,
                catalog: feed.allMovies,
                onMovieSelected: (movie) {
                  _showMovieDetails(movie);
                },
                  ),
                  TicketsPage(
                    displayName: widget.displayName,
                    tickets: _tickets,
                    onBrowseMovies: () {
                      _openMovies();
                    },
                    onLogout: widget.onLogout,
                  ),
                ],
              );

        return Scaffold(
          body: body,
          bottomNavigationBar: AppBottomNavigationBar(
            currentTab: _currentTab,
            onSelect: _selectTab,
          ),
        );
      },
    );
  }
}
