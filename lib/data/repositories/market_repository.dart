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

class PackCapException implements Exception {
  const PackCapException({required this.itemId, required this.cap});
  final String itemId;
  final int cap;
  @override
  String toString() =>
      'PackCapException(itemId: $itemId, cap: $cap)';
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

  // Atomic purchase. Re-reads state inside the transaction so a stale
  // UI snapshot can't authorise an overdraft, double-buy, or
  // cap-exceeding restock.
  //
  // • `quantityDelta` — for crops: pack size (e.g. 5). For fertilizers:
  //   1. For decorations / avatars / plot colors: 1.
  // • `oneTime = true` rejects re-purchases of cosmetics with an
  //   AlreadyOwnedException.
  // • `inventoryCap` — non-null only for crops. Rejects buys that would
  //   push the seed stock above the pack max from shop.md.
  Future<void> purchase({
    required String itemId,
    required OwnedItemType itemType,
    required int priceCoins,
    required int quantityDelta,
    required String description,
    bool oneTime = false,
    int? inventoryCap,
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

      final existingOwned = await (_db.select(_db.ownedItems)
            ..where((t) => t.itemId.equals(itemId)))
          .getSingleOrNull();
      if (oneTime && existingOwned != null && existingOwned.quantity > 0) {
        throw AlreadyOwnedException(itemId);
      }
      if (inventoryCap != null) {
        final current = existingOwned?.quantity ?? 0;
        if (current + quantityDelta > inventoryCap) {
          throw PackCapException(itemId: itemId, cap: inventoryCap);
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
      await _db.customStatement(
        'INSERT INTO owned_items (item_id, item_type, quantity, acquired_at) '
        'VALUES (?, ?, ?, ?) '
        'ON CONFLICT(item_id) DO UPDATE SET '
        'quantity = owned_items.quantity + excluded.quantity',
        <Object?>[
          itemId,
          _ownedItemTypeWire(itemType),
          quantityDelta,
          now,
        ],
      );
    });
  }
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
