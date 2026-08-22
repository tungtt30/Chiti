import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/id_generator.dart';
import '../core/settlement_calculator.dart';
import '../data/models/models.dart';
import '../data/repository.dart';

final repositoryProvider = Provider<AppRepository>((ref) => AppRepository());

// ---- Trips ----

final tripListProvider =
    StateNotifierProvider<TripListNotifier, AsyncValue<List<Trip>>>(
      (ref) => TripListNotifier(ref),
    );

class TripListNotifier extends StateNotifier<AsyncValue<List<Trip>>> {
  final Ref ref;
  final AppRepository _repo;

  TripListNotifier(this.ref)
    : _repo = ref.read(repositoryProvider),
      super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final trips = await _repo.getAllTrips();
      state = AsyncValue.data(trips);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Trip> createTrip({
    required String name,
    required String destination,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final trip = await _repo.createTrip(
      name: name,
      destination: destination,
      currency: currency,
      startDate: startDate,
      endDate: endDate,
    );
    await load();
    return trip;
  }

  Future<void> deleteTrip(String id) async {
    await _repo.deleteTrip(id);
    await load();
  }
}

// ---- Single Trip Detail ----

final tripDetailProvider =
    StateNotifierProvider.family<TripDetailNotifier, AsyncValue<Trip?>, String>(
      (ref, tripId) => TripDetailNotifier(ref, tripId),
    );

class TripDetailNotifier extends StateNotifier<AsyncValue<Trip?>> {
  final Ref ref;
  final String tripId;
  final AppRepository _repo;

  TripDetailNotifier(this.ref, this.tripId)
    : _repo = ref.read(repositoryProvider),
      super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final trip = await _repo.getTrip(tripId);
      state = AsyncValue.data(trip);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTrip(Trip trip) async {
    await _repo.updateTrip(trip);
    await load();
    ref.invalidate(tripListProvider);
  }
}

// ---- Participants ----

final participantsProvider =
    StateNotifierProvider.family<
      ParticipantsNotifier,
      AsyncValue<List<Participant>>,
      String
    >((ref, tripId) => ParticipantsNotifier(ref, tripId));

class ParticipantsNotifier
    extends StateNotifier<AsyncValue<List<Participant>>> {
  final Ref ref;
  final String tripId;
  final AppRepository _repo;

  ParticipantsNotifier(this.ref, this.tripId)
    : _repo = ref.read(repositoryProvider),
      super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final participants = await _repo.getParticipants(tripId);
      state = AsyncValue.data(participants);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addParticipant({
    required String name,
    required int color,
    String? contact,
    String? note,
  }) async {
    await _repo.addParticipant(
      tripId: tripId,
      name: name,
      color: color,
      contact: contact,
      note: note,
    );
    await load();
  }

  Future<void> updateParticipant(Participant participant) async {
    await _repo.updateParticipant(participant);
    await load();
  }

  Future<void> removeParticipant(String id) async {
    await _repo.removeParticipant(id);
    await load();
  }
}

// ---- Expenses ----

final expensesProvider =
    StateNotifierProvider.family<
      ExpensesNotifier,
      AsyncValue<List<Expense>>,
      String
    >((ref, tripId) => ExpensesNotifier(ref, tripId));

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final Ref ref;
  final String tripId;
  final AppRepository _repo;

