import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/data/models/models.dart';
import 'package:chiti/data/repository.dart';
import 'package:chiti/providers/providers.dart';

/// In-memory fake repository backing sponsorship notifier tests without
/// sqflite.
class FakeAppRepository extends AppRepository {
  final List<Sponsorship> sponsorships = [];
  final List<Settlement> settlements = [];

  @override
  Future<List<Sponsorship>> getSponsorships(String tripId) async =>
      sponsorships.where((s) => s.tripId == tripId).toList();

  @override
  Future<Sponsorship> createSponsorship({
    required String tripId,
    required String sponsorName,
    String? memberId,
    required double amount,
    String? note,
  }) async {
    final s = Sponsorship(
      id: 'sp-${sponsorships.length + 1}',
      tripId: tripId,
      sponsorName: sponsorName,
      memberId: memberId,
      amount: amount,
      note: note,
      createdAt: DateTime.now(),
    );
    sponsorships.add(s);
    return s;
  }

  @override
  Future<void> updateSponsorship(Sponsorship sponsorship) async {
    final index = sponsorships.indexWhere((s) => s.id == sponsorship.id);
    if (index == -1) throw StateError('sponsorship not found');
    sponsorships[index] = sponsorship;
  }

  @override
  Future<void> deleteSponsorship(String id) async {
    sponsorships.removeWhere((s) => s.id == id);
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

  @override
  Future<List<Expense>> getExpenses(String tripId) async => [];

  @override
  Future<List<Participant>> getParticipants(String tripId) async => [
    Participant(
      id: 'p1',
      tripId: tripId,
      name: 'Alice',
      color: 1,
      createdAt: DateTime(2026),
    ),
    Participant(
      id: 'p2',
      tripId: tripId,
      name: 'Bob',
      color: 2,
      createdAt: DateTime(2026),
    ),
  ];

  @override
  Future<List<ExpenseParticipant>> getParticipantsForTrip(String tripId) async =>
      [];

  @override
  Future<Trip?> getTrip(String id) async => Trip(
    id: id,
    name: 'Nhóm',
    destination: '',
    currency: 'VND',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 1),
    createdAt: DateTime(2026),
    hostId: 'p1',
  );
}

void main() {
  const tripId = 'trip-1';

  late FakeAppRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeAppRepository();
    container = ProviderContainer(
      overrides: [repositoryProvider.overrideWithValue(repo)],
    );
    // Keep autoDispose providers alive while in-flight futures settle.
    container.listen(sponsorshipsProvider(tripId), (_, _) {});
    container.listen(summaryProvider(tripId), (_, _) {});
    addTearDown(container.dispose);
  });

  test('loads existing sponsorships', () async {
    repo.sponsorships.add(
      Sponsorship(
        id: 'sp-1',
        tripId: tripId,
        sponsorName: 'Anh Nam tài trợ',
        amount: 100,
        createdAt: DateTime(2026),
      ),
    );
    await container.read(sponsorshipsProvider(tripId).notifier).load();
    final list = container.read(sponsorshipsProvider(tripId)).valueOrNull;
    expect(list, hasLength(1));
    expect(list!.first.sponsorName, 'Anh Nam tài trợ');
    expect(list.first.isInternal, isFalse);
  });

  test('addSponsorship persists and recomputes settlements', () async {
    await container
        .read(sponsorshipsProvider(tripId).notifier)
        .addSponsorship(
          sponsorName: 'Alice',
          memberId: 'p1',
          amount: 200,
        );

    final list = container.read(sponsorshipsProvider(tripId)).valueOrNull;
    expect(list, hasLength(1));
    expect(list!.first.isInternal, isTrue);
    expect(list.first.amount, 200);
    // Settlement plan was recalculated (and re-persisted).
    expect(repo.settlements, isEmpty); // no expenses -> no transfers.
  });

  test('updateSponsorship edits the entry', () async {
    final notifier = container.read(sponsorshipsProvider(tripId).notifier);
    await notifier.addSponsorship(
      sponsorName: 'Bob',
      memberId: 'p2',
      amount: 100,
    );
    final created = container.read(sponsorshipsProvider(tripId)).valueOrNull!.first;

    await notifier.updateSponsorship(
      created.copyWith(amount: 300, note: 'Cảm ơn Bob'),
    );

    final updated = container.read(sponsorshipsProvider(tripId)).valueOrNull!.first;
    expect(updated.amount, 300);
    expect(updated.note, 'Cảm ơn Bob');
    expect(updated.id, created.id);
  });

  test('deleteSponsorship removes the entry', () async {
    final notifier = container.read(sponsorshipsProvider(tripId).notifier);
    await notifier.addSponsorship(
      sponsorName: 'Quỹ công ty',
      amount: 500,
    );
    final created = container.read(sponsorshipsProvider(tripId)).valueOrNull!.first;

    await notifier.deleteSponsorship(created.id);

    expect(container.read(sponsorshipsProvider(tripId)).valueOrNull, isEmpty);
  });
}