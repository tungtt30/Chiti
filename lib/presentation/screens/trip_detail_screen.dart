import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../data/models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../widgets/summary/summary_screen.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return tripAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text(l10n.errorLabel(e.toString())))),
      data: (trip) {
        if (trip == null) {
          return Scaffold(body: Center(child: Text(l10n.tripNotFound)));
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(trip.name),
              bottom: TabBar(
                tabs: [
                  Tab(
                    icon: const Icon(Icons.receipt_long),
                    text: l10n.tabExpenses,
                  ),
                  Tab(
                    icon: const Icon(Icons.people),
                    text: l10n.tabMembersAndNotes,
                  ),
                  Tab(
                    icon: const Icon(Icons.balance),
                    text: l10n.tabSummary,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.editTrip,
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
                SummaryScreen(tripId: tripId, currency: trip.currency),
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
    final l10n = AppLocalizations.of(context)!;

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorLabel(e.toString()))),
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
                  l10n.noExpensesYet,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noExpensesHint,
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
            final payerLabel = nameMap[e.payerId] ?? l10n.unknown;
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
                subtitle: Text(
                  l10n.expenseSubtitle(
                    payerLabel,
                    joined,
                    participants.length,
                  ),
                ),
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

