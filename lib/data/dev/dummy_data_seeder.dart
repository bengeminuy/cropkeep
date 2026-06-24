import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/cycle_summaries.dart';
import '../tables/cycles.dart';
import '../tables/plot_cycle_results.dart';
import '../tables/wells.dart';

// All demo transaction/income notes start with this prefix so they can be
// hard-deleted in cleanup without relying on FK cascades. The prefix is
// visible in the Ledger UI on purpose — it visually signals "this row is
// fake" while the seeder is loaded.
const String _demoNotePrefix = '[demo] ';

// Visual-preview seeder for the farmer screen. Writes a leveled-up profile,
// a populated savings barn, and 12 months of completed cycles with a varied
// spread of result tiers and plot states. All dummy cycles are labeled
// 'demo' so [clear] can remove just the demo rows without touching real data.
class DummyDataSeeder {
  const DummyDataSeeder._();

  static const String _demoLabel = 'demo';

  static Stream<bool> watchHasDemo(AppDatabase db) {
    return (db.select(db.cycles)..where((t) => t.label.equals(_demoLabel)))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

  static Future<void> seedFarmerScreen(AppDatabase db) async {
    final settings = await (db.select(db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (settings == null) return;
    final baseCode = settings.baseCurrencyCode;

    final already = await (db.select(db.cycles)
          ..where((t) => t.label.equals(_demoLabel)))
        .get();
    if (already.isNotEmpty) return;

    await db.transaction(() async {
      final now = DateTime.now();
      final nowMs = now.millisecondsSinceEpoch;

      // Inactive demo plots — kept off the farm screen but valid FK targets
      // for the snapshot rows below.
      const demoPlots = <_DemoPlot>[
        _DemoPlot('Groceries', 'wheat', 'peach'),
        _DemoPlot('Dining out', 'wheat', 'butter'),
        _DemoPlot('Transport', 'apple', 'sky'),
        _DemoPlot('Entertainment', 'apple', 'lavender'),
        _DemoPlot('Bills', 'potato', 'pink'),
      ];
      final plotIds = <int>[];
      for (final p in demoPlots) {
        final id = await db.into(db.plots).insert(
              PlotsCompanion.insert(
                name: p.name,
                cropTypeId: p.cropId,
                currencyCode: baseCode,
                plotColorId: Value(p.colorId),
                isActive: const Value(false),
                createdAt: nowMs,
              ),
            );
        plotIds.add(id);
      }

      final unplanned = await (db.select(db.plots)
            ..where((t) => t.isUnplanned.equals(true)))
          .getSingleOrNull();

      // Inactive demo wells — same isolation trick as demo plots. Cleanup
      // removes any well that's inactive + not the Carryover well.
      const demoWells = <_DemoWell>[
        _DemoWell('Salary', WellType.foundation, expected: 320000),
        _DemoWell('Freelance', WellType.bonus, estimateMin: 50000, estimateMax: 200000),
        _DemoWell('Rental income', WellType.foundation, expected: 80000),
      ];
      final wellIds = <int>[];
      for (final w in demoWells) {
        final id = await db.into(db.wells).insert(
              WellsCompanion.insert(
                name: w.name,
                wellType: w.type,
                currencyCode: baseCode,
                expectedAmount: Value(w.expected),
                estimateMin: Value(w.estimateMin),
                estimateMax: Value(w.estimateMax),
                isActive: const Value(false),
                createdAt: nowMs,
              ),
            );
        wellIds.add(id);
      }
      // Aliases for readability in the seeded transactions below.
      final salaryWellId = wellIds[0];
      final freelanceWellId = wellIds[1];
      final rentalWellId = wellIds[2];

      // Map demo cycle plans to a cycle id keyed by monthsAgo so we can
      // attach transactions/incomes to specific past months below.
      final cycleIdByMonthsAgo = <int, int>{};

      var totalSaved = 0;
      for (final plan in _cyclePlan) {
        final startD = DateTime(now.year, now.month - plan.monthsAgo, 1);
        final endD = DateTime(now.year, now.month - plan.monthsAgo + 1, 0);
        final startMs = startD.millisecondsSinceEpoch;
        final endMs = endD.millisecondsSinceEpoch;

        final cycleId = await db.into(db.cycles).insert(
              CyclesCompanion.insert(
                startDate: startMs,
                endDate: endMs,
                state: CycleState.completed,
                label: const Value(_demoLabel),
                createdAt: startMs,
                completedAt: Value(endMs),
              ),
            );
        cycleIdByMonthsAgo[plan.monthsAgo] = cycleId;

        await db.into(db.cycleSummaries).insert(
              CycleSummariesCompanion.insert(
                cycleId: cycleId,
                totalFoundationIncome: plan.foundationIncome,
                totalBonusIncome: plan.bonusIncome,
                totalSpentPlanned: plan.spentPlanned,
                totalSpentUnplanned: plan.spentUnplanned,
                totalSpent: plan.spentPlanned + plan.spentUnplanned,
                surplus: plan.surplus,
                resultTier: plan.tier,
                amountSaved: Value(plan.saved),
                amountRolledToNext: Value(plan.rolled),
                completedAt: endMs,
              ),
            );
        totalSaved += plan.saved;

        if (unplanned != null) {
          await db.into(db.plotCycleResults).insert(
                PlotCycleResultsCompanion.insert(
                  cycleId: cycleId,
                  plotId: unplanned.id,
                  plotNameSnapshot: 'Unplanned',
                  cropTypeIdSnapshot: 'unplanned',
                  plotColorIdSnapshot: const Value('sand'),
                  isUnplanned: const Value(true),
                  currencyCodeSnapshot: baseCode,
                  totalSpent: plan.spentUnplanned,
                  finalState: plan.unplannedState,
                  completedAt: endMs,
                ),
              );
        }

        for (var i = 0;
            i < plan.plotStates.length && i < plotIds.length;
            i++) {
          await db.into(db.plotCycleResults).insert(
                PlotCycleResultsCompanion.insert(
                  cycleId: cycleId,
                  plotId: plotIds[i],
                  plotNameSnapshot: demoPlots[i].name,
                  cropTypeIdSnapshot: demoPlots[i].cropId,
                  plotColorIdSnapshot: Value(demoPlots[i].colorId),
                  currencyCodeSnapshot: baseCode,
                  totalSpent: 40000 + i * 6500,
                  finalState: plan.plotStates[i],
                  completedAt: endMs,
                ),
              );
        }
      }

      await (db.update(db.savingsBarn)..where((t) => t.id.equals(1))).write(
        SavingsBarnCompanion(
          totalSaved: Value(totalSaved),
          lastUpdatedAt: Value(nowMs),
        ),
      );

      // ─────────────────────────────────────────────────────────────
      // Ledger seed — transactions + income entries on the active cycle
      // plus the two most recent demo cycles. Notes are prefixed with
      // `[demo]` so clearDummyData can hard-delete them without touching
      // any real user entries.

      final activeCycle = await (db.select(db.cycles)
            ..where((t) => t.state.equalsValue(CycleState.active)))
          .getSingleOrNull();
      final carryover = await (db.select(db.wells)
            ..where((t) => t.isCarryover.equals(true)))
          .getSingleOrNull();

      // Maps demo-plot name → row id so we can attach transactions by name.
      int plotIdNamed(String name) {
        final i = demoPlots.indexWhere((p) => p.name == name);
        return plotIds[i];
      }

      // Insert helper: a single demo expense. `daysAgo` measured from now.
      Future<void> addExpense({
        required int cycleId,
        required int plotId,
        required int daysAgo,
        required int hour,
        int minute = 0,
        required int amountMinor,
        required String note,
        bool isEmergency = false,
        int? editedDaysAgo,
      }) async {
        final ts = DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
        final editedAt = editedDaysAgo == null
            ? null
            : DateTime(
                now.year,
                now.month,
                now.day - editedDaysAgo,
                hour,
                minute,
              ).millisecondsSinceEpoch;
        await db.into(db.transactions).insert(
              TransactionsCompanion.insert(
                plotId: plotId,
                cycleId: cycleId,
                amount: amountMinor,
                currencyCode: baseCode,
                baseAmount: amountMinor,
                plotAmount: amountMinor,
                exchangeRate: 1.0,
                spentAt: ts.millisecondsSinceEpoch,
                note: Value(_demoNotePrefix + note),
                isEmergency: Value(isEmergency),
                createdAt: ts.millisecondsSinceEpoch,
                editedAt: Value(editedAt),
              ),
            );
      }

      Future<void> addIncome({
        required int wellId,
        required int cycleId,
        required int daysAgo,
        required int hour,
        int minute = 0,
        required int amountMinor,
        required String note,
        bool isSystemGenerated = false,
      }) async {
        final ts = DateTime(now.year, now.month, now.day - daysAgo, hour, minute);
        await db.into(db.incomeEntries).insert(
              IncomeEntriesCompanion.insert(
                wellId: wellId,
                cycleId: cycleId,
                amount: amountMinor,
                currencyCode: baseCode,
                baseAmount: amountMinor,
                exchangeRate: 1.0,
                receivedAt: ts.millisecondsSinceEpoch,
                note: Value(_demoNotePrefix + note),
                isSystemGenerated: Value(isSystemGenerated),
                createdAt: ts.millisecondsSinceEpoch,
              ),
            );
      }

      Future<void> addSoftDeletedExpense({
        required int cycleId,
        required int plotId,
        required int daysAgo,
        required int hour,
        required int deletedDaysAgo,
        required int amountMinor,
        required String note,
      }) async {
        final spentTs =
            DateTime(now.year, now.month, now.day - daysAgo, hour).millisecondsSinceEpoch;
        final delTs =
            DateTime(now.year, now.month, now.day - deletedDaysAgo, hour + 1)
                .millisecondsSinceEpoch;
        await db.into(db.transactions).insert(
              TransactionsCompanion.insert(
                plotId: plotId,
                cycleId: cycleId,
                amount: amountMinor,
                currencyCode: baseCode,
                baseAmount: amountMinor,
                plotAmount: amountMinor,
                exchangeRate: 1.0,
                spentAt: spentTs,
                note: Value(_demoNotePrefix + note),
                createdAt: spentTs,
                deletedAt: Value(delTs),
              ),
            );
      }

      // Active cycle entries — these become the default Ledger view.
      if (activeCycle != null && unplanned != null) {
        final cycleId = activeCycle.id;
        final groceries = plotIdNamed('Groceries');
        final dining = plotIdNamed('Dining out');
        final transport = plotIdNamed('Transport');
        final entertainment = plotIdNamed('Entertainment');
        final bills = plotIdNamed('Bills');

        // Today
        await addExpense(
          cycleId: cycleId,
          plotId: groceries,
          daysAgo: 0,
          hour: 9,
          minute: 24,
          amountMinor: 3247,
          note: 'Costco run',
        );
        await addExpense(
          cycleId: cycleId,
          plotId: entertainment,
          daysAgo: 0,
          hour: 14,
          minute: 30,
          amountMinor: 1099,
          note: 'Spotify',
        );

        // Yesterday
        await addExpense(
          cycleId: cycleId,
          plotId: dining,
          daysAgo: 1,
          hour: 12,
          minute: 45,
          amountMinor: 4820,
          note: 'Lunch with team',
        );
        await addExpense(
          cycleId: cycleId,
          plotId: bills,
          daysAgo: 1,
          hour: 8,
          amountMinor: 120000,
          note: 'Monthly rent',
        );

        // 2 days ago — includes a paycheck and an edited transaction
        await addIncome(
          wellId: salaryWellId,
          cycleId: cycleId,
          daysAgo: 2,
          hour: 10,
          amountMinor: 300000,
          note: 'June paycheck',
        );
        await addExpense(
          cycleId: cycleId,
          plotId: transport,
          daysAgo: 2,
          hour: 17,
          minute: 20,
          amountMinor: 2500,
          note: 'Bus pass',
          editedDaysAgo: 1,
        );

        // 3 days ago
        await addExpense(
          cycleId: cycleId,
          plotId: groceries,
          daysAgo: 3,
          hour: 15,
          minute: 30,
          amountMinor: 8043,
          note: "Trader Joe's",
        );
        await addIncome(
          wellId: freelanceWellId,
          cycleId: cycleId,
          daysAgo: 3,
          hour: 11,
          amountMinor: 24000,
          note: 'Logo design',
        );

        // 5 days ago — emergency on the Unplanned plot
        await addExpense(
          cycleId: cycleId,
          plotId: unplanned.id,
          daysAgo: 5,
          hour: 13,
          amountMinor: 3500,
          note: 'Vet bill',
          isEmergency: true,
        );

        // 7 days ago — locked Carryover income (rollover from last cycle)
        if (carryover != null) {
          await addIncome(
            wellId: carryover.id,
            cycleId: cycleId,
            daysAgo: 7,
            hour: 0,
            minute: 1,
            amountMinor: 50000,
            note: 'Rollover from May',
            isSystemGenerated: true,
          );
        }

        // Spread a few more entries through the cycle so older cycles are
        // visually distinct from "current days only".
        await addExpense(
          cycleId: cycleId,
          plotId: entertainment,
          daysAgo: 9,
          hour: 18,
          amountMinor: 2400,
          note: 'Movie tickets',
        );
        await addExpense(
          cycleId: cycleId,
          plotId: dining,
          daysAgo: 12,
          hour: 9,
          amountMinor: 1450,
          note: 'Coffee shop',
        );
        await addIncome(
          wellId: rentalWellId,
          cycleId: cycleId,
          daysAgo: 14,
          hour: 8,
          amountMinor: 80000,
          note: 'Cottage rent',
        );

        // Soft-deleted entries (within 30 days) — feeds Recently removed.
        await addSoftDeletedExpense(
          cycleId: cycleId,
          plotId: dining,
          daysAgo: 2,
          hour: 19,
          deletedDaysAgo: 1,
          amountMinor: 1500,
          note: 'Double-logged tip',
        );
        await addSoftDeletedExpense(
          cycleId: cycleId,
          plotId: groceries,
          daysAgo: 6,
          hour: 11,
          deletedDaysAgo: 5,
          amountMinor: 4200,
          note: 'Wrong amount',
        );
      }

      // Older cycles — sprinkle a few entries on the two most recent demo
      // cycles so "Show older cycles" reveals actual content.
      Future<void> seedPastCycle({
        required int monthsAgo,
        required int spentMonth,
        required int hour,
      }) async {
        final cycleId = cycleIdByMonthsAgo[monthsAgo];
        if (cycleId == null) return;
        // Pick a representative day in that month — first of month.
        final cycleMonth = DateTime(now.year, now.month - monthsAgo, 5);
        final daysAgo = now.difference(cycleMonth).inDays;
        final groceries = plotIdNamed('Groceries');
        final dining = plotIdNamed('Dining out');
        final bills = plotIdNamed('Bills');
        final entertainment = plotIdNamed('Entertainment');

        await addExpense(
          cycleId: cycleId,
          plotId: groceries,
          daysAgo: daysAgo,
          hour: hour,
          amountMinor: 7500 + spentMonth,
          note: 'Weekly groceries',
        );
        await addExpense(
          cycleId: cycleId,
          plotId: dining,
          daysAgo: daysAgo - 4,
          hour: hour + 2,
          amountMinor: 3200 + spentMonth,
          note: 'Date night',
        );
        await addExpense(
          cycleId: cycleId,
          plotId: bills,
          daysAgo: daysAgo - 8,
          hour: 7,
          amountMinor: 120000,
          note: 'Monthly rent',
        );
        await addExpense(
          cycleId: cycleId,
          plotId: entertainment,
          daysAgo: daysAgo - 10,
          hour: 20,
          amountMinor: 1899,
          note: 'Streaming bundle',
        );
        await addIncome(
          wellId: salaryWellId,
          cycleId: cycleId,
          daysAgo: daysAgo - 2,
          hour: 9,
          amountMinor: 300000,
          note: 'Paycheck',
        );
        if (monthsAgo == 1) {
          await addIncome(
            wellId: freelanceWellId,
            cycleId: cycleId,
            daysAgo: daysAgo - 5,
            hour: 14,
            amountMinor: 12500,
            note: 'Side gig',
          );
        }
      }

      // monthsAgo=0 is the live active cycle — entries for it were seeded
      // above. Demo content for past cycles starts at monthsAgo=1.
      await seedPastCycle(monthsAgo: 1, spentMonth: 250, hour: 12);
      await seedPastCycle(monthsAgo: 2, spentMonth: 500, hour: 10);
      await seedPastCycle(monthsAgo: 3, spentMonth: 350, hour: 14);

      // Level 8 mid-progress puts the ring at ~56% and labels the farmer
      // a Sapling — populated but with visible headroom on the bar.
      await (db.update(db.appSettings)..where((t) => t.id.equals(1))).write(
        const AppSettingsCompanion(
          farmerLevel: Value(8),
          farmerXp: Value(2380),
          coinsBalance: Value(1240),
        ),
      );
    });
  }

  static Future<void> clearDummyData(AppDatabase db) async {
    await db.transaction(() async {
      final demoCycles = await (db.select(db.cycles)
            ..where((t) => t.label.equals(_demoLabel)))
          .get();
      if (demoCycles.isEmpty) return;
      final demoCycleIds = [for (final c in demoCycles) c.id];

      // Delete seeded transactions + incomes first so the demo plots/wells
      // can be deleted without FK violations. Match by the `[demo]` note
      // prefix — covers both demo-cycle and active-cycle seeded entries.
      await (db.delete(db.transactions)
            ..where((t) => t.note.like('$_demoNotePrefix%')))
          .go();
      await (db.delete(db.incomeEntries)
            ..where((t) => t.note.like('$_demoNotePrefix%')))
          .go();

      await (db.delete(db.plotCycleResults)
            ..where((t) => t.cycleId.isIn(demoCycleIds)))
          .go();
      await (db.delete(db.cycleSummaries)
            ..where((t) => t.cycleId.isIn(demoCycleIds)))
          .go();
      await (db.delete(db.cycles)
            ..where((t) => t.label.equals(_demoLabel)))
          .go();

      // Demo plots are inactive and don't appear in onboarding — anything
      // left inactive is ours to remove.
      await (db.delete(db.plots)
            ..where((t) =>
                t.isActive.equals(false) & t.isUnplanned.equals(false)))
          .go();
      // Demo wells are inactive; the Carryover well is the only inactive
      // well that's NOT ours, so it's explicitly excluded.
      await (db.delete(db.wells)
            ..where((t) =>
                t.isActive.equals(false) & t.isCarryover.equals(false)))
          .go();

      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await (db.update(db.savingsBarn)..where((t) => t.id.equals(1))).write(
        SavingsBarnCompanion(
          totalSaved: const Value(0),
          lastUpdatedAt: Value(nowMs),
        ),
      );
      await (db.update(db.appSettings)..where((t) => t.id.equals(1))).write(
        const AppSettingsCompanion(
          farmerLevel: Value(1),
          farmerXp: Value(0),
          coinsBalance: Value(0),
        ),
      );
    });
  }
}

class _DemoPlot {
  const _DemoPlot(this.name, this.cropId, this.colorId);
  final String name;
  final String cropId;
  // Placeholder id from the in-app swatch palette. Resolved to a Color
  // by `_swatchForColorId` on the farmer screen. When the real plot-color
  // catalog lands, these strings become FK references.
  final String colorId;
}

class _DemoWell {
  const _DemoWell(
    this.name,
    this.type, {
    this.expected,
    this.estimateMin,
    this.estimateMax,
  });
  final String name;
  final WellType type;
  final int? expected;
  final int? estimateMin;
  final int? estimateMax;
}

class _DemoCycle {
  const _DemoCycle({
    required this.monthsAgo,
    required this.foundationIncome,
    required this.bonusIncome,
    required this.spentPlanned,
    required this.spentUnplanned,
    required this.surplus,
    required this.tier,
    required this.saved,
    required this.rolled,
    required this.plotStates,
    this.unplannedState = PlotFinalState.harvested,
  });

  final int monthsAgo;
  final int foundationIncome;
  final int bonusIncome;
  final int spentPlanned;
  final int spentUnplanned;
  final int surplus;
  final CycleResultTier tier;
  final int saved;
  final int rolled;
  final List<PlotFinalState> plotStates;
  final PlotFinalState unplannedState;
}

// Amounts are minor units (USD: cents). Oldest first; renders newest-first in
// the harvest ribbon. Mix of tiers keeps every card variant visible.
const _cyclePlan = <_DemoCycle>[
  _DemoCycle(
    monthsAgo: 11,
    foundationIncome: 320000,
    bonusIncome: 0,
    spentPlanned: 320000,
    spentUnplanned: 120000,
    surplus: -120000,
    tier: CycleResultTier.negative,
    saved: 0,
    rolled: 0,
    plotStates: [
      PlotFinalState.mildStress,
      PlotFinalState.withered,
      PlotFinalState.harvested,
      PlotFinalState.dead,
      PlotFinalState.mildStress,
    ],
    unplannedState: PlotFinalState.withered,
  ),
  _DemoCycle(
    monthsAgo: 10,
    foundationIncome: 320000,
    bonusIncome: 15000,
    spentPlanned: 295000,
    spentUnplanned: 32000,
    surplus: 8000,
    tier: CycleResultTier.barelyPositive,
    saved: 8000,
    rolled: 0,
    plotStates: [
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
      PlotFinalState.harvested,
    ],
  ),
  _DemoCycle(
    monthsAgo: 9,
    foundationIncome: 330000,
    bonusIncome: 20000,
    spentPlanned: 280000,
    spentUnplanned: 38000,
    surplus: 32000,
    tier: CycleResultTier.solidlyPositive,
    saved: 25000,
    rolled: 7000,
    plotStates: [
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
      PlotFinalState.harvested,
    ],
  ),
  _DemoCycle(
    monthsAgo: 8,
    foundationIncome: 350000,
    bonusIncome: 45000,
    spentPlanned: 290000,
    spentUnplanned: 30000,
    surplus: 75000,
    tier: CycleResultTier.excellent,
    saved: 50000,
    rolled: 25000,
    plotStates: [
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
    ],
  ),
  _DemoCycle(
    monthsAgo: 7,
    foundationIncome: 330000,
    bonusIncome: 18000,
    spentPlanned: 285000,
    spentUnplanned: 35000,
    surplus: 28000,
    tier: CycleResultTier.solidlyPositive,
    saved: 20000,
    rolled: 8000,
    plotStates: [
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
    ],
  ),
  _DemoCycle(
    monthsAgo: 6,
    foundationIncome: 320000,
    bonusIncome: 10000,
    spentPlanned: 290000,
    spentUnplanned: 35000,
    surplus: 5000,
    tier: CycleResultTier.barelyPositive,
    saved: 5000,
    rolled: 0,
    plotStates: [
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
      PlotFinalState.withered,
      PlotFinalState.harvested,
    ],
    unplannedState: PlotFinalState.mildStress,
  ),
  _DemoCycle(
    monthsAgo: 5,
    foundationIncome: 320000,
    bonusIncome: 0,
    spentPlanned: 310000,
    spentUnplanned: 55000,
    surplus: -45000,
    tier: CycleResultTier.negative,
    saved: 0,
    rolled: 0,
    plotStates: [
      PlotFinalState.mildStress,
      PlotFinalState.withered,
      PlotFinalState.harvested,
      PlotFinalState.withered,
      PlotFinalState.mildStress,
    ],
    unplannedState: PlotFinalState.dead,
  ),
  _DemoCycle(
    monthsAgo: 4,
    foundationIncome: 340000,
    bonusIncome: 25000,
    spentPlanned: 295000,
    spentUnplanned: 28000,
    surplus: 42000,
    tier: CycleResultTier.solidlyPositive,
    saved: 30000,
    rolled: 12000,
    plotStates: [
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
      PlotFinalState.harvested,
    ],
  ),
  _DemoCycle(
    monthsAgo: 3,
    foundationIncome: 360000,
    bonusIncome: 55000,
    spentPlanned: 295000,
    spentUnplanned: 32000,
    surplus: 88000,
    tier: CycleResultTier.excellent,
    saved: 60000,
    rolled: 28000,
    plotStates: [
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
    ],
  ),
  _DemoCycle(
    monthsAgo: 2,
    foundationIncome: 340000,
    bonusIncome: 20000,
    spentPlanned: 295000,
    spentUnplanned: 30000,
    surplus: 35000,
    tier: CycleResultTier.solidlyPositive,
    saved: 25000,
    rolled: 10000,
    plotStates: [
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
    ],
  ),
  _DemoCycle(
    monthsAgo: 1,
    foundationIncome: 330000,
    bonusIncome: 12000,
    spentPlanned: 295000,
    spentUnplanned: 35000,
    surplus: 12000,
    tier: CycleResultTier.barelyPositive,
    saved: 12000,
    rolled: 0,
    plotStates: [
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
      PlotFinalState.harvested,
      PlotFinalState.harvested,
      PlotFinalState.mildStress,
    ],
  ),
  // monthsAgo=0 (the current month) is intentionally omitted — that month
  // belongs to the live active cycle, not to a completed-and-summarised
  // history row.
];
