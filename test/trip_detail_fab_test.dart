import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chiti/data/models/models.dart';
import 'package:chiti/data/repository.dart';
import 'package:chiti/l10n/app_localizations.dart';
import 'package:chiti/presentation/screens/trip_detail_screen.dart';
import 'package:chiti/providers/providers.dart';

/// In-memory fake repository so the trip detail screen can be pumped without
/// sqflite. Widget tests default to the en_US platform locale, so English
/// strings are asserted.
class FakeAppRepository extends AppRepository {
  final Trip trip;
  final List<Participant> participants;

  FakeAppRepository(this.trip, {this.participants = const []});

  @override
  Future<Trip?> getTrip(String id) async => trip;

  @override
  Future<List<Participant>> getParticipants(String tripId) async =>
      participants;

  @override
  Future<Participant> addParticipant({
    required String tripId,
    required String name,
    required int color,
    String? contact,
    String? note,
  }) async {
    return Participant(
      id: 'new',
      tripId: tripId,
      name: name,
      color: color,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<List<Expense>> getExpenses(String tripId) async => [];

  @override
  Future<List<ExpenseParticipant>> getParticipantsForTrip(String tripId) async =>
      [];

  @override
  Future<List<Settlement>> getSettlements(String tripId) async => [];

  @override
  Future<List<Sponsorship>> getSponsorships(String tripId) async => [];
}

Future<void> _settle(WidgetTester tester) async {
  // Clipboard.setData needs the platform channel mocked, otherwise the
  // await never resolves inside the widget-test binary messenger.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
}

void main() {
  final trip = Trip(
    id: 'trip-1',
    name: 'Phố Cổ',
    destination: 'Hà Nội',
    currency: 'VND',
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 5),
    createdAt: DateTime(2026, 8, 1),
  );

  Widget buildApp({List<Participant> participants = const []}) {
    return ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(
          FakeAppRepository(trip, participants: participants),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: [Locale('vi'), Locale('en')],
        home: TripDetailScreen(tripId: 'trip-1'),
      ),
    );
  }

  testWidgets('expenses tab shows the add-expense FAB', (tester) async {
    await _settle(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fab_expense')), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Add Expense'),
        findsOneWidget);
    expect(find.descendant(
      of: find.byKey(const ValueKey('fab_expense')),
      matching: find.byIcon(Icons.receipt_long),
    ), findsOneWidget);

    // Exactly one FAB is visible at a time.
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('members tab shows the add-member FAB', (tester) async {
    final alice = Participant(
      id: 'p1',
      tripId: 'trip-1',
      name: 'Alice',
      color: 0xFF64B5F6,
      createdAt: DateTime(2026, 8, 1),
    );
    await tester.pumpWidget(buildApp(participants: [alice]));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Members & Notes'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fab_member')), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Add Member'),
        findsOneWidget);
    expect(find.byIcon(Icons.person_add), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tapping the FAB opens the participant dialog.
    await tester.tap(find.byKey(const ValueKey('fab_member')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);

    // Dismiss.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('summary tab shows the share FAB and copies the report',
      (tester) async {
    await _settle(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Summary'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fab_summary')), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Share Summary'),
        findsOneWidget);
    expect(find.byIcon(Icons.share), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fab_summary')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Group report copied'), findsOneWidget);
  });

  testWidgets('tab switching animates exactly one FAB at a time',
      (tester) async {
    await _settle(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Swipe twice to reach the Summary tab so the listener path is exercised.
    await tester.drag(find.byType(TabBarView), const Offset(-800, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(TabBarView), const Offset(-800, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fab_summary')), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}