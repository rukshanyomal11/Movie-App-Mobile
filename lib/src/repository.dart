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

    // 1. Fetch ALL showtimes to determine which movies are active
    final stResponse = await Supabase.instance.client
        .from('showtimes')
        .select('''
          show_date,
          movie:movies (
            tmdb_id
          )
        ''');

    final List<dynamic> showtimes = (stResponse as List<dynamic>?) ?? <dynamic>[];
    final today = DateTime.now();
    final todayDateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    final nowShowingIds = <int>{};
    final upcomingIds = <int>{};
    
    for (final st in showtimes) {
      if (st == null || st is! Map) continue;
      final movie = st['movie'] as Map?;
      if (movie == null) continue;
      
      final tmdbId = movie['tmdb_id'] as int?;
      if (tmdbId == null) continue;
      
      final showDateStr = st['show_date']?.toString();
      if (showDateStr == todayDateStr) {
        nowShowingIds.add(tmdbId);
      } else if (showDateStr != null && showDateStr.compareTo(todayDateStr) > 0) {
        upcomingIds.add(tmdbId);
      }
    }
    
    // Deduplicate: If a movie is today, it's not "upcoming"
    upcomingIds.removeAll(nowShowingIds);

    // 3. Helper to fetch TMDB details for a list of IDs
    Future<List<Movie>> fetchMoviesByIds(Set<int> ids) async {
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
    final futures = await Future.wait<dynamic>([
      _getJson(
        '/movie/$movieId',
        queryParameters: <String, String>{
          'append_to_response': 'credits,videos',
        },
      ),
      Supabase.instance.client
          .from('movies')
          .select('''
            id,
            showtimes (
              id,
              show_date,
              start_time,
              status,
              ticket_price,
              seats_available,
              screens (
                name,
                format,
                theaters (
                  name,
                  city
                )
              )
            )
          ''')
          .eq('tmdb_id', movieId)
          .catchError((_) => <dynamic>[])
    ]);

    final json = futures[0] as Map<String, dynamic>;
    final sbMoviesList = futures[1] as List<dynamic>?;

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

    final List<ShowtimeDay> schedule = [];
    if (sbMoviesList != null) {
      final Map<String, List<ShowtimeSlot>> grouped = {};
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      for (final movieRow in sbMoviesList) {
        if (movieRow is! Map || movieRow['showtimes'] is! List) continue;
        final showtimes = movieRow['showtimes'] as List<dynamic>;
        
        for (final st in showtimes) {
          if (st is! Map) continue;
        
        final dateStr = st['show_date']?.toString() ?? '';
        final timeStr = st['start_time']?.toString() ?? '';
        final statusStr = st['status']?.toString() ?? 'scheduled';
        if (dateStr.isEmpty) continue;
        if (statusStr == 'cancelled') continue;
        
        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;
        final showDate = DateTime(date.year, date.month, date.day);
        if (showDate.isBefore(todayDate)) continue;
        
        final screen = st['screens'];
        final theater = screen is Map ? screen['theaters'] : null;
        
        // Format time HH:MM:SS to HH:MM AM/PM
        String formattedTime = timeStr;
        if (timeStr.length >= 5) {
          final parts = timeStr.split(':');
          if (parts.length >= 2) {
            int hour = int.tryParse(parts[0]) ?? 0;
            final min = parts[1];
            final ampm = hour >= 12 ? 'PM' : 'AM';
            hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
            formattedTime = '$hour:$min $ampm';
          }
        }
        
        final theaterName = theater is Map ? theater['name']?.toString() ?? 'Theater' : 'Theater';
        final theaterCity = theater is Map ? theater['city']?.toString() ?? '' : '';
        final fullTheater = theaterCity.isNotEmpty ? '$theaterName - $theaterCity' : theaterName;
        
        final slot = ShowtimeSlot(
          id: st['id']?.toString() ?? '',
          date: showDate,
          timeLabel: formattedTime,
          theater: fullTheater,
          hall: screen is Map ? screen['name']?.toString() ?? 'Screen' : 'Screen',
          format: screen is Map ? screen['format']?.toString() ?? '2D' : '2D',
          price: double.tryParse(st['ticket_price']?.toString() ?? '0') ?? 0.0,
          seatsLeft: st['seats_available'] is num ? (st['seats_available'] as num).toInt() : 0,
        );
        
        if (!grouped.containsKey(dateStr)) {
          grouped[dateStr] = [];
        }
        grouped[dateStr]!.add(slot);
      }
    }
      
    final sortedDates = grouped.keys.toList()..sort();
      for (final d in sortedDates) {
        final dateObj = DateTime.parse(d);
        final slots = grouped[d]!..sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
        schedule.add(ShowtimeDay(date: dateObj, slots: slots));
      }
    }

    return MovieDetail(
      movie: movie,
      director: director,
      cast: cast,
      language: language,
      trailer: trailer,
      schedule: schedule,
    );
  }

  Future<List<String>> fetchBookedSeats(String showtimeId) async {
    final response = await Supabase.instance.client
        .from('booking_seats')
        .select('seat_label, bookings!inner(showtime_id)')
        .eq('bookings.showtime_id', showtimeId);
    
    if (response is List) {
      return response.map((row) => row['seat_label'].toString()).toList();
    }
    return [];
  }

  Future<void> createBooking({
    required String showtimeId,
    required List<String> seats,
    required double totalAmount,
  }) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    String? appUserId;

    if (authUser != null) {
      final res = await Supabase.instance.client
          .from('app_users')
          .select('id')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();
      appUserId = res?['id']?.toString();
    }

    if (appUserId == null) throw Exception('You must be logged in to book tickets.');

    final bookingId = 'BK-${DateTime.now().millisecondsSinceEpoch}';
    
    // 1. Create the booking
    final booking = await Supabase.instance.client.from('bookings').insert({
      'booking_code': bookingId,
      'user_id': appUserId,
      'showtime_id': showtimeId,
      'seats_count': seats.length,
      'total_amount': totalAmount,
      'payment_status': 'paid',
      'booking_status': 'confirmed',
    }).select().single();

    final realBookingId = booking['id'];

    // 2. Insert the seats
    final seatInserts = seats.map((seat) => {
      'booking_id': realBookingId,
      'seat_label': seat,
      'seat_price': totalAmount / seats.length, // Rough estimate per seat
    }).toList();

    await Supabase.instance.client.from('booking_seats').insert(seatInserts);
  }

  Future<List<BookedTicket>> fetchMyBookings() async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return [];

    final userRes = await Supabase.instance.client
        .from('app_users')
        .select('id')
        .eq('auth_user_id', authUser.id)
        .maybeSingle();
    
    if (userRes == null) return [];
    final appUserId = userRes['id'];

    final response = await Supabase.instance.client
        .from('bookings')
        .select('''
          id,
          booking_code,
          total_amount,
          booked_at,
          booking_status,
          showtimes (
            id,
            show_date,
            start_time,
            screens (
              name
            ),
            movies (
              id,
              title,
              poster_url
            )
          ),
          booking_seats (
            seat_label
          )
        ''')
        .eq('user_id', appUserId)
        .order('booked_at', ascending: false);
    
    if (response is! List) return [];

    final List<BookedTicket> tickets = [];
    for (final row in response) {
      if (row is! Map) continue;
      
      final st = row['showtimes'];
      if (st is! Map) continue;
      
      final movieRow = st['movies'];
      if (movieRow is! Map) continue;
      
      final screen = st['screens'];
      final seats = row['booking_seats'] as List? ?? [];
      final seatsList = seats.map((s) => s['seat_label'].toString()).toList();
      final showDate = DateTime.tryParse(st['show_date']?.toString() ?? '') ?? DateTime.now();

      final timeStr = st['start_time']?.toString() ?? '';
      String formattedTime = timeStr;
      if (timeStr.length >= 5) {
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          int hour = int.tryParse(parts[0]) ?? 0;
          final min = parts[1];
          final ampm = hour >= 12 ? 'PM' : 'AM';
          hour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
          formattedTime = '$hour:$min $ampm';
        }
      }

      tickets.add(BookedTicket(
        id: row['id']?.toString() ?? '',
        movie: Movie(
          id: int.tryParse(movieRow['id']?.toString() ?? '0') ?? 0,
          title: movieRow['title']?.toString() ?? 'Unknown',
          overview: '',
          posterPath: movieRow['poster_url']?.toString() ?? '',
          backdropPath: '',
          rating: 0,
          genreIds: [],
          genres: [],
          releaseDate: '',
          adult: false,
        ),
        bookedAt: DateTime.tryParse(row['booked_at']?.toString() ?? '') ?? DateTime.now(),
        showDate: showDate,
        showTime: formattedTime,
        hallName: screen?['name']?.toString() ?? 'Screen',
        seats: seatsList,
        price: double.tryParse(row['total_amount']?.toString() ?? '0') ?? 0.0,
        cancelled: row['booking_status'] == 'cancelled',
      ));
    }
    
    return tickets;
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
