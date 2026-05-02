enum AppTab { home, movies, search, tickets }

enum MovieCategoryTab { all, nowPlaying, upcoming }

typedef OpenMoviesCallback = void Function({
  MovieCategoryTab category,
  int? genreId,
});

class GenreOption {
  const GenreOption(this.id, this.label);

  final int id;
  final String label;
}

const popularGenres = <GenreOption>[
  GenreOption(28, 'Action'),
  GenreOption(878, 'Sci-Fi'),
  GenreOption(18, 'Drama'),
  GenreOption(16, 'Animation'),
  GenreOption(53, 'Thriller'),
  GenreOption(35, 'Comedy'),
];

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.rating,
    required this.genreIds,
    required this.genres,
    required this.releaseDate,
    required this.adult,
    this.runtimeMinutes,
  });

  final int id;
  final String title;
  final String overview;
  final String? posterPath;
  final String? backdropPath;
  final double rating;
  final List<int> genreIds;
  final List<String> genres;
  final String releaseDate;
  final bool adult;
  final int? runtimeMinutes;

  String? get posterUrl =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w500$posterPath';

  String? get backdropUrl => backdropPath == null
      ? null
      : 'https://image.tmdb.org/t/p/w780$backdropPath';

  String get primaryGenre => genres.isNotEmpty ? genres.first : 'Movie';

  String get secondaryGenre => genres.length > 1 ? genres[1] : primaryGenre;

  String get yearLabel =>
      releaseDate.length >= 4 ? releaseDate.substring(0, 4) : 'TBA';

  String get runtimeLabel =>
      runtimeMinutes != null && runtimeMinutes! > 0
          ? '${runtimeMinutes}m'
          : yearLabel;

  String get maturityLabel => adult ? 'R' : 'PG-13';
}

class HomeFeed {
  const HomeFeed({
    required this.nowPlaying,
    required this.upcoming,
    required this.topRated,
  });

  final List<Movie> nowPlaying;
  final List<Movie> upcoming;
  final List<Movie> topRated;

  List<Movie> get featured => nowPlaying.take(5).toList();

  List<Movie> get allMovies =>
      _mergeUnique(<List<Movie>>[nowPlaying, upcoming, topRated]);

  bool isUpcoming(Movie movie) => upcoming.any((item) => item.id == movie.id);

  bool isNowPlaying(Movie movie) =>
      nowPlaying.any((item) => item.id == movie.id);

  String badgeFor(Movie movie) => isUpcoming(movie) ? 'SOON' : 'NOW';

  static List<Movie> _mergeUnique(List<List<Movie>> groups) {
    final seen = <int>{};
    final items = <Movie>[];

    for (final group in groups) {
      for (final movie in group) {
        if (seen.add(movie.id)) {
          items.add(movie);
        }
      }
    }

    return items;
  }
}

class BookedTicket {
  const BookedTicket({
    required this.movie,
    required this.bookedAt,
    required this.price,
    required this.seatLabel,
    this.cancelled = false,
  });

  final Movie movie;
  final DateTime bookedAt;
  final double price;
  final String seatLabel;
  final bool cancelled;
}

class MovieDetail {
  const MovieDetail({
    required this.movie,
    required this.director,
    required this.cast,
    required this.language,
  });

  final Movie movie;
  final String director;
  final List<String> cast;
  final String language;
}
