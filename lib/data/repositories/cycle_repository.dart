import 'dart:math' as math;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/coin_ledger.dart';
import '../tables/cycle_summaries.dart';
import '../tables/cycles.dart';
import '../tables/owned_items.dart';
import '../tables/plot_cycle_results.dart';
import '../tables/plots.dart';
import '../tables/wells.dart';

class CycleRepository {
  CycleRepository(this._db);

  final AppDatabase _db;

  // Emits null when no row has `state = 'active'`. Two situations produce
  // that: a fresh install where the user hasn't pressed Begin tracking
  // yet, and the transient state between closing one cycle and starting
  // the next. The Crops subpage uses this stream to swap between its
  // normal layout and the Begin-tracking hero CTA.
  Stream<CycleRow?> watchActiveCycle() {
    return (_db.select(_db.cycles)
          ..where((t) => t.state.equalsValue(CycleState.active))
          ..limit(1))
        .watchSingleOrNull();
  }

  // True once any cycle has been started (regardless of state). Lets the
  // Begin-tracking hero pick between first-time copy and between-cycles
  // copy without an extra read.
  Stream<bool> watchHasAnyCycle() {
    final count = _db.cycles.id.count();
    final query = _db.selectOnly(_db.cycles)..addColumns([count]);
    return query.watchSingle().map((row) => (row.read(count) ?? 0) > 0);
  }

