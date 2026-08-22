import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../data/models/models.dart';

/// Section C — Category breakdown & spending distribution with progress bars.
class CategoryBreakdown extends StatelessWidget {
  final List<CategoryStat> categories;
  final String currency;

  const CategoryBreakdown({
    super.key,
    required this.categories,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (categories.isEmpty) {
      return Text(
        'Chưa có dữ liệu danh mục.',
        style: theme.textTheme.bodySmall,
      );
    }

    return Column(
      children: [
        for (final c in categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${c.emoji} ', style: theme.textTheme.titleSmall),
                    Expanded(
                      child: Text(
                        c.label,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${formatCurrency(c.total, currency)} · '
                      '${(c.percent * 100).round()}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: c.percent.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}