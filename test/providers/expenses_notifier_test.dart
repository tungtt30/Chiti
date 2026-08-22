import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/data/models/models.dart';
import 'package:chiti/data/repository.dart';
import 'package:chiti/providers/providers.dart';

/// In-memory fake repository backing notifier tests without sqflite.
class FakeAppRepository extends AppRepository {
  final List<Expense> expenses = [];
  final Map<String, List<ExpenseParticipant>> joinedByExpense = {};
  final List<Settlement> settlements = [];

  @override
  Future<List<Expense>> getExpenses(String tripId) async =>
      expenses.where((e) => e.tripId == tripId).toList();

  @override
  Future<Expense> createExpense({
    required String tripId,
    required String title,
    required double amount,
    required String payerId,
    required List<ExpenseParticipant> participants,
  }) async {
    final e = Expense(
      id: 'exp-${expenses.length + 1}',
      tripId: tripId,
      title: title,
      amount: amount,
      payerId: payerId,
      createdAt: DateTime.now(),
    );
    expenses.add(e);
    joinedByExpense[e.id] = participants
        .map((p) => p.copyWith(expenseId: e.id))
        .toList();
    return e;
  }

  @override
  Future<void> updateExpense({
    required Expense expense,
    required List<ExpenseParticipant> participants,
  }) async {
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) throw StateError('expense not found');
    expenses[index] = expense;
    joinedByExpense[expense.id] = participants
        .map((p) => p.copyWith(expenseId: expense.id))
        .toList();
  }

  @override
  Future<void> deleteExpense(String id) async {
    expenses.removeWhere((e) => e.id == id);
    joinedByExpense.remove(id);
  }

  @override
  Future<List<ExpenseParticipant>> getExpenseParticipants(
    String expenseId,
  ) async => List.of(joinedByExpense[expenseId] ?? const []);

  @override
  Future<ExpenseWithParticipants?> getExpenseDetails(String expenseId) async {
    final match = expenses.where((e) => e.id == expenseId).toList();
    if (match.isEmpty) return null;
    return ExpenseWithParticipants(
      expense: match.first,
      participants: List.of(joinedByExpense[expenseId] ?? const []),
    );
  }

  @override
  Future<List<ExpenseParticipant>> getParticipantsForTrip(
    String tripId,
  ) async {
    final ids = expenses.where((e) => e.tripId == tripId).map((e) => e.id);
    return [
      for (final id in ids) ...joinedByExpense[id] ?? const [],
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
    container.listen(expenseParticipantsForTripProvider(tripId), (_, _) {});
    container.listen(summaryProvider(tripId), (_, _) {});
    addTearDown(container.dispose);
  });

  Expense initialExpense() => Expense(
    id: 'exp-9',
    tripId: tripId,
    title: 'Dinner',
    amount: 100,
    payerId: payerId,
    createdAt: DateTime(2026, 8, 22),
  );

  setUpExpense() {
    final e = initialExpense();
    repo.expenses.add(e);
    repo.joinedByExpense[e.id] = [
      ExpenseParticipant(
        id: 'ep-1',
        expenseId: e.id,
        participantId: payerId,
        shareAmount: 50,
      ),
      ExpenseParticipant(
        id: 'ep-2',
        expenseId: e.id,
        participantId: otherId,
        shareAmount: 50,
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
      participants: [
        ExpenseParticipant(
          id: 'ep-new-1',
          expenseId: '',
          participantId: payerId,
          shareAmount: 40,
        ),
        ExpenseParticipant(
          id: 'ep-new-2',
          expenseId: '',
          participantId: otherId,
          shareAmount: 40,
        ),
      ],
    );

    final items = container.read(expensesProvider(tripId)).requireValue;
    expect(items, hasLength(1));
    expect(items.first.title, 'Late dinner');
    expect(items.first.amount, 80);

    // Downstream joined provider recomputed after the edit.
    final joined = await container.read(
      expenseParticipantsForTripProvider(tripId).future,
    );
    expect(joined, hasLength(2));
    expect(joined.first.shareAmount, 40);

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
    final joined = await container.read(
      expenseParticipantsForTripProvider(tripId).future,
    );
    expect(joined, isEmpty);
  });

  test('settlement calculation uses updated balance after edit', () async {
    // One expense of 100 paid by payer, split equally between payer & other.
    setUpExpense();
    final notifier = container.read(expensesProvider(tripId).notifier);
    await notifier.load();

    // Edit: other person now paid the whole 100 (was payer). Net flips.
    await notifier.updateExpense(
      expense: initialExpense().copyWith(
        title: 'Reassigned payment',
        payerId: otherId,
      ),
      participants: [
        ExpenseParticipant(
          id: 'ep-new-1',
          expenseId: '',
          participantId: payerId,
          shareAmount: 50,
        ),
        ExpenseParticipant(
          id: 'ep-new-2',
          expenseId: '',
          participantId: otherId,
          shareAmount: 50,
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

  test('expenseDetailsProvider returns bundled expense and joined members',
      () async {
    setUpExpense();

    final details =
        await container.read(expenseDetailsProvider('exp-9').future);

    expect(details, isNotNull);
    expect(details!.expense.title, 'Dinner');
    expect(details.participants, hasLength(2));

    // Unknown id resolves to null.
    final missing =
        await container.read(expenseDetailsProvider('missing').future);
    expect(missing, isNull);
  });
}