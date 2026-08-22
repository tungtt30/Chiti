import 'package:flutter/material.dart';

import '../../core/formatters.dart';

/// A visual card for one settlement transaction with a
/// "paid / completed" checkbox.
class SettlementCard extends StatelessWidget {
  final String fromName;
  final String toName;
  final double amount;
  final String currency;
  final bool isPaid;
  final ValueChanged<bool> onChanged;

  const SettlementCard({
    super.key,
    required this.fromName,
    required this.toName,
    required this.amount,
    required this.currency,
    required this.isPaid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: CheckboxListTile(
        value: isPaid,
        onChanged: (v) => onChanged(v ?? false),
        secondary: CircleAvatar(
          backgroundColor: isPaid
              ? Colors.green.withValues(alpha: 0.15)
              : colors.primaryContainer,
          child: isPaid
              ? const Icon(Icons.check, color: Colors.green)
              : const Icon(Icons.sync, color: Colors.orange),
        ),
        title: Text(
          '$fromName pays $toName',
          style: theme.textTheme.titleMedium?.copyWith(
            decoration: isPaid ? TextDecoration.lineThrough : null,
            color: isPaid ? theme.disabledColor : null,
          ),
        ),
        subtitle: Text(
          formatCurrency(amount, currency),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isPaid ? theme.disabledColor : colors.onSurfaceVariant,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}
