import 'package:drift/drift.dart';

import '../currency_catalog.dart';
import '../database.dart';
import '../tables/cycles.dart';
import '../tables/owned_items.dart';
import '../tables/wells.dart';

class AppSettingsRepository {
  AppSettingsRepository(this._db);

  final AppDatabase _db;

  Stream<AppSettingsRow?> watch() {
    return (_db.select(_db.appSettings)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<void> updateAvatar(String avatarId) {
    return (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(avatarId: Value(avatarId)),
    );
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

  Future<void> completeOnboarding({
    required String name,
    required String avatarId,
    required String baseCode,
    required Set<String> secondaryCodes,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final monthLater = DateTime.fromMillisecondsSinceEpoch(now)
        .add(const Duration(days: 30))
        .millisecondsSinceEpoch;

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

      final activeCycle = await (_db.select(_db.cycles)
            ..where((t) => t.state.equalsValue(CycleState.active)))
          .getSingleOrNull();
      if (activeCycle == null) {
        await _db.into(_db.cycles).insert(
              CyclesCompanion.insert(
                startDate: now,
                endDate: monthLater,
                state: CycleState.active,
                createdAt: now,
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
      await _db.delete(_db.cropsCatalog).go();

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
}

class _StarterCropSeed {
  const _StarterCropSeed(this.id, this.name, this.coinYield, this.order);

  final String id;
  final String name;
  final int coinYield;
  final int order;
}
