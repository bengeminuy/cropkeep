import 'package:drift/drift.dart';

import '../../screens/market/market_catalog.dart';
import '../currency_catalog.dart';
import '../database.dart';
import '../pending_rates_store.dart';
import '../tables/coin_ledger.dart';
import '../tables/cycles.dart';
import '../tables/owned_items.dart';
import '../tables/wells.dart';

class AppSettingsRepository {
  AppSettingsRepository(this._db, {required PendingRatesStore pendingRates})
      : _pendingRates = pendingRates;

  final AppDatabase _db;
  final PendingRatesStore _pendingRates;

  Stream<AppSettingsRow?> watch() {
    return (_db.select(_db.appSettings)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<void> updateAvatar(String avatarId) {
    return (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(avatarId: Value(avatarId)),
    );
  }

  // Debug-only: grants spendable coins for testing the Market without
  // playing through cycles. Mirrors the production write pattern —
  // balance bump + matching `manualAdjustment` ledger row in one
  // transaction so the ledger stays the source of truth. Surfaced from
  // the Farmer tab's Dev tools card; remove the card (and this method)
  // before shipping.
  Future<void> grantCoinsForTesting(int amount) async {
    await _db.transaction(() async {
      final settings = await (_db.select(_db.appSettings)
            ..where((t) => t.id.equals(1)))
          .getSingle();
      await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
        AppSettingsCompanion(
          coinsBalance: Value(settings.coinsBalance + amount),
        ),
      );
      final activeCycle = await (_db.select(_db.cycles)
            ..where((t) => t.state.equalsValue(CycleState.active))
            ..limit(1))
          .getSingleOrNull();
      await _db.into(_db.coinLedger).insert(
            CoinLedgerCompanion.insert(
              cycleId: Value(activeCycle?.id),
              amount: amount,
              reason: CoinReason.manualAdjustment,
              description: const Value('Dev tool: granted coins'),
              occurredAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    });
  }

  Stream<List<CurrencyRow>> watchCurrencies() {
    return (_db.select(_db.currencies)
          ..orderBy([
            (t) => OrderingTerm(expression: t.displayOrder),
            (t) => OrderingTerm(expression: t.code),
          ]))
        .watch();
  }

  Future<List<String>> findActiveCurrencyUsages(String code) async {
    final wells = await (_db.select(_db.wells)
          ..where((t) => t.isActive.equals(true) & t.currencyCode.equals(code)))
        .get();
    final plots = await (_db.select(_db.plots)
          ..where((t) => t.isActive.equals(true) & t.currencyCode.equals(code)))
        .get();
    return [
      for (final w in wells) w.name,
      for (final p in plots) p.name,
    ];
  }

  Future<void> setSecondaryCurrencyEnabled(
    CurrencySpec spec,
    bool enabled,
  ) async {
    await _db.transaction(() async {
      final existing = await (_db.select(_db.currencies)
            ..where((t) => t.code.equals(spec.code)))
          .getSingleOrNull();
      if (existing == null) {
        if (!enabled) return;
        await _db.into(_db.currencies).insert(
              CurrenciesCompanion.insert(
                code: spec.code,
                symbol: spec.symbol,
                name: spec.name,
                decimalPlaces: spec.decimalPlaces,
                isBase: const Value(false),
                isActive: const Value(true),
              ),
            );
      } else {
        await (_db.update(_db.currencies)
              ..where((t) => t.code.equals(spec.code)))
            .write(CurrenciesCompanion(isActive: Value(enabled)));
      }
    });
  }

  // Onboarding seeds the farm (currencies, plots, wells, starter crops,
  // savings barn) but does NOT create an active cycle. The user starts
  // their first cycle explicitly from the Farm tab's "Begin tracking"
  // CTA — see CycleRepository.startFirstCycle. Exchange rates picked
  // here are stashed in `_pendingInitialRates` and applied to whichever
  // cycle the user begins next.
  Future<void> completeOnboarding({
    required String name,
    required String avatarId,
    required String baseCode,
    required Set<String> secondaryCodes,
    Map<String, double> initialRates = const <String, double>{},
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction(() async {
      await _db.update(_db.currencies).write(
            const CurrenciesCompanion(
              isBase: Value(false),
              isActive: Value(false),
            ),
          );

      final selectedCodes = <String>{baseCode, ...secondaryCodes};
      for (final code in selectedCodes) {
        final spec = CurrencyCatalog.findByCode(code);
        if (spec == null) continue;
        await _db.into(_db.currencies).insertOnConflictUpdate(
              CurrenciesCompanion.insert(
                code: spec.code,
                symbol: spec.symbol,
                name: spec.name,
                decimalPlaces: spec.decimalPlaces,
                isBase: Value(spec.code == baseCode),
                isActive: const Value(true),
              ),
            );
      }

      await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
        AppSettingsCompanion(
          farmerName: Value(name),
          avatarId: Value(avatarId),
          baseCurrencyCode: Value(baseCode),
          onboardingCompleted: const Value(true),
        ),
      );

      const starterCrops = <_StarterCropSeed>[
        _StarterCropSeed('wheat', 'Wheat', 5, 1),
        _StarterCropSeed('apple', 'Apple', 5, 2),
        _StarterCropSeed('potato', 'Potato', 5, 3),
        _StarterCropSeed('unplanned', 'Wildflowers', 0, 99),
      ];
      for (final crop in starterCrops) {
        await _db.into(_db.cropsCatalog).insertOnConflictUpdate(
              CropsCatalogCompanion.insert(
                cropId: crop.id,
                name: crop.name,
                baseCoinYield: crop.coinYield,
                isStarter: const Value(true),
                displayOrder: Value(crop.order),
              ),
            );
      }

      final existingUnplanned = await (_db.select(_db.plots)
            ..where((t) => t.isUnplanned.equals(true)))
          .getSingleOrNull();
      if (existingUnplanned == null) {
        await _db.into(_db.plots).insert(
              PlotsCompanion.insert(
                name: 'Unplanned',
                currencyCode: baseCode,
                cropTypeId: 'unplanned',
                isUnplanned: const Value(true),
                createdAt: now,
              ),
            );
      }

      final existingCarryover = await (_db.select(_db.wells)
            ..where((t) => t.isCarryover.equals(true)))
          .getSingleOrNull();
      if (existingCarryover == null) {
        await _db.into(_db.wells).insert(
              WellsCompanion.insert(
                name: 'Carryover',
                wellType: WellType.bonus,
                isCarryover: const Value(true),
                currencyCode: baseCode,
                createdAt: now,
              ),
            );
      }

      for (final cropId in const ['wheat', 'apple', 'potato']) {
        await _db.into(_db.ownedItems).insertOnConflictUpdate(
              OwnedItemsCompanion.insert(
                itemId: cropId,
                itemType: OwnedItemType.crop,
                acquiredAt: now,
              ),
            );
      }

    });

    // Onboarding-time rate entries can't be persisted yet — there's no
    // active cycle to scope them to. Stash them in the disk-backed
    // pending-rates store so they survive process kill and are usable
    // by pre-cycle screens (new well / new plot / rates sheet). The
    // first CycleRepository.startFirstCycle call drains the store via
    // `consumePendingInitialRates()` into the new cycle's id.
    if (initialRates.isEmpty) {
      await _pendingRates.clear();
    } else {
      await _pendingRates.replaceAll(initialRates);
    }
  }

  // Initial exchange rates the user entered during onboarding. Consumed
  // once when the first cycle is created. See `completeOnboarding`.
  Future<Map<String, double>> consumePendingInitialRates() {
    return _pendingRates.consume();
  }

  Future<void> resetAll() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.transaction(() async {
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.incomeEntries).go();
      await _db.delete(_db.bonusAllocations).go();
      await _db.delete(_db.plotCycleResults).go();
      await _db.delete(_db.plotFertilizerApplications).go();
      await _db.delete(_db.cycleSummaries).go();
      await _db.delete(_db.exchangeRates).go();
      await _db.delete(_db.coinLedger).go();
      await _db.delete(_db.badgesEarned).go();
      await _db.delete(_db.ownedItems).go();
      await _db.delete(_db.plots).go();
      await _db.delete(_db.wells).go();
      await _db.delete(_db.cycles).go();
      // crops_catalog is application-defined (it carries the
      // definitions of every crop the app supports), not user data —
      // keep it across reset. Wiping it here previously left the
      // catalog empty until the next process startup re-ran
      // ensureSeeded, which crashed the crop picker mid-session.
      // _resyncConsumableCrops in ensureSeeded is idempotent via
      // insertOnConflictUpdate, so any catalog drift from app upgrades
      // self-heals on next launch without needing a reset to scrub it.

      await _db.into(_db.currencies).insertOnConflictUpdate(
            CurrenciesCompanion.insert(
              code: 'USD',
              symbol: r'$',
              name: 'US Dollar',
              decimalPlaces: 2,
              isBase: const Value(true),
              isActive: const Value(true),
            ),
          );

      await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
        AppSettingsCompanion(
          farmerName: const Value('Farmer'),
          avatarId: const Value('farmer'),
          baseCurrencyCode: const Value('USD'),
          onboardingCompleted: const Value(false),
          farmerLevel: const Value(1),
          farmerXp: const Value(0),
          coinsBalance: const Value(0),
        ),
      );

      await (_db.delete(_db.currencies)
            ..where((t) => t.code.equals('USD').not()))
          .go();

      await (_db.update(_db.savingsBarn)..where((t) => t.id.equals(1))).write(
        SavingsBarnCompanion(
          totalSaved: const Value(0),
          barnSkinId: const Value('default'),
          lastUpdatedAt: Value(now),
        ),
      );
    });
    await _pendingRates.clear();
  }

