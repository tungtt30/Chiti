import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/core/constants.dart';
import 'package:chiti/data/models/models.dart';
import 'package:chiti/data/repository.dart';
import 'package:chiti/providers/providers.dart';

/// In-memory fake repository backing notifier tests without sqflite.
class FakeAppRepository extends AppRepository {
  final List<Expense> expenses = [];
  final Map<String, List<ExpensePayer>> payersByExpense = {};
  final Map<String, List<ExpenseSplit>> splitsByExpense = {};
  final List<Settlement> settlements = [];

  @override
  Future<List<Expense>> getExpenses(String tripId) async =>
      expenses.where((e) => e.tripId == tripId).toList();

  @override
  Future<Expense> createExpense({
    required String tripId,
    required String title,
    required double amount,
    required DateTime date,
    required String category,
    required String splitMode,
    required List<ExpensePayer> payers,
    required List<ExpenseSplit> splits,
  }) async {
    final e = Expense(
      id: 'exp-${expenses.length + 1}',
      tripId: tripId,
      title: title,
      amount: amount,
      date: date,
      category: category,
      splitMode: splitMode,
      createdAt: DateTime.now(),
    );
    expenses.add(e);
    payersByExpense[e.id] = payers
        .map((p) => p.copyWith(expenseId: e.id))
        .toList();
    splitsByExpense[e.id] = splits
        .map((s) => s.copyWith(expenseId: e.id))
        .toList();
    return e;
  }

  @override
  Future<void> updateExpense({
    required Expense expense,
    required List<ExpensePayer> payers,
    required List<ExpenseSplit> splits,
  }) async {
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) throw StateError('expense not found');
    expenses[index] = expense;
    payersByExpense[expense.id] = payers
        .map((p) => p.copyWith(expenseId: expense.id))
        .toList();
    splitsByExpense[expense.id] = splits
        .map((s) => s.copyWith(expenseId: expense.id))
        .toList();
  }

  @override
  Future<void> deleteExpense(String id) async {
    expenses.removeWhere((e) => e.id == id);
    payersByExpense.remove(id);
    splitsByExpense.remove(id);
  }

  @override
  Future<List<ExpensePayer>> getExpensePayers(String expenseId) async =>
      List.of(payersByExpense[expenseId] ?? const []);

  @override
  Future<List<ExpenseSplit>> getExpenseSplits(String expenseId) async =>
      List.of(splitsByExpense[expenseId] ?? const []);

  @override
  Future<List<ExpensePayer>> getPayersForTrip(String tripId) async {
    final ids = expenses.where((e) => e.tripId == tripId).map((e) => e.id);
    return [
      for (final id in ids) ...payersByExpense[id] ?? const [],
    ];
  }

  @override
  Future<List<ExpenseSplit>> getSplitsForTrip(String tripId) async {
    final ids = expenses.where((e) => e.tripId == tripId).map((e) => e.id);
    return [
      for (final id in ids) ...splitsByExpense[id] ?? const [],
    ];
  }

  @override
  Future<List<Settlement>> getSettlements(String tripId) async =>
      settlements.where((s) => s.tripId == tripId).toList();

  @override
  Future<void> replaceSettlements(
    String tripId,
    List<Settlement> newSettlements,
  ) async {
    settlements
      ..removeWhere((s) => s.tripId == tripId)
      ..addAll(newSettlements);
  }
}

