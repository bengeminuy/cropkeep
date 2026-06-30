import 'package:drift/drift.dart';

import '../database.dart';

class OutOfFertilizerStockException implements Exception {
  const OutOfFertilizerStockException(this.fertilizerItemId);
  final String fertilizerItemId;
  @override
  String toString() =>
      'OutOfFertilizerStockException(itemId: $fertilizerItemId)';
}

// Writes against `plot_fertilizer_applications` and the `owned_items`
// stock for fertilizer packs. Mid-cycle application is the primary
// path; cycle-reset application is staged in memory by the cycle
// transition screen and committed inside `CycleRepository.closeAndStartNext`,
// so this repo doesn't need a "stage" surface.
//
// Policy:
//  • One fertilizer per plot per cycle. UNIQUE(cycle_id, plot_id) is
//    enforced at the DB level; the repo also reads the existing row
//    before writing so the old pack is forfeited (no refund) when the
//    user swaps mid-cycle.
//  • `removeFromPlot` deletes the application row without refunding the
//    owned_items quantity. Consistent with the satchel rule: a pack
//    you apply is gone, no take-backs.
//  • All writes use `customUpdate` (not `customStatement`) so streams
//    watching the affected tables invalidate — same lesson as
//    MarketRepository.purchase. customStatement skips notification
//    and leaves the breakdown / satchel views on stale data.
class FertilizerRepository {
  FertilizerRepository(this._db);

  final AppDatabase _db;

  // Watches every fertilizer application for the given cycle. The
  // Crops subpage uses this to paint the small per-plot indicator —
  // one stream per page, then a per-plot lookup by plotId.
  Stream<List<PlotFertilizerApplicationRow>> watchByCycle(int cycleId) {
    return (_db.select(_db.plotFertilizerApplications)
          ..where((t) => t.cycleId.equals(cycleId)))
        .watch();
  }

  // Single-row watch for the plot breakdown screen. Emits null when no
  // fertilizer is applied to the plot this cycle.
  Stream<PlotFertilizerApplicationRow?> watchByPlotAndCycle({
    required int cycleId,
    required int plotId,
  }) {
    return (_db.select(_db.plotFertilizerApplications)
          ..where((t) =>
              t.cycleId.equals(cycleId) & t.plotId.equals(plotId)))
        .watchSingleOrNull();
  }

  // Applies a fertilizer to one plot for the given cycle. If a different
  // fertilizer is already applied to the plot this cycle, the existing
  // row is replaced (old pack forfeited — no refund). If the same
  // fertilizer is already applied, the call is a no-op rather than
  // burning a second pack.
  //
  // Throws OutOfFertilizerStockException when the user owns zero of
  // the requested pack. The sheet pre-filters quantity > 0, so this
  // path only fires on a race (purchase elsewhere or a stale UI).
  Future<void> applyToPlot({
    required int cycleId,
    required int plotId,
    required String fertilizerItemId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      // Same-fertilizer reapply is a no-op. Avoids charging a second
      // pack when the user taps the already-applied row from the sheet
      // (it's filtered out of the list, but the apply-during-edit
      // path can still reach it via a stale UI).
      final existing = await (_db.select(_db.plotFertilizerApplications)
            ..where((t) =>
                t.cycleId.equals(cycleId) & t.plotId.equals(plotId)))
          .getSingleOrNull();
      if (existing != null &&
          existing.fertilizerItemId == fertilizerItemId) {
        return;
      }

      // Verify the user owns at least one pack of the requested item.
      final owned = await (_db.select(_db.ownedItems)
            ..where((t) => t.itemId.equals(fertilizerItemId)))
          .getSingleOrNull();
      if (owned == null || owned.quantity < 1) {
        throw OutOfFertilizerStockException(fertilizerItemId);
      }

      // Decrement stock. customUpdate keeps stream invalidation in
      // sync with the change.
      await _db.customUpdate(
        'UPDATE owned_items SET quantity = quantity - 1 '
        'WHERE item_id = ?',
        variables: [Variable.withString(fertilizerItemId)],
        updates: {_db.ownedItems},
      );

      if (existing != null) {
        // Replace the previous application — old pack already
        // forfeited (its stock was decremented when it was applied,
        // not refunded here). Plain update is fine since the row id
        // doesn't change.
        await (_db.update(_db.plotFertilizerApplications)
              ..where((t) => t.id.equals(existing.id)))
            .write(PlotFertilizerApplicationsCompanion(
          fertilizerItemId: Value(fertilizerItemId),
          appliedAt: Value(now),
        ));
      } else {
        await _db.into(_db.plotFertilizerApplications).insert(
              PlotFertilizerApplicationsCompanion.insert(
                cycleId: cycleId,
                plotId: plotId,
                fertilizerItemId: fertilizerItemId,
                appliedAt: now,
              ),
            );
      }
    });
  }

  // Removes any fertilizer application from this plot for the cycle.
  // No refund: the pack was consumed when it was applied; choosing to
  // remove it doesn't bring it back. Matches the project memory rule
  // "Transactions can be edited and soft-deleted, never silently
  // erased" — the application is hard-deleted because the cycle is
  // still active and the row carries no historical meaning until
  // cycle close.
  Future<void> removeFromPlot({
    required int cycleId,
    required int plotId,
  }) async {
    await (_db.delete(_db.plotFertilizerApplications)
          ..where((t) =>
              t.cycleId.equals(cycleId) & t.plotId.equals(plotId)))
        .go();
  }
}
