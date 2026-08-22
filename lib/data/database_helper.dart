import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const int _dbVersion = 2;
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

  /// v1 -> v2 rebuilds the schema. This app targets a fresh offline-first
  /// install; for dev releases we recreate the tables on upgrade.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _dropSchema(db);
      await _createSchema(db);
    }
  }

  Future<void> _dropSchema(Database db) async {
    await db.execute('DROP TABLE IF EXISTS settlements');
    await db.execute('DROP TABLE IF EXISTS expense_payers');
    await db.execute('DROP TABLE IF EXISTS expense_splits');
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
        date INTEGER NOT NULL,
        category TEXT NOT NULL,
        split_mode TEXT NOT NULL DEFAULT 'equal',
        created_at INTEGER NOT NULL,
        FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_payers (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        participant_id TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (expense_id) REFERENCES expenses(id) ON DELETE CASCADE,
        FOREIGN KEY (participant_id) REFERENCES participants(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_splits (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL,
        participant_id TEXT NOT NULL,
        amount REAL NOT NULL,
        weight REAL,
        note TEXT,
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
      'CREATE INDEX idx_expense_payers_expense ON expense_payers(expense_id)',
    );
    await db.execute(
      'CREATE INDEX idx_expense_splits_expense ON expense_splits(expense_id)',
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