void main() {
  const tripId = 'trip-1';
  const payerId = 'p-1';
  const otherId = 'p-2';

  late FakeAppRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeAppRepository();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    // Keep the autoDispose derived providers alive during the test so they are
    // not disposed while an in-flight future is still loading.
    container.listen(payersForTripProvider(tripId), (_, _) {});
    container.listen(splitsForTripProvider(tripId), (_, _) {});
    container.listen(summaryProvider(tripId), (_, _) {});
    addTearDown(container.dispose);
  });

  Expense initialExpense() => Expense(
    id: 'exp-9',
    tripId: tripId,
    title: 'Dinner',
    amount: 100,
    date: DateTime(2026, 8, 22),
    category: 'Food',
    splitMode: SplitMode.equal,
    createdAt: DateTime(2026, 8, 22),
  );

  setUpExpense() {
    final e = initialExpense();
    repo.expenses.add(e);
    repo.payersByExpense[e.id] = [
      ExpensePayer(
        id: 'payer-1',
        expenseId: e.id,
        participantId: payerId,
        amount: 100,
      ),
    ];
    repo.splitsByExpense[e.id] = [
      ExpenseSplit(
        id: 'split-1',
        expenseId: e.id,
        participantId: payerId,
        amount: 50,
      ),
      ExpenseSplit(
        id: 'split-2',
        expenseId: e.id,
        participantId: otherId,
        amount: 50,
      ),
    ];
    return e;
  }

  test('updateExpense updates state and re-triggers settlements', () async {
    setUpExpense();
    final notifier = container.read(expensesProvider(tripId).notifier);
    await notifier.load();

    final updated = initialExpense().copyWith(title: 'Late dinner', amount: 80);
    await notifier.updateExpense(
      expense: updated,
      payers: [
        ExpensePayer(
          id: 'payer-new',
          expenseId: '',
          participantId: payerId,
          amount: 80,
        ),
      ],
      splits: [
        ExpenseSplit(
          id: 's-new-1',
          expenseId: '',
          participantId: payerId,
          amount: 40,
        ),
        ExpenseSplit(
          id: 's-new-2',
          expenseId: '',
          participantId: otherId,
          amount: 40,
        ),
      ],
    );

    final items = container.read(expensesProvider(tripId)).requireValue;
    expect(items, hasLength(1));
    expect(items.first.title, 'Late dinner');
    expect(items.first.amount, 80);

    // Downstream payers/splits providers recomputed after the edit.
    final payers = await container.read(
      payersForTripProvider(tripId).future,
    );
    expect(payers, hasLength(1));
    expect(payers.first.amount, 80);

    // Settlement plan regenerated.
    final settlements = container.read(settlementsProvider(tripId)).valueOrNull;
    expect(settlements, isNotNull);
  });

  test('deleteExpense removes it and returns to empty state', () async {
    setUpExpense();
    final notifier = container.read(expensesProvider(tripId).notifier);
    await notifier.load();

    await notifier.deleteExpense('exp-9');

    expect(container.read(expensesProvider(tripId)).requireValue, isEmpty);
    final payers = await container.read(payersForTripProvider(tripId).future);
    expect(payers, isEmpty);
  });

  test('settlement calculation uses updated balance after edit', () async {
    // One expense of 100 paid by payer, split equally between payer & other.
    setUpExpense();
    final notifier = container.read(expensesProvider(tripId).notifier);
    await notifier.load();

    // Edit: other person now paid the whole 100 (was payer). Net flips.
    await notifier.updateExpense(
      expense: initialExpense().copyWith(title: 'Reassigned payment'),
      payers: [
        ExpensePayer(
          id: 'payer-new',
          expenseId: '',
          participantId: otherId,
          amount: 100,
        ),
      ],
      splits: [
        ExpenseSplit(
          id: 's-new-1',
          expenseId: '',
          participantId: payerId,
          amount: 50,
        ),
        ExpenseSplit(
          id: 's-new-2',
          expenseId: '',
          participantId: otherId,
          amount: 50,
        ),
      ],
    );

    final rows = await container.read(summaryProvider(tripId).future);
    final payer = rows.firstWhere((r) => r.participantId == payerId);
    final other = rows.firstWhere((r) => r.participantId == otherId);
    // payer paid 0, owes 50 -> net -50; other paid 100, share 50 -> net +50.
    expect(payer.net, closeTo(-50, 0.01));
    expect(other.net, closeTo(50, 0.01));
  });
}