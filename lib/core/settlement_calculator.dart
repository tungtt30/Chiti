/// Greedy Debt Simplification Algorithm.
///
/// Computes the minimal set of transfers to settle all debts among
/// participants using a greedy approach: match the largest debtor with the
/// largest creditor.
library;

import 'constants.dart' show SplitMode;

/// How a trip settles its balances: centralized through a Host (Thủ quỹ) or
/// direct peer-to-peer transfers.
enum SettlementMode {
  host,
  peerToPeer;

  /// Persisted value in the `trips.settlement_mode` column.
  String get dbValue => switch (this) {
    SettlementMode.host => 'host',
    SettlementMode.peerToPeer => 'peer_to_peer',
  };

  static SettlementMode fromDbValue(String? value) {
    return switch (value) {
      'peer_to_peer' => SettlementMode.peerToPeer,
      _ => SettlementMode.host,
    };
  }
}

/// Direction of a settlement transaction relative to the Host.
enum TransactionType {
  /// A debtor transfers money *to* the Host (Thu tiền về Thủ quỹ).
  inbound,

  /// The Host transfers money *to* a creditor (Thủ quỹ hoàn tiền).
  outbound,

  /// A direct peer-to-peer transfer (no Host involvement).
  peerToPeer,
}

/// One settlement transaction produced by the settlement engine:
/// [fromParticipantId] pays [amount] to [toParticipantId].
class SettlementTransaction {
  final String fromParticipantId;
  final String toParticipantId;
  final double amount;
  final bool isHostTransaction; // true if involving host
  final TransactionType type; // inbound (to host) or outbound (from host)

