import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/trip_report_text.dart';
import '../../../data/models/models.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/providers.dart';
import '../../../providers/trip_summary_provider.dart';
import 'category_breakdown.dart';
import 'kpi_cards.dart';
import 'member_audit_list.dart';
import 'transfer_card.dart';

/// Rich "Detailed Summary & Statistics" dashboard (Bảng Thống Kê Chi Tiết).
class SummaryScreen extends ConsumerWidget {
  final String tripId;
  final String currency;
  const SummaryScreen({super.key, required this.tripId, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(tripSummaryProvider(tripId));
    final tripName =
        ref.watch(tripDetailProvider(tripId)).valueOrNull?.name ?? '';
    final participants =
        ref.watch(participantsProvider(tripId)).valueOrNull ?? [];
    final nameMap = {for (final p in participants) p.id: p.name};
    final avatarMap = {for (final p in participants) p.id: p};

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text(l10n.errorLabel(e.toString()))),
      data: (stats) {
        if (stats.expenseCount == 0) {
          return _EmptyState(l10n: l10n);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          children: [
            // ---------------- Section A: KPI ----------------
            KpiCards(
              stats: stats,
              currency: currency,
              nameMap: nameMap,
            ),

            _SectionHeader(
              icon: Icons.fact_check_outlined,
              title: l10n.memberAuditTitle,
            ),
            MemberAuditList(
              members: stats.members,
              participants: participants,
              currency: currency,
            ),

            _SectionHeader(
              icon: Icons.pie_chart_outline,
              title: l10n.categoryAnalysisTitle,
            ),
            Card.filled(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CategoryBreakdown(
                  categories: stats.categories,
                  currency: currency,
                ),
              ),
            ),

            _SectionHeader(
              icon: Icons.swap_horiz_rounded,
              title: l10n.settlementPlanTitle,
            ),
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
            else ...[
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(settlementsProvider(tripId).notifier)
                    .recalculate(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.recalculate),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: stats.paidSettlementsCount / stats.settlements.length,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  l10n.paidProgress(
                    stats.paidSettlementsCount,
                    stats.settlements.length,
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              ...stats.settlements.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransferCard(
                    settlement: s,
                    fromName: nameMap[s.fromParticipantId] ?? '?',
                    toName: nameMap[s.toParticipantId] ?? '?',
                    fromAvatar: avatarMap[s.fromParticipantId],
                    toAvatar: avatarMap[s.toParticipantId],
                    currency: currency,
                    onSettledChanged: (paid) => ref
                        .read(settlementsProvider(tripId).notifier)
                        .togglePaid(s.id, paid),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            _ExportButton(
              l10n: l10n,
              tripName: tripName,
              stats: stats,
              currency: currency,
              nameMap: nameMap,
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  final AppLocalizations l10n;
  final String tripName;
  final TripSummaryStats stats;
  final String currency;
  final Map<String, String> nameMap;

  const _ExportButton({
    required this.l10n,
    required this.tripName,
    required this.stats,
    required this.currency,
    required this.nameMap,
  });

  Future<void> _copyFullReport(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.reportCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => _copyFullReport(
        context,
        buildTripReportText(
          l10n: l10n,
          tripName: tripName,
          currency: currency,
          stats: stats,
          nameMap: nameMap,
        ),
      ),
      icon: const Icon(Icons.ios_share),
      label: Text(l10n.copyTripReport),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: theme.colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.statsEmptyTitle,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.statsEmptyHint,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}