  // Onboarding will overwrite the placeholder name/avatar/currency.
  Future<void> ensureSeeded() async {
    final existingCurrency = await (_db.select(_db.currencies)
          ..where((t) => t.code.equals('USD')))
        .getSingleOrNull();
    if (existingCurrency == null) {
      await _db.into(_db.currencies).insert(
            CurrenciesCompanion.insert(
              code: 'USD',
              symbol: r'$',
              name: 'US Dollar',
              decimalPlaces: 2,
              isBase: const Value(true),
            ),
          );
    }

    await _resyncCurrencyCatalog();
    await _resyncConsumableCrops();
    await _migrateLegacyAvatarId();

    final existingSettings = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (existingSettings == null) {
      await _db.into(_db.appSettings).insert(
            AppSettingsCompanion.insert(
              id: const Value(1),
              farmerName: 'Farmer',
              avatarId: 'farmer',
              baseCurrencyCode: 'USD',
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    }

    final existingBarn = await (_db.select(_db.savingsBarn)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (existingBarn == null) {
      await _db.into(_db.savingsBarn).insert(
            SavingsBarnCompanion.insert(
              id: const Value(1),
              lastUpdatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    }

  }

  // Seeds the 15 consumable seed-pack crops driven by `MarketCatalog`.
  // Idempotent via `insertOnConflictUpdate` keyed on `cropId`, so price
  // / yield / pack-size rebalancing in MarketCatalog lands cleanly on
  // existing installs without manual migration. Mirrors the
  // `_resyncCurrencyCatalog` pattern. Tier-level economics (price,
  // pack size, yield) come from `MarketCatalog.tierSpecs` so the DB
  // row carries the canonical numbers per shop.md.
  Future<void> _resyncConsumableCrops() async {
    for (final spec in MarketCatalog.consumables) {
      final tier = MarketCatalog.tierSpecs[spec.tier]!;
      await _db.into(_db.cropsCatalog).insertOnConflictUpdate(
            CropsCatalogCompanion.insert(
              cropId: spec.cropId,
              name: spec.name,
              baseCoinYield: tier.yieldPerSeed,
              isStarter: const Value(false),
              isConsumable: const Value(true),
              seedPackSize: Value(tier.seedPackSize),
              priceCoins: Value(tier.priceCoins),
              displayOrder: Value(spec.displayOrder),
            ),
          );
    }
  }

  // Resets any install carrying the dropped `farmer-fl` avatar id back
  // to the default `farmer`. The legacy id was a hardcoded second option
  // in the old onboarding flow; it has no `MarketCatalog.avatars` entry,
  // so the picker would render the fallback farmer SVG and never show
  // the avatar as equipped. Idempotent — no-op on fresh installs and on
  // installs that have already migrated.
  Future<void> _migrateLegacyAvatarId() async {
    await (_db.update(_db.appSettings)
          ..where(
            (t) => t.id.equals(1) & t.avatarId.equals('farmer-fl'),
          ))
        .write(const AppSettingsCompanion(avatarId: Value('farmer')));
  }

  // Pulls catalog-managed fields (symbol/name/decimalPlaces) forward onto
  // any existing currency rows whose codes match the catalog. Catches
  // installs that pre-date a catalog change — e.g. TWD's symbol going from
  // "NT$" to "$" — without disturbing the user-controlled isBase/isActive
  // state. Codes not in the catalog are left alone.
  Future<void> _resyncCurrencyCatalog() async {
    final existing = await _db.select(_db.currencies).get();
    for (final row in existing) {
      final spec = CurrencyCatalog.findByCode(row.code);
      if (spec == null) continue;
      final bool drifted = row.symbol != spec.symbol ||
          row.name != spec.name ||
          row.decimalPlaces != spec.decimalPlaces;
      if (!drifted) continue;
      await (_db.update(_db.currencies)..where((t) => t.code.equals(row.code)))
          .write(
        CurrenciesCompanion(
          symbol: Value(spec.symbol),
          name: Value(spec.name),
          decimalPlaces: Value(spec.decimalPlaces),
        ),
      );
    }
  }
}

class _StarterCropSeed {
  const _StarterCropSeed(this.id, this.name, this.coinYield, this.order);

  final String id;
  final String name;
  final int coinYield;
  final int order;
}
