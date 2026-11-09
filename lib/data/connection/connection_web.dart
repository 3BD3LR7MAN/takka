import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
// Read the old WebDatabase blob once so users keep existing browser data.
// ignore: deprecated_member_use
import 'package:drift/web.dart' show DriftWebStorage;

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'takka',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
      initializeDatabase: () async {
        final legacyStorage =
            await DriftWebStorage.indexedDbIfSupported('takka');
        await legacyStorage.open();
        try {
          return await legacyStorage.restore();
        } finally {
          await legacyStorage.close();
        }
      },
    );
    return result.resolvedExecutor;
  });
}
