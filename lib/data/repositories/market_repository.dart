import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/coin_ledger.dart';
import '../tables/cycles.dart';
import '../tables/owned_items.dart';

class InsufficientCoinsException implements Exception {
  const InsufficientCoinsException({required this.have, required this.need});
  final int have;
  final int need;
  @override
  String toString() =>
      'InsufficientCoinsException(have: $have, need: $need)';
}

class AlreadyOwnedException implements Exception {
  const AlreadyOwnedException(this.itemId);
  final String itemId;
  @override
  String toString() => 'AlreadyOwnedException(itemId: $itemId)';
}

class MarketRepository {
  MarketRepository(this._db);

  final AppDatabase _db;

  Stream<List<CropCatalogRow>> watchCropCatalog() {
    return (_db.select(_db.cropsCatalog)
          ..orderBy([
            (t) => OrderingTerm(expression: t.displayOrder),
            (t) => OrderingTerm(expression: t.cropId),
          ]))
        .watch();
  }

  Stream<List<OwnedItemRow>> watchOwned() {
    return _db.select(_db.ownedItems).watch();
  }

  // Crop catalog joined with the user's owned seed-pack stock. The plot
  // creation picker reads this to decide which tiles to surface: starters
  // always render with `stock: null`; consumable seed packs render with
  // the current quantity (0 means "Out of stock" — the tile still shows
  // so the user knows the crop exists, but selection bounces to the
  // Market hint per the spec).
  Stream<List<CropPickerEntry>> watchCropPicker() {
    final query = _db.select(_db.cropsCatalog).join([
      leftOuterJoin(
        _db.ownedItems,
        _db.ownedItems.itemId.equalsExp(_db.cropsCatalog.cropId),
      ),
    ])
      ..orderBy([
        OrderingTerm(expression: _db.cropsCatalog.displayOrder),
        OrderingTerm(expression: _db.cropsCatalog.cropId),
      ]);
    return query.watch().map((rows) {
      return rows.map((row) {
        final crop = row.readTable(_db.cropsCatalog);
        final owned = row.readTableOrNull(_db.ownedItems);
        return CropPickerEntry(
          crop: crop,
          stock: crop.isStarter ? null : (owned?.quantity ?? 0),
        );
      }).toList(growable: false);
    });
  }

  // Atomic purchase. Re-reads state inside the transaction so a stale
  // UI snapshot can't authorise an overdraft or double-buy.
  //
  // • `quantityDelta` — for crops: pack size (e.g. 5). For fertilizers:
  //   1. For decorations / avatars / plot colors: 1.
  // • `oneTime = true` rejects re-purchases of cosmetics with an
  //   AlreadyOwnedException.
  Future<void> purchase({
    required String itemId,
    required OwnedItemType itemType,
    required int priceCoins,
    required int quantityDelta,
    required String description,
    bool oneTime = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      final settings = await (_db.select(_db.appSettings)
            ..where((t) => t.id.equals(1)))
          .getSingle();
      if (settings.coinsBalance < priceCoins) {
        throw InsufficientCoinsException(
          have: settings.coinsBalance,
          need: priceCoins,
        );
      }

      if (oneTime) {
        final existingOwned = await (_db.select(_db.ownedItems)
              ..where((t) => t.itemId.equals(itemId)))
            .getSingleOrNull();
        if (existingOwned != null && existingOwned.quantity > 0) {
          throw AlreadyOwnedException(itemId);
        }
      }

      await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
        AppSettingsCompanion(
          coinsBalance: Value(settings.coinsBalance - priceCoins),
        ),
      );

      final activeCycle = await (_db.select(_db.cycles)
            ..where((t) => t.state.equalsValue(CycleState.active)))
          .getSingleOrNull();

      await _db.into(_db.coinLedger).insert(
            CoinLedgerCompanion.insert(
              cycleId: Value(activeCycle?.id),
              amount: -priceCoins,
              reason: CoinReason.marketPurchase,
              relatedType: const Value('owned_items'),
              description: Value(description),
              occurredAt: now,
            ),
          );

      // Increment-or-insert the owned_items row. Drift's
      // insertOnConflictUpdate would overwrite quantity instead of
      // adding to it, so we issue an UPSERT directly.
      //
      // Use customUpdate (not customStatement) so Drift invalidates
      // streams watching the owned_items table — customStatement is
      // documented to skip stream notification, which left the Market
      // "owned" chips and the Satchel page stuck on stale data until
      // the screen was rebuilt from scratch.
      await _db.customUpdate(
        'INSERT INTO owned_items (item_id, item_type, quantity, acquired_at) '
        'VALUES (?, ?, ?, ?) '
        'ON CONFLICT(item_id) DO UPDATE SET '
        'quantity = owned_items.quantity + excluded.quantity',
        variables: [
          Variable.withString(itemId),
          Variable.withString(_ownedItemTypeWire(itemType)),
          Variable.withInt(quantityDelta),
          Variable.withInt(now),
        ],
        updates: {_db.ownedItems},
      );
    });
  }
}

class CropPickerEntry {
  const CropPickerEntry({required this.crop, required this.stock});

  final CropCatalogRow crop;
  // null = starter (no inventory concept); 0+ = consumable seed pack count.
  final int? stock;
}

// Mirrors `SnakeEnumConverter`'s wire format used by the OwnedItems
// table's `itemType` column — drift's converter writes snake_case
// strings, and a raw INSERT has to match that exact encoding.
String _ownedItemTypeWire(OwnedItemType type) {
  switch (type) {
    case OwnedItemType.crop:
      return 'crop';
    case OwnedItemType.fertilizer:
      return 'fertilizer';
    case OwnedItemType.decoration:
      return 'decoration';
    case OwnedItemType.plotColor:
      return 'plot_color';
    case OwnedItemType.wellSkin:
      return 'well_skin';
    case OwnedItemType.barnSkin:
      return 'barn_skin';
    case OwnedItemType.avatar:
      return 'avatar';
  }
}