  const SettlementTransaction({
    required this.fromParticipantId,
    required this.toParticipantId,
    required this.amount,
    this.isHostTransaction = true,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettlementTransaction &&
          runtimeType == other.runtimeType &&
          fromParticipantId == other.fromParticipantId &&
          toParticipantId == other.toParticipantId &&
          amount == other.amount &&
          isHostTransaction == other.isHostTransaction &&
          type == other.type;

  @override
  int get hashCode =>
      fromParticipantId.hashCode ^
      toParticipantId.hashCode ^
      amount.hashCode ^
      isHostTransaction.hashCode ^
      type.hashCode;

  @override
  String toString() =>
      '$fromParticipantId pays $amount to $toParticipantId ($type)';
}

class Transfer {
  final String from;
  final String to;
  final double amount;

  const Transfer({required this.from, required this.to, required this.amount});

  @override
  String toString() => '$from pays $amount to $to';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transfer &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          amount == other.amount;

  @override
  int get hashCode => from.hashCode ^ to.hashCode ^ amount.hashCode;
}

/// One row of the summary dashboard.
class SummaryRow {
  final String participantId;
  final String name;
  final double paid; // Total amount spent / paid for the group.
  final double share; // Total obligation (amounts owed).
  final double net; // paid - share. Positive = is owed, negative = owes.

  const SummaryRow({
    required this.participantId,
    required this.name,
    required this.paid,
    required this.share,
    required this.net,
  });
}

double _round2(double value) => double.parse(value.toStringAsFixed(2));

/// Compute net balances for each participant.
///
/// [totalPaid] maps participant name -> total amount they paid.
/// [totalShare] maps participant name -> total amount they owe.
/// Returns a map of participant name -> net balance (positive = owed money,
/// negative = owes money).
Map<String, double> computeNetBalances({
  required Map<String, double> totalPaid,
  required Map<String, double> totalShare,
}) {
  final allNames = <String>{...totalPaid.keys, ...totalShare.keys};
  final balances = <String, double>{};
  for (final name in allNames) {
    final paid = totalPaid[name] ?? 0.0;
    final share = totalShare[name] ?? 0.0;
    balances[name] = _round2(paid - share);
  }
  return balances;
}

/// Build ordered [SummaryRow]s for a trip.
///
/// [participants] must provide name/id in display order; every id that appears
/// in [totalPaid] or [totalShare] is included, ordered after the given list.
List<SummaryRow> buildSummary({
  required List<({String id, String name})> participants,
  required Map<String, double> totalPaid,
  required Map<String, double> totalShare,
}) {
  final balances = computeNetBalances(
    totalPaid: totalPaid,
    totalShare: totalShare,
  );

  final rows = <SummaryRow>[];
  final handled = <String>{};
  for (final p in participants) {
    final net = balances[p.id] ?? 0.0;
    rows.add(
      SummaryRow(
        participantId: p.id,
        name: p.name,
        paid: totalPaid[p.id] ?? 0.0,
        share: totalShare[p.id] ?? 0.0,
        net: net,
      ),
    );
    handled.add(p.id);
  }
  for (final entry in balances.entries) {
    if (!handled.contains(entry.key)) {
      rows.add(
        SummaryRow(
          participantId: entry.key,
          name: entry.key,
          paid: totalPaid[entry.key] ?? 0.0,
          share: totalShare[entry.key] ?? 0.0,
          net: entry.value,
        ),
      );
    }
  }
  return rows;
}

/// Simplify debts using the greedy algorithm.
///
/// Given a map of participant name -> net balance, returns the minimal list of
/// [Transfer] objects to settle all debts.
List<Transfer> simplifyDebts(Map<String, double> balances) {
  final debtors = <MapEntry<String, double>>[];
  final creditors = <MapEntry<String, double>>[];

  for (final entry in balances.entries) {
    final rounded = _round2(entry.value);
    if (rounded < -0.01) {
      debtors.add(MapEntry(entry.key, -rounded));
    } else if (rounded > 0.01) {
      creditors.add(MapEntry(entry.key, rounded));
    }
  }

  debtors.sort((a, b) => b.value.compareTo(a.value));
  creditors.sort((a, b) => b.value.compareTo(a.value));

  final transfers = <Transfer>[];
  var i = 0;
  var j = 0;

  while (i < debtors.length && j < creditors.length) {
    final debtor = debtors[i];
    final creditor = creditors[j];
    final amount = debtor.value < creditor.value
        ? debtor.value
        : creditor.value;

    final rounded = _round2(amount);
    if (rounded > 0.01) {
      transfers.add(
        Transfer(from: debtor.key, to: creditor.key, amount: rounded),
      );
    }

    debtors[i] = MapEntry(debtor.key, _round2(debtor.value - amount));
    creditors[j] = MapEntry(creditor.key, _round2(creditor.value - amount));

    if (debtors[i].value < 0.01) i++;
    if (creditors[j].value < 0.01) j++;
  }

  return transfers;
}

/// Compute the settlement plan for a trip, honoring the settlement [mode].
///
/// **Host mode** (Mô hình thanh toán tập trung qua Thủ quỹ):
/// 1. Inbound phase (Thu tiền về Host): every debtor `i != host` with
///    `Net_i < 0` transfers `|Net_i|` to the Host.
/// 2. Outbound phase (Host hoàn tiền): every creditor `j != host` with
///    `Net_j > 0` receives `Net_j` from the Host.
///
/// Because `sum(Net) = 0`, the Host self-balances:
/// `Net_H + D_H - C_H = 0`, i.e. `C_H - D_H = Net_H`:
/// - Host owes money (`Net_H < 0`): the Host disburses `|Net_H|` more than it
///   collects — the exact shortfall it pays out of pocket.
/// - Host is owed (`Net_H > 0`): the Host collects `Net_H` more than it
///   disburses — exactly what the group owes the Host.
/// - Host balanced (`Net_H = 0`): `C_H = D_H`.
/// Either way the Host never needs a transaction of its own.
///
/// **Peer-to-peer mode**: delegates to the greedy [simplifyDebts] algorithm.
///
/// If [mode] is host but [hostId] is null or not present in [balances]
/// (e.g. a legacy trip with no members), the plan falls back to the
/// peer-to-peer result so it never breaks.
List<SettlementTransaction> computeSettlementPlan({
  required Map<String, double> balances,
  required SettlementMode mode,
  String? hostId,
}) {
  if (mode == SettlementMode.peerToPeer || hostId == null ||
      !balances.containsKey(hostId)) {
    return simplifyDebts(balances)
        .map(
          (t) => SettlementTransaction(
            fromParticipantId: t.from,
            toParticipantId: t.to,
            amount: t.amount,
            isHostTransaction: false,
            type: TransactionType.peerToPeer,
          ),
        )
        .toList();
  }

  final plan = <SettlementTransaction>[];
  for (final entry in balances.entries) {
    if (entry.key == hostId) continue;
    final net = _round2(entry.value);
    if (net < -0.01) {
      plan.add(
        SettlementTransaction(
          fromParticipantId: entry.key,
          toParticipantId: hostId,
          amount: _round2(-net),
          isHostTransaction: true,
          type: TransactionType.inbound,
        ),
      );
    } else if (net > 0.01) {
      plan.add(
        SettlementTransaction(
          fromParticipantId: hostId,
          toParticipantId: entry.key,
          amount: net,
          isHostTransaction: true,
          type: TransactionType.outbound,
        ),
      );
    }
  }
  return plan;
}

/// Round-robin distribute [total] among [count] shares so each share is
/// equally rounded to the cent and the last share absorbs any remainder.
List<double> splitEqually({required double total, required int count}) {
  if (count <= 0) return const [];
  final perHead = _round2(total / count);
  final shares = List.filled(count, perHead);
  final remainder = _round2(total - perHead * count);
  if (remainder != 0 && count > 0) {
    shares[count - 1] = _round2(shares[count - 1] + remainder);
  }
  return shares;
}

/// Distribute [total] proportionally to [weights]. The last share absorbs the
/// rounding remainder so the sum always equals [total].
List<double> splitByWeight({
  required double total,
  required List<double> weights,
}) {
  if (weights.isEmpty) return const [];
  final weightSum = weights.fold(0.0, (a, b) => a + b);
  if (weightSum <= 0) return List.filled(weights.length, 0.0);

  final shares = <double>[];
  var allocated = 0.0;
  for (var i = 0; i < weights.length; i++) {
    var share = _round2(total * weights[i] / weightSum);
    if (i == weights.length - 1) {
      share = _round2(total - allocated);
    } else {
      allocated += share;
    }
    shares.add(share);
  }
  return shares;
}

/// ----------------------------------
/// Subset (sub-group) split helpers
/// ----------------------------------

/// On-the-spot per-person share for a single expense over the selected
/// *subset* of participants. Participants not in [selectedIds] get no entry in
/// the result (they owe nothing for this expense).
///
/// - equal:         each selected person owes `total / k`; the last share in
///                  list order absorbs the cent-rounding remainder (mirroring
///                  [splitEqually] so the preview matches what is persisted).
/// - custom_amount: [customAmounts] is used verbatim per selected id.
/// - custom_weight: proportional to [weights] via [splitByWeight].
Map<String, double> computeSubsetShares({
  required double total,
  required List<String> selectedIds,
  required String splitMode,
  Map<String, double> customAmounts = const {},
  Map<String, double> weights = const {},
}) {
  if (selectedIds.isEmpty || total <= 0) return const {};
  switch (splitMode) {
    case SplitMode.customAmount:
      return {
        for (final id in selectedIds) id: customAmounts[id] ?? 0.0,
      };
    case SplitMode.customWeight:
      final shareList = splitByWeight(
        total: total,
        weights: selectedIds.map((id) => weights[id] ?? 0).toList(),
      );
      return {
        for (var i = 0; i < selectedIds.length; i++)
          selectedIds[i]: shareList[i],
      };
    default: // SplitMode.equal
      final shareList = splitEqually(total: total, count: selectedIds.length);
      return {
        for (var i = 0; i < selectedIds.length; i++)
          selectedIds[i]: shareList[i],
      };
  }
}

/// One payer's net impact for a single expense.
///
/// Positive = this payer is owed money back (credited), negative = they still
/// owe more.
///
/// Two spec branches:
/// - Payer is part of the selected participants: they are credited
///   [amountPaid] - [shareObligation].
/// - Payer is NOT part of the selected participants (paid on behalf of the
///   sub-group): [shareObligation] is 0 and they are credited the full
///   [amountPaid].
double computePayerNetImpact({
  required double amountPaid,
  required double shareObligation,
}) {
  return _round2(amountPaid - shareObligation);
}