  ExpensesNotifier(this.ref, this.tripId)
    : _repo = ref.read(repositoryProvider),
      super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _repo.getExpenses(tripId);
      state = AsyncValue.data(expenses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createExpense({
    required String title,
    required double amount,
    required DateTime date,
    required String category,
    required String splitMode,
    required List<ExpensePayer> payers,
    required List<ExpenseSplit> splits,
  }) async {
    await _repo.createExpense(
      tripId: tripId,
      title: title,
      amount: amount,
      date: date,
      category: category,
      splitMode: splitMode,
      payers: payers,
      splits: splits,
    );
    await load();
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    await load();
  }
}

// ---- Derived scores for a trip ----

/// Amount each participant paid across all expenses (one row per payer).
final payersForTripProvider = FutureProvider.autoDispose
    .family<List<ExpensePayer>, String>((ref, tripId) async {
      ref.watch(expensesProvider(tripId));
      return ref.read(repositoryProvider).getPayersForTrip(tripId);
    });

/// Obligation per participant across all split rows.
final splitsForTripProvider = FutureProvider.autoDispose
    .family<List<ExpenseSplit>, String>((ref, tripId) async {
      ref.watch(expensesProvider(tripId));
      return ref.read(repositoryProvider).getSplitsForTrip(tripId);
    });

/// Ordered summary rows for the dashboard table.
final summaryProvider = FutureProvider.autoDispose
    .family<List<SummaryRow>, String>((ref, tripId) async {
      // Each `ref.watch` below subscribes this provider to changes in the
      // participants / expenses notifiers, so the summary recomputes automatically.
      final participantsAsync = ref.watch(participantsProvider(tripId));
      ref.watch(expensesProvider(tripId));
      final payersAsync = ref.watch(payersForTripProvider(tripId));
      final splitsAsync = ref.watch(splitsForTripProvider(tripId));

      final participants =
          participantsAsync.valueOrNull ?? const <Participant>[];
      final payers = payersAsync.valueOrNull ?? const <ExpensePayer>[];
      final splits = splitsAsync.valueOrNull ?? const <ExpenseSplit>[];

      final totalPaid = <String, double>{};
      final totalShare = <String, double>{};
      for (final p in participants) {
        totalPaid[p.id] = 0;
        totalShare[p.id] = 0;
      }

      for (final payer in payers) {
        totalPaid[payer.participantId] =
            (totalPaid[payer.participantId] ?? 0) + payer.amount;
      }
      for (final split in splits) {
        totalShare[split.participantId] =
            (totalShare[split.participantId] ?? 0) + split.amount;
      }

      return buildSummary(
        participants: participants
            .map((p) => (id: p.id, name: p.name))
            .toList(),
        totalPaid: totalPaid,
        totalShare: totalShare,
      );
    });

// ---- Settlements ----

final settlementsProvider =
    StateNotifierProvider.family<
      SettlementsNotifier,
      AsyncValue<List<Settlement>>,
      String
    >((ref, tripId) => SettlementsNotifier(ref, tripId));

class SettlementsNotifier extends StateNotifier<AsyncValue<List<Settlement>>> {
  final Ref ref;
  final String tripId;
  final AppRepository _repo;

  SettlementsNotifier(this.ref, this.tripId)
    : _repo = ref.read(repositoryProvider),
      super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final settlements = await _repo.getSettlements(tripId);
      state = AsyncValue.data(settlements);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Re-runs the greedy settlement engine and persists the new plan.
  Future<void> recalculate() async {
    state = const AsyncValue.loading();
    try {
      final rows = await ref.read(summaryProvider(tripId).future);
      final balances = {for (final r in rows) r.participantId: r.net};
      final transfers = simplifyDebts(balances);
      final createdAt = DateTime.now();

      final pledges = transfers
          .map(
            (t) => Settlement(
              id: generateId(),
              tripId: tripId,
              fromParticipantId: t.from,
              toParticipantId: t.to,
              amount: t.amount,
              isPaid: false,
              createdAt: createdAt,
            ),
          )
          .toList();

      await _repo.replaceSettlements(tripId, pledges);
      state = AsyncValue.data(await _repo.getSettlements(tripId));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePaid(String id, bool isPaid) async {
    await _repo.setSettlementPaid(id, isPaid);
    await load();
  }
}

// ---- Total spent per trip ----

final totalSpentProvider = FutureProvider.autoDispose.family<double, String>((
  ref,
  tripId,
) async {
  final expenses =
      ref.watch(expensesProvider(tripId)).valueOrNull ?? const <Expense>[];
  return expenses.fold<double>(0, (sum, e) => sum + e.amount);
});
