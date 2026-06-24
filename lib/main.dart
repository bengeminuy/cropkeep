import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_scope.dart';
import 'data/database.dart';
import 'data/repositories/app_settings_repository.dart';
import 'data/repositories/income_entry_repository.dart';
import 'data/repositories/market_repository.dart';
import 'data/repositories/savings_barn_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/xp_curve.dart';
import 'screens/farm_screen.dart';
import 'screens/farmer_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/market_screen.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'theme/colors.dart';
import 'widgets/cropkeep_header.dart';
import 'widgets/cropkeep_nav_bar.dart';
import 'widgets/log_transaction_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final appSettings = AppSettingsRepository(database);
  await appSettings.ensureSeeded();
  final savingsBarn = SavingsBarnRepository(database);
  final transactions = TransactionRepository(database);
  final incomeEntries = IncomeEntryRepository(database);
  final market = MarketRepository(database);
  runApp(CropkeepApp(
    database: database,
    appSettings: appSettings,
    savingsBarn: savingsBarn,
    transactions: transactions,
    incomeEntries: incomeEntries,
    market: market,
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
  });

  final AppDatabase database;
  final AppSettingsRepository appSettings;
  final SavingsBarnRepository savingsBarn;
  final TransactionRepository transactions;
  final IncomeEntryRepository incomeEntries;
  final MarketRepository market;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      database: database,
      appSettings: appSettings,
      savingsBarn: savingsBarn,
      transactions: transactions,
      incomeEntries: incomeEntries,
      market: market,
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
                final int level = s?.farmerLevel ?? 1;
                final int xp = s?.farmerXp ?? 0;
                final int coins = s?.coinsBalance ?? 0;
                return CropkeepHeader(
                  avatarId: avatarId,
                  level: level,
                  xpProgress:
                      XpCurve.progress(totalXp: xp, level: level),
                  coins: coins,
                );
              },
            ),
          Expanded(child: IndexedStack(index: _index, children: _tabs)),
        ],
      ),
      bottomNavigationBar: CropkeepNavBar(
        currentIndex: _index,
        onTabSelected: (i) => setState(() => _index = i),
        onFabTapped: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const LogTransactionSheet(),
        ),
      ),
    );
  }
}
