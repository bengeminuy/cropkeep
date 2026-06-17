import '../database.dart';

class SavingsBarnRepository {
  SavingsBarnRepository(this._db);

  final AppDatabase _db;

  Stream<SavingsBarnRow?> watch() {
    return (_db.select(_db.savingsBarn)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }
}
