import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/core/constants.dart';
import 'package:chiti/core/settlement_calculator.dart';

void main() {
  group('computeSubsetShares', () {
    test('equal split over a subset excludes non-members', () {
      final shares = computeSubsetShares(
        total: 300,
        selectedIds: const ['a', 'b', 'c'],
        splitMode: SplitMode.equal,
      );

      expect(shares.keys.toSet(), {'a', 'b', 'c'});
      expect(shares, {'a': 100.0, 'b': 100.0, 'c': 100.0});
    });

    test('equal split with a single selected member gets the full total', () {
      final shares = computeSubsetShares(
        total: 87.5,
        selectedIds: const ['a'],
        splitMode: SplitMode.equal,
      );

      expect(shares, {'a': 87.5});
    });

    test('equal split absorbs rounding remainder on the last share', () {
      final shares = computeSubsetShares(
        total: 100,
        selectedIds: const ['a', 'b', 'c'],
        splitMode: SplitMode.equal,
      );

      final sum = shares.values.fold(0.0, (a, b) => a + b);
      expect(sum, closeTo(100, 0.001));
      expect(shares['a'], closeTo(33.33, 0.01));
      expect(shares['b'], closeTo(33.33, 0.01));
      expect(shares['c'], closeTo(33.34, 0.01));
    });

    test('custom amounts pass through per selected member', () {
      final shares = computeSubsetShares(
        total: 100,
        selectedIds: const ['a', 'c'],
        splitMode: SplitMode.customAmount,
        customAmounts: {'a': 70, 'c': 30},
      );

      expect(shares, {'a': 70.0, 'c': 30.0});
    });

    test('weighted split distributes proportionally in the subset', () {
      final shares = computeSubsetShares(
        total: 100,
        selectedIds: const ['a', 'b'],
        splitMode: SplitMode.customWeight,
        weights: {'a': 1, 'b': 3},
      );

      expect(shares['a'], closeTo(25, 0.01));
      expect(shares['b'], closeTo(75, 0.01));
    });

    test('empty selection yields no shares', () {
      expect(
        computeSubsetShares(
          total: 100,
          selectedIds: const [],
          splitMode: SplitMode.equal,
        ),
        isEmpty,
      );
    });

    test('zero or negative total yields no shares', () {
      expect(
        computeSubsetShares(
          total: 0,
          selectedIds: const ['a', 'b'],
          splitMode: SplitMode.equal,
        ),
        isEmpty,
      );
    });
  });

  group('computePayerNetImpact', () {
    test('payer inside the subset is credited total minus own share', () {
      // Paid 100, owes 25 -> credited 75.
      final net = computePayerNetImpact(amountPaid: 100, shareObligation: 25);
      expect(net, 75);
    });

    test('payer outside the subset is credited the full amount paid', () {
      // Paid on behalf of the subgroup, owes nothing -> credited 100.
      final net = computePayerNetImpact(amountPaid: 100, shareObligation: 0);
      expect(net, 100);
    });

    test('payer who owes more than they paid gets a negative net', () {
      final net = computePayerNetImpact(amountPaid: 10, shareObligation: 40);
      expect(net, -30);
    });
  });
}