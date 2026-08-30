import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chiti/data/models/models.dart';
import 'package:chiti/data/repository.dart';
import 'package:chiti/l10n/app_localizations.dart';
import 'package:chiti/presentation/screens/add_edit_expense_screen.dart';
import 'package:chiti/providers/providers.dart';

class FakeAppRepository extends AppRepository {
  final List<Expense> expenses = [];
  ExpenseParticipant? _loadedParticipant;

  FakeAppRepository() {
    expenses.add(
      Expense(
        id: 'e1',
        tripId: 't1',
        title: 'Cơm trưa',
        amount: 300000,
        payerId: 'p1',
        category: 'dining',
        createdAt: DateTime(2026, 8, 2),
      ),
    );
    _loadedParticipant = ExpenseParticipant(
      id: 'j1',
      expenseId: 'e1',
      participantId: 'p2',
      shareAmount: 150000,
    );
  }

  @override
  Future<List<ExpenseParticipant>> getExpenseParticipants(String expenseId) async =>
      expenseId == 'e1' ? [_loadedParticipant!] : [];

  @override
  Future<Expense> createExpense({
    required String tripId,
    required String title,
    required double amount,
    required String payerId,
    required String category,
    required List<ExpenseParticipant> participants,
  }) async {
    final e = Expense(
      id: 'e2',
      tripId: tripId,
      title: title,
      amount: amount,
      payerId: payerId,
      category: category,
      createdAt: DateTime.now(),
    );
    expenses.add(e);
    return e;
  }

  @override
  Future<List<Expense>> getExpenses(String tripId) async =>
      expenses.where((e) => e.tripId == tripId).toList();

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
  Future<List<Settlement>> getSettlements(String tripId) async => [];

  @override
  Future<Trip?> getTrip(String id) async => Trip(
    id: id,
    name: 'Nhóm cầu lông',
    destination: '',
    currency: 'VND',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 1),
    createdAt: DateTime(2026),
    hostId: 'p1',
  );

  @override
  Future<void> replaceSettlements(
    String tripId,
    List<Settlement> settlements,
  ) async {}
}

void main() {
  Widget buildApp(FakeAppRepository repo, {required bool duplicate}) {
    return ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('vi'), Locale('en')],
        home: AddEditExpenseScreen(
          tripId: 't1',
          existing: repo.expenses.first,
          duplicate: duplicate,
        ),
      ),
    );
  }

  testWidgets('duplicate mode prefills fields and creates a new expense', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeAppRepository();
    await tester.pumpWidget(buildApp(repo, duplicate: true));
    await tester.pumpAndSettle();

    // Prefilled from the source expense (create-mode title, no edit delete).
    expect(find.text('Cơm trưa'), findsOneWidget);
    expect(find.text('300,000'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNothing);

    // Save: creates a brand-new expense row.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.expenses, hasLength(2));
    final dup = repo.expenses.last;
    expect(dup.id, isNot('e1'));
    expect(dup.title, 'Cơm trưa');
    expect(dup.amount, 300000);
    expect(dup.payerId, 'p1');
  });

  testWidgets('edit mode shows the delete action and keeps the same id', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeAppRepository();
    await tester.pumpWidget(buildApp(repo, duplicate: false));
    await tester.pumpAndSettle();

    expect(find.text('Edit Expense'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });
}