import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/core/settlement_calculator.dart';
import 'package:chiti/core/summary_calculator.dart';
import 'package:chiti/data/models/models.dart';

Expense _expense({
  required String id,
  required String payer,
  required double amount,
}) => Expense(
  id: id,
  tripId: 'trip-1',
  title: id,
  amount: amount,
  payerId: payer,
  category: 'dining',
  createdAt: DateTime(2026, 8, 22),
);

Sponsorship _sponsorship({
  required String id,
  required double amount,
  String? memberId,
  String sponsorName = 'Sponsor',
}) => Sponsorship(
  id: id,
  tripId: 'trip-1',
  sponsorName: sponsorName,
  memberId: memberId,
  amount: amount,
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

  final joined = [
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
  ];

  group('sponsorshipDiscountFactor', () {
    test('no sponsorships => k = 1', () {
      expect(
        sponsorshipDiscountFactor(totalSpent: 300, totalSponsorship: 0),
        1,
      );
    });

    test('partial coverage scales proportionally', () {
      // E=300, S=150 -> k = 150/300 = 0.5.
      expect(
        sponsorshipDiscountFactor(totalSpent: 300, totalSponsorship: 150),
        closeTo(0.5, 0.0001),
      );
    });

    test('full coverage (S >= E) => k = 0', () {
      expect(
        sponsorshipDiscountFactor(totalSpent: 300, totalSponsorship: 300),
        0,
      );
      expect(
        sponsorshipDiscountFactor(totalSpent: 300, totalSponsorship: 500),
        0,
      );
    });

    test('no expenses => k = 1', () {
      expect(
        sponsorshipDiscountFactor(totalSpent: 0, totalSponsorship: 100),
        1,
      );
    });
  });

  group('computeTripSummary with sponsorships', () {
    final expenses = [_expense(id: 'e1', payer: 'a', amount: 300)];

    test('no sponsorships: consumption unchanged', () {
      final stats = computeTripSummary(
        expenses: expenses,
        participants: [alice, bob, carol],
        joined: joined,
        settlements: const [],
      );

      expect(stats.totalSponsorship, 0);
      expect(stats.netTotal, 300);
      expect(stats.discountFactor, 1);
      expect(stats.sponsorships, isEmpty);

      final a = stats.members.firstWhere((m) => m.participantId == 'a');
      expect(a.consumed, 100);
      expect(a.net, 200);
    });

    test('sponsorship scales every member consumption by k', () {
      final stats = computeTripSummary(
        expenses: expenses,
        participants: [alice, bob, carol],
        joined: joined,
        settlements: const [],
        sponsorships: [
          _sponsorship(id: 's1', amount: 150),
        ],
      );

      expect(stats.totalSponsorship, 150);
      expect(stats.netTotal, 150);
      expect(stats.discountFactor, closeTo(0.5, 0.0001));

      for (final m in stats.members) {
        expect(m.consumed, 50); // 100 * 0.5
      }
      final a = stats.members.firstWhere((m) => m.participantId == 'a');
      expect(a.paid, 300);
      expect(a.net, 250); // 300 - 50
      final b = stats.members.firstWhere((m) => m.participantId == 'b');
      expect(b.net, -50);
    });

    test('internal sponsor paid advance is NOT inflated by sponsorship', () {
      final stats = computeTripSummary(
        expenses: expenses,
        participants: [alice, bob, carol],
        joined: joined,
        settlements: const [],
        sponsorships: [
          // Alice both sponsors 100 and paid the 300 expense.
          _sponsorship(id: 's1', amount: 100, memberId: 'a'),
        ],
      );

      final a = stats.members.firstWhere((m) => m.participantId == 'a');
      // Sponsorship funds do not count toward her refundable advance.
      expect(a.paid, 300);
      // k = 200/300 -> consumed = 100 * 2/3 ≈ 66.67.
      expect(a.consumed, closeTo(66.67, 0.01));
      expect(a.net, closeTo(233.33, 0.01));

      final b = stats.members.firstWhere((m) => m.participantId == 'b');
      expect(b.net, closeTo(-66.67, 0.01));
    });

    test('full coverage: nothing to split, everyone refunded', () {
      final stats = computeTripSummary(
        expenses: expenses,
        participants: [alice, bob, carol],
        joined: joined,
        settlements: const [],
        sponsorships: [
          _sponsorship(id: 's1', amount: 300),
        ],
      );

      expect(stats.discountFactor, 0);
      expect(stats.netTotal, 0);
      for (final m in stats.members) {
        expect(m.consumed, 0);
        expect(m.net, m.paid);
      }
      // Alice paid everything -> gets the full 300 back.
      final a = stats.members.firstWhere((m) => m.participantId == 'a');
      expect(a.net, 300);
    });

    test('sum of net balances equals the sponsorship surplus', () {
      final stats = computeTripSummary(
        expenses: expenses,
        participants: [alice, bob, carol],
        joined: joined,
        settlements: const [],
        sponsorships: [
          _sponsorship(id: 's1', amount: 120),
        ],
      );

      final sum = stats.members.fold<double>(0, (acc, m) => acc + m.net);
      // sum(Net) = S_total = 120 (surplus absorbed by the sponsor).
      expect(sum, closeTo(120, 0.01));
    });

    test('external and internal sponsors are both listed', () {
      final stats = computeTripSummary(
        expenses: expenses,
        participants: [alice, bob, carol],
        joined: joined,
        settlements: const [],
        sponsorships: [
          _sponsorship(
            id: 's1',
            amount: 50,
            memberId: 'b',
            sponsorName: 'Bob',
          ),
          _sponsorship(
            id: 's2',
            amount: 70,
            sponsorName: 'Anh Nam tài trợ',
          ),
        ],
      );

      expect(stats.sponsorships, hasLength(2));
      expect(stats.totalSponsorship, 120);
      expect(stats.sponsorships.first.isInternal, isTrue);
      expect(stats.sponsorships.last.isInternal, isFalse);
    });
  });

  group('summary rows with sponsorship', () {
    test('net rows reflect the discounted share', () {
      final rows = buildSummary(
        participants: [
          (id: 'a', name: 'Alice'),
          (id: 'b', name: 'Bob'),
          (id: 'c', name: 'Carol'),
        ],
        totalPaid: const {'a': 300, 'b': 0, 'c': 0},
        totalShare: const {'a': 100, 'b': 100, 'c': 100},
      );

      // No discount (k=1): identical to the engine's raw output.
      expect(rows.firstWhere((r) => r.participantId == 'a').net, 200);
      expect(rows.firstWhere((r) => r.participantId == 'b').net, -100);
    });
  });
}