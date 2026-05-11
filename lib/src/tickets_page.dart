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
              children: [
                const Expanded(
                  child: Text(
                    'My Account',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
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
            const SizedBox(height: 18),
            _ProfileSection(
              displayName: displayName,
              onLogout: onLogout,
            ),
            const SizedBox(height: 32),
            Text(
              'Booking Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 32),
            Text(
              'My Tickets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.displayName,
    required this.onLogout,
  });

  final String displayName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final isGuest = displayName == 'Guest';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.stroke),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            const Color(0xFF181822),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        isGuest ? 'Guest User' : 'Pro Member',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isGuest) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ProfileInfoItem(
                  label: 'Account Type',
                  value: 'Premium',
                  icon: Icons.verified_user_rounded,
                ),
                _ProfileInfoItem(
                  label: 'Since',
                  value: 'May 2026',
                  icon: Icons.calendar_month_rounded,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileInfoItem extends StatelessWidget {
  const _ProfileInfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
