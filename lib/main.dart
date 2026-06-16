import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/farm_screen.dart';
import 'screens/farmer_screen.dart';
import 'screens/ledger_screen.dart';
import 'screens/market_screen.dart';
import 'theme/colors.dart';
import 'widgets/cropkeep_nav_bar.dart';
import 'widgets/log_transaction_sheet.dart';

void main() {
  runApp(const CropkeepApp());
}

class CropkeepApp extends StatelessWidget {
  const CropkeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cropkeep',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: CropkeepColors.bgScreen,
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      home: const RootShell(),
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

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
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
