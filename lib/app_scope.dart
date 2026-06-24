import 'package:flutter/widgets.dart';

import 'data/database.dart';
import 'data/repositories/app_settings_repository.dart';
import 'data/repositories/income_entry_repository.dart';
import 'data/repositories/market_repository.dart';
import 'data/repositories/savings_barn_repository.dart';
import 'data/repositories/transaction_repository.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.database,
    required this.appSettings,
    required this.savingsBarn,
    required this.transactions,
    required this.incomeEntries,
    required this.market,
    required super.child,
  });

  final AppDatabase database;
  final AppSettingsRepository appSettings;
  final SavingsBarnRepository savingsBarn;
  final TransactionRepository transactions;
  final IncomeEntryRepository incomeEntries;
  final MarketRepository market;

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
      market != oldWidget.market;
}
