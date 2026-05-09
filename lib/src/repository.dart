import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class MovieRepository {
  MovieRepository({
    required this.apiKey,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final http.Client _client;

  static const _baseUrl = 'https://api.themoviedb.org/3';

  Future<HomeFeed> fetchHomeFeed() async {
    final genres = await _fetchGenreMap();

    // 1. Fetch movies added by the Admin in Supabase
    final response = await Supabase.instance.client
        .from('movies')
        .select('tmdb_id, status')
        .not('tmdb_id', 'is', null);

    // Ensure it's treated as a list, even if Supabase returns null or dynamic
    final List<dynamic> sbMovies = (response as List<dynamic>?) ?? <dynamic>[];

    // 2. Separate into Now Playing (now_showing, featured) and Upcoming
    final nowShowingIds = <int>[];
    final upcomingIds = <int>[];
    
    for (final row in sbMovies) {
      if (row == null || row is! Map) continue;
      
      final id = row['tmdb_id'];
      final status = row['status'];
      
      if (id == null || id is! num) continue;
      
      final statusStr = status?.toString();
      if (statusStr == 'now_showing' || statusStr == 'featured') {
        nowShowingIds.add(id.toInt());
      } else if (statusStr == 'upcoming') {
        upcomingIds.add(id.toInt());
      }
    }

    // 3. Helper to fetch TMDB details for a list of IDs
    Future<List<Movie>> fetchMoviesByIds(List<int> ids) async {
      if (ids.isEmpty) return <Movie>[];
      final futures = ids.map((id) => _getJson('/movie/$id').catchError((_) => <String, dynamic>{}));
      final jsons = await Future.wait(futures);
      final validJsons = jsons.where((j) => j.isNotEmpty).toList();
      return _parseMoviesList(validJsons, genres);
    }

    // 4. Fetch the real TMDB data for these specific movies in parallel
    final results = await Future.wait([
      fetchMoviesByIds(nowShowingIds),
      fetchMoviesByIds(upcomingIds),
      _getJson('/movie/top_rated'), // Restored Top Rated public TMDB feed
    ]);

    // Safely extract results without dangerous forced casts
    final List<Movie> nowPlayingData = (results[0] is List) ? List<Movie>.from(results[0] as List) : <Movie>[];
    final List<Movie> upcomingData = (results[1] is List) ? List<Movie>.from(results[1] as List) : <Movie>[];
    final Map<String, dynamic> topRatedData = (results[2] is Map<String, dynamic>) ? results[2] as Map<String, dynamic> : <String, dynamic>{};

    return HomeFeed(
      nowPlaying: nowPlayingData,
      upcoming: upcomingData,
      topRated: _parseMovies(topRatedData, genres),
    );
  }

  Future<List<Movie>> searchMovies(String query) async {
    final genres = await _fetchGenreMap();
    final json = await _getJson(
      '/search/movie',
      queryParameters: <String, String>{
        'query': query,
        'include_adult': 'false',
      },
    );

    return _parseMovies(json, genres);
  }

  Future<List<Movie>> discoverMoviesByGenre(int genreId) async {
    final genres = await _fetchGenreMap();
    final json = await _getJson(
      '/discover/movie',
      queryParameters: <String, String>{
        'with_genres': '$genreId',
        'sort_by': 'popularity.desc',
        'include_adult': 'false',
      },
    );

    return _parseMovies(json, genres);
  }

  Future<MovieDetail> fetchMovieDetail(int movieId) async {
    final json = await _getJson(
      '/movie/$movieId',
      queryParameters: <String, String>{
        'append_to_response': 'credits,videos',
      },
    );

    final movie = _movieFromJson(json, const <int, String>{});
    final credits = json['credits'];
    final trailer = _pickTrailer(json);

    String director = 'Unknown';
    final cast = <String>[];
    String language = 'English';

    if (credits is Map<String, dynamic>) {
      final crew = credits['crew'];
      if (crew is List) {
        for (final member in crew) {
          if (member is Map<String, dynamic> && member['job'] == 'Director') {
            final name = member['name'];
            if (name is String && name.isNotEmpty) {
              director = name;
              break;
            }
          }
        }
      }

      final castEntries = credits['cast'];
      if (castEntries is List) {
        for (final member in castEntries.take(6)) {
          if (member is Map<String, dynamic>) {
            final name = member['name'];
            if (name is String && name.isNotEmpty) {
              cast.add(name);
            }
          }
        }
      }
    }

    final spokenLanguages = json['spoken_languages'];
    if (spokenLanguages is List && spokenLanguages.isNotEmpty) {
      final first = spokenLanguages.first;
      if (first is Map<String, dynamic>) {
        final englishName = first['english_name'];
        final name = first['name'];
        if (englishName is String && englishName.isNotEmpty) {
          language = englishName;
        } else if (name is String && name.isNotEmpty) {
          language = name;
        }
      }
    }

    return MovieDetail(
      movie: movie,
      director: director,
      cast: cast,
      language: language,
      trailer: trailer,
    );
  }

  Future<Map<int, String>> _fetchGenreMap() async {
    final json = await _getJson('/genre/movie/list');
    final entries = json['genres'];
    final map = <int, String>{};

    if (entries is List) {
      for (final entry in entries) {
        if (entry is Map<String, dynamic>) {
          final id = entry['id'];
          final name = entry['name'];
          if (id is num && name is String) {
            map[id.toInt()] = name;
          }
        }
      }
    }

    return map;
  }

  List<Movie> _parseMovies(
    Map<String, dynamic> json,
    Map<int, String> genreLookup,
  ) {
    final results = json['results'];
    if (results is! List) {
      return const <Movie>[];
    }

    final movies = <Movie>[];
    for (final item in results) {
      if (item is Map<String, dynamic>) {
        movies.add(_movieFromJson(item, genreLookup));
      }
    }

    return movies;
  }

  List<Movie> _parseMoviesList(
    List<dynamic> list,
    Map<int, String> genreLookup,
  ) {
    final movies = <Movie>[];
    for (final item in list) {
      if (item is Map<String, dynamic>) {
        movies.add(_movieFromJson(item, genreLookup));
      }
    }
    return movies;
  }

  Movie _movieFromJson(
    Map<String, dynamic> json,
    Map<int, String> genreLookup,
  ) {
    final ids = <int>[];
    final genres = <String>[];

    final genreIds = json['genre_ids'];
    if (genreIds is List) {
      for (final value in genreIds) {
        if (value is num) {
          final id = value.toInt();
          ids.add(id);
          final name = genreLookup[id];
          if (name != null) {
            genres.add(name);
          }
        }
      }
    }

    final inlineGenres = json['genres'];
    if (genres.isEmpty && inlineGenres is List) {
      for (final value in inlineGenres) {
        if (value is Map<String, dynamic>) {
          final id = value['id'];
          final name = value['name'];
          if (id is num) {
            ids.add(id.toInt());
          }
          if (name is String) {
            genres.add(name);
          }
        }
      }
    }

    return Movie(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? json['name'] ?? 'Untitled').toString(),
      overview: (json['overview'] ?? 'No description available yet.')
          .toString(),
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0,
      genreIds: ids,
      genres: genres,
      releaseDate: (json['release_date'] ?? '').toString(),
      adult: json['adult'] == true,
      runtimeMinutes: (json['runtime'] as num?)?.toInt(),
    );
  }

  MovieTrailer? _pickTrailer(Map<String, dynamic> json) {
    final videos = json['videos'];
    if (videos is! Map<String, dynamic>) {
      return null;
    }

    final results = videos['results'];
    if (results is! List) {
      return null;
    }

    MovieTrailer? bestMatch;
    var bestScore = -1;

    for (final item in results) {
      if (item is! Map<String, dynamic>) {
        continue;
      }

      final site = item['site'];
      final key = item['key'];
      if (site != 'YouTube' || key is! String || key.isEmpty) {
        continue;
      }

      final type = (item['type'] ?? '').toString();
      final official = item['official'] == true;
      final score = switch (type) {
        'Trailer' => official ? 6 : 4,
        'Teaser' => official ? 3 : 2,
        _ => official ? 1 : 0,
      };

      if (score <= bestScore) {
        continue;
      }

      bestScore = score;
      bestMatch = MovieTrailer(
        name: (item['name'] ?? 'Trailer').toString(),
        youtubeKey: key,
      );
    }

    return bestMatch;
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: <String, String>{
        'api_key': apiKey,
        'language': 'en-US',
        ...?queryParameters,
      },
    );

    final response = await _client.get(uri);
    final decoded = _decodeObject(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['status_message'] ??
          'TMDB request failed with ${response.statusCode}.';
      throw Exception(message);
    }

    return decoded;
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception('Unexpected TMDB response.');
  }

  void dispose() {
    _client.close();
  }
}
