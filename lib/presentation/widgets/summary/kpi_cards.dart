import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../data/models/models.dart';

/// Section A — Trip financial overview KPI cards.
class KpiCards extends StatelessWidget {
  final TripSummaryStats stats;
  final String currency;
  final Map<String, String> nameMap;

  const KpiCards({
    super.key,
    required this.stats,
    required this.currency,
    required this.nameMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _KpiCard(
          icon: Icons.account_balance_wallet,
          iconColor: theme.colorScheme.primary,
          label: 'Tổng chi tiêu chuyến đi',
          value: formatCurrency(stats.totalSpent, currency),
          emphasized: true,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.people_alt_outlined,
                iconColor: theme.colorScheme.tertiary,
                label: 'TB / người',
                value: formatCurrency(stats.averagePerMember, currency),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KpiCard(
                icon: Icons.receipt_long_outlined,
                iconColor: theme.colorScheme.secondary,
                label: 'Số khoản chi',
                value: '${stats.expenseCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (stats.topExpense != null)
          _KpiCard(
            icon: Icons.emoji_events_outlined,
            iconColor: Colors.orange.shade800,
            label: 'Khoản chi lớn nhất',
            value: stats.topExpense!.title,
            subtitle:
                '${formatCurrency(stats.topExpense!.amount, currency)} · '
                '${nameMap[stats.topExpense!.payerId] ?? '?'}',
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subtitle;
  final bool emphasized;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                    overflow: TextOverflow.ellipsis,
                    style: emphasized
                        ? theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          )
                        : theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      overflow: TextOverflow.ellipsis,
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
    );
  }
}