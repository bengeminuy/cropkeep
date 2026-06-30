import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_scope.dart';
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
import 'data/tables/cycles.dart' show CycleState;
import 'screens/farm_screen.dart';
import 'screens/farmer_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/market_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'theme/colors.dart';
import 'widgets/cropkeep_header.dart';
import 'widgets/cropkeep_nav_bar.dart';
import 'widgets/cropkeep_toast.dart';
import 'widgets/log_transaction_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final pendingRates = PendingRatesStore();
  await pendingRates.load();
  final appSettings = AppSettingsRepository(database, pendingRates: pendingRates);
  await appSettings.ensureSeeded();
  final savingsBarn = SavingsBarnRepository(database);
  final transactions = TransactionRepository(database);
  final incomeEntries = IncomeEntryRepository(database);
  final market = MarketRepository(database);
  final plots = PlotRepository(database);
  final wells = WellRepository(database);
  final cycles = CycleRepository(database);
  final exchangeRates = ExchangeRateRepository(
    database,
    pendingRates: pendingRates,
  );
  final fertilizers = FertilizerRepository(database);
  runApp(CropkeepApp(
    database: database,
    appSettings: appSettings,
    savingsBarn: savingsBarn,
    transactions: transactions,
    incomeEntries: incomeEntries,
    market: market,
    plots: plots,
    wells: wells,
    cycles: cycles,
    exchangeRates: exchangeRates,
    fertilizers: fertilizers,
    pendingRates: pendingRates,
  ));
}

class CropkeepApp extends StatelessWidget {
  const CropkeepApp({
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

  @override
  Widget build(BuildContext context) {
    return AppScope(
      database: database,
      appSettings: appSettings,
      savingsBarn: savingsBarn,
      transactions: transactions,
      incomeEntries: incomeEntries,
      market: market,
      plots: plots,
      wells: wells,
      cycles: cycles,
      exchangeRates: exchangeRates,
      fertilizers: fertilizers,
      pendingRates: pendingRates,
      child: MaterialApp(
        title: 'Cropkeep',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          scaffoldBackgroundColor: CropkeepColors.bgScreen,
          textTheme: GoogleFonts.nunitoTextTheme(),
        ),
        home: const _OnboardingGate(),
      ),
    );
  }
}

class _OnboardingGate extends StatelessWidget {
  const _OnboardingGate();

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).appSettings;
    return StreamBuilder<AppSettingsRow?>(
      stream: repo.watch(),
      builder: (context, snapshot) {
        final settings = snapshot.data;
        if (settings == null) {
          return const Scaffold(
            backgroundColor: CropkeepColors.bgScreen,
            body: SizedBox.shrink(),
          );
        }
        if (!settings.onboardingCompleted) {
          return const OnboardingFlow();
        }
        return const RootShell();
      },
    );
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  static const List<Widget> _tabs = <Widget>[
    FarmScreen(),
    LedgerScreen(),
    MarketScreen(),
    FarmerScreen(),
  ];

  static const int _farmerIndex = 3;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Daily-refresh trigger: once we mount after onboarding, kick a
    // background fetch of today's rates. The repo no-ops if a row for
    // every active secondary already has today's `setAt`, so multiple
    // launches per day cost nothing. Network failure is silent — the
    // previous snapshot stays in place.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRefreshRates());
  }

  // Gates the FAB's Log Transaction action on the presence of an
  // active cycle. With no cycle, there's no `cycle_id` to scope a new
  // transaction to — surface a snackbar pointing the user to the
  // Begin tracking CTA on the Farm tab.
  Future<void> _handleFabTapped() async {
    final scope = AppScope.of(context);
    final cycle = await scope.cycles.watchActiveCycle().first;
    if (!mounted) return;
    if (cycle == null) {
      CropkeepToast.warning(
        context,
        title: 'No active cycle yet',
        flavor: 'Begin tracking from the Farm tab before logging transactions.',
        duration: const Duration(seconds: 3),
      );
      setState(() => _index = 0);
      return;
    }
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LogTransactionSheet(),
    );
  }

  Future<void> _maybeRefreshRates() async {
    if (!mounted) return;
    final scope = AppScope.of(context);
    final db = scope.database;
    final cycle = await (db.select(db.cycles)
          ..where((t) => t.state.equalsValue(CycleState.active))
          ..limit(1))
        .getSingleOrNull();
    if (cycle == null) return;
    final settings = await (db.select(db.appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (settings == null) return;
    final secondaries = await (db.select(db.currencies)
          ..where((t) => t.isActive.equals(true) & t.isBase.equals(false))
          ..orderBy([(t) => drift.OrderingTerm(expression: t.code)]))
        .get();
    final codes = [for (final c in secondaries) c.code];
    if (codes.isEmpty) return;
    try {
      await scope.exchangeRates.refreshDailyIfStale(
        cycleId: cycle.id,
        baseCode: settings.baseCurrencyCode,
        secondaryCodes: codes,
      );
    } catch (e) {
      debugPrint('Daily FX refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showHeader = _index != _farmerIndex;
    final repo = AppScope.of(context).appSettings;

    return Scaffold(
      body: Column(
        children: [
          if (showHeader)
            StreamBuilder<AppSettingsRow?>(
              stream: repo.watch(),
              builder: (context, snapshot) {
                final s = snapshot.data;
                final String avatarId = s?.avatarId ?? 'farmer';
                final String farmerName = s?.farmerName ?? 'Farmer';
                final int coins = s?.coinsBalance ?? 0;
                return StreamBuilder<CycleRow?>(
                  stream: AppScope.of(context).cycles.watchActiveCycle(),
                  builder: (context, cycleSnap) {
                    return CropkeepHeader(
                      avatarId: avatarId,
                      farmerName: farmerName,
                      coins: coins,
                      showCyclePill: cycleSnap.data != null,
                    );
                  },
                );
              },
            ),
          Expanded(child: IndexedStack(index: _index, children: _tabs)),
        ],
      ),
      bottomNavigationBar: CropkeepNavBar(
        currentIndex: _index,
        onTabSelected: (i) => setState(() => _index = i),
        onFabTapped: _handleFabTapped,
      ),
    );
  }
}
