import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/core/summary_calculator.dart';
import 'package:chiti/data/models/models.dart';

Expense _expense({
  required String id,
  required String payer,
  required double amount,
  String category = 'Food',
}) => Expense(
  id: id,
  tripId: 'trip-1',
  title: id,
  amount: amount,
  payerId: payer,
  category: category,
  createdAt: DateTime(2026, 8, 22),
);

void main() {
  final alice = Participant(
    id: 'a',
    tripId: 'trip-1',
    name: 'Alice',
    color: 1,
    createdAt: DateTime(2026),
  );
  final bob = Participant(
    id: 'b',
    tripId: 'trip-1',
    name: 'Bob',
    color: 2,
    createdAt: DateTime(2026),
  );
  final carol = Participant(
    id: 'c',
    tripId: 'trip-1',
    name: 'Carol',
    color: 3,
    createdAt: DateTime(2026),
  );

  test('computes KPIs: total, average, count, top expense', () {
    final stats = computeTripSummary(
      expenses: [
        _expense(id: 'e1', payer: 'a', amount: 100, category: 'Food'),
        _expense(id: 'e2', payer: 'b', amount: 260, category: 'Transport'),
      ],
      participants: [alice, bob, carol],
      joined: const [],
      settlements: const [],
    );

    expect(stats.totalSpent, 360);
    expect(stats.averagePerMember, closeTo(120, 0.001));
    expect(stats.expenseCount, 2);
    expect(stats.topExpense!.title, 'e2');
    expect(stats.topExpense!.amount, 260);
    expect(stats.topExpense!.payerId, 'b');
  });

  test('empty trip yields zero KPIs, top null, empty categories', () {
    final stats = computeTripSummary(
      expenses: const [],
      participants: [alice, bob],
      joined: const [],
      settlements: const [],
    );

    expect(stats.totalSpent, 0);
    expect(stats.averagePerMember, 0);
    expect(stats.expenseCount, 0);
    expect(stats.topExpense, isNull);
    expect(stats.categories, isEmpty);
    expect(stats.members.length, 2);
  });

  test('member paid/consumed/net and participation rate', () {
    final stats = computeTripSummary(
      expenses: [
        _expense(id: 'e1', payer: 'a', amount: 300, category: 'Food'),
        _expense(id: 'e2', payer: 'a', amount: 100, category: 'Food'),
      ],
      participants: [alice, bob, carol],
      joined: const [
        ExpenseParticipant(
          id: 'j1',
          expenseId: 'e1',
          participantId: 'a',
          shareAmount: 100,
        ),
        ExpenseParticipant(
          id: 'j2',
          expenseId: 'e1',
          participantId: 'b',
          shareAmount: 100,
        ),
        ExpenseParticipant(
          id: 'j3',
          expenseId: 'e1',
          participantId: 'c',
          shareAmount: 100,
        ),
        // Second bill only Alice joins.
        ExpenseParticipant(
          id: 'j4',
          expenseId: 'e2',
          participantId: 'a',
          shareAmount: 100,
        ),
      ],
      settlements: const [],
    );

    final a = stats.members.firstWhere((m) => m.participantId == 'a');
    final b = stats.members.firstWhere((m) => m.participantId == 'b');
    final c = stats.members.firstWhere((m) => m.participantId == 'c');

    expect(a.paid, 400);
    expect(a.consumed, 200);
    expect(a.net, 200);
    expect(a.joinedCount, 2);
    expect(a.participationRate, 1.0);

    expect(b.paid, 0);
    expect(b.consumed, 100);
    expect(b.net, -100);
    expect(b.joinedCount, 1);
    expect(b.participationRate, 0.5);

    expect(c.consumed, 100);
    expect(c.net, -100);
  });

  test('category totals and percentages, ranked descending', () {
    final stats = computeTripSummary(
      expenses: [
        _expense(id: 'e1', payer: 'a', amount: 500, category: 'Food'),
        _expense(id: 'e2', payer: 'a', amount: 300, category: 'Transport'),
        _expense(id: 'e3', payer: 'a', amount: 200, category: 'Food'),
        _expense(id: 'e4', payer: 'a', amount: 1000, category: 'Lodging'),
      ],
      participants: [alice],
      joined: const [],
      settlements: const [],
    );

    expect(stats.totalSpent, 2000);
    expect(stats.categories, hasLength(3));
    final lodging = stats.categories.first;
    expect(lodging.categoryId, 'Lodging');
    expect(lodging.percent, closeTo(0.5, 0.001));
    final food = stats.categories.firstWhere((c) => c.categoryId == 'Food');
    expect(food.total, 700);
    expect(food.label, 'Food');
  });

  test('unknown category folds into Other', () {
    final stats = computeTripSummary(
      expenses: [
        _expense(id: 'e1', payer: 'a', amount: 50, category: 'Strange'),
      ],
      participants: [alice],
      joined: const [],
      settlements: const [],
    );

    expect(stats.categories, hasLength(1));
    expect(stats.categories.first.categoryId, 'Other');
  });

  test('settlements passthrough and paidCount', () {
    final stats = computeTripSummary(
      expenses: [_expense(id: 'e1', payer: 'a', amount: 100)],
      participants: [alice, bob],
      joined: const [],
      settlements: [
        Settlement(
          id: 's1',
          tripId: 'trip-1',
          fromParticipantId: 'b',
          toParticipantId: 'a',
          amount: 50,
          isPaid: true,
          createdAt: DateTime(2026),
        ),
        Settlement(
          id: 's2',
          tripId: 'trip-1',
          fromParticipantId: 'b',
          toParticipantId: 'a',
          amount: 30,
          isPaid: false,
          createdAt: DateTime(2026),
        ),
      ],
    );

    expect(stats.settlements, hasLength(2));
    expect(stats.paidSettlementsCount, 1);
  });
}