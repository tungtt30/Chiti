import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../data/models/models.dart';
import '../../../l10n/app_localizations.dart';
import '../participant_chips.dart';

/// Section B — Detailed participant audit rows.
class MemberAuditList extends StatelessWidget {
  final List<MemberStat> members;
  final List<Participant> participants;
  final String currency;

  const MemberAuditList({
    super.key,
    required this.members,
    required this.participants,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final avatars = {for (final p in participants) p.id: p};

    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Column headers.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(l10n.auditMember),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    l10n.auditPaid,
                    textAlign: TextAlign.right,
                    style: _headerStyle(theme),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    l10n.auditOwes,
                    textAlign: TextAlign.right,
                    style: _headerStyle(theme),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          for (final m in members)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            ParticipantAvatar(
                              participant:
                                  avatars[m.participantId] ??
                                  _fallback(m.name),
                              radius: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${l10n.billsParticipation(m.joinedCount, m.totalBillsCount)} · '
                                    '${(m.participationRate * 100).round()}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          formatCurrency(m.paid, currency),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          formatCurrency(m.consumed, currency),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _NetBadge(net: m.net, currency: currency),
                  ),
                ],
              ),
            ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                l10n.auditNetRule,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle? _headerStyle(ThemeData theme) => theme.textTheme.labelMedium
      ?.copyWith(color: theme.colorScheme.primary);

  Participant _fallback(String name) => Participant(
    id: '',
    tripId: '',
    name: name,
    color: 0xFF9E9E9E,
    createdAt: DateTime.now(),
  );
}

class _NetBadge extends StatelessWidget {
  final double net;
  final String currency;

  const _NetBadge({required this.net, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final String label;
    final Color background;
    final Color foreground;
    final IconData icon;
    if (net > 0.01) {
      label = l10n.netReceiveBack(formatCurrency(net, currency));
      background = Colors.green.withValues(alpha: 0.14);
      foreground = Colors.green.shade800;
      icon = Icons.arrow_downward;
    } else if (net < -0.01) {
      label = l10n.netPayMore(formatCurrency(net.abs(), currency));
      background = Colors.red.withValues(alpha: 0.12);
      foreground = Colors.red.shade700;
      icon = Icons.arrow_upward;
    } else {
      label = l10n.netSettled;
      background = theme.colorScheme.surfaceContainerHigh;
      foreground = theme.disabledColor;
      icon = Icons.check;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}