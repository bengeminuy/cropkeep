import 'package:drift/drift.dart';

import '../database.dart';

class IncomeEntryRepository {
  IncomeEntryRepository(this._db);

  final AppDatabase _db;

  Future<int> logIncome({
    required int wellId,
    required int cycleId,
    required int amountMinor,
    required String currencyCode,
    required int baseAmountMinor,
    required double exchangeRate,
    required DateTime receivedAt,
    String? note,
    bool isSystemGenerated = false,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return _db.into(_db.incomeEntries).insert(
          IncomeEntriesCompanion.insert(
            wellId: wellId,
            cycleId: cycleId,
            amount: amountMinor,
            currencyCode: currencyCode,
            baseAmount: baseAmountMinor,
            exchangeRate: exchangeRate,
            receivedAt: receivedAt.millisecondsSinceEpoch,
            note: Value(note),
            isSystemGenerated: Value(isSystemGenerated),
            createdAt: now.millisecondsSinceEpoch,
          ),
        );
  }

  Future<int> editIncome({
    required int id,
    int? amountMinor,
    int? baseAmountMinor,
    String? note,
    DateTime? receivedAt,
    DateTime? editedAt,
  }) {
    final companion = IncomeEntriesCompanion(
      amount: amountMinor != null ? Value(amountMinor) : const Value.absent(),
      baseAmount: baseAmountMinor != null
          ? Value(baseAmountMinor)
          : const Value.absent(),
      note: note != null ? Value(note) : const Value.absent(),
      receivedAt: receivedAt != null
          ? Value(receivedAt.millisecondsSinceEpoch)
          : const Value.absent(),
      editedAt: Value((editedAt ?? DateTime.now()).millisecondsSinceEpoch),
    );
    return (_db.update(_db.incomeEntries)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<int> softDelete(int id, {DateTime? at}) {
    return (_db.update(_db.incomeEntries)..where((t) => t.id.equals(id))).write(
      IncomeEntriesCompanion(
        deletedAt: Value((at ?? DateTime.now()).millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> restore(int id) {
    return (_db.update(_db.incomeEntries)..where((t) => t.id.equals(id))).write(
      const IncomeEntriesCompanion(deletedAt: Value(null)),
    );
  }

  Stream<List<IncomeEntryRow>> watchByCycle(int cycleId) {
    return (_db.select(_db.incomeEntries)
          ..where((t) => t.cycleId.equals(cycleId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .watch();
  }

  Stream<List<IncomeEntryRow>> watchByWell({
    required int wellId,
    required int cycleId,
  }) {
    return (_db.select(_db.incomeEntries)
          ..where((t) =>
              t.wellId.equals(wellId) &
              t.cycleId.equals(cycleId) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .watch();
  }

  Stream<int> watchWellLoggedMinor({
    required int wellId,
    required int cycleId,
  }) {
    final sum = _db.incomeEntries.baseAmount.sum();
    final query = _db.selectOnly(_db.incomeEntries)
      ..addColumns([sum])
      ..where(_db.incomeEntries.wellId.equals(wellId) &
          _db.incomeEntries.cycleId.equals(cycleId) &
          _db.incomeEntries.deletedAt.isNull());
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }
}
