import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/models/models.dart';
import '../../providers/providers.dart';
import '../widgets/net_balance_list.dart';
import '../widgets/settlement_card.dart';
import 'add_edit_expense_screen.dart';
import 'add_trip_screen.dart';
import 'expense_detail_screen.dart';
import 'manage_participants_screen.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));

    return tripAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (trip) {
        if (trip == null) {
          return const Scaffold(body: Center(child: Text('Trip not found')));
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(trip.name),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.receipt_long), text: 'Expenses'),
                  Tab(icon: Icon(Icons.people), text: 'Members & Notes'),
                  Tab(icon: Icon(Icons.balance), text: 'Summary'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Trip',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddTripScreen(existing: trip),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _ExpensesTab(tripId: tripId, currency: trip.currency),
                ManageParticipantsScreen(tripId: tripId),
                _SummaryTab(tripId: tripId, currency: trip.currency),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditExpenseScreen(tripId: tripId),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  final String tripId;
  final String currency;
  const _ExpensesTab({required this.tripId, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(tripId));
    final participantsAsync = ref.watch(participantsProvider(tripId));
    final joinedAsync = ref.watch(expenseParticipantsForTripProvider(tripId));

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary
                      .withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No expenses yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add an expense',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final participants = participantsAsync.valueOrNull ?? [];
        final nameMap = {for (final p in participants) p.id: p.name};
        final joinedCount = <String, int>{};
        for (final member in joinedAsync.valueOrNull ?? <ExpenseParticipant>[]) {
          joinedCount[member.expenseId] =
              (joinedCount[member.expenseId] ?? 0) + 1;
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final e = expenses[index];
            final payerLabel = nameMap[e.payerId] ?? 'Unknown';
            final joined = joinedCount[e.id] ?? 0;

            return Dismissible(
              key: Key(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) {
                ref.read(expensesProvider(tripId).notifier).deleteExpense(e.id);
              },
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer,
                  child: Text(
                    e.title.isNotEmpty ? e.title[0].toUpperCase() : '?',
                  ),
                ),
                title: Text(e.title),
                subtitle: Text('Paid by $payerLabel · $joined of '
                    '${participants.length} joined'),
                trailing: Text(
                  formatCurrency(e.amount, currency),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExpenseDetailScreen(expenseId: e.id),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  final String tripId;
  final String currency;
  const _SummaryTab({required this.tripId, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryProvider(tripId));
    final settlementsAsync = ref.watch(settlementsProvider(tripId));
    final participantsAsync = ref.watch(participantsProvider(tripId));
    final participants = participantsAsync.valueOrNull ?? [];
    final nameMap = {for (final p in participants) p.id: p.name};

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Net Balance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        summaryAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e'),
          ),
          data: (rows) => rows.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No data yet. Add expenses.')),
                )
              : NetBalanceList(
                  rows: rows,
                  participants: participants,
                  currency: currency,
                ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Settlement Plan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FilledButton.tonalIcon(
            onPressed: () =>
                ref.read(settlementsProvider(tripId).notifier).recalculate(),
            icon: const Icon(Icons.refresh),
            label: const Text('Calculate / Re-balance'),
          ),
        ),
        const SizedBox(height: 8),
        settlementsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e'),
          ),
          data: (settlements) {
            if (settlements.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All settled!',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Text(
                      'Tap "Calculate / Re-balance" to generate a plan.',
                    ),
                  ],
                ),
              );
            }
            final paidCount = settlements.where((s) => s.isPaid).length;
            return Column(
              children: [
                LinearProgressIndicator(
                  value: paidCount / settlements.length,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHigh,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    '$paidCount / ${settlements.length} settlements paid',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                ...settlements.map((s) {
                  final fromName = nameMap[s.fromParticipantId] ?? '?';
                  final toName = nameMap[s.toParticipantId] ?? '?';
                  return SettlementCard(
                    fromName: fromName,
                    toName: toName,
                    amount: s.amount,
                    currency: currency,
                    isPaid: s.isPaid,
                    onChanged: (paid) => ref
                        .read(settlementsProvider(tripId).notifier)
                        .togglePaid(s.id, paid),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }
}
