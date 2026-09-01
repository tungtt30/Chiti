import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/data/models/models.dart';
import 'package:chiti/data/repository.dart';
import 'package:chiti/l10n/app_localizations.dart';
import 'package:chiti/presentation/screens/trip_detail_screen.dart';
import 'package:chiti/providers/providers.dart';

/// In-memory fake repository so the sponsorship flow runs without sqflite.
class FakeAppRepository extends AppRepository {
  final List<Sponsorship> sponsorships = [];
  final List<Settlement> settlements = [];

  @override
  Future<Trip?> getTrip(String id) async => Trip(
    id: id,
    name: 'Nhóm cầu lông',
    destination: '',
    currency: 'VND',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 5),
    createdAt: DateTime(2026, 8, 1),
    hostId: 'p1',
  );

  @override
  Future<List<Participant>> getParticipants(String tripId) async => [
    Participant(
      id: 'p1',
      tripId: tripId,
      name: 'Alice',
      color: 0xFF64B5F6,
      createdAt: DateTime(2026, 8, 1),
    ),
    Participant(
      id: 'p2',
      tripId: tripId,
      name: 'Bob',
      color: 0xFF81C784,
      createdAt: DateTime(2026, 8, 1),
    ),
  ];

  @override
  Future<List<Expense>> getExpenses(String tripId) async => [
    Expense(
      id: 'e1',
      tripId: tripId,
      title: 'Sân cầu lông',
      amount: 300000,
      payerId: 'p1',
      category: 'sports',
      createdAt: DateTime(2026, 8, 2),
    ),
  ];

  @override
  Future<List<ExpenseParticipant>> getParticipantsForTrip(String tripId) async =>
      const [
        ExpenseParticipant(
          id: 'j1',
          expenseId: 'e1',
          participantId: 'p1',
          shareAmount: 150000,
        ),
        ExpenseParticipant(
          id: 'j2',
          expenseId: 'e1',
          participantId: 'p2',
          shareAmount: 150000,
        ),
      ];

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
  Future<void> deleteSponsorship(String id) async {
    sponsorships.removeWhere((s) => s.id == id);
  }
}

void main() {
  testWidgets('adds an external sponsorship and shows it on the tab', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    final repo = FakeAppRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: [Locale('vi'), Locale('en')],
          home: TripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the Sponsorships tab.
    await tester.tap(find.text('Sponsorships'));
    await tester.pumpAndSettle();

    // Empty state + FAB.
    expect(find.text('No sponsorships yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('fab_sponsorship')), findsOneWidget);

    // Open the add form.
    await tester.tap(find.byKey(const ValueKey('fab_sponsorship')));
    await tester.pumpAndSettle();
    expect(find.text('Add Sponsorship'), findsOneWidget);

    // Switch to an external sponsor and fill the fields.
    await tester.tap(find.text('External Sponsor'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sponsor'),
      'Anh Nam tài trợ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '150,000',
    );
    await tester.tap(find.text('Save Sponsorship'));
    await tester.pumpAndSettle();

    // Back on the tab: the sponsorship card shows name + amount, and the
    // net-to-split reflects the 50% discount (300,000 - 150,000).
    expect(repo.sponsorships, hasLength(1));
    expect(repo.sponsorships.first.sponsorName, 'Anh Nam tài trợ');
    expect(repo.sponsorships.first.isInternal, isFalse);
    expect(find.text('Anh Nam tài trợ'), findsOneWidget);
    expect(find.text('₫150,000'), findsWidgets);
    expect(find.text('₫150,000'), findsWidgets);
  });

  testWidgets('internal sponsorship selects a member from the list', (
    tester,
  ) async {
    final repo = FakeAppRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWithValue(repo)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: [Locale('vi'), Locale('en')],
          home: TripDetailScreen(tripId: 'trip-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sponsorships'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fab_sponsorship')));
    await tester.pumpAndSettle();

    // Internal is the default segment: member chips are shown.
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);

    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '100,000',
    );
    await tester.tap(find.text('Save Sponsorship'));
    await tester.pumpAndSettle();

    expect(repo.sponsorships, hasLength(1));
    expect(repo.sponsorships.first.memberId, 'p2');
    expect(repo.sponsorships.first.sponsorName, 'Bob');
    expect(find.text('Bob'), findsWidgets);
  });
}