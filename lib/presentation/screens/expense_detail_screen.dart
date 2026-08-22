import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/participant_chips.dart';
import 'add_edit_expense_screen.dart';

/// Read-only detail view of a single expense: who joined (and owes a share)
/// vs. who was excluded, who paid, and the exact per-person amounts.
class ExpenseDetailScreen extends ConsumerWidget {
  final String expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(expenseDetailsProvider(expenseId));

    return detailsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (details) {
        if (details == null) {
          return const Scaffold(body: Center(child: Text('Expense not found')));
        }
        final expense = details.expense;
        final participants =
            ref
                .watch(participantsProvider(expense.tripId))
                .valueOrNull ??
            const <Participant>[];
        final currency =
            ref.watch(tripDetailProvider(expense.tripId)).valueOrNull
                ?.currency ??
            'VND';

        final nameMap = {for (final p in participants) p.id: p.name};
        final joinedIds = {
          for (final s in details.splits) s.participantId,
        };
        final excluded = participants
            .where((p) => !joinedIds.contains(p.id))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Expense Details'),
            actions: [
              IconButton.filledTonal(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit expense',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditExpenseScreen(
                        tripId: expense.tripId,
                        existing: expense,
                      ),
                    ),
                  );
                  ref.invalidate(expenseDetailsProvider(expenseId));
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeaderCard(
                expense: expense,
                currency: currency,
                payerNames: details.payers
                    .map((p) => nameMap[p.participantId] ?? 'Unknown')
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Joined (${details.splits.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final split in details.splits)
                      ListTile(
                        dense: true,
                        leading: ParticipantAvatar(
                          participant: _participantFor(
                            participants,
                            split.participantId,
                          ),
                          radius: 15,
                        ),
                        title: Text(
                          nameMap[split.participantId] ?? 'Unknown',
                        ),
                        subtitle: split.note == null
                            ? null
                            : Text(split.note!),
                        trailing: Text(
                          formatCurrency(split.amount, currency),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Excluded (${excluded.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (excluded.isEmpty)
                Text(
                  'Everyone joined this expense.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (final p in excluded)
                        ListTile(
                          dense: true,
                          leading: ParticipantAvatar(
                            participant: p,
                            radius: 15,
                          ),
                          title: Text(
                            p.name,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          trailing: Text(
                            'No share',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddEditExpenseScreen(
                        tripId: expense.tripId,
                        existing: expense,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Expense'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Participant _participantFor(List<Participant> participants, String id) {
    return participants.firstWhere(
      (p) => p.id == id,
      orElse: () => Participant(
        id: id,
        tripId: '',
        name: '?',
        color: 0xFF9E9E9E,
        createdAt: DateTime.now(),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Expense expense;
  final String currency;
  final List<String> payerNames;

  const _HeaderCard({
    required this.expense,
    required this.currency,
    required this.payerNames,
  });

  String get _splitModeLabel {
    switch (expense.splitMode) {
      case SplitMode.customAmount:
        return 'Custom amounts';
      case SplitMode.customWeight:
        return 'Split by weight';
      default:
        return 'Split equally';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    expense.title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Text(
                  formatCurrency(expense.amount, currency),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${ExpenseCategory.icons[expense.category] ?? ''} '
              '$expense.category · $_splitModeLabel · '
              '${formatDate(expense.date)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Paid by ${payerNames.join(', ')}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}