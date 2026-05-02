import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'utils.dart';

class SeatSelectionPage extends StatefulWidget {
  const SeatSelectionPage({
    super.key,
    required this.movie,
    required this.showtime,
    required this.onBack,
    required this.onContinue,
  });

  final Movie movie;
  final ShowtimeSlot showtime;
  final VoidCallback onBack;
  final void Function(List<String> seats, double total) onContinue;

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final Set<String> _selectedSeats = <String>{'A4', 'B3', 'E4', 'F6'};
  final Set<String> _bookedSeats = <String>{
    'C3',
    'C4',
    'C5',
    'C6',
    'D4',
    'D5',
    'D6',
    'E5',
    'G6',
  };
  final Set<String> _vipRows = <String>{'H', 'I', 'J'};

  double get _total {
    var total = 0.0;
    for (final seat in _selectedSeats) {
      final isVip = _vipRows.contains(seat.substring(0, 1));
      total += widget.showtime.price + (isVip ? 2.5 : 0);
    }
    return total;
  }

  void _toggleSeat(String seatId) {
    if (_bookedSeats.contains(seatId)) {
      return;
    }

    setState(() {
      if (_selectedSeats.contains(seatId)) {
        _selectedSeats.remove(seatId);
      } else {
        _selectedSeats.add(seatId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                _BackButton(onTap: widget.onBack),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.movie.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            '${formatShowtimeHeader(widget.showtime.date)} | ${widget.showtime.timeLabel}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.showtime.format,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[
                          Colors.transparent,
                          AppColors.accent,
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'SCREEN',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 18,
                            child: Text(
                              row,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          for (var seat = 1; seat <= 10; seat++) ...<Widget>[
                            _SeatTile(
                              label: '$seat',
                              state: _seatState('$row$seat'),
                              onTap: () => _toggleSeat('$row$seat'),
                            ),
                            if (seat != 10) const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Row(
                    children: <Widget>[
                      _SeatLegend(
                        label: 'Available',
                        sample: SeatVisualState.available,
                      ),
                      SizedBox(width: 14),
                      _SeatLegend(
                        label: 'Selected',
                        sample: SeatVisualState.selected,
                      ),
                      SizedBox(width: 14),
                      _SeatLegend(
                        label: 'Booked',
                        sample: SeatVisualState.booked,
                      ),
                      SizedBox(width: 14),
                      _SeatLegend(label: 'VIP', sample: SeatVisualState.vip),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${_selectedSeats.length} seats selected',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedSeats
                                  .map(
                                    (seat) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent.withOpacity(0.14),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        seat,
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _selectedSeats.isEmpty
                          ? null
                          : () => widget.onContinue(
                                _selectedSeats.toList()..sort(),
                                _total,
                              ),
                      icon: const Icon(Icons.confirmation_num_outlined),
                      label: Text(
                        'Continue | \$${_total.toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SeatVisualState _seatState(String seatId) {
    if (_selectedSeats.contains(seatId)) {
      return SeatVisualState.selected;
    }

    if (_bookedSeats.contains(seatId)) {
      return SeatVisualState.booked;
    }

    if (_vipRows.contains(seatId.substring(0, 1))) {
      return SeatVisualState.vip;
    }

    return SeatVisualState.available;
  }
}

enum SeatVisualState { available, selected, booked, vip }

class _SeatTile extends StatelessWidget {
  const _SeatTile({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final SeatVisualState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = switch (state) {
      SeatVisualState.selected => (
          background: AppColors.accent,
          border: AppColors.accent,
          text: AppColors.textPrimary,
        ),
      SeatVisualState.booked => (
          background: const Color(0xFF1A1A22),
          border: const Color(0xFF1A1A22),
          text: const Color(0xFF51515E),
        ),
      SeatVisualState.vip => (
          background: Colors.transparent,
          border: const Color(0xFFD0A328),
          text: const Color(0xFFD0A328),
        ),
      SeatVisualState.available => (
          background: Colors.transparent,
          border: const Color(0xFF284D96),
          text: const Color(0xFF86B7FF),
        ),
    };

    return GestureDetector(
      onTap: state == SeatVisualState.booked ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: style.border),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: style.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend({
    required this.label,
    required this.sample,
  });

  final String label;
  final SeatVisualState sample;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _SeatTile(label: '', state: sample, onTap: () {}),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.stroke),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}
