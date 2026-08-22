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
    required String payerId,
    required String category,
    required List<ExpenseParticipant> participants,
  }) async {
    await _repo.createExpense(
      tripId: tripId,
      title: title,
      amount: amount,
      payerId: payerId,
      category: category,
      participants: participants,
    );
    await load();
    // Recompute the who-owes-whom plan so balances reflect the new expense
    // immediately (matches update/delete behaviour).
    await ref.read(settlementsProvider(tripId).notifier).recalculate();
  }

  Future<void> updateExpense({
    required Expense expense,
    required List<ExpenseParticipant> participants,
  }) async {
    await _repo.updateExpense(
      expense: expense,
      participants: participants,
    );
    await load();
    // Recompute the who-owes-whom plan so balances reflect the edit immediately.
    await ref.read(settlementsProvider(tripId).notifier).recalculate();
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    await load();
    // Recompute the who-owes-whom plan after removing the expense.
    await ref.read(settlementsProvider(tripId).notifier).recalculate();
  }
}

// ---- Derived scores for a trip ----

/// Single expense bundled with its participating members (detail view).
final expenseDetailsProvider = FutureProvider.autoDispose
    .family<ExpenseWithParticipants?, String>((ref, expenseId) {
      return ref.read(repositoryProvider).getExpenseDetails(expenseId);
    });

/// Share obligation per participant across all expense_participants rows.
final expenseParticipantsForTripProvider = FutureProvider.autoDispose
    .family<List<ExpenseParticipant>, String>((ref, tripId) async {
      ref.watch(expensesProvider(tripId));
      return ref.read(repositoryProvider).getParticipantsForTrip(tripId);
    });

/// Ordered summary rows for the dashboard table.
final summaryProvider = FutureProvider.autoDispose
    .family<List<SummaryRow>, String>((ref, tripId) async {
      // Each `ref.watch` below subscribes this provider to changes in the
      // participants / expenses notifiers, so the summary recomputes
      // automatically.
      final participantsAsync = ref.watch(participantsProvider(tripId));
      final expensesAsync = ref.watch(expensesProvider(tripId));
      final participantsJoinedAsync = ref.watch(
        expenseParticipantsForTripProvider(tripId),
      );

      final participants =
          participantsAsync.valueOrNull ?? const <Participant>[];
      final expenses =
          expensesAsync.valueOrNull ?? const <Expense>[];
      final joined =
          participantsJoinedAsync.valueOrNull ??
          const <ExpenseParticipant>[];

      final totalPaid = <String, double>{};
      final totalShare = <String, double>{};
      for (final p in participants) {
        totalPaid[p.id] = 0;
        totalShare[p.id] = 0;
      }

      // Paid: the single payer of each expense covers its full amount.
      for (final expense in expenses) {
        totalPaid[expense.payerId] =
            (totalPaid[expense.payerId] ?? 0) + expense.amount;
      }
      // Obligation: only participants who joined incur a share.
      for (final member in joined) {
        totalShare[member.participantId] =
            (totalShare[member.participantId] ?? 0) + member.shareAmount;
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
