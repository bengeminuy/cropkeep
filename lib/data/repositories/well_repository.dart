import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/wells.dart';

class WellRepository {
  WellRepository(this._db);

  final AppDatabase _db;

  // is_carryover DESC then created_at ASC so the system-managed Carryover
  // pins to the top of the Bonus section, with user-created wells beneath
  // it in the order the user added them.
  Stream<List<WellRow>> watchActiveWells({WellType? type}) {
    final query = _db.select(_db.wells)
      ..where((t) => t.isActive.equals(true))
      ..orderBy([
        (t) => OrderingTerm.desc(t.isCarryover),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    if (type != null) {
      query.where((t) => t.wellType.equalsValue(type));
    }
    return query.watch();
  }

  Future<int> create({
    required String name,
    required WellType wellType,
    required String currencyCode,
    int? expectedAmount,
    int? estimateMin,
    int? estimateMax,
    String? iconId,
    DateTime? createdAt,
  }) {
    final now = (createdAt ?? DateTime.now()).millisecondsSinceEpoch;
    return _db.into(_db.wells).insert(
          WellsCompanion.insert(
            name: name,
            wellType: wellType,
            currencyCode: currencyCode,
            expectedAmount: Value(expectedAmount),
            estimateMin: Value(estimateMin),
            estimateMax: Value(estimateMax),
            wellIconId: iconId == null ? const Value.absent() : Value(iconId),
            createdAt: now,
          ),
        );
  }

  Future<int> archive(int id, {DateTime? at}) {
    return (_db.update(_db.wells)..where((t) => t.id.equals(id))).write(
      const WellsCompanion(isActive: Value(false)),
    );
  }
}
