import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';
import 'widgets.dart';

class TicketsPage extends StatelessWidget {
  const TicketsPage({
    super.key,
    required this.displayName,
    required this.tickets,
    required this.onBrowseMovies,
    required this.onLogout,
  });

  final String displayName;
  final List<BookedTicket> tickets;
  final VoidCallback onBrowseMovies;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final confirmed = tickets.where((ticket) => !ticket.cancelled).length;
    final cancelled = tickets.where((ticket) => ticket.cancelled).length;
    final spent = tickets.fold<double>(
      0,
      (total, ticket) => total + ticket.price,
    );

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'My Tickets',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.stroke),
                  ),
                  child: IconButton(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout_rounded),
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              displayName == 'Guest'
                  ? 'All your reservations in one place'
                  : '$displayName, all your reservations in one place',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                TicketStatCard(
                  label: 'TOTAL',
                  value: '${tickets.length}',
                  icon: Icons.confirmation_num_outlined,
                ),
                TicketStatCard(
                  label: 'CONFIRMED',
                  value: '$confirmed',
                  icon: Icons.check_circle_outline_rounded,
                ),
                TicketStatCard(
                  label: 'CANCELLED',
                  value: '$cancelled',
                  icon: Icons.cancel_outlined,
                ),
                TicketStatCard(
                  label: 'TOTAL SPENT',
                  value: '\$${spent.toStringAsFixed(2)}',
                  icon: Icons.attach_money_rounded,
                  highlight: true,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (tickets.isEmpty)
              EmptyTicketsCard(onBrowseMovies: onBrowseMovies)
            else
              Column(
                children: tickets
                    .map(
                      (ticket) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TicketCard(ticket: ticket),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
