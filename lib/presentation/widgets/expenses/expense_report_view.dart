import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../data/models/models.dart';
import '../../../l10n/app_localizations.dart';
import '../summary/summary_report_view.dart' show NameAvatarTile;

/// A full-page, non-scrolling report of the trip's expense list — the widget
/// tree exported as a long image by [ImageExporter].
///
/// Must stay a plain [Column] so [ScreenshotController.captureFromLongWidget]
/// can measure its natural height.
class ExpenseReportView extends StatelessWidget {
  final Trip trip;
  final List<Expense> expenses;
  final List<Participant> participants;
  final Map<String, int> joinedCount; // expenseId -> number of joined members.

  const ExpenseReportView({
    super.key,
    required this.trip,
    required this.expenses,
    required this.participants,
    required this.joinedCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final nameMap = {for (final p in participants) p.id: p.name};
    final avatarMap = {for (final p in participants) p.id: p};
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              l10n.kpiExpenseCount,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${expenses.length}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${l10n.kpiTotalSpent}: ',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              formatCurrency(total, trip.currency),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final e in expenses) ...[
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      e.title.isNotEmpty ? e.title[0].toUpperCase() : '?',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.expenseSubtitle(
                            nameMap[e.payerId] ?? l10n.unknown,
                            joinedCount[e.id] ?? 0,
                            participants.length,
                          ),
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatCurrency(e.amount, trip.currency),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (avatarMap[e.payerId] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: NameAvatarTile(
                            participant: avatarMap[e.payerId]!,
                            name: nameMap[e.payerId] ?? '?',
                            radius: 10,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 4),
        Center(
          child: Text(
            l10n.reportGeneratedFooter,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}