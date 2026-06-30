import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/app_settings.dart';
import 'tables/badges_earned.dart';
import 'tables/bonus_allocations.dart';
import 'tables/coin_ledger.dart';
import 'tables/crops_catalog.dart';
import 'tables/currencies.dart';
import 'tables/cycle_summaries.dart';
import 'tables/cycles.dart';
import 'tables/enum_converters.dart';
import 'tables/exchange_rates.dart';
import 'tables/income_entries.dart';
import 'tables/owned_items.dart';
import 'tables/plot_cycle_results.dart';
import 'tables/plot_fertilizer_applications.dart';
import 'tables/plots.dart';
import 'tables/savings_barn.dart';
import 'tables/transactions.dart';
import 'tables/wells.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  AppSettings,
  Currencies,
  Cycles,
  CycleSummaries,
  ExchangeRates,
  Wells,
  IncomeEntries,
  BonusAllocations,
  SavingsBarn,
  Plots,
  Transactions,
  PlotCycleResults,
  PlotFertilizerApplications,
  CoinLedger,
  BadgesEarned,
  CropsCatalog,
  OwnedItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'cropkeep'));

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          for (final stmt in _indexStatements) {
            await customStatement(stmt);
          }
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(appSettings, appSettings.notificationsEnabled);
            // plots: + kind, due_day, plus three new CHECK constraints.
            await m.alterTable(TableMigration(plots));
            // plot_cycle_results: + kind_snapshot, plus new CHECK.
            await m.alterTable(TableMigration(plotCycleResults));
            // coin_ledger: 'crop_set_bonus' added to reason CHECK.
            await m.alterTable(TableMigration(coinLedger));
            // crops_catalog: + is_consumable, seed_pack_size, plus new CHECK.
            await m.alterTable(TableMigration(cropsCatalog));
            for (final stmt in _v2NewIndexStatements) {
              await customStatement(stmt);
            }
          }
          if (from < 3) {
            // Widening the plot-kind enum from {discretionary,
            // fixed_obligation} to also include 'investment'. SQLite can't
            // ALTER a CHECK constraint in place, so both tables holding the
            // enum are recreated to pick up the new constraint plus the
            // loosened due_day requirement (now only fixed_obligation
            // requires due_day).
            await m.alterTable(TableMigration(plots));
            await m.alterTable(TableMigration(plotCycleResults));
          }
        },
      );
}

const _v2NewIndexStatements = <String>[
  'CREATE INDEX IF NOT EXISTS idx_plots_kind ON plots(kind)',
  'CREATE INDEX IF NOT EXISTS idx_crops_catalog_consumable '
      'ON crops_catalog(is_consumable)',
];

const _indexStatements = <String>[
  // cycles
  'CREATE INDEX idx_cycles_state ON cycles(state)',
  'CREATE INDEX idx_cycles_dates ON cycles(start_date, end_date)',
  // cycle_summaries
  'CREATE INDEX idx_cycle_summary_tier ON cycle_summaries(result_tier)',
  // exchange_rates
  'CREATE INDEX idx_rates_cycle ON exchange_rates(cycle_id)',
  // wells
  'CREATE INDEX idx_wells_type ON wells(well_type)',
  'CREATE INDEX idx_wells_active ON wells(is_active)',
  'CREATE UNIQUE INDEX idx_wells_carryover ON wells(is_carryover) '
      'WHERE is_carryover = 1',
  // income_entries
  'CREATE INDEX idx_income_cycle ON income_entries(cycle_id)',
  'CREATE INDEX idx_income_well ON income_entries(well_id)',
  'CREATE INDEX idx_income_received ON income_entries(received_at)',
  'CREATE INDEX idx_income_deleted ON income_entries(deleted_at)',
  // bonus_allocations
  'CREATE INDEX idx_bonus_alloc_cycle ON bonus_allocations(cycle_id)',
  // plots
  'CREATE INDEX idx_plots_active ON plots(is_active)',
  'CREATE INDEX idx_plots_kind ON plots(kind)',
  'CREATE UNIQUE INDEX idx_plots_unplanned ON plots(is_unplanned) '
      'WHERE is_unplanned = 1',
  // transactions
  'CREATE INDEX idx_txn_plot ON transactions(plot_id)',
  'CREATE INDEX idx_txn_cycle ON transactions(cycle_id)',
  'CREATE INDEX idx_txn_spent ON transactions(spent_at)',
  'CREATE INDEX idx_txn_plot_cycle ON transactions(plot_id, cycle_id)',
  'CREATE INDEX idx_txn_deleted ON transactions(deleted_at)',
  'CREATE INDEX idx_txn_emergency ON transactions(is_emergency) '
      'WHERE is_emergency = 1',
  // plot_cycle_results
  'CREATE INDEX idx_pcr_cycle ON plot_cycle_results(cycle_id)',
  'CREATE INDEX idx_pcr_plot ON plot_cycle_results(plot_id)',
  'CREATE INDEX idx_pcr_final_state ON plot_cycle_results(final_state)',
  // plot_fertilizer_applications
  'CREATE INDEX idx_pfa_cycle_plot '
      'ON plot_fertilizer_applications(cycle_id, plot_id)',
  // coin_ledger
  'CREATE INDEX idx_coin_cycle ON coin_ledger(cycle_id)',
  'CREATE INDEX idx_coin_occurred ON coin_ledger(occurred_at)',
  'CREATE INDEX idx_coin_reason ON coin_ledger(reason)',
  // crops_catalog
  'CREATE INDEX idx_crops_catalog_starter ON crops_catalog(is_starter)',
  'CREATE INDEX idx_crops_catalog_consumable ON crops_catalog(is_consumable)',
  // owned_items
  'CREATE INDEX idx_owned_items_type ON owned_items(item_type)',
];
