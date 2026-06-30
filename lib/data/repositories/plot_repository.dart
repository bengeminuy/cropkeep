import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/plots.dart';

// Thrown from create/update when a consumable seed is required but the
// matching `owned_items.quantity` is 0 (or no row exists). The picker
// gates this case ahead of time, but the repository re-checks inside the
// transaction so a stale UI snapshot can't authorise a free seed.
class OutOfSeedException implements Exception {
  const OutOfSeedException(this.cropId);
  final String cropId;
  @override
  String toString() => 'OutOfSeedException(cropId: $cropId)';
}

class PlotRepository {
  PlotRepository(this._db);

  final AppDatabase _db;

  // Unplanned first, then created_at ASC. Matches the order the Crops grid
  // expects: the wild patch always pins to the top, everything else lines
  // up in creation order so the user's mental model of their farm is
  // stable across sessions.
  Stream<List<PlotRow>> watchActivePlots() {
    return (_db.select(_db.plots)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm.desc(t.isUnplanned),
            (t) => OrderingTerm(expression: t.createdAt),
          ]))
        .watch();
  }

  Stream<PlotRow?> watchById(int id) {
    return (_db.select(_db.plots)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  // One-shot read of a plot row by id. Use when you need the current
  // value once (e.g. building a swap or edit request) and don't want to
  // subscribe to a stream you'll have to manage.
  Future<PlotRow?> readById(int id) {
    return (_db.select(_db.plots)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // Wraps insert + (consumable) seed deduction in one transaction so the
  // picker's stock check can't be defeated by a race. See md/database.md
  // §"Permanent vs consumable" for the two consumption points (here, plus
  // cycle start).
  Future<int> create({
    required String name,
    required PlotKind kind,
    required int budgetAmountMinor,
    required String currencyCode,
    required String cropTypeId,
    String? colorId,
    int? dueDay,
    DateTime? createdAt,
  }) {
    final now = (createdAt ?? DateTime.now()).millisecondsSinceEpoch;
    return _db.transaction(() async {
      await _consumeSeedIfConsumable(cropTypeId);
      return _db.into(_db.plots).insert(
            PlotsCompanion.insert(
              name: name,
              kind: Value(kind),
              budgetAmount: Value(budgetAmountMinor),
              currencyCode: currencyCode,
              cropTypeId: cropTypeId,
              plotColorId: Value(colorId),
              dueDay: Value(dueDay),
              createdAt: now,
            ),
          );
    });
  }

  // Full-row update. Callers send every value back even for fields the UI
  // had locked — locked fields just re-supply the existing value, which
  // keeps this method dumb about which fields are gated (the gate lives
  // in the screen). plot_color_id stays nullable; due_day is null when
  // the kind doesn't carry one.
  //
  // Crop-type changes follow the same consumption rule as create: if the
  // user switches a plot's crop to a different consumable mid-cycle, that
  // counts as planting a fresh seed and decrements stock. The old crop is
  // never refunded.
  Future<int> update({
    required int id,
    required String name,
    required PlotKind kind,
    required int budgetAmountMinor,
    required String currencyCode,
    required String cropTypeId,
    String? colorId,
    int? dueDay,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.plots)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (existing != null && existing.cropTypeId != cropTypeId) {
        await _consumeSeedIfConsumable(cropTypeId);
      }
      return (_db.update(_db.plots)..where((t) => t.id.equals(id))).write(
        PlotsCompanion(
          name: Value(name),
          kind: Value(kind),
          budgetAmount: Value(budgetAmountMinor),
          currencyCode: Value(currencyCode),
          cropTypeId: Value(cropTypeId),
          plotColorId: Value(colorId),
          dueDay: Value(dueDay),
        ),
      );
    });
  }

  // Soft-removal — flips `is_active = false` and nothing else. Intentional:
  // no seed refund. Seeds are consumed at plant time (create + cycle start),
  // not reserved, so removing a plot mid-cycle cannot return its seed to
  // inventory. See memory/project_seed_consumption.md.
  Future<int> archive(int id, {DateTime? at}) {
    return (_db.update(_db.plots)..where((t) => t.id.equals(id))).write(
      const PlotsCompanion(isActive: Value(false)),
    );
  }

  // Looks up the crop's catalog row to learn whether it's consumable; if
  // so, decrements its `owned_items.quantity` by 1. Starters and
  // never-purchased crops (no `owned_items` row at all) are guarded by
  // the picker upstream — defensive throw here for the race window.
  //
  // Uses Drift's typed update() so stream watchers of owned_items (Market
  // chips, Satchel) repaint without needing customUpdate.
  Future<void> _consumeSeedIfConsumable(String cropTypeId) async {
    final crop = await (_db.select(_db.cropsCatalog)
          ..where((t) => t.cropId.equals(cropTypeId)))
        .getSingleOrNull();
    if (crop == null || !crop.isConsumable) return;
    final owned = await (_db.select(_db.ownedItems)
          ..where((t) => t.itemId.equals(cropTypeId)))
        .getSingleOrNull();
    if (owned == null || owned.quantity < 1) {
      throw OutOfSeedException(cropTypeId);
    }
    await (_db.update(_db.ownedItems)..where((t) => t.id.equals(owned.id)))
        .write(OwnedItemsCompanion(quantity: Value(owned.quantity - 1)));
  }
}
