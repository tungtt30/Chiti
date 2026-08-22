import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const int _dbVersion = 4;
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chiti.db');

    return await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        // Enforce FOREIGN KEY constraints (off by default in SQLite).
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createSchema(db);
  }

  /// v3 -> v4 adds the additive `category` column to expenses (no data loss).
  /// Older versions (v2) are rebuilt wholesale by _dropSchema + _createSchema.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await _dropSchema(db);
      await _createSchema(db);
    } else if (oldVersion == 3) {
      final columns =
          await db.rawQuery('PRAGMA table_info(expenses)');
      final hasCategory = columns.any((c) => c['name'] == 'category');
      if (!hasCategory) {
        await db.execute(
          "ALTER TABLE expenses ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'",
        );
      }
    }
  }

  Future<void> _dropSchema(Database db) async {
    // Drop referencing tables before their parents, otherwise the legacy v2
    // child tables (expense_payers/expense_splits) break FK resolution when a
    // parent (expenses/participants) is dropped with PRAGMA foreign_keys = ON.
    await db.execute('DROP TABLE IF EXISTS settlements');
    await db.execute('DROP TABLE IF EXISTS expense_payers');
    await db.execute('DROP TABLE IF EXISTS expense_splits');
    await db.execute('DROP TABLE IF EXISTS expense_participants');
    await db.execute('DROP TABLE IF EXISTS expenses');
    await db.execute('DROP TABLE IF EXISTS participants');
    await db.execute('DROP TABLE IF EXISTS trips');
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        destination TEXT NOT NULL,
        currency TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE participants (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        name TEXT NOT NULL,
        color INTEGER NOT NULL DEFAULT 4294127219,
        contact TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        payer_id TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Other',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
        FOREIGN KEY (payer_id) REFERENCES participants(id) ON DELETE CASCADE
      )
    ''');

    // Junction table: one row per participant who joins this expense, with the
    // exact share they owe. Non-selected members have no row -> zero debt.
    await db.execute('''
      CREATE TABLE expense_participants (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        participant_id TEXT NOT NULL,
        share_amount REAL NOT NULL,
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
        FOREIGN KEY (participant_id) REFERENCES participants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE settlements (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        from_participant_id TEXT NOT NULL,
        to_participant_id TEXT NOT NULL,
        amount REAL NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE,
        FOREIGN KEY (from_participant_id) REFERENCES participants(id) ON DELETE CASCADE,
        FOREIGN KEY (to_participant_id) REFERENCES participants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_participants_trip ON participants(trip_id)',
    );
    await db.execute('CREATE INDEX idx_expenses_trip ON expenses(trip_id)');
    await db.execute(
      'CREATE INDEX idx_expenses_payer ON expenses(payer_id)',
    );
    await db.execute(
      'CREATE INDEX idx_expense_participants_expense '
      'ON expense_participants(expense_id)',
    );
    await db.execute(
      'CREATE INDEX idx_settlements_trip ON settlements(trip_id)',
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
