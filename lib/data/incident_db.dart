import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/incident.dart';

/// Local SQLite storage for incidents (create, read, update, delete).
///
/// Every query uses placeholders ("?") with whereArgs, so user input is
/// sent to SQLite as data and is never part of the SQL text. This is the
/// fix for the SQL injection finding in Section 8 of the Passport.
class IncidentDb {
  IncidentDb({DatabaseFactory? factory, String? path})
      : _factory = factory ?? databaseFactory,
        _path = path;

  final DatabaseFactory _factory;
  final String? _path;
  Database? _db;

  static const table = 'incidents';

  Future<Database> get db async {
    if (_db != null) return _db!;
    final path = _path ?? p.join(await _factory.getDatabasesPath(), 'safelog.db');
    _db = await _factory.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 1, onCreate: _create),
    );
    return _db!;
  }

  static Future<void> _create(Database db, int version) async {
    // CHECK constraints repeat the app's validation inside the database,
    // so bad data is refused even if a code path skips the form.
    await db.execute('''
      CREATE TABLE $table (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        title       TEXT NOT NULL CHECK (length(title) BETWEEN 3 AND 60),
        description TEXT NOT NULL DEFAULT '' CHECK (length(description) <= 500),
        severity    TEXT NOT NULL CHECK (severity IN ('Low','Medium','High','Critical')),
        date        TEXT NOT NULL,
        status      TEXT NOT NULL DEFAULT 'Open' CHECK (status IN ('Open','Closed'))
      )
    ''');
  }

  // Create
  Future<int> insert(Incident incident) async =>
      (await db).insert(table, incident.toMap()..remove('id'));

  // Read
  Future<List<Incident>> all() async {
    final rows = await (await db).query(table, orderBy: 'date DESC, id DESC');
    return rows.map(Incident.fromMap).toList();
  }

  Future<List<Incident>> search(String text) async {
    final rows = await (await db).query(table,
        where: 'title LIKE ?',
        whereArgs: ['%$text%'],
        orderBy: 'date DESC, id DESC');
    return rows.map(Incident.fromMap).toList();
  }

  // Update
  Future<int> update(Incident incident) async => (await db).update(
        table,
        incident.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [incident.id],
      );

  // Delete
  Future<int> delete(int id) async =>
      (await db).delete(table, where: 'id = ?', whereArgs: [id]);

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
