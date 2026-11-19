import 'package:flutter_test/flutter_test.dart';
import 'package:safelog/data/incident_db.dart';
import 'package:safelog/models/incident.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Runs the real SQLite code on the desktop (via sqflite_common_ffi) so the
/// CRUD and SQL injection tests can run with `flutter test`.
void main() {
  sqfliteFfiInit();
  late IncidentDb store;

  setUp(() {
    store = IncidentDb(factory: databaseFactoryFfi, path: inMemoryDatabasePath);
  });

  tearDown(() => store.close());

  Incident sample(String title) => Incident(
        title: title,
        severity: 'High',
        date: DateTime(2026, 11, 1),
      );

  test('create, read, update and delete', () async {
    final id = await store.insert(sample('Phishing email'));
    var all = await store.all();
    expect(all, hasLength(1));
    expect(all.first.title, 'Phishing email');

    await store.update(all.first.copyWith(status: 'Closed'));
    all = await store.all();
    expect(all.first.status, 'Closed');

    await store.delete(id);
    expect(await store.all(), isEmpty);
  });

  test("search treats ' OR 1=1 -- as plain text", () async {
    await store.insert(sample('Phishing email'));
    await store.insert(sample('Lost laptop'));

    expect(await store.search("' OR 1=1 --"), isEmpty);
    expect(await store.search('laptop'), hasLength(1));
  });

  test('database refuses invalid severity even without the form', () async {
    final bad = Incident(title: 'Test item', severity: 'Urgent', date: DateTime(2026));
    await expectLater(store.insert(bad), throwsA(isA<DatabaseException>()));
  });
}
