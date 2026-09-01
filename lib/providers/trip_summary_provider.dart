import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/summary_calculator.dart';
import '../data/models/models.dart';
import 'providers.dart';

/// Computed analytical snapshot for a trip.
///
/// Listens to participants / expenses / joined-participants / settlements and
/// the trip itself, so the dashboard recomputes whenever anything is added,
/// edited or deleted (the expenses notifier already pushes a refresh).
final tripSummaryProvider = FutureProvider.autoDispose.family<
  TripSummaryStats,
  String
>((ref, tripId) async {
  final participants =
      ref.watch(participantsProvider(tripId)).valueOrNull ??
      const <Participant>[];
  final expenses =
      ref.watch(expensesProvider(tripId)).valueOrNull ??
      const <Expense>[];
  final joined =
      ref.watch(expenseParticipantsForTripProvider(tripId)).valueOrNull ??
      const <ExpenseParticipant>[];
  final settlements =
      ref.watch(settlementsProvider(tripId)).valueOrNull ??
      const <Settlement>[];
  final sponsorships =
      ref.watch(sponsorshipsProvider(tripId)).valueOrNull ??
      const <Sponsorship>[];

  return computeTripSummary(
    expenses: expenses,
    participants: participants,
    joined: joined,
    settlements: settlements,
    sponsorships: sponsorships,
  );
});