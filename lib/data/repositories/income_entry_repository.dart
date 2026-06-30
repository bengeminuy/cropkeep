import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/wells.dart' show WellType;

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

  // wellId → logged base minor for every well with at least one
  // non-deleted income entry this cycle. Wells with zero entries are
  // absent from the map (caller treats missing as 0).
  Stream<Map<int, int>> watchLoggedByWellAndCycle(int cycleId) {
    final sum = _db.incomeEntries.baseAmount.sum();
    final query = _db.selectOnly(_db.incomeEntries)
      ..addColumns([_db.incomeEntries.wellId, sum])
      ..where(_db.incomeEntries.cycleId.equals(cycleId) &
          _db.incomeEntries.deletedAt.isNull())
      ..groupBy([_db.incomeEntries.wellId]);
    return query.watch().map((rows) {
      return {
        for (final row in rows)
          row.read(_db.incomeEntries.wellId)!: row.read(sum) ?? 0,
      };
    });
  }

  Stream<List<IncomeEntryRow>> watchRecentlyDeleted({
    Duration window = const Duration(days: 30),
  }) {
    final cutoff = DateTime.now().subtract(window).millisecondsSinceEpoch;
    return (_db.select(_db.incomeEntries)
          ..where((t) => t.deletedAt.isNotNull() & t.deletedAt.isBiggerThanValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .watch();
  }

  // Sum of every bonus income entry's base_amount this cycle. Reservoir
  // math on the Wells subpage's bonus headline reads this against the
  // bonus allocation total to know what's actually "free" in the pool.
  Stream<int> watchBonusLoggedMinor(int cycleId) {
    final sum = _db.incomeEntries.baseAmount.sum();
    final joined = _db.selectOnly(_db.incomeEntries).join([
      innerJoin(
        _db.wells,
        _db.wells.id.equalsExp(_db.incomeEntries.wellId),
      ),
    ])
      ..addColumns([sum])
      ..where(_db.incomeEntries.cycleId.equals(cycleId) &
          _db.incomeEntries.deletedAt.isNull() &
          _db.wells.wellType.equalsValue(WellType.bonus));
    return joined.watchSingle().map((row) => row.read(sum) ?? 0);
  }
}
