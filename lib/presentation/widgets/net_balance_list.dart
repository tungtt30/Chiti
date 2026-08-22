import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/settlement_calculator.dart';
import '../../data/models/models.dart';
import 'participant_chips.dart';

/// Streamlined net-balance list: one card per participant showing only their
/// final status (must pay / gets back / balanced).
class NetBalanceList extends StatelessWidget {
  final List<SummaryRow> rows;
  final List<Participant> participants;
  final String currency;

  const NetBalanceList({
    super.key,
    required this.rows,
    required this.participants,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatars = {for (final p in participants) p.id: p};

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          for (final row in rows)
            ListTile(
              leading: ParticipantAvatar(
                participant: avatars[row.participantId] ?? _fallback(row.name),
                radius: 18,
              ),
              title: Text(
                row.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: _StatusChip(row: row, currency: currency),
            ),
        ],
      ),
    );
  }

  Participant _fallback(String name) => Participant(
    id: '',
    tripId: '',
    name: name,
    color: 0xFF9E9E9E,
    createdAt: DateTime.now(),
  );
}

class _StatusChip extends StatelessWidget {
  final SummaryRow row;
  final String currency;

  const _StatusChip({required this.row, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = row.net;

    final String label;
    final Color background;
    final Color foreground;
    if (net > 0.01) {
      label = 'Gets back: ${formatCurrency(net, currency)}';
      background = Colors.green.withValues(alpha: 0.15);
      foreground = Colors.green.shade800;
    } else if (net < -0.01) {
      label = 'Must pay: ${formatCurrency(net.abs(), currency)}';
      background = Colors.orange.withValues(alpha: 0.15);
      foreground = Colors.deepOrange.shade800;
    } else {
      label = 'Balanced';
      background = theme.colorScheme.surfaceContainerHigh;
      foreground = theme.disabledColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}