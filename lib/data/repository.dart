import 'models/models.dart';
import '../core/id_generator.dart';
import 'database_helper.dart';

class AppRepository {
  final DatabaseHelper _helper = DatabaseHelper();

  // ---- Trips ----

  Future<List<Trip>> getAllTrips() async {
    final db = await _helper.database;
    final maps = await db.query('trips', orderBy: 'start_date DESC');
    return maps.map((m) => Trip.fromMap(m)).toList();
  }

  Future<Trip?> getTrip(String id) async {
    final db = await _helper.database;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Trip.fromMap(maps.first);
  }

  Future<Trip> createTrip({
    required String name,
    required String destination,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await _helper.database;
    final trip = Trip(
      id: generateId(),
      name: name,
      destination: destination,
      currency: currency,
      startDate: startDate,
      endDate: endDate,
      createdAt: DateTime.now(),
    );
    await db.insert('trips', trip.toMap());
    return trip;
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await _helper.database;
    await db.update(
      'trips',
      trip.toMap(),
      where: 'id = ?',
      whereArgs: [trip.id],
    );
  }

  Future<void> deleteTrip(String id) async {
    final db = await _helper.database;
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Participants ----

  Future<List<Participant>> getParticipants(String tripId) async {
    final db = await _helper.database;
    final maps = await db.query(
      'participants',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => Participant.fromMap(m)).toList();
  }

  Future<Participant> addParticipant({
    required String tripId,
    required String name,
    required int color,
    String? contact,
    String? note,
  }) async {
    final db = await _helper.database;
    final participant = Participant(
      id: generateId(),
      tripId: tripId,
      name: name,
      color: color,
      contact: contact,
      note: note,
      createdAt: DateTime.now(),
    );
    await db.insert('participants', participant.toMap());
    return participant;
  }

  Future<void> updateParticipant(Participant participant) async {
    final db = await _helper.database;
    await db.update(
      'participants',
      participant.toMap(),
      where: 'id = ?',
      whereArgs: [participant.id],
    );
  }

  Future<void> removeParticipant(String id) async {
    final db = await _helper.database;
    await db.delete('participants', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Expenses ----

  Future<List<Expense>> getExpenses(String tripId) async {
    final db = await _helper.database;
    final maps = await db.query(
      'expenses',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  /// Creates an expense together with its participating member rows in a
  /// single transaction.
  Future<Expense> createExpense({
    required String tripId,
    required String title,
    required double amount,
    required String payerId,
    required String category,
    required List<ExpenseParticipant> participants,
  }) async {
    final db = await _helper.database;
    final expense = Expense(
      id: generateId(),
      tripId: tripId,
      title: title,
      amount: amount,
      payerId: payerId,
      category: category,
      createdAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      await txn.insert('expenses', expense.toMap());

      final batch = txn.batch();
      for (final participant in participants) {
        batch.insert(
          'expense_participants',
          participant.copyWith(expenseId: expense.id).toMap(),
        );
      }
      await batch.commit(noResult: true);
    });

    return expense;
  }

  /// Updates an expense row and replaces its participating-member rows in a
  /// single transaction (child rows are recreated wholesale).
  Future<void> updateExpense({
    required Expense expense,
    required List<ExpenseParticipant> participants,
  }) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.update(
        'expenses',
        expense.toMap(),
        where: 'id = ?',
        whereArgs: [expense.id],
      );

      await txn.delete(
        'expense_participants',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );

      final batch = txn.batch();
      for (final participant in participants) {
        batch.insert(
          'expense_participants',
          participant.copyWith(expenseId: expense.id).toMap(),
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> deleteExpense(String id) async {
    final db = await _helper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Returns an expense together with its participating members, or null when
  /// the expense no longer exists.
  Future<ExpenseWithParticipants?> getExpenseDetails(String expenseId) async {
    final db = await _helper.database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [expenseId],
    );
    if (maps.isEmpty) return null;
    final expense = Expense.fromMap(maps.first);
    return ExpenseWithParticipants(
      expense: expense,
      participants: await getExpenseParticipants(expenseId),
    );
  }

  // ---- Expense participants ----

  Future<List<ExpenseParticipant>> getExpenseParticipants(
    String expenseId,
  ) async {
    final db = await _helper.database;
    final maps = await db.query(
      'expense_participants',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    return maps.map((m) => ExpenseParticipant.fromMap(m)).toList();
  }

  Future<List<ExpenseParticipant>> getParticipantsForTrip(String tripId) async {
    final db = await _helper.database;
    final maps = await db.rawQuery(
      '''
      SELECT ep.* FROM expense_participants ep
      INNER JOIN expenses e ON ep.expense_id = e.id
      WHERE e.trip_id = ?
    ''',
      [tripId],
    );
    return maps.map((m) => ExpenseParticipant.fromMap(m)).toList();
  }

  // ---- Settlements ----

  Future<List<Settlement>> getSettlements(String tripId) async {
    final db = await _helper.database;
    final maps = await db.query(
      'settlements',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => Settlement.fromMap(m)).toList();
  }

  /// Replaces every settlement row for a trip with [settlements].
  Future<void> replaceSettlements(
    String tripId,
    List<Settlement> settlements,
  ) async {
    final db = await _helper.database;
    await db.transaction((txn) async {
      await txn.delete(
        'settlements',
        where: 'trip_id = ?',
        whereArgs: [tripId],
      );
      final batch = txn.batch();
      for (final s in settlements) {
        batch.insert('settlements', s.toMap());
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> setSettlementPaid(String id, bool isPaid) async {
    final db = await _helper.database;
    await db.update(
      'settlements',
      {'is_paid': isPaid ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---- Sponsorships ----

  Future<List<Sponsorship>> getSponsorships(String tripId) async {
    final db = await _helper.database;
    final maps = await db.query(
      'sponsorships',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => Sponsorship.fromMap(m)).toList();
  }

  Future<Sponsorship> createSponsorship({
    required String tripId,
    required String sponsorName,
    String? memberId,
    required double amount,
    String? note,
  }) async {
    final db = await _helper.database;
    final sponsorship = Sponsorship(
      id: generateId(),
      tripId: tripId,
      sponsorName: sponsorName,
      memberId: memberId,
      amount: amount,
      note: note,
      createdAt: DateTime.now(),
    );
    await db.insert('sponsorships', sponsorship.toMap());
    return sponsorship;
  }

  Future<void> updateSponsorship(Sponsorship sponsorship) async {
    final db = await _helper.database;
    await db.update(
      'sponsorships',
      sponsorship.toMap(),
      where: 'id = ?',
      whereArgs: [sponsorship.id],
    );
  }

  Future<void> deleteSponsorship(String id) async {
    final db = await _helper.database;
    await db.delete('sponsorships', where: 'id = ?', whereArgs: [id]);
  }
}
