import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'utils.dart';
import 'widgets.dart';

enum MovieDetailsTab { about, showtimes }

class MovieDetailsPage extends StatefulWidget {
  const MovieDetailsPage({
    super.key,
    required this.movie,
    required this.detailFuture,
    required this.onBack,
    required this.onBook,
    this.badge,
  });

  final Movie movie;
  final Future<MovieDetail> detailFuture;
  final VoidCallback onBack;
  final ValueChanged<Movie> onBook;
  final String? badge;

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  MovieDetailsTab _selectedTab = MovieDetailsTab.about;

  @override
  Widget build(BuildContext context) {
    final badgeLabel = switch (widget.badge) {
      'NOW' => 'Now Playing',
      'SOON' => 'Coming Soon',
      final value? => value,
      null => null,
    };

    return SafeArea(
      bottom: false,
      child: FutureBuilder<MovieDetail>(
        future: widget.detailFuture,
        builder: (context, snapshot) {
          final detail = snapshot.data;
          final movie = detail?.movie ?? widget.movie;
          final director = detail?.director ?? 'Loading...';
          final cast = detail?.cast ?? const <String>[];
          final language = detail?.language ?? 'English';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: SizedBox(
                        height: 320,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            NetworkArtwork(
                              imageUrl: movie.backdropUrl ?? movie.posterUrl,
                              fit: BoxFit.cover,
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Colors.black.withOpacity(0.08),
                                    Colors.black.withOpacity(0.2),
                                    Colors.black.withOpacity(0.88),
                                  ],
                                  stops: const <double>[0.0, 0.38, 1.0],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 16,
                              child: CircularIconButton(
                                icon: Icons.arrow_back_ios_new_rounded,
                                onTap: widget.onBack,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: -70,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: SizedBox(
                              width: 108,
                              height: 160,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: NetworkArtwork(
                                  imageUrl: movie.posterUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    movie.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: <Widget>[
                                      RatingPill(rating: movie.rating),
                                      MetadataDotLabel(
                                        icon: Icons.schedule_rounded,
                                        label: movie.runtimeLabel,
                                      ),
                                      Text(
                                        movie.primaryGenre,
                                        style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      if (badgeLabel != null)
                                        StatusBadge(label: badgeLabel),
                                      InfoChip(label: movie.maturityLabel),
                                      InfoChip(label: language),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 96),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _TabPill(
                          label: 'About',
                          selected: _selectedTab == MovieDetailsTab.about,
                          onTap: () {
                            setState(() {
                              _selectedTab = MovieDetailsTab.about;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _TabPill(
                          label: 'Showtimes',
                          selected: _selectedTab == MovieDetailsTab.showtimes,
                          onTap: () {
                            setState(() {
                              _selectedTab = MovieDetailsTab.showtimes;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: ErrorInlineCard(message: snapshot.error.toString()),
                  ),
                if (_selectedTab == MovieDetailsTab.about)
                  _AboutTab(
                    movie: movie,
                    director: director,
                    cast: cast,
                  )
                else
                  _ShowtimesTab(movie: movie),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => widget.onBook(movie),
                    icon: const Icon(Icons.confirmation_num_outlined),
                    label: const Text('Book Tickets'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.movie,
    required this.director,
    required this.cast,
  });

  final Movie movie;
  final String director;
  final List<String> cast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          movie.overview,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFFD2D2E0),
              ),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            DetailFactCard(label: 'DIRECTOR', value: director),
            DetailFactCard(
              label: 'RELEASE',
              value: formatReleaseDate(movie.releaseDate),
            ),
            DetailFactCard(label: 'GENRE', value: movie.primaryGenre),
            DetailFactCard(
              label: 'DURATION',
              value: movie.runtimeMinutes != null
                  ? '${movie.runtimeMinutes} minutes'
                  : movie.runtimeLabel,
            ),
          ],
        ),
        const SizedBox(height: 18),
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
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.people_outline_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'CAST',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cast.isEmpty
                    ? const <Widget>[InfoChip(label: 'Cast loading...')]
                    : cast.map((name) => InfoChip(label: name)).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShowtimesTab extends StatelessWidget {
  const _ShowtimesTab({
    required this.movie,
  });

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final schedule = <String, List<String>>{
      'Today': const <String>['1:30 PM', '4:45 PM', '8:00 PM'],
      'Tomorrow': const <String>['12:15 PM', '3:40 PM', '7:10 PM'],
      'Friday': const <String>['11:45 AM', '2:50 PM', '6:15 PM', '9:20 PM'],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Available showtimes',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your preferred slot for ${movie.title}.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        for (final entry in schedule.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
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
                    entry.key,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: entry.value
                        .map(
                          (time) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.stroke),
                            ),
                            child: Text(
                              time,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
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
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.textPrimary : AppColors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
