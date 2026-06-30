import 'package:flutter/widgets.dart';

import 'data/database.dart';
import 'data/pending_rates_store.dart';
import 'data/repositories/app_settings_repository.dart';
import 'data/repositories/cycle_repository.dart';
import 'data/repositories/exchange_rate_repository.dart';
import 'data/repositories/fertilizer_repository.dart';
import 'data/repositories/income_entry_repository.dart';
import 'data/repositories/market_repository.dart';
import 'data/repositories/plot_repository.dart';
import 'data/repositories/savings_barn_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/well_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.database,
    required this.appSettings,
    required this.savingsBarn,
    required this.transactions,
    required this.incomeEntries,
    required this.market,
    required this.plots,
    required this.wells,
    required this.cycles,
    required this.exchangeRates,
    required this.fertilizers,
    required this.pendingRates,
    required super.child,
  });

  final AppDatabase database;
  final AppSettingsRepository appSettings;
  final SavingsBarnRepository savingsBarn;
  final TransactionRepository transactions;
  final IncomeEntryRepository incomeEntries;
  final MarketRepository market;
  final PlotRepository plots;
  final WellRepository wells;
  final CycleRepository cycles;
  final ExchangeRateRepository exchangeRates;
  final FertilizerRepository fertilizers;
  final PendingRatesStore pendingRates;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found. Wrap your app in an AppScope.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      database != oldWidget.database ||
      appSettings != oldWidget.appSettings ||
      savingsBarn != oldWidget.savingsBarn ||
      transactions != oldWidget.transactions ||
      incomeEntries != oldWidget.incomeEntries ||
      market != oldWidget.market ||
      plots != oldWidget.plots ||
      wells != oldWidget.wells ||
      cycles != oldWidget.cycles ||
      exchangeRates != oldWidget.exchangeRates ||
      fertilizers != oldWidget.fertilizers ||
      pendingRates != oldWidget.pendingRates;
}
