import 'package:drift/drift.dart';

import '../database.dart';

class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;

  Future<int> logExpense({
    required int plotId,
    required int cycleId,
    required int amountMinor,
    required String currencyCode,
    required int baseAmountMinor,
    required int plotAmountMinor,
    required double exchangeRate,
    required DateTime spentAt,
    String? note,
    bool isEmergency = false,
    DateTime? createdAt,
  }) {
    final now = createdAt ?? DateTime.now();
    return _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            plotId: plotId,
            cycleId: cycleId,
            amount: amountMinor,
            currencyCode: currencyCode,
            baseAmount: baseAmountMinor,
            plotAmount: plotAmountMinor,
            exchangeRate: exchangeRate,
            spentAt: spentAt.millisecondsSinceEpoch,
            note: Value(note),
            isEmergency: Value(isEmergency),
            createdAt: now.millisecondsSinceEpoch,
          ),
        );
  }

  Future<int> editExpense({
    required int id,
    int? amountMinor,
    int? baseAmountMinor,
    int? plotAmountMinor,
    String? note,
    DateTime? spentAt,
    DateTime? editedAt,
  }) {
    final companion = TransactionsCompanion(
      amount: amountMinor != null ? Value(amountMinor) : const Value.absent(),
      baseAmount: baseAmountMinor != null
          ? Value(baseAmountMinor)
          : const Value.absent(),
      plotAmount: plotAmountMinor != null
          ? Value(plotAmountMinor)
          : const Value.absent(),
      note: note != null ? Value(note) : const Value.absent(),
      spentAt:
          spentAt != null ? Value(spentAt.millisecondsSinceEpoch) : const Value.absent(),
      editedAt: Value((editedAt ?? DateTime.now()).millisecondsSinceEpoch),
    );
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<int> softDelete(int id, {DateTime? at}) {
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: Value((at ?? DateTime.now()).millisecondsSinceEpoch),
      ),
    );
  }

  Future<int> restore(int id) {
    return (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      const TransactionsCompanion(deletedAt: Value(null)),
    );
  }

  Stream<List<TransactionRow>> watchByCycle(int cycleId) {
    return (_db.select(_db.transactions)
          ..where((t) => t.cycleId.equals(cycleId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]))
        .watch();
  }

  Stream<List<TransactionRow>> watchByPlot({
    required int plotId,
    required int cycleId,
  }) {
    return (_db.select(_db.transactions)
          ..where((t) =>
              t.plotId.equals(plotId) &
              t.cycleId.equals(cycleId) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.spentAt)]))
        .watch();
  }

  Stream<int> watchPlotSpentMinor({
    required int plotId,
    required int cycleId,
  }) {
    final sum = _db.transactions.baseAmount.sum();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([sum])
      ..where(_db.transactions.plotId.equals(plotId) &
          _db.transactions.cycleId.equals(cycleId) &
          _db.transactions.deletedAt.isNull());
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  // plotId → spent base minor for every plot with at least one
  // non-deleted transaction this cycle. Plots with zero transactions
  // are absent from the map (the caller should treat missing as 0).
  Stream<Map<int, int>> watchPlotSpentByCycle(int cycleId) {
    final sum = _db.transactions.baseAmount.sum();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([_db.transactions.plotId, sum])
      ..where(_db.transactions.cycleId.equals(cycleId) &
          _db.transactions.deletedAt.isNull())
      ..groupBy([_db.transactions.plotId]);
    return query.watch().map((rows) {
      return {
        for (final row in rows)
          row.read(_db.transactions.plotId)!: row.read(sum) ?? 0,
      };
    });
  }

  Stream<List<TransactionRow>> watchRecentlyDeleted({
    Duration window = const Duration(days: 30),
  }) {
    final cutoff = DateTime.now().subtract(window).millisecondsSinceEpoch;
    return (_db.select(_db.transactions)
          ..where((t) => t.deletedAt.isNotNull() & t.deletedAt.isBiggerThanValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .watch();
  }
}
