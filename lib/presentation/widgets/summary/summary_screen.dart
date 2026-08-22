import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/trip_report_text.dart';
import '../../../data/models/models.dart';
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
    final statsAsync = ref.watch(tripSummaryProvider(tripId));
    final tripName =
        ref.watch(tripDetailProvider(tripId)).valueOrNull?.name ?? '';
    final participants =
        ref.watch(participantsProvider(tripId)).valueOrNull ?? [];
    final nameMap = {for (final p in participants) p.id: p.name};
    final avatarMap = {for (final p in participants) p.id: p};

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (stats) {
        if (stats.expenseCount == 0) {
          return const _EmptyState();
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
              title: 'Bảng đối soát thành viên',
            ),
            MemberAuditList(
              members: stats.members,
              participants: participants,
              currency: currency,
            ),

            _SectionHeader(
              icon: Icons.pie_chart_outline,
              title: 'Phân tích danh mục',
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
              title: 'Kế hoạch thanh toán tối ưu',
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
                          'Đã cân bằng, không cần chuyển khoản 🎉',
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
                label: const Text('Tính / Cân đối lại'),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: stats.paidSettlementsCount / stats.settlements.length,
                backgroundColor: theme.colorScheme.surfaceContainerHigh,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Đã thanh toán: ${stats.paidSettlementsCount}/'
                  '${stats.settlements.length}',
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
  final String tripName;
  final TripSummaryStats stats;
  final String currency;
  final Map<String, String> nameMap;

  const _ExportButton({
    required this.tripName,
    required this.stats,
    required this.currency,
    required this.nameMap,
  });

  Future<void> _copyFullReport(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép báo cáo chuyến đi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => _copyFullReport(
        context,
        buildTripReportText(
          tripName: tripName,
          currency: currency,
          stats: stats,
          nameMap: nameMap,
        ),
      ),
      icon: const Icon(Icons.ios_share),
      label: const Text('Sao chép báo cáo chuyến đi'),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
            'Chưa có khoản chi nào',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm chi tiêu để xem bảng thống kê và kế hoạch thanh toán.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}