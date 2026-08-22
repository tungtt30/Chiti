import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/settlement_calculator.dart';

/// 4-column summary table for one trip:
/// Participant | Total Spent | Total Share | Net Balance.
class SummaryTable extends StatelessWidget {
  final List<SummaryRow> rows;
  final String currency;

  const SummaryTable({super.key, required this.rows, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Participant',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Spent (đã chi)',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Share (phải chịu)',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Net (cần đóng/nhận)',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: theme.dividerColor,
              indent: 12,
              endIndent: 12,
            ),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatCurrency(row.paid, currency),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatCurrency(row.share, currency),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        _netLabel(row, currency),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _netColor(theme, row.net),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Divider(
              height: 1,
              color: theme.dividerColor,
              indent: 12,
              endIndent: 12,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Total',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      formatCurrency(
                        rows.fold<double>(0, (sum, r) => sum + r.paid),
                        currency,
                      ),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      formatCurrency(
                        rows.fold<double>(0, (sum, r) => sum + r.share),
                        currency,
                      ),
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('', textAlign: TextAlign.right),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _netLabel(SummaryRow row, String currency) {
    if (row.net > 0.01) return '+${formatCurrency(row.net, currency)}';
    if (row.net < -0.01) return '-${formatCurrency(row.net.abs(), currency)}';
    return formatCurrency(0, currency);
  }

  Color _netColor(ThemeData theme, double net) {
    if (net > 0.01) return Colors.green.shade700;
    if (net < -0.01) return theme.colorScheme.error;
    return theme.disabledColor;
  }
}
