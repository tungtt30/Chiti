import 'package:flutter_test/flutter_test.dart';
import 'package:chiti/core/settlement_calculator.dart';

void main() {
  group('computeNetBalances', () {
    test('equal payments and shares yields zero balances', () {
      final balances = computeNetBalances(
        totalPaid: {'Alice': 100, 'Bob': 100},
        totalShare: {'Alice': 100, 'Bob': 100},
      );
      expect(balances['Alice'], 0);
      expect(balances['Bob'], 0);
    });

    test('single payer, equal split', () {
      final balances = computeNetBalances(
        totalPaid: {'Alice': 100, 'Bob': 0},
        totalShare: {'Alice': 50, 'Bob': 50},
      );
      expect(balances['Alice'], 50);
      expect(balances['Bob'], -50);
    });

    test('multiple payers, uneven split', () {
      final balances = computeNetBalances(
        totalPaid: {'Alice': 200, 'Bob': 50, 'Charlie': 0},
        totalShare: {'Alice': 100, 'Bob': 100, 'Charlie': 50},
      );
      expect(balances['Alice'], 100);
      expect(balances['Bob'], -50);
      expect(balances['Charlie'], -50);
    });

    test('handles missing participants gracefully', () {
      final balances = computeNetBalances(
        totalPaid: {'Alice': 100},
        totalShare: {'Alice': 60, 'Bob': 40},
      );
      expect(balances['Alice'], 40);
      expect(balances['Bob'], -40);
    });

    test('multiple payers aggregate into net balances', () {
      // Alice and Bob both paid toward the same dinner; Charlie owes.
      final balances = computeNetBalances(
        totalPaid: {'Alice': 60, 'Bob': 40, 'Charlie': 0},
        totalShare: {'Alice': 33.33, 'Bob': 33.33, 'Charlie': 33.34},
      );
      expect(balances['Alice'], closeTo(26.67, 0.01));
      expect(balances['Bob'], closeTo(6.67, 0.01));
      expect(balances['Charlie'], closeTo(-33.34, 0.01));
    });
  });

  group('buildSummary', () {
    test('returns ordered rows with paid, share and net', () {
      final rows = buildSummary(
        participants: const [
          (id: 'a', name: 'Alice'),
          (id: 'b', name: 'Bob'),
          (id: 'c', name: 'Charlie'),
        ],
        totalPaid: {'a': 60, 'b': 40},
        totalShare: {'a': 33.33, 'b': 33.33, 'c': 33.34},
      );
      expect(rows.length, 3);
      expect(rows[0].name, 'Alice');
      expect(rows[0].net, closeTo(26.67, 0.01));
      expect(rows[1].net, closeTo(6.67, 0.01));
      expect(rows[2].net, closeTo(-33.34, 0.01));
    });
  });

  group('splitEqually', () {
    test('splits evenly with remainder on the last share', () {
      final shares = splitEqually(total: 100, count: 3);
      expect(shares.length, 3);
      expect(shares[0], 33.33);
      expect(shares[1], 33.33);
      expect(shares[2], closeTo(33.34, 0.01));
      expect(shares.fold<double>(0, (a, b) => a + b), closeTo(100, 0.01));
    });

    test('single person pays everything', () {
      expect(splitEqually(total: 250, count: 1), [250.0]);
    });

    test('zero count returns empty', () {
      expect(splitEqually(total: 100, count: 0), isEmpty);
    });
  });

  group('splitByWeight', () {
    test('distributes proportionally to weights', () {
      final shares = splitByWeight(total: 100, weights: [1, 3]);
      expect(shares[0], 25.0);
      expect(shares[1], 75.0);
    });

    test('sum equals total even with rounding', () {
      final shares = splitByWeight(total: 100, weights: [1, 1, 1]);
      expect(shares.fold<double>(0, (a, b) => a + b), closeTo(100, 0.01));
      expect(shares[2], closeTo(33.34, 0.01));
    });

    test('zero weights produce zeros', () {
      final shares = splitByWeight(total: 100, weights: [0, 0]);
      expect(shares, [0.0, 0.0]);
    });
  });

  group('simplifyDebts', () {
    test('no debts returns empty list', () {
      final transfers = simplifyDebts({'Alice': 0.0, 'Bob': 0.0});
      expect(transfers, isEmpty);
    });

    test('simple two-person debt', () {
      final transfers = simplifyDebts({'Alice': 50.0, 'Bob': -50.0});
      expect(transfers.length, 1);
      expect(transfers[0].from, 'Bob');
      expect(transfers[0].to, 'Alice');
      expect(transfers[0].amount, 50.0);
    });

    test('three person chain debt simplification', () {
      final balances = <String, double>{
        'Alice': 100,
        'Bob': -30,
        'Charlie': -70,
      };
      final transfers = simplifyDebts(balances);

      expect(transfers.length, 2);

      final totalTransferred = transfers.fold(0.0, (sum, t) => sum + t.amount);
      expect(totalTransferred, closeTo(100, 0.01));
    });

    test('greedy matching minimizes transactions', () {
      final balances = <String, double>{
        'Alice': 50.0,
        'Bob': 20.0,
        'Charlie': -40.0,
        'Diana': -30.0,
      };
      final transfers = simplifyDebts(balances);

      // 3 transactions needed: Charlie->Alice(40), Diana->Alice(10), Diana->Bob(20)
      expect(transfers.length, 3);

      final totalTransferred = transfers.fold(0.0, (sum, t) => sum + t.amount);
      expect(totalTransferred, closeTo(70, 0.01));

      for (final t in transfers) {
        expect(t.amount, greaterThan(0));
      }
    });

    test('handles fractional amounts correctly', () {
      final balances = <String, double>{
        'Alice': 33.33,
        'Bob': 33.33,
        'Charlie': -66.66,
      };
      final transfers = simplifyDebts(balances);

      final totalTransferred = transfers.fold(0.0, (sum, t) => sum + t.amount);
      expect(totalTransferred, closeTo(66.66, 0.1));
    });

    test('large group simplification', () {
      final balances = <String, double>{
        'Alice': 200,
        'Bob': 100,
        'Charlie': 50,
        'Diana': -150,
        'Eve': -100,
        'Frank': -100,
      };
      final transfers = simplifyDebts(balances);

      expect(transfers.length, lessThanOrEqualTo(5));

      final totalTransferred = transfers.fold(0.0, (sum, t) => sum + t.amount);
      expect(totalTransferred, closeTo(350, 0.01));
    });

    test('one person paid for everyone', () {
      final balances = <String, double>{
        'Alice': 300,
        'Bob': -100,
        'Charlie': -100,
        'Diana': -100,
      };
      final transfers = simplifyDebts(balances);

      expect(transfers.length, 3);
      for (final t in transfers) {
        expect(t.from, isNot('Alice'));
        expect(t.to, 'Alice');
        expect(t.amount, 100);
      }
    });

    test('everyone paid equally, no transfers needed', () {
      final transfers = simplifyDebts({
        'Alice': 0.0,
        'Bob': 0.0,
        'Charlie': 0.0,
      });
      expect(transfers, isEmpty);
    });

    test('works with ids (not just names)', () {
      final balances = <String, double>{'p1': -200, 'p2': 120, 'p3': 80};
      final transfers = simplifyDebts(balances);
      expect(transfers.length, 2);
      for (final t in transfers) {
        expect(t.from, 'p1');
      }
    });
  });

  group('Transfer', () {
    test('toString returns human readable format', () {
      final t = Transfer(from: 'Bob', to: 'Alice', amount: 50.0);
      expect(t.toString(), 'Bob pays 50.0 to Alice');
    });

    test('equality works correctly', () {
      final t1 = Transfer(from: 'Bob', to: 'Alice', amount: 50);
      final t2 = Transfer(from: 'Bob', to: 'Alice', amount: 50);
      expect(t1, equals(t2));
    });
  });
}
