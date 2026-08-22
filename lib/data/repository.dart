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
      orderBy: 'date DESC, created_at DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  /// Creates an expense together with its payers and split rows in a single
  /// transaction.
  Future<Expense> createExpense({
    required String tripId,
    required String title,
    required double amount,
    required DateTime date,
    required String category,
    required String splitMode,
    required List<ExpensePayer> payers,
    required List<ExpenseSplit> splits,
  }) async {
    final db = await _helper.database;
    final expense = Expense(
      id: generateId(),
      tripId: tripId,
      title: title,
      amount: amount,
      date: date,
      category: category,
      splitMode: splitMode,
      createdAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      await txn.insert('expenses', expense.toMap());

      final payerBatch = txn.batch();
      for (final payer in payers) {
        payerBatch.insert(
          'expense_payers',
          payer.copyWith(expenseId: expense.id).toMap(),
        );
      }
      await payerBatch.commit(noResult: true);

      final splitBatch = txn.batch();
      for (final split in splits) {
        splitBatch.insert(
          'expense_splits',
          split.copyWith(expenseId: expense.id).toMap(),
        );
      }
      await splitBatch.commit(noResult: true);
    });

    return expense;
  }

  /// Updates an expense row and replaces its payer / split rows in a single
  /// transaction. Old child rows are deleted and re-inserted wholesale because
  /// they carry their own UUIDs and the clearest push-based refresh is to
  /// recreate them.
  Future<void> updateExpense({
    required Expense expense,
    required List<ExpensePayer> payers,
    required List<ExpenseSplit> splits,
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
        'expense_payers',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );
      await txn.delete(
        'expense_splits',
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );

      final payerBatch = txn.batch();
      for (final payer in payers) {
        payerBatch.insert(
          'expense_payers',
          payer.copyWith(expenseId: expense.id).toMap(),
        );
      }
      await payerBatch.commit(noResult: true);

      final splitBatch = txn.batch();
      for (final split in splits) {
        splitBatch.insert(
          'expense_splits',
          split.copyWith(expenseId: expense.id).toMap(),
        );
      }
      await splitBatch.commit(noResult: true);
    });
  }

  Future<void> deleteExpense(String id) async {
    final db = await _helper.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ---- Expense payers ----

  Future<List<ExpensePayer>> getExpensePayers(String expenseId) async {
    final db = await _helper.database;
    final maps = await db.query(
      'expense_payers',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    return maps.map((m) => ExpensePayer.fromMap(m)).toList();
  }

  Future<List<ExpensePayer>> getPayersForTrip(String tripId) async {
    final db = await _helper.database;
    final maps = await db.rawQuery(
      '''
      SELECT ep.* FROM expense_payers ep
      INNER JOIN expenses e ON ep.expense_id = e.id
      WHERE e.trip_id = ?
    ''',
      [tripId],
    );
    return maps.map((m) => ExpensePayer.fromMap(m)).toList();
  }

  // ---- Expense splits ----

  Future<List<ExpenseSplit>> getExpenseSplits(String expenseId) async {
    final db = await _helper.database;
    final maps = await db.query(
      'expense_splits',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    return maps.map((m) => ExpenseSplit.fromMap(m)).toList();
  }

  Future<List<ExpenseSplit>> getSplitsForTrip(String tripId) async {
    final db = await _helper.database;
    final maps = await db.rawQuery(
      '''
      SELECT es.* FROM expense_splits es
      INNER JOIN expenses e ON es.expense_id = e.id
      WHERE e.trip_id = ?
    ''',
      [tripId],
    );
    return maps.map((m) => ExpenseSplit.fromMap(m)).toList();
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
}
