import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chiti/data/models/models.dart';
import 'package:chiti/data/repository.dart';
import 'package:chiti/l10n/app_localizations.dart';
import 'package:chiti/presentation/screens/add_trip_screen.dart';
import 'package:chiti/presentation/screens/trip_dashboard_screen.dart';
import 'package:chiti/providers/providers.dart';

/// In-memory fake repository so the create-group flow can run without sqflite.
class FakeAppRepository extends AppRepository {
  Trip? created;
  final List<Trip> trips = [];

  @override
  Future<Trip> createTrip({
    required String name,
    required String destination,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final trip = Trip(
      id: 't1',
      name: name,
      destination: destination,
      currency: currency,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
    );
    created = trip;
    trips.add(trip);
    return trip;
  }

  @override
  Future<List<Trip>> getAllTrips() async => List.of(trips);

  @override
  Future<Trip?> getTrip(String id) async =>
      trips.where((t) => t.id == id).firstOrNull;

  @override
  Future<List<Participant>> getParticipants(String tripId) async => [];

  @override
  Future<List<Sponsorship>> getSponsorships(String tripId) async => [];

  @override
  Future<Participant> addParticipant({
    required String tripId,
    required String name,
    required int color,
    String? contact,
    String? note,
  }) async => Participant(
    id: 'p1',
    tripId: tripId,
    name: name,
    color: color,
    createdAt: DateTime.now(),
  );
}

void main() {
  Widget buildApp(FakeAppRepository repo) {
    return ProviderScope(
      overrides: [repositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: [Locale('vi'), Locale('en')],
        home: TripDashboardScreen(),
      ),
    );
  }

  testWidgets('new group form defaults the currency to VND', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(FakeAppRepository()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: [Locale('vi'), Locale('en')],
          home: AddTripScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The currency dropdown shows VND as the initially selected value.
    expect(find.text('VND'), findsOneWidget);
    expect(find.text('USD'), findsNothing);
  });

  testWidgets('empty location saves without a validation error', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeAppRepository();
    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    // Open the create-group screen from the dashboard.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Fill in the name only; leave the location field empty.
    await tester.enterText(find.byType(TextFormField).first, 'Badminton Club');

    // Save and confirm the group is created without an error message.
    await tester.tap(find.widgetWithText(FilledButton, 'Create Group'));
    await tester.pumpAndSettle();

    expect(find.text('Badminton Club'), findsOneWidget);
    // No "Required" validation error is shown.
    expect(find.text('Required'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(repo.created, isNotNull);
  });

  testWidgets('location is persisted as an empty string when left blank', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final repo = FakeAppRepository();
    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Roomies');
    await tester.tap(find.widgetWithText(FilledButton, 'Create Group'));
    await tester.pumpAndSettle();

    expect(repo.created, isNotNull);
    expect(repo.created!.name, 'Roomies');
    expect(repo.created!.destination, '');
    expect(repo.created!.currency, 'VND');
  });
}