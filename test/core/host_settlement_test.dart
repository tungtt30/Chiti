import 'package:flutter_test/flutter_test.dart';
import 'package:chiti/core/settlement_calculator.dart';

void main() {
  group('computeSettlementPlan - host mode inbound/outbound', () {
    test('all debtors transfer to host, host refunds all creditors', () {
      final plan = computeSettlementPlan(
        balances: {'host': -50, 'a': 80, 'b': -30},
        mode: SettlementMode.host,
        hostId: 'host',
      );

      expect(plan.length, 2);

      final inbound = plan.where((t) => t.type == TransactionType.inbound);
      final outbound = plan.where((t) => t.type == TransactionType.outbound);
      expect(inbound.length, 1);
      expect(outbound.length, 1);

      final toHost = inbound.single;
      expect(toHost.fromParticipantId, 'b');
      expect(toHost.toParticipantId, 'host');
      expect(toHost.amount, 30);
      expect(toHost.isHostTransaction, isTrue);

      final fromHost = outbound.single;
      expect(fromHost.fromParticipantId, 'host');
      expect(fromHost.toParticipantId, 'a');
      expect(fromHost.amount, 80);
      expect(fromHost.isHostTransaction, isTrue);
    });

    test('host never receives a transaction of its own', () {
      final plan = computeSettlementPlan(
        balances: {'host': 120, 'a': -50, 'b': -70},
        mode: SettlementMode.host,
        hostId: 'host',
      );
      for (final t in plan) {
        expect(t.fromParticipantId, isNot('host'));
      }
    });

    test('zero balances produce empty plan', () {
      final plan = computeSettlementPlan(
        balances: {'host': 0.0, 'a': 0.0},
        mode: SettlementMode.host,
        hostId: 'host',
      );
      expect(plan, isEmpty);
    });

    test('amounts are rounded to the cent', () {
      final plan = computeSettlementPlan(
        balances: {'host': -10, 'a': 33.33, 'b': 33.33, 'c': -56.66},
        mode: SettlementMode.host,
        hostId: 'host',
      );
      for (final t in plan) {
        expect(t.amount, (t.amount * 100).roundToDouble() / 100);
      }
    });
  });

  group('computeSettlementPlan - host self-balancing invariant', () {
    /// Invariant: collected - disbursed == net_host (Host self-balancing).
    double collected(List<SettlementTransaction> plan) => plan
        .where((t) => t.type == TransactionType.inbound)
        .fold(0.0, (s, t) => s + t.amount);

    double disbursed(List<SettlementTransaction> plan) => plan
        .where((t) => t.type == TransactionType.outbound)
        .fold(0.0, (s, t) => s + t.amount);

    test('host owes money: pays the shortfall out of pocket', () {
      // Group: host consumed 100 more than paid -> net_host = -100, so the
      // host disburses 100 to the creditors and collects nothing.
      final balances = {'host': -100.0, 'a': 40.0, 'b': 35.0, 'c': 25.0};
      final plan = computeSettlementPlan(
        balances: balances,
        mode: SettlementMode.host,
        hostId: 'host',
      );

      final c = collected(plan);
      final d = disbursed(plan);
      expect(c - d, closeTo(-100, 0.001));
      expect(d - c, closeTo(100, 0.001));
      // No inbound needed since everyone else is a creditor.
      expect(plan.where((t) => t.type == TransactionType.inbound), isEmpty);
      expect(d, closeTo(100, 0.001));
    });

    test('host is owed money: keeps exactly the group debt', () {
      // Group owes host 60 total -> net_host = +60, the host collects 60.
      final balances = {'host': 60.0, 'a': -20.0, 'b': -20.0, 'c': -20.0};
      final plan = computeSettlementPlan(
        balances: balances,
        mode: SettlementMode.host,
        hostId: 'host',
      );

      final c = collected(plan);
      final d = disbursed(plan);
      expect(c - d, closeTo(60, 0.001));
      // No outbound needed since everyone else is a debtor.
      expect(plan.where((t) => t.type == TransactionType.outbound), isEmpty);
      expect(c, closeTo(60, 0.001));
    });

    test('host balanced: collected equals disbursed', () {
      final balances = {
        'host': 0.0,
        'a': -30.0,
        'b': 10.0,
        'c': 20.0,
      };
      final plan = computeSettlementPlan(
        balances: balances,
        mode: SettlementMode.host,
        hostId: 'host',
      );

      final c = collected(plan);
      final d = disbursed(plan);
      expect(c, closeTo(d, 0.001));
      expect(c, closeTo(30, 0.001));
      expect(d, closeTo(30, 0.001));
    });

    test('mixed group keeps collected - disbursed == net_host', () {
      final balances = {
        'host': 25.0,
        'a': -50.0,
        'b': -15.0,
        'c': 40.0,
      };
      final plan = computeSettlementPlan(
        balances: balances,
        mode: SettlementMode.host,
        hostId: 'host',
      );
      final c = collected(plan);
      final d = disbursed(plan);
      expect(c - d, closeTo(25, 0.001));
    });
  });

  group('computeSettlementPlan - peer-to-peer and fallbacks', () {
    test('peerToPeer mode delegates to greedy simplification', () {
      final plan = computeSettlementPlan(
        balances: {'a': 50.0, 'b': -20.0, 'c': -30.0},
        mode: SettlementMode.peerToPeer,
        hostId: 'a',
      );
      expect(plan.length, 2);
      for (final t in plan) {
        expect(t.isHostTransaction, isFalse);
        expect(t.type, TransactionType.peerToPeer);
      }
      final total = plan.fold<double>(0, (s, t) => s + t.amount);
      expect(total, closeTo(50, 0.01));
    });

    test('host mode with missing hostId falls back to peer-to-peer', () {
      final plan = computeSettlementPlan(
        balances: {'a': 50.0, 'b': -50.0},
        mode: SettlementMode.host,
        hostId: null,
      );
      expect(plan.length, 1);
      expect(plan.single.isHostTransaction, isFalse);
      expect(plan.single.type, TransactionType.peerToPeer);
      expect(plan.single.fromParticipantId, 'b');
      expect(plan.single.toParticipantId, 'a');
    });

    test('host mode with unknown hostId falls back to peer-to-peer', () {
      final plan = computeSettlementPlan(
        balances: {'a': 50.0, 'b': -50.0},
        mode: SettlementMode.host,
        hostId: 'ghost',
      );
      expect(plan.length, 1);
      expect(plan.single.isHostTransaction, isFalse);
    });
  });

  group('SettlementMode', () {
    test('dbValue round-trips', () {
      expect(SettlementMode.host.dbValue, 'host');
      expect(SettlementMode.peerToPeer.dbValue, 'peer_to_peer');
      expect(SettlementMode.fromDbValue('host'), SettlementMode.host);
      expect(
        SettlementMode.fromDbValue('peer_to_peer'),
        SettlementMode.peerToPeer,
      );
      expect(SettlementMode.fromDbValue(null), SettlementMode.host);
      expect(SettlementMode.fromDbValue('weird'), SettlementMode.host);
    });
  });

  group('SettlementTransaction', () {
    test('equality works correctly', () {
      const t1 = SettlementTransaction(
        fromParticipantId: 'a',
        toParticipantId: 'host',
        amount: 50,
        isHostTransaction: true,
        type: TransactionType.inbound,
      );
      const t2 = SettlementTransaction(
        fromParticipantId: 'a',
        toParticipantId: 'host',
        amount: 50,
        isHostTransaction: true,
        type: TransactionType.inbound,
      );
      expect(t1, equals(t2));
      expect(t1.hashCode, t2.hashCode);
    });

    test('toString is readable', () {
      const t = SettlementTransaction(
        fromParticipantId: 'b',
        toParticipantId: 'host',
        amount: 30,
        isHostTransaction: true,
        type: TransactionType.inbound,
      );
      expect(t.toString(), 'b pays 30.0 to host (TransactionType.inbound)');
    });
  });
}