import 'dart:async';

import 'package:flutter/material.dart';

import 'models.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.feed,
    required this.onBook,
    required this.onMovieSelected,
    required this.onOpenMovies,
  });

  final HomeFeed feed;
  final ValueChanged<Movie> onBook;
  final ValueChanged<Movie> onMovieSelected;
  final OpenMoviesCallback onOpenMovies;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  Timer? _heroTimer;
  int _currentHeroIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _syncHeroTimer();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feed.featured.length != widget.feed.featured.length) {
      _syncHeroTimer();
    }
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _syncHeroTimer() {
    _heroTimer?.cancel();
    if (widget.feed.featured.length < 2) {
      return;
    }

    _heroTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pageController.hasClients) {
        return;
      }

      final nextPage = (_currentHeroIndex + 1) % widget.feed.featured.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final featured = widget.feed.featured;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (featured.isNotEmpty)
              FeaturedCarousel(
                movies: featured,
                currentIndex: _currentHeroIndex,
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentHeroIndex = index;
                  });
                },
                onBook: widget.onBook,
                onDetails: widget.onMovieSelected,
              ),
            const SizedBox(height: 28),
            SectionHeader(
              title: 'Now Playing',
              subtitle: 'In theaters today',
              onTap: () {
                widget.onOpenMovies(category: MovieCategoryTab.nowPlaying);
              },
            ),
            const SizedBox(height: 16),
            MovieRail(
              movies: widget.feed.nowPlaying.take(10).toList(),
              badgeText: 'NOW',
              onMovieSelected: widget.onMovieSelected,
            ),
            const SizedBox(height: 32),
            SectionHeader(
              title: 'Coming Soon',
              subtitle: 'Upcoming releases',
              onTap: () {
                widget.onOpenMovies(category: MovieCategoryTab.upcoming);
              },
            ),
            const SizedBox(height: 16),
            MovieRail(
              movies: widget.feed.upcoming.take(10).toList(),
              badgeText: 'SOON',
              onMovieSelected: widget.onMovieSelected,
            ),
            const SizedBox(height: 32),
            const Text(
              'Top Rated',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            for (final movie in widget.feed.topRated.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: RankedMovieTile(
                  rank: widget.feed.topRated.indexOf(movie) + 1,
                  movie: movie,
                  onTap: () => widget.onMovieSelected(movie),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
