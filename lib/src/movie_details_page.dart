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
    required this.onSelectShowtime,
    this.badge,
  });

  final Movie movie;
  final Future<MovieDetail> detailFuture;
  final VoidCallback onBack;
  final ValueChanged<Movie> onBook;
  final ValueChanged<ShowtimeSlot> onSelectShowtime;
  final String? badge;

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  MovieDetailsTab _selectedTab = MovieDetailsTab.about;
  int _selectedDayIndex = 0;

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
          final schedule = buildShowtimeSchedule(movie);
          final safeDayIndex = schedule.isEmpty
              ? 0
              : _selectedDayIndex.clamp(0, schedule.length - 1) as int;

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
                  _ShowtimesTab(
                    schedule: schedule,
                    selectedDayIndex: safeDayIndex,
                    onDaySelected: (index) {
                      setState(() {
                        _selectedDayIndex = index;
                      });
                    },
                    onSelectShowtime: widget.onSelectShowtime,
                  ),
                if (_selectedTab == MovieDetailsTab.about) ...<Widget>[
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
    required this.schedule,
    required this.selectedDayIndex,
    required this.onDaySelected,
    required this.onSelectShowtime,
  });

  final List<ShowtimeDay> schedule;
  final int selectedDayIndex;
  final ValueChanged<int> onDaySelected;
  final ValueChanged<ShowtimeSlot> onSelectShowtime;

  @override
  Widget build(BuildContext context) {
    final selectedDay = schedule[selectedDayIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: schedule.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final day = schedule[index];
              return _ShowtimeDayChip(
                label: index == 0 ? 'Today' : formatWeekdayShort(day.date),
                dayNumber: '${day.date.day}',
                selected: index == selectedDayIndex,
                onTap: () => onDaySelected(index),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Available showtimes',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 18),
        for (final slot in selectedDay.slots)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ShowtimeCard(
              slot: slot,
              onTap: () => onSelectShowtime(slot),
            ),
          ),
      ],
    );
  }
}

class _ShowtimeDayChip extends StatelessWidget {
  const _ShowtimeDayChip({
    required this.label,
    required this.dayNumber,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String dayNumber;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 64,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.stroke,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dayNumber,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowtimeCard extends StatelessWidget {
  const _ShowtimeCard({
    required this.slot,
    required this.onTap,
  });

  final ShowtimeSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = switch (slot.format) {
      'IMAX' => const Color(0xFF8CB4FF),
      '3D' => const Color(0xFFD0A7FF),
      _ => const Color(0xFFD1D1DD),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  slot.timeLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  slot.format,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${slot.theater} | ${slot.hall}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      '\$${slot.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${slot.seatsLeft} seats left',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(120, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text('Select Seats'),
              ),
            ],
          ),
        ],
      ),
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
