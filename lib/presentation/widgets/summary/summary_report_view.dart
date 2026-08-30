import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../data/models/models.dart';
import '../../../l10n/app_localizations.dart';
import '../participant_chips.dart';
import 'category_breakdown.dart';
import 'kpi_cards.dart';
import 'member_audit_list.dart';
import 'transfer_card.dart';

/// A full-page, non-scrolling report of the trip summary — the exact widget
/// tree exported as a long image by [ImageExporter].
///
/// Must stay a plain [Column] (no scrollables / [Expanded] / [Flexible] /
/// [Spacer]) so [ScreenshotController.captureFromLongWidget] can measure its
/// natural height.
class SummaryReportView extends StatelessWidget {
  final Trip trip;
  final TripSummaryStats stats;
  final List<Participant> participants;
  final String? hostId;

  const SummaryReportView({
    super.key,
    required this.trip,
    required this.stats,
    required this.participants,
    this.hostId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final nameMap = {for (final p in participants) p.id: p.name};
    final avatarMap = {for (final p in participants) p.id: p};
    final hostName = hostId != null ? nameMap[hostId] : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReportHeader(trip: trip, hostName: hostName),
        const SizedBox(height: 12),
        KpiCards(stats: stats, currency: trip.currency, nameMap: nameMap),
        const SizedBox(height: 16),
        Text(
          l10n.memberAuditTitle.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        MemberAuditList(
          members: stats.members,
          participants: participants,
          currency: trip.currency,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.categoryAnalysisTitle.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card.filled(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CategoryBreakdown(
              categories: stats.categories,
              currency: trip.currency,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.settlementPlanTitle.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (stats.settlements.isEmpty)
          Card.outlined(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.allSettledNoTransfer,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final s in stats.settlements)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TransferCard(
                settlement: s,
                fromName: nameMap[s.fromParticipantId] ?? '?',
                toName: nameMap[s.toParticipantId] ?? '?',
                fromAvatar: avatarMap[s.fromParticipantId],
                toAvatar: avatarMap[s.toParticipantId],
                currency: trip.currency,
                hostName: hostName,
                onSettledChanged: (_) {},
              ),
            ),
        const SizedBox(height: 12),
        _ReportFooter(l10n: l10n),
      ],
    );
  }
}

/// Report title block: emoji, group name, location & dates, host chip.
class _ReportHeader extends StatelessWidget {
  final Trip trip;
  final String? hostName;

  const _ReportHeader({required this.trip, required this.hostName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🧾 ${trip.name}',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        if (trip.destination.isNotEmpty)
          Text(
            '📍 ${trip.destination}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          '🗓 ${formatDate(trip.startDate, locale)}'
          ' – ${formatDate(trip.endDate, locale)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (hostName != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 16),
              const SizedBox(width: 4),
              Text(
                '${l10n.hostBadge}: $hostName',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Trailing "generated by" line.
class _ReportFooter extends StatelessWidget {
  final AppLocalizations l10n;

  const _ReportFooter({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        l10n.reportGeneratedFooter,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Small avatar with a name label, reused by the expense report.
class NameAvatarTile extends StatelessWidget {
  final Participant participant;
  final String name;
  final double radius;

  const NameAvatarTile({
    super.key,
    required this.participant,
    required this.name,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ParticipantAvatar(participant: participant, radius: radius),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}