  // Most recently completed cycle row, for the between-cycles hero copy
  // ("Your March cycle ended on Mar 31"). Null until at least one cycle
  // has been closed.
  Future<CycleRow?> readLastCompletedCycle() async {
    return (_db.select(_db.cycles)
          ..where((t) => t.state.equalsValue(CycleState.completed))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<List<ExchangeRateRow>> watchRatesFor(int cycleId) {
    return (_db.select(_db.exchangeRates)
          ..where((t) => t.cycleId.equals(cycleId)))
        .watch();
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  // ──────────────────────────────────────────────────────────────────
  // Cycle lifecycle

  // A cycle is conceptually a calendar month, so the proposed range is
  // always day 1 through last day of the current calendar month —
  // regardless of when within the month the user actually opens the
  // confirmation. If the user presses Begin tracking on Mar 25, the
  // cycle is still "March (Mar 1 – Mar 31)"; days 1–24 are simply
  // unlogged unless they backfill.
  static ({DateTime start, DateTime end}) proposedNextCycleRange({
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);
    return (start: startOfMonth, end: endOfMonth);
  }

  // Debug-only: backdates the active cycle's start/end to the previous
  // calendar month so the Farm tab's `_CycleStatusStrip` detects it as
  // past-end and surfaces the "Cycle ended" banner. The user then taps
  // through the natural close UX (reconciliation, exchange rates,
  // surplus split slider) instead of skipping past it. Cycle-bound
  // transactions and income entries keep their `cycle_id` and stay in
  // the cycle; their `spent_at` / `received_at` timestamps are not
  // touched (the cycle id is the source of truth for membership, not
  // dates). Pace math derives from `now` (`_CycleProvider`) and is
  // unaffected. Surfaced from the Farmer tab's Dev tools card — remove
  // both the card and this method before shipping.
  Future<void> forceCycleExpiredForTesting() async {
    final now = DateTime.now();
    final prevMonthStart = DateTime(now.year, now.month - 1, 1);
    final prevMonthEnd = DateTime(now.year, now.month, 0);
    await (_db.update(_db.cycles)
          ..where((t) => t.state.equalsValue(CycleState.active)))
        .write(CyclesCompanion(
          startDate: Value(prevMonthStart.millisecondsSinceEpoch),
          endDate: Value(prevMonthEnd.millisecondsSinceEpoch),
        ));
  }

  // Creates the first-ever active cycle. Idempotent guard: if an active
  // cycle already exists, returns its id without touching anything else.
  Future<int> startFirstCycle({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.cycles)
            ..where((t) => t.state.equalsValue(CycleState.active))
            ..limit(1))
          .getSingleOrNull();
      if (existing != null) return existing.id;
      return _db.into(_db.cycles).insert(
            CyclesCompanion.insert(
              startDate: _dateOnly(startDate).millisecondsSinceEpoch,
              endDate: _dateOnly(endDate).millisecondsSinceEpoch,
              state: CycleState.active,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    });
  }

  // Builds a read-only snapshot of what closing the active cycle would
  // produce — per-plot final states, totals, result tier, coin payouts
  // (excluding the surplus-saved bonus, which depends on the user's
  // split). Drives both the harvest preview step in the transition
  // screen and the actual persistence in `closeAndStartNext`.
  Future<CyclePreview?> previewClose() async {
    final cycle = await (_db.select(_db.cycles)
          ..where((t) => t.state.equalsValue(CycleState.active))
          ..limit(1))
        .getSingleOrNull();
    if (cycle == null) return null;
    return _buildPreview(cycle);
  }

  // Closes the active cycle, persists the per-plot frozen record and
  // cycle summary, emits coin_ledger rows, updates the savings barn,
  // then creates the next active cycle. The user-supplied
  // `amountSavedMinor` + `amountRolledMinor` MUST sum to
  // preview.surplus when surplus > 0; pass 0/0 when surplus ≤ 0.
  //
  // `pendingCropSwaps` carries user-staged crop changes from the
  // planting-plan step (plotId → new cropTypeId). Applied inside this
  // transaction BEFORE the cycle-start seed consumption, so the swap
  // itself is free — the single per-plot deduction in
  // _consumeCycleStartSeeds charges the chosen crop. This deliberately
  // bypasses PlotRepository.update's mid-cycle deduction semantics:
  // a swap performed at cycle hand-off is between-cycles, not
  // mid-cycle, so it should cost one seed (the next cycle's plant),
  // not two.
  Future<int> closeAndStartNext({
    required int amountSavedMinor,
    required int amountRolledMinor,
    required DateTime nextStartDate,
    required DateTime nextEndDate,
    Map<int, String> pendingCropSwaps = const <int, String>{},
    // Fertilizers the user staged on the planting-plan step. plotId →
    // fertilizer itemId. Each entry decrements owned_items.quantity by
    // 1 and inserts a plot_fertilizer_applications row scoped to the
    // NEW cycle id created below. Discarded if the user abandons the
    // close flow; no packs are forfeited in that case.
    Map<int, String> pendingFertilizers = const <int, String>{},
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _db.transaction(() async {
      final cycle = await (_db.select(_db.cycles)
            ..where((t) => t.state.equalsValue(CycleState.active))
            ..limit(1))
          .getSingle();
      final preview = await _buildPreview(cycle);

      // Surplus-saved coin bonus is the only payout that depends on the
      // user's split — clamp to the cap from shop.md (floor(saved/10),
      // max +50) here so the math stays in one place.
      final int surplusSavedCoins =
          amountSavedMinor <= 0 ? 0 : math.min(50, amountSavedMinor ~/ 10);

      // 1. Mark previous cycle completed.
      await (_db.update(_db.cycles)..where((t) => t.id.equals(cycle.id))).write(
        CyclesCompanion(
          state: const Value(CycleState.completed),
          completedAt: Value(now),
        ),
      );

      // 2. Freeze per-plot results.
      for (final result in preview.plotResults) {
        await _db.into(_db.plotCycleResults).insert(
              PlotCycleResultsCompanion.insert(
                cycleId: cycle.id,
                plotId: result.plotId,
                plotNameSnapshot: result.plotName,
                kindSnapshot: Value(result.kind),
                cropTypeIdSnapshot: result.cropTypeId,
                plotColorIdSnapshot: Value(result.plotColorId),
                isUnplanned: Value(result.isUnplanned),
                budgetAmountSnapshot: Value(result.budgetAmountBase),
                currencyCodeSnapshot: result.currencyCode,
                totalSpent: result.totalSpentBase,
                incomeShareAtClose: Value(result.incomeShareAtClose),
                finalState: result.finalState,
                completedAt: now,
              ),
            );
      }

      // 3. Write the cycle summary scalar row.
      final int totalCoins = preview.perPlotCoins +
          preview.unplannedHealthyCoins +
          preview.overallBonusCoins +
          preview.comboBonusCoins +
          surplusSavedCoins;
      await _db.into(_db.cycleSummaries).insert(
            CycleSummariesCompanion.insert(
              cycleId: cycle.id,
              totalFoundationIncome: preview.totalFoundationIncome,
              totalBonusIncome: preview.totalBonusIncome,
              totalSpentPlanned: preview.totalSpentPlanned,
              totalSpentUnplanned: preview.totalSpentUnplanned,
              totalSpent: preview.totalSpent,
              surplus: preview.surplus,
              resultTier: preview.resultTier,
              overallBonusCoins: Value(preview.overallBonusCoins),
              perPlotCoins: Value(preview.perPlotCoins +
                  preview.unplannedHealthyCoins +
                  preview.comboBonusCoins),
              surplusSavedCoins: Value(surplusSavedCoins),
              totalCoinsEarned: Value(totalCoins),
              amountSaved: Value(amountSavedMinor),
              amountRolledToNext: Value(amountRolledMinor),
              completedAt: now,
            ),
          );

      // 4. Emit coin_ledger rows + grow the user's spendable balance.
      await _writeCoinPayouts(
        cycleId: cycle.id,
        preview: preview,
        surplusSavedCoins: surplusSavedCoins,
        occurredAt: now,
      );
      if (totalCoins > 0) {
        final settings = await (_db.select(_db.appSettings)
              ..where((t) => t.id.equals(1)))
            .getSingle();
        await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(
          AppSettingsCompanion(
            coinsBalance: Value(settings.coinsBalance + totalCoins),
          ),
        );
      }

      // 5. Grow the savings barn.
      if (amountSavedMinor > 0) {
        final barn = await (_db.select(_db.savingsBarn)
              ..where((t) => t.id.equals(1)))
            .getSingle();
        await (_db.update(_db.savingsBarn)..where((t) => t.id.equals(1))).write(
          SavingsBarnCompanion(
            totalSaved: Value(barn.totalSaved + amountSavedMinor),
            lastUpdatedAt: Value(now),
          ),
        );
      }

      // 6. Create next active cycle.
      final int newCycleId = await _db.into(_db.cycles).insert(
            CyclesCompanion.insert(
              startDate: _dateOnly(nextStartDate).millisecondsSinceEpoch,
              endDate: _dateOnly(nextEndDate).millisecondsSinceEpoch,
              state: CycleState.active,
              createdAt: now,
            ),
          );

      // 7. If user chose to roll over surplus, log a system-generated
      //    income entry on the Carryover well scoped to the new cycle.
      if (amountRolledMinor > 0) {
        final carryover = await (_db.select(_db.wells)
              ..where((t) => t.isCarryover.equals(true))
              ..limit(1))
            .getSingleOrNull();
        if (carryover != null) {
          await _db.into(_db.incomeEntries).insert(
                IncomeEntriesCompanion.insert(
                  wellId: carryover.id,
                  cycleId: newCycleId,
                  amount: amountRolledMinor,
                  currencyCode: carryover.currencyCode,
                  baseAmount: amountRolledMinor,
                  exchangeRate: 1.0,
                  receivedAt: now,
                  note: const Value('Rolled over from previous cycle'),
                  isSystemGenerated: const Value(true),
                  createdAt: now,
                ),
              );
        }
      }

      // 7.5 Apply user-staged crop swaps from the planting-plan step.
      //     Writes only the crop_type_id field — no seed deduction here.
      //     The deduction is the responsibility of the cycle-start
      //     consumption pass below, so a swap costs exactly one seed
      //     (the new crop), not two.
      for (final entry in pendingCropSwaps.entries) {
        await (_db.update(_db.plots)
              ..where((t) => t.id.equals(entry.key)))
            .write(PlotsCompanion(cropTypeId: Value(entry.value)));
      }

      // 8. Cycle-start seed consumption — deduct 1 seed for each active
      //    plot planting a consumable crop. If a plot would go negative,
      //    auto-revert that plot's crop to wheat for the new cycle.
      await _consumeCycleStartSeeds();

      // 9. Apply user-staged fertilizers for the new cycle. Same
      //    forfeit-on-shortage policy as elsewhere: if a pack was
      //    consumed since staging (race with mid-cycle Market
      //    activity), the entry is silently skipped — we already
      //    couldn't honor it, and surfacing a partial commit failure
      //    here would be worse than dropping a row that no longer
      //    has a backing pack. The sheet's filter on owned ≥1 makes
      //    this path very rare in practice.
      for (final entry in pendingFertilizers.entries) {
        final owned = await (_db.select(_db.ownedItems)
              ..where((t) => t.itemId.equals(entry.value)))
            .getSingleOrNull();
        if (owned == null || owned.quantity < 1) continue;
        await _db.customUpdate(
          'UPDATE owned_items SET quantity = quantity - 1 '
          'WHERE item_id = ?',
          variables: [Variable.withString(entry.value)],
          updates: {_db.ownedItems},
        );
        await _db.into(_db.plotFertilizerApplications).insert(
              PlotFertilizerApplicationsCompanion.insert(
                cycleId: newCycleId,
                plotId: entry.key,
                fertilizerItemId: entry.value,
                appliedAt: now,
              ),
            );
      }

      return newCycleId;
    });
  }

  // ──────────────────────────────────────────────────────────────────
  // Internals — preview math

  Future<CyclePreview> _buildPreview(CycleRow cycle) async {
    final settings = await (_db.select(_db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingle();
    final baseCode = settings.baseCurrencyCode;
    final baseCurrency = await (_db.select(_db.currencies)
          ..where((t) => t.code.equals(baseCode)))
        .getSingle();

    final currencies = await _db.select(_db.currencies).get();
    final currencyByCode = {for (final c in currencies) c.code: c};

    final rateRows = await (_db.select(_db.exchangeRates)
          ..where((t) =>
              t.cycleId.equals(cycle.id) & t.toCurrencyCode.equals(baseCode)))
        .get();
    final rateToBase = <String, double>{
      for (final r in rateRows) r.fromCurrencyCode: r.rate,
    };

    // Market-side state that feeds the shop.md §2-5 modifiers. Loaded
    // once up front so the plot loop and cycle-level aggregations all
    // read from the same snapshot.
    final ownedDecorationRows = await (_db.select(_db.ownedItems)
          ..where((t) =>
              t.itemType.equalsValue(OwnedItemType.decoration) &
              t.quantity.isBiggerOrEqualValue(1)))
        .get();
    final Set<String> ownedDecorations =
        ownedDecorationRows.map((r) => r.itemId).toSet();
    // app_settings.avatar_id doubles as the equipped slot until the
    // explicit equipped_avatar_id column lands (see md/to-do.md
    // §"Schema additions for equipping"). 'farmer' on day 1 carries no
    // passive, so the modifier checks below just no-op.
    final String equippedAvatarId = settings.avatarId;
    final fertilizerApps = await (_db.select(_db.plotFertilizerApplications)
          ..where((t) => t.cycleId.equals(cycle.id)))
        .get();
    final Map<int, String> fertilizerByPlot = {
      for (final f in fertilizerApps) f.plotId: f.fertilizerItemId,
    };
    // Crystal Aquifer: needs the previous cycle's rollover ratio to
    // decide whether to lift this cycle's tier.
    final CycleSummaryRow? prevSummary = ownedDecorations
            .contains('crystal_aquifer')
        ? await (_db.select(_db.cycleSummaries)
              ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
              ..limit(1))
            .getSingleOrNull()
        : null;

    int toBase(int sourceMinor, String sourceCode) {
      if (sourceCode == baseCode) return sourceMinor;
      final int srcDecimals =
          currencyByCode[sourceCode]?.decimalPlaces ?? baseCurrency.decimalPlaces;
      final double rate = rateToBase[sourceCode] ?? 1.0;
      final num scale = math.pow(10, baseCurrency.decimalPlaces - srcDecimals);
      return (sourceMinor * rate * scale).round();
    }

    final activePlots = await (_db.select(_db.plots)
          ..where((t) => t.isActive.equals(true)))
        .get();

    final transactions = await (_db.select(_db.transactions)
          ..where(
              (t) => t.cycleId.equals(cycle.id) & t.deletedAt.isNull()))
        .get();
    final spentByPlot = <int, int>{};
    for (final t in transactions) {
      spentByPlot.update(t.plotId, (v) => v + t.baseAmount,
          ifAbsent: () => t.baseAmount);
    }

    final wells = await (_db.select(_db.wells)
          ..where((t) => t.isActive.equals(true)))
        .get();
    final foundationWells =
        wells.where((w) => w.wellType == WellType.foundation).toList();

    final incomeEntries = await (_db.select(_db.incomeEntries)
          ..where(
              (t) => t.cycleId.equals(cycle.id) & t.deletedAt.isNull()))
        .get();
    final loggedByWell = <int, int>{};
    for (final e in incomeEntries) {
      loggedByWell.update(e.wellId, (v) => v + e.baseAmount,
          ifAbsent: () => e.baseAmount);
    }

    int totalFoundationIncome = 0;
    for (final w in foundationWells) {
      final logged = loggedByWell[w.id];
      if (logged != null) {
        totalFoundationIncome += logged;
      } else if (w.expectedAmount != null) {
        totalFoundationIncome += toBase(w.expectedAmount!, w.currencyCode);
      }
    }

    int totalBonusIncome = 0;
    for (final e in incomeEntries) {
      final well = wells.firstWhere(
        (w) => w.id == e.wellId,
        orElse: () => _missingWell,
      );
      if (well.wellType == WellType.bonus) {
        totalBonusIncome += e.baseAmount;
      }
    }
    final int totalIncome = totalFoundationIncome + totalBonusIncome;

    int totalSpentPlanned = 0;
    int totalSpentUnplanned = 0;
    for (final p in activePlots) {
      final spent = spentByPlot[p.id] ?? 0;
      if (p.isUnplanned) {
        totalSpentUnplanned += spent;
      } else {
        totalSpentPlanned += spent;
      }
    }
    final int totalSpent = totalSpentPlanned + totalSpentUnplanned;
    final int surplus = totalIncome - totalSpent;

    final CycleResultTier tier;
    if (totalFoundationIncome <= 0) {
      tier = totalSpent > 0
          ? CycleResultTier.negative
          : CycleResultTier.barelyPositive;
    } else {
      final ratio = totalSpent / totalFoundationIncome;
      if (ratio > 1.0) {
        tier = CycleResultTier.negative;
      } else if (ratio > 0.90) {
        tier = CycleResultTier.barelyPositive;
      } else if (ratio > 0.70) {
        tier = CycleResultTier.solidlyPositive;
      } else {
        tier = CycleResultTier.excellent;
      }
    }

    final crops = await _db.select(_db.cropsCatalog).get();
    final cropById = {for (final c in crops) c.cropId: c};

    final plotResults = <PlotResultPreview>[];
    for (final p in activePlots) {
      final spent = spentByPlot[p.id] ?? 0;
      final int? budgetBase =
          p.budgetAmount == null ? null : toBase(p.budgetAmount!, p.currencyCode);
      final PlotFinalState finalState;
      double? incomeShare;
      if (p.isUnplanned) {
        incomeShare = totalIncome <= 0 ? null : spent / totalIncome;
        finalState = _unplannedFinalState(incomeShare);
      } else {
        finalState = _regularFinalState(
          kind: p.kind,
          spent: spent,
          budgetBase: budgetBase ?? 0,
        );
      }
      final crop = cropById[p.cropTypeId];
      final baseYield = crop?.baseCoinYield ?? 0;
      final int coinsEarned = p.isUnplanned
          ? 0
          : _plotHarvestCoinsWithModifiers(
              baseYield: baseYield,
              finalState: finalState,
              fertilizerId: fertilizerByPlot[p.id],
              hasEternalSun: ownedDecorations.contains('eternal_sun'),
              hasStoneFountain: ownedDecorations.contains('stone_fountain'),
              equippedAvatarId: equippedAvatarId,
            );
      plotResults.add(PlotResultPreview(
        plotId: p.id,
        plotName: p.name,
        kind: p.kind,
        isUnplanned: p.isUnplanned,
        cropTypeId: p.cropTypeId,
        plotColorId: p.plotColorId,
        currencyCode: p.currencyCode,
        budgetAmountBase: budgetBase,
        totalSpentBase: spent,
        finalState: finalState,
        incomeShareAtClose: incomeShare,
        coinsEarned: coinsEarned,
      ));
    }

    final int perPlotCoins = plotResults.fold<int>(
      0,
      (sum, r) => sum + r.coinsEarned,
    );

    // Unplanned plot's flat bonus per shop.md; Wishing Windmill (700c
    // decoration) lifts the harvested payout from 15→25.
    final unplanned = plotResults.where((r) => r.isUnplanned).firstOrNull;
    final int unplannedHealthyCoins = switch (unplanned?.finalState) {
      PlotFinalState.harvested =>
        ownedDecorations.contains('wishing_windmill') ? 25 : 15,
      PlotFinalState.mildStress => 5,
      _ => 0,
    };

    // Crystal Aquifer (1800c): if the previous cycle rolled over ≥10%
    // of its income, lift this cycle's tier by one for the
    // `cycleOverallPositive` payout (the displayed result_tier itself
    // is left untouched — only the coin amount shifts).
    CycleResultTier coinTier = tier;
    if (prevSummary != null) {
      final int prevIncome =
          prevSummary.totalFoundationIncome + prevSummary.totalBonusIncome;
      if (prevIncome > 0 &&
          prevSummary.amountRolledToNext / prevIncome >= 0.10) {
        coinTier = _liftTier(coinTier);
      }
    }

    int overallBonusCoins = _overallBonusForTier(coinTier);
    // Mushroom Gnome (200c): +5 every net-positive cycle. Folded into
    // overallBonusCoins because no `decoration_bonus` ledger reason
    // exists yet (build_runner 2.15.0 + Dart 3.10 blocks adding one).
    if (ownedDecorations.contains('mushroom_gnome') &&
        coinTier != CycleResultTier.negative) {
      overallBonusCoins += 5;
    }

    // Combo: every non-Unplanned plot ≥ mildStress earns +15; ≥ harvested
    // earns +25 instead. Skips when there are no regular plots.
    //
    // Iron Pitchfork (350c) lets withered plots be ignored for both
    // thresholds. Arcane Wizard (2500c, equipped) lets mildStress
    // count as harvested for the +25 check.
    final regular = plotResults.where((r) => !r.isUnplanned).toList();
    int comboBonusCoins = 0;
    if (regular.isNotEmpty) {
      final bool hasPitchfork =
          ownedDecorations.contains('iron_pitchfork');
      final bool hasWizard = equippedAvatarId == 'arcane_wizard';
      final considered = hasPitchfork
          ? regular
              .where((r) => r.finalState != PlotFinalState.withered)
              .toList()
          : regular;
      if (considered.isNotEmpty) {
        final allHealthy = considered.every((r) =>
            r.finalState == PlotFinalState.harvested ||
            (hasWizard && r.finalState == PlotFinalState.mildStress));
        final allAtLeastMild = considered.every((r) =>
            r.finalState == PlotFinalState.harvested ||
            r.finalState == PlotFinalState.mildStress);
        if (allHealthy) {
          comboBonusCoins = 25;
        } else if (allAtLeastMild) {
          comboBonusCoins = 15;
        }
      }
    }

    // Set bonuses are paused for v1 — see md/to-do.md §"Set bonuses
    // paused for v1". The `CoinReason.cropSetBonus` enum value, its
    // CHECK entry, and the `MarketCatalog.sets` catalog stay dormant
    // until the feature returns (touching the CHECK string needs
    // build_runner regen, which is broken on Dart 3.10).

    // Planting plan — what each active non-Unplanned plot intends to grow
    // at the start of the next cycle, paired with current inventory.
    // Lets the UI surface premium-crop costs and warn before the silent
    // wheat fallback fires in _consumeCycleStartSeeds.
    final ownedRows = await _db.select(_db.ownedItems).get();
    final ownedByCrop = {for (final o in ownedRows) o.itemId: o.quantity};
    final plantingPlan = <PlotPlanEntry>[];
    for (final p in activePlots) {
      if (p.isUnplanned) continue;
      final crop = cropById[p.cropTypeId];
      if (crop == null) continue;
      plantingPlan.add(PlotPlanEntry(
        plotId: p.id,
        plotName: p.name,
        plotColorId: p.plotColorId,
        cropTypeId: p.cropTypeId,
        cropName: crop.name,
        isConsumable: crop.isConsumable,
        isStarter: crop.isStarter,
        seedsOwned: ownedByCrop[p.cropTypeId] ?? 0,
      ));
    }

    return CyclePreview(
      cycle: cycle,
      plotResults: plotResults,
      totalFoundationIncome: totalFoundationIncome,
      totalBonusIncome: totalBonusIncome,
      totalSpentPlanned: totalSpentPlanned,
      totalSpentUnplanned: totalSpentUnplanned,
      totalSpent: totalSpent,
      surplus: surplus,
      resultTier: tier,
      perPlotCoins: perPlotCoins,
      unplannedHealthyCoins: unplannedHealthyCoins,
      overallBonusCoins: overallBonusCoins,
      comboBonusCoins: comboBonusCoins,
      baseCurrencyCode: baseCode,
      baseCurrencyDecimals: baseCurrency.decimalPlaces,
      plantingPlan: plantingPlan,
    );
  }

  PlotFinalState _regularFinalState({
    required PlotKind kind,
    required int spent,
    required int budgetBase,
  }) {
    if (budgetBase <= 0) {
      return spent > 0 ? PlotFinalState.dead : PlotFinalState.harvested;
    }
    final ratio = spent / budgetBase;
    switch (kind) {
      case PlotKind.discretionary:
        if (ratio <= 1.0) return PlotFinalState.harvested;
        if (ratio <= 1.10) return PlotFinalState.mildStress;
        if (ratio <= 1.50) return PlotFinalState.withered;
        return PlotFinalState.dead;
      case PlotKind.fixedObligation:
        if (spent == 0) return PlotFinalState.dead;
        if (ratio >= 0.95 && ratio <= 1.05) return PlotFinalState.harvested;
        if ((ratio >= 0.75 && ratio < 0.95) ||
            (ratio > 1.05 && ratio <= 1.25)) {
          return PlotFinalState.mildStress;
        }
        if ((ratio >= 0.50 && ratio < 0.75) ||
            (ratio > 1.25 && ratio <= 1.50)) {
          return PlotFinalState.withered;
        }
        return PlotFinalState.dead;
      case PlotKind.investment:
        if (spent == 0) return PlotFinalState.dead;
        if (ratio >= 1.0) return PlotFinalState.harvested;
        if (ratio >= 0.75) return PlotFinalState.mildStress;
        if (ratio >= 0.50) return PlotFinalState.withered;
        return PlotFinalState.dead;
    }
  }

  PlotFinalState _unplannedFinalState(double? incomeShare) {
    if (incomeShare == null) return PlotFinalState.harvested;
    if (incomeShare < 0.05) return PlotFinalState.harvested;
    if (incomeShare < 0.10) return PlotFinalState.mildStress;
    if (incomeShare < 0.20) return PlotFinalState.withered;
    return PlotFinalState.dead;
  }

  int _plotHarvestCoins(int baseYield, PlotFinalState state) {
    switch (state) {
      case PlotFinalState.harvested:
        return baseYield;
      case PlotFinalState.mildStress:
        return baseYield ~/ 2;
      case PlotFinalState.withered:
      case PlotFinalState.dead:
        return 0;
    }
  }

  // Per-plot reward calculation honoring shop.md §2-5 stacking rules:
  //   1. Fertilizer state-transforms run first (Storm Umbrella,
  //      Faerie Reviver, Buzzing Beehive). Mystic Potion zeroes the
  //      plot if the *actual* finalState isn't harvested.
  //   2. Base coins = baseYield × stateMultiplier on the effective
  //      state.
  //   3. Additive % modifiers (fertilizers, Eternal Sun, Forest Elf,
  //      Arcane Wizard) stack into a single sum capped at +50%.
  //   4. Mystic Potion's +100% bypasses the cap (per §5).
  //   5. Stone Fountain adds a flat +1c per actually-harvested plot,
  //      outside the cap.
  int _plotHarvestCoinsWithModifiers({
    required int baseYield,
    required PlotFinalState finalState,
    String? fertilizerId,
    required bool hasEternalSun,
    required bool hasStoneFountain,
    required String equippedAvatarId,
  }) {
    if (baseYield == 0) return 0;

    // Mystic Potion's "must finish harvested" gate keys off the actual
    // finalState, not the post-transform one — by design, modifier
    // rescues don't satisfy it.
    if (fertilizerId == 'mystic_potion' &&
        finalState != PlotFinalState.harvested) {
      return 0;
    }

    PlotFinalState effective = finalState;
    switch (fertilizerId) {
      case 'storm_umbrella':
        if (effective == PlotFinalState.mildStress) {
          effective = PlotFinalState.harvested;
        }
        break;
      case 'faerie_reviver':
        if (effective == PlotFinalState.withered) {
          effective = PlotFinalState.mildStress;
        }
        break;
      case 'buzzing_beehive':
        effective = PlotFinalState.harvested;
        break;
    }

    int coins = _plotHarvestCoins(baseYield, effective);
    if (coins == 0) return 0;

    int cappedPct = 0;
    switch (fertilizerId) {
      case 'fertilizer_mix':
        cappedPct += 15;
        break;
      case 'compost_heap':
        cappedPct += 25;
        break;
      case 'liquid_boost':
        cappedPct += 35;
        break;
      case 'pumpkin_bloom':
        cappedPct += 50;
        break;
      case 'buzzing_beehive':
        cappedPct += 25;
        break;
    }
    if (hasEternalSun) cappedPct += 10;
    if (equippedAvatarId == 'forest_elf') cappedPct += 5;
    if (equippedAvatarId == 'arcane_wizard') cappedPct += 10;
    if (cappedPct > 50) cappedPct = 50;

    final int uncappedPct = fertilizerId == 'mystic_potion' ? 100 : 0;
    coins += (coins * (cappedPct + uncappedPct)) ~/ 100;

    // Stone Fountain: only fires on actually-healthy plots — modifier
    // rescues that change `effective` don't satisfy it. Cheap flat
    // payout, outside the cap.
    if (hasStoneFountain && finalState == PlotFinalState.harvested) {
      coins += 1;
    }

    return coins;
  }

  CycleResultTier _liftTier(CycleResultTier t) {
    switch (t) {
      case CycleResultTier.negative:
        return CycleResultTier.barelyPositive;
      case CycleResultTier.barelyPositive:
        return CycleResultTier.solidlyPositive;
      case CycleResultTier.solidlyPositive:
        return CycleResultTier.excellent;
      case CycleResultTier.excellent:
        return CycleResultTier.excellent;
    }
  }

  int _overallBonusForTier(CycleResultTier t) => switch (t) {
        CycleResultTier.excellent => 40,
        CycleResultTier.solidlyPositive => 20,
        CycleResultTier.barelyPositive => 10,
        CycleResultTier.negative => 0,
      };

  Future<void> _writeCoinPayouts({
    required int cycleId,
    required CyclePreview preview,
    required int surplusSavedCoins,
    required int occurredAt,
  }) async {
    for (final r in preview.plotResults) {
      if (r.isUnplanned) continue;
      if (r.coinsEarned == 0) continue;
      await _db.into(_db.coinLedger).insert(
            CoinLedgerCompanion.insert(
              cycleId: Value(cycleId),
              amount: r.coinsEarned,
              reason: CoinReason.plotHarvestedHealthy,
              relatedId: Value(r.plotId),
              relatedType: const Value('plot'),
              description: Value(r.plotName),
              occurredAt: occurredAt,
            ),
          );
    }
    if (preview.unplannedHealthyCoins > 0) {
      await _db.into(_db.coinLedger).insert(
            CoinLedgerCompanion.insert(
              cycleId: Value(cycleId),
              amount: preview.unplannedHealthyCoins,
              reason: CoinReason.unplannedHealthyShare,
              occurredAt: occurredAt,
            ),
          );
    }
    if (preview.overallBonusCoins > 0) {
      await _db.into(_db.coinLedger).insert(
            CoinLedgerCompanion.insert(
              cycleId: Value(cycleId),
              amount: preview.overallBonusCoins,
              reason: CoinReason.cycleOverallPositive,
              occurredAt: occurredAt,
            ),
          );
    }
    if (preview.comboBonusCoins > 0) {
      await _db.into(_db.coinLedger).insert(
            CoinLedgerCompanion.insert(
              cycleId: Value(cycleId),
              amount: preview.comboBonusCoins,
              reason: CoinReason.cycleComboBonus,
              occurredAt: occurredAt,
            ),
          );
    }
    if (surplusSavedCoins > 0) {
      await _db.into(_db.coinLedger).insert(
            CoinLedgerCompanion.insert(
              cycleId: Value(cycleId),
              amount: surplusSavedCoins,
              reason: CoinReason.surplusSaved,
              occurredAt: occurredAt,
            ),
          );
    }
  }

  // Cycle-start seed consumption. Iterates every active plot whose crop
  // is consumable and decrements `owned_items.quantity` by 1. If stock
  // is zero, swaps that plot to wheat (the no-cost starter) for the new
  // cycle. Mirrors PlotRepository._consumeSeedIfConsumable but applied
  // in bulk at hand-off.
  Future<void> _consumeCycleStartSeeds() async {
    final activePlots = await (_db.select(_db.plots)
          ..where((t) => t.isActive.equals(true) & t.isUnplanned.equals(false)))
        .get();
    for (final p in activePlots) {
      final crop = await (_db.select(_db.cropsCatalog)
            ..where((t) => t.cropId.equals(p.cropTypeId)))
          .getSingleOrNull();
      if (crop == null || !crop.isConsumable) continue;
      final owned = await (_db.select(_db.ownedItems)
            ..where((t) => t.itemId.equals(p.cropTypeId)))
          .getSingleOrNull();
      if (owned != null && owned.quantity >= 1) {
        await (_db.update(_db.ownedItems)..where((t) => t.id.equals(owned.id)))
            .write(OwnedItemsCompanion(quantity: Value(owned.quantity - 1)));
      } else {
        await (_db.update(_db.plots)..where((t) => t.id.equals(p.id))).write(
          const PlotsCompanion(cropTypeId: Value('wheat')),
        );
      }
    }
  }
}

// ──────────────────────────────────────────────────────────────────────
// Preview value objects — shared between the harvest preview step and
// the actual persistence in closeAndStartNext.

class CyclePreview {
  const CyclePreview({
    required this.cycle,
    required this.plotResults,
    required this.totalFoundationIncome,
    required this.totalBonusIncome,
    required this.totalSpentPlanned,
    required this.totalSpentUnplanned,
    required this.totalSpent,
    required this.surplus,
    required this.resultTier,
    required this.perPlotCoins,
    required this.unplannedHealthyCoins,
    required this.overallBonusCoins,
    required this.comboBonusCoins,
    required this.baseCurrencyCode,
    required this.baseCurrencyDecimals,
    required this.plantingPlan,
  });

  final CycleRow cycle;
  final List<PlotResultPreview> plotResults;
  final int totalFoundationIncome;
  final int totalBonusIncome;
  final int totalSpentPlanned;
  final int totalSpentUnplanned;
  final int totalSpent;
  final int surplus;
  final CycleResultTier resultTier;
  final int perPlotCoins;
  final int unplannedHealthyCoins;
  final int overallBonusCoins;
  final int comboBonusCoins;
  final String baseCurrencyCode;
  final int baseCurrencyDecimals;
  // What each active non-Unplanned plot intends to plant at the start of
  // the next cycle, paired with the user's current seed inventory. Empty
  // when no regular plots exist. Drives the planting-plan card on the
  // begin-next step so the user sees premium-crop costs and shortages
  // before the cycle commits (rather than discovering silent wheat
  // fallback after the fact).
  final List<PlotPlanEntry> plantingPlan;

  // Coins guaranteed regardless of the user's surplus split decision —
  // displayed on the preview step before the slider.
  int get baselineCoins =>
      perPlotCoins +
      unplannedHealthyCoins +
      overallBonusCoins +
      comboBonusCoins;
}

// One row of the next cycle's planting plan: the plot, the crop it
// intends to grow, and whether the user currently owns enough seeds to
// cover the cycle-start deduction. Computed in _buildPreview from the
// same active-plots query used elsewhere; the UI reads this directly.
class PlotPlanEntry {
  const PlotPlanEntry({
    required this.plotId,
    required this.plotName,
    required this.plotColorId,
    required this.cropTypeId,
    required this.cropName,
    required this.isConsumable,
    required this.isStarter,
    required this.seedsOwned,
  });

  final int plotId;
  final String plotName;
  final String? plotColorId;
  final String cropTypeId;
  final String cropName;
  final bool isConsumable;
  final bool isStarter;
  final int seedsOwned;

  // True iff committing the cycle would auto-revert this plot to wheat
  // (consumable crop with zero stock at cycle start). Starters and
  // crops with stock ≥ 1 are fine.
  bool get hasShortage => isConsumable && seedsOwned < 1;
}

class PlotResultPreview {
  const PlotResultPreview({
    required this.plotId,
    required this.plotName,
    required this.kind,
    required this.isUnplanned,
    required this.cropTypeId,
    required this.plotColorId,
    required this.currencyCode,
    required this.budgetAmountBase,
    required this.totalSpentBase,
    required this.finalState,
    required this.incomeShareAtClose,
    required this.coinsEarned,
  });

  final int plotId;
  final String plotName;
  final PlotKind kind;
  final bool isUnplanned;
  final String cropTypeId;
  final String? plotColorId;
  final String currencyCode;
  final int? budgetAmountBase;
  final int totalSpentBase;
  final PlotFinalState finalState;
  final double? incomeShareAtClose;
  final int coinsEarned;
}

final WellRow _missingWell = WellRow(
  id: -1,
  name: '',
  wellType: WellType.bonus,
  isCarryover: false,
  currencyCode: '',
  wellIconId: 'default',
  isActive: false,
  displayOrder: 0,
  createdAt: 0,
);
