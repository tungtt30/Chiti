import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../../../data/models/models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/providers.dart';
import '../../../providers/trip_summary_provider.dart';
import '../../screens/add_edit_sponsorship_screen.dart';
import '../participant_chips.dart';

/// Sponsorship (Tài trợ) tab: shows the total sponsored, how much is left to
/// split after sponsorship, and the list of sponsorship entries with
/// add / edit / delete actions.
class SponsorshipTab extends ConsumerWidget {
  final String tripId;
  final String currency;

  const SponsorshipTab({
    super.key,
    required this.tripId,
    required this.currency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final sponsorshipsAsync = ref.watch(sponsorshipsProvider(tripId));
    final statsAsync = ref.watch(tripSummaryProvider(tripId));
    final participants =
        ref.watch(participantsProvider(tripId)).valueOrNull ?? [];
    final avatarMap = {for (final p in participants) p.id: p};

    final sponsorships = sponsorshipsAsync.valueOrNull ?? const <Sponsorship>[];
    final stats = statsAsync.valueOrNull;

    if (sponsorships.isEmpty) {
      return _EmptyState(
        l10n: l10n,
        onAdd: () => _openAdd(context),
      );
    }

    final coveredPercent = stats == null || stats.totalSpent <= 0
        ? 0
        : ((stats.totalSponsorship / stats.totalSpent) * 100).round().clamp(
            0,
            100,
          );
    final payPercent = stats == null
        ? 100
        : ((stats.discountFactor) * 100).round().clamp(0, 100);

    return ListView(
      primary: false,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      children: [
        // ---- Summary banner ----
        Card.filled(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.sponsorshipSectionTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: l10n.kpiTotalSponsorship,
                        value: formatCurrency(
                          stats?.totalSponsorship ?? 0,
                          currency,
                        ),
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: l10n.kpiNetToSplit,
                        value: formatCurrency(stats?.netTotal ?? 0, currency),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (stats != null &&
                    stats.totalSpent > 0 &&
                    stats.discountFactor <= 0)
                  _Banner(
                    icon: Icons.celebration,
                    color: Colors.green.shade700,
                    message: l10n.sponsorshipFullyCovered,
                  )
                else ...[
                  _Banner(
                    icon: Icons.savings_outlined,
                    color: theme.colorScheme.primary,
                    message: l10n.sponsorshipCovered(coveredPercent),
                  ),
                  const SizedBox(height: 4),
                  _Banner(
                    icon: Icons.percent,
                    color: theme.colorScheme.tertiary,
                    message: l10n.sponsorshipDiscountFactor(payPercent),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final s in sponsorships)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Dismissible(
              key: Key('sponsorship_${s.id}'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => ref
                  .read(sponsorshipsProvider(tripId).notifier)
                  .deleteSponsorship(s.id),
              child: _SponsorshipCard(
                sponsorship: s,
                currency: currency,
                avatar: s.memberId != null ? avatarMap[s.memberId] : null,
                onTap: () => _openEdit(context, s),
                onLongPress: () => _confirmDelete(context, ref, s),
              ),
            ),
          ),
      ],
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSponsorshipScreen(tripId: tripId),
      ),
    );
  }

  void _openEdit(BuildContext context, Sponsorship s) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSponsorshipScreen(tripId: tripId, existing: s),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Sponsorship s,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteSponsorshipDialogTitle),
        content: Text(
          l10n.deleteSponsorshipDialogContent(
            formatCurrency(s.amount, currency),
            s.sponsorName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(sponsorshipsProvider(tripId).notifier)
          .deleteSponsorship(s.id);
    }
  }
}

class _SponsorshipCard extends StatelessWidget {
  final Sponsorship sponsorship;
  final String currency;
  final Participant? avatar;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _SponsorshipCard({
    required this.sponsorship,
    required this.currency,
    this.avatar,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isInternal = sponsorship.isInternal;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: isInternal && avatar != null
            ? ParticipantAvatar(participant: avatar!, radius: 22)
            : CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.volunteer_activism,
                  color: theme.colorScheme.primary,
                ),
              ),
        title: Text(
          sponsorship.sponsorName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isInternal ? Icons.person : Icons.volunteer_activism,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    isInternal
                        ? l10n.sponsorshipTypeInternal
                        : l10n.sponsorshipTypeExternal,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (sponsorship.note != null && sponsorship.note!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                sponsorship.note!,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Text(
          formatCurrency(sponsorship.amount, currency),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onAdd;

  const _EmptyState({required this.l10n, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.volunteer_activism,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(l10n.noSponsorshipsYet, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.noSponsorshipsHint,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(l10n.addSponsorship),
          ),
        ],
      ),
    );
  }
}