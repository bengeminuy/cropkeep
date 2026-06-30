import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../data/database.dart';
import '../data/repositories/cycle_repository.dart';
import '../data/tables/plots.dart' show PlotKind;
import '../data/tables/wells.dart' show WellType;
import '../theme/colors.dart';
import '../widgets/cropkeep_toast.dart';
import 'cycle/cycle_transition_screen.dart';
import 'farm/general_spending_breakdown_screen.dart';
import 'farm/new_plot_screen.dart';
import 'farm/new_well_screen.dart';
import 'farm/plot_breakdown_screen.dart';
import 'market/market_catalog.dart';

// ──────────────────────────────────────────────────────────────────────────
// FarmScreen — first visual pass.
//
// Two subpages live behind a segmented control + swipeable PageView:
//   • Crops — compact reservoir meter + plot grid (default)
//   • Wells — detailed reservoir, bonus harvest pool, foundation & bonus
//             wells, plus the system-managed Carryover well
//
// All data is hardcoded sample content so the aesthetic can be iterated on.
// Every tap (other than segment + swipe) surfaces a "coming soon" snackbar.
// Repositories, creation sheets, and live cycle math come in follow-up passes.

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectSegment(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int i) {
    if (i != _index) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    // No SafeArea wrapper here — the parent (RootShell) renders the
    // CropkeepHeader directly above, which already consumes the top
    // status-bar inset via its own SafeArea. Wrapping FarmScreen in a
    // second SafeArea reads the same MediaQuery top inset (SafeArea
    // doesn't propagate consumption to siblings, only descendants) and
    // ends up double-padding the top by the notch height — a ~47px ghost
    // gap on notch iPhones between the header and the segment control.
    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: _BaseCurrencyProvider(
        child: Column(
          children: [
            Padding(
              // 8px top so the segment couples to the header (header has
              // 8px internal bottom padding → ~16px reading gap, the
              // standard Material tabs-under-header pattern).
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SubpageSegmentedControl(
                index: _index,
                onSelected: _selectSegment,
              ),
            ),
            const SizedBox(height: 4),
            _PageIndicatorDots(index: _index, count: 2),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: const [
                  _CropsSubpage(),
                  _WellsSubpage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wires app-settings → base currency once, exposes the {symbol, decimals}
// pair as an InheritedWidget so every nested money render reads the same
// values. Folds two nested StreamBuilders into the child so the rest of
// the screen never threads currency through constructors.
class _BaseCurrencyProvider extends StatelessWidget {
  const _BaseCurrencyProvider({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<AppSettingsRow?>(
      stream: scope.appSettings.watch(),
      builder: (context, settingsSnap) {
        final String? code = settingsSnap.data?.baseCurrencyCode;
        return StreamBuilder<CurrencyRow?>(
          stream: _watchBaseCurrency(scope.database, code),
          builder: (context, currencySnap) {
            final currency = currencySnap.data;
            return _BaseCurrencyScope(
              symbol: currency?.symbol ?? r'$',
              decimals: currency?.decimalPlaces ?? 2,
              child: child,
            );
          },
        );
      },
    );
  }
}

class _BaseCurrencyScope extends InheritedWidget {
  const _BaseCurrencyScope({
    required this.symbol,
    required this.decimals,
    required super.child,
  });

  final String symbol;
  final int decimals;

  static _BaseCurrencyScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_BaseCurrencyScope>();
    assert(scope != null, '_BaseCurrencyScope missing — wrap with _BaseCurrencyProvider.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_BaseCurrencyScope old) =>
      symbol != old.symbol || decimals != old.decimals;
}

Stream<CurrencyRow?> _watchBaseCurrency(AppDatabase db, String? code) {
  if (code == null) return Stream<CurrencyRow?>.value(null);
  return (db.select(db.currencies)..where((t) => t.code.equals(code)))
      .watchSingleOrNull();
}

// ──────────────────────────────────────────────────────────────────────────
// Cycle scope — exposes the 1-based cycle day + total cycle length so any
// descendant that needs them (reservoir bar tick, pace math, breakdown
// data) can read both from one place instead of plumbing them through five
// widget constructors. Populated at the top of each subpage from the
// active cycle row.

class _CycleScope extends InheritedWidget {
  const _CycleScope({
    required this.cycleDay,
    required this.cycleLength,
    required this.cycleStartWeekday,
    required this.activeCycleId,
    required super.child,
  });

  final int cycleDay;
  final int cycleLength;
  final int cycleStartWeekday;
  final int? activeCycleId;

  // Inclusive of today: the current day is still a day you can spend on, so
  // pace = remaining ÷ (cycleLength − cycleDay + 1). On day 1 of a 30-day
  // cycle this is 30, matching the onboarding spec; on the final day it's
  // 1, so the headline collapses to "spend the rest today."
  int get daysLeft => (cycleLength - cycleDay + 1).clamp(1, cycleLength);

  static _CycleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_CycleScope>();
    assert(scope != null, '_CycleScope missing — wrap with _CycleProvider.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_CycleScope old) =>
      cycleDay != old.cycleDay ||
      cycleLength != old.cycleLength ||
      cycleStartWeekday != old.cycleStartWeekday ||
      activeCycleId != old.activeCycleId;
}

class _CycleProvider extends StatelessWidget {
  const _CycleProvider({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<CycleRow?>(
      stream: scope.cycles.watchActiveCycle(),
      builder: (context, snap) {
        // A cycle is conceptually a calendar month, so cycleDay /
        // cycleLength / cycleStartWeekday all derive from `now` and
        // the month it falls in — regardless of when within the month
        // the user actually pressed Begin tracking. Pace math gets the
        // same answer (cycle's end_date is always the last day of the
        // month), and the breakdown screen's weekday tiles want
        // calendar weekdays anyway.
        final cycle = snap.data;
        final now = DateTime.now();
        final length = DateTime(now.year, now.month + 1, 0).day;
        final start = DateTime(now.year, now.month, 1);
        return _CycleScope(
          cycleDay: now.day.clamp(1, length),
          cycleLength: length,
          cycleStartWeekday: start.weekday,
          activeCycleId: cycle?.id,
          child: child,
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// View-model builders — wrap a PlotRow / WellRow with the derived display
// fields the existing widgets already expect (swatch, status label,
// visual state, etc.). Keeping the type shape stable means the rendering
// widgets below don't need to change.

const Map<String, Color> _plotColorTable = {
  'Tomato': Color(0xFFFFB5B5),
  'Carrot': Color(0xFFFFCEA8),
  'Honey': Color(0xFFFFE3A8),
  'Butter': Color(0xFFFFF5B0),
  'Lettuce': Color(0xFFD4ECA8),
  'Mint': Color(0xFFB5E6B8),
  'Sage': Color(0xFFA8D8C2),
  'Sky': Color(0xFFB5DCEB),
  'Cornflower': Color(0xFFB5C5F0),
  'Lavender': Color(0xFFC9B5F0),
  'Lilac': Color(0xFFE6B5E6),
  'Rose': Color(0xFFF5B5D5),
};

Color _plotSwatchFor(PlotRow row) {
  if (row.isUnplanned) return const Color(0xFFE6D8BC);
  final id = row.plotColorId;
  if (id == null) return CropkeepColors.greenHint;
  return _plotColorTable[id] ?? CropkeepColors.greenHint;
}

String _cropIconForCropId(String cropId) {
  if (cropId == 'unplanned') return 'assets/icons/cornucopia.svg';
  const starters = {'wheat', 'apple', 'potato'};
  if (starters.contains(cropId)) return 'assets/icons/crops/$cropId.svg';
  return 'assets/icons/crops/icons8-${cropId.replaceAll('_', '-')}.svg';
}

_PlotKind _kindFromRow(PlotKind dbKind) {
  switch (dbKind) {
    case PlotKind.discretionary:
      return _PlotKind.discretionary;
    case PlotKind.fixedObligation:
      return _PlotKind.fixedObligation;
    case PlotKind.investment:
      return _PlotKind.investment;
  }
}

_PlotVisualState _visualStateFor({
  required int spent,
  required int? budget,
  required _PlotKind kind,
  required bool isUnplanned,
}) {
  if (isUnplanned) return _PlotVisualState.growing;
  if (budget == null || budget <= 0) return _PlotVisualState.growing;
  final double ratio = spent / budget;
  switch (kind) {
    case _PlotKind.fixedObligation:
      if (spent <= 0) return _PlotVisualState.seedling;
      if (ratio >= 1.0) return _PlotVisualState.ready;
      if (ratio >= 0.5) return _PlotVisualState.almostFull;
      return _PlotVisualState.growing;
    case _PlotKind.discretionary:
      if (ratio > 1.0) return _PlotVisualState.withering;
      if (ratio >= 0.80) return _PlotVisualState.almostFull;
      return _PlotVisualState.growing;
    case _PlotKind.investment:
      if (ratio >= 1.0) return _PlotVisualState.ready;
      return _PlotVisualState.growing;
  }
}

String? _statusLabelFor(_PlotKind kind, _PlotVisualState state, int? dueDay) {
  if (kind != _PlotKind.fixedObligation) return null;
  final String dueSuffix = dueDay != null ? ' · Due day $dueDay' : '';
  switch (state) {
    case _PlotVisualState.ready:
      return 'Paid$dueSuffix';
    case _PlotVisualState.almostFull:
      return 'Due soon$dueSuffix';
    case _PlotVisualState.seedling:
      return 'Awaiting$dueSuffix';
    case _PlotVisualState.withering:
      return 'Short$dueSuffix';
    case _PlotVisualState.growing:
      return 'Partial$dueSuffix';
  }
}

_SamplePlot _plotVmFromRow(
  PlotRow row, {
  required int spent,
  required int totalIncome,
  required _BaseConverter converter,
}) {
  final int? budgetBase = row.budgetAmount == null
      ? null
      : converter.toBase(row.budgetAmount!, row.currencyCode);
  final kind = _kindFromRow(row.kind);
  final state = _visualStateFor(
    spent: spent,
    budget: budgetBase,
    kind: kind,
    isUnplanned: row.isUnplanned,
  );
  final double? sharePct =
      row.isUnplanned && totalIncome > 0 ? (spent / totalIncome) * 100 : null;
  return _SamplePlot(
    plotId: row.id,
    name: row.name,
    iconAsset: _cropIconForCropId(row.cropTypeId),
    budget: budgetBase,
    spent: spent,
    state: state,
    kind: kind,
    swatch: _plotSwatchFor(row),
    statusLabel: _statusLabelFor(kind, state, row.dueDay),
    dueDay: row.dueDay,
    isUnplanned: row.isUnplanned,
    incomeSharePct: sharePct,
  );
}

String _formatExpectedSubtitle(
  WellRow row,
  CurrencyRow? currency,
  _BaseConverter converter,
) {
  final symbol = currency?.symbol ?? r'$';
  final decimals = currency?.decimalPlaces ?? 2;
  if (row.wellType == WellType.foundation && row.expectedAmount != null) {
    final base = converter.toBase(row.expectedAmount!, row.currencyCode);
    return 'Expected ${_formatMoney(base, symbol, decimals)} / cycle';
  }
  if (row.isCarryover) return 'From last cycle\'s rollover';
  final hasMin = row.estimateMin != null && row.estimateMin! > 0;
  final hasMax = row.estimateMax != null && row.estimateMax! > 0;
  if (hasMin && hasMax) {
    final minBase = converter.toBase(row.estimateMin!, row.currencyCode);
    final maxBase = converter.toBase(row.estimateMax!, row.currencyCode);
    return 'Estimate ${_formatMoney(minBase, symbol, decimals)} – ${_formatMoney(maxBase, symbol, decimals)}';
  }
  if (hasMin) {
    final base = converter.toBase(row.estimateMin!, row.currencyCode);
    return 'At least ${_formatMoney(base, symbol, decimals)}';
  }
  if (hasMax) {
    final base = converter.toBase(row.estimateMax!, row.currencyCode);
    return 'Up to ${_formatMoney(base, symbol, decimals)}';
  }
  return 'Variable income';
}

_SampleWell _wellVmFromRow(
  WellRow row, {
  required int loggedThisCycle,
  required CurrencyRow? currency,
  required _BaseConverter converter,
}) {
  final int? expectedInBase =
      row.wellType == WellType.foundation && row.expectedAmount != null
          ? converter.toBase(row.expectedAmount!, row.currencyCode)
          : null;
  return _SampleWell(
    id: row.id,
    name: row.name,
    iconAsset: row.wellType == WellType.foundation
        ? 'assets/icons/well.svg'
        : 'assets/icons/water-bottle.svg',
    subtitle: _formatExpectedSubtitle(row, currency, converter),
    loggedThisCycle: loggedThisCycle,
    isBonus: row.wellType == WellType.bonus,
    isCarryover: row.isCarryover,
    expectedInBase: expectedInBase,
  );
}

// Converts an amount stored in `sourceCode` minor units to base minor units
// using the active cycle's rate map. Identity when the source currency is
// already base. A missing rate defaults to 1.0 — matches new_plot_screen so
// the reservoir cap and the display agree on the same number. The decimals
// adjustment handles the (rare) case of a non-base currency whose minor
// unit differs from base (e.g. JPY with 0 decimals while base is USD).
class _BaseConverter {
  const _BaseConverter({
    required this.baseCode,
    required this.baseDecimals,
    required Map<String, CurrencyRow> currencyByCode,
    required Map<String, double> rateToBase,
  })  : _currencyByCode = currencyByCode,
        _rateToBase = rateToBase;

  final String baseCode;
  final int baseDecimals;
  final Map<String, CurrencyRow> _currencyByCode;
  final Map<String, double> _rateToBase;

  int toBase(int sourceMinor, String sourceCode) {
    if (sourceCode == baseCode) return sourceMinor;
    final int srcDecimals =
        _currencyByCode[sourceCode]?.decimalPlaces ?? baseDecimals;
    final double rate = _rateToBase[sourceCode] ?? 1.0;
    final num scale = math.pow(10, baseDecimals - srcDecimals);
    return (sourceMinor * rate * scale).round();
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Single dashboard query — combines plots, foundation/bonus wells, per-cycle
// spending, and bonus-pool logged so each subpage builds from a coherent
// snapshot. Without this, individual StreamBuilders could each see slightly
// different commits and the reservoir / allocated math could disagree
// across the hero and rows for a frame or two after a write.
//
// Currency-aware totals stay simple in Phase 1: amounts already stored in
// base minor units (transactions.base_amount, income_entries.base_amount)
// are summed directly. Plot budgets and well expecteds are stored in the
// row's currency, so they're converted to base via the cycle rate map
// before they hit the headline. The cycle-transition rate prompt is
// Phase 2; missing rates default to identity here so the math doesn't
// silently produce zero.

class _FarmDashboard {
  const _FarmDashboard({
    required this.plots,
    required this.plotSpends,
    required this.foundationWells,
    required this.bonusWells,
    required this.wellLogged,
    required this.totalSpent,
    required this.totalBonusLogged,
    required this.foundationTotal,
    required this.allocatedSoFar,
    required this.baseCurrency,
    required this.converter,
    required this.fertilizersByPlot,
  });

  final List<PlotRow> plots;
  final Map<int, int> plotSpends;
  final List<WellRow> foundationWells;
  final List<WellRow> bonusWells;
  final Map<int, int> wellLogged;
  final int totalSpent;
  final int totalBonusLogged;
  final int foundationTotal;
  // Sum of every non-Unplanned plot budget, converted to base. Used both
  // on the reservoir hero and as `allocatedSoFar` when the user opens
  // the New Plot screen, so passing it down keeps the two consistent.
  final int allocatedSoFar;
  final CurrencyRow? baseCurrency;
  final _BaseConverter converter;
  // plotId → fertilizer itemId for the active cycle. Drives the small
  // corner indicator on each Crops row so "which plots are boosted"
  // is scannable without drilling into the breakdown.
  final Map<int, String> fertilizersByPlot;

  int get totalIncome => foundationTotal + totalBonusLogged;
}

class _FarmDataBuilder extends StatelessWidget {
  const _FarmDataBuilder({required this.builder});

  final Widget Function(BuildContext context, _FarmDashboard data) builder;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final cycle = _CycleScope.of(context);
    final cycleId = cycle.activeCycleId;
    return StreamBuilder<List<CurrencyRow>>(
      stream: scope.appSettings.watchCurrencies(),
      builder: (context, currencySnap) {
        final currencies = currencySnap.data ?? const <CurrencyRow>[];
        final base = currencies
            .where((c) => c.isBase)
            .cast<CurrencyRow?>()
            .firstWhere((_) => true, orElse: () => null);
        final String baseCodeForRates = base?.code ?? 'USD';
        return StreamBuilder<Map<String, double>>(
          // Pre-cycle: fall back to the disk-backed pending-rates store
          // so foundation wells and plot budgets in non-base currencies
          // convert correctly on the reservoir hero before Begin
          // tracking. Post-cycle: the cycle-scoped rows take over.
          stream: cycleId == null
              ? scope.pendingRates.watch().map(
                  (m) => {for (final e in m.entries) e.key: e.value.rate})
              : scope.cycles.watchRatesFor(cycleId).map((rows) => {
                    for (final r in rows)
                      if (r.toCurrencyCode == baseCodeForRates)
                        r.fromCurrencyCode: r.rate,
                  }),
          builder: (context, ratesSnap) {
            final rateToBase = ratesSnap.data ?? const <String, double>{};
            return StreamBuilder<List<PlotRow>>(
              stream: scope.plots.watchActivePlots(),
              builder: (context, plotsSnap) {
                final plots = plotsSnap.data ?? const <PlotRow>[];
                return StreamBuilder<List<WellRow>>(
                  stream: scope.wells.watchActiveWells(),
                  builder: (context, wellsSnap) {
                    final wells = wellsSnap.data ?? const <WellRow>[];
                    return StreamBuilder<Map<int, int>>(
                      stream: cycleId == null
                          ? Stream<Map<int, int>>.value(const {})
                          : scope.transactions.watchPlotSpentByCycle(cycleId),
                      builder: (context, spendsSnap) {
                        final plotSpends =
                            spendsSnap.data ?? const <int, int>{};
                        return StreamBuilder<Map<int, int>>(
                          stream: cycleId == null
                              ? Stream<Map<int, int>>.value(const {})
                              : scope.incomeEntries
                                  .watchLoggedByWellAndCycle(cycleId),
                          builder: (context, loggedSnap) {
                            final wellLogged =
                                loggedSnap.data ?? const <int, int>{};
                            return StreamBuilder<
                                List<PlotFertilizerApplicationRow>>(
                              stream: cycleId == null
                                  ? Stream<List<
                                          PlotFertilizerApplicationRow>>.value(
                                      const [])
                                  : scope.fertilizers.watchByCycle(cycleId),
                              builder: (context, fertSnap) {
                                final fertList = fertSnap.data ??
                                    const <PlotFertilizerApplicationRow>[];
                                final fertilizersByPlot = <int, String>{
                                  for (final f in fertList)
                                    f.plotId: f.fertilizerItemId,
                                };
                                return _composeDashboard(
                                  plots: plots,
                                  wells: wells,
                                  plotSpends: plotSpends,
                                  wellLogged: wellLogged,
                                  currencies: currencies,
                                  rateToBase: rateToBase,
                                  base: base,
                                  fertilizersByPlot: fertilizersByPlot,
                                  builder: builder,
                                  context: context,
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _composeDashboard({
    required List<PlotRow> plots,
    required List<WellRow> wells,
    required Map<int, int> plotSpends,
    required Map<int, int> wellLogged,
    required List<CurrencyRow> currencies,
    required Map<String, double> rateToBase,
    required CurrencyRow? base,
    required Map<int, String> fertilizersByPlot,
    required BuildContext context,
    required Widget Function(BuildContext, _FarmDashboard) builder,
  }) {
    final String baseCode = base?.code ?? 'USD';
    final int baseDecimals = base?.decimalPlaces ?? 2;
    final Map<String, CurrencyRow> currencyByCode = {
      for (final c in currencies) c.code: c,
    };
    final converter = _BaseConverter(
      baseCode: baseCode,
      baseDecimals: baseDecimals,
      currencyByCode: currencyByCode,
      rateToBase: rateToBase,
    );
    final foundation = <WellRow>[];
    final bonus = <WellRow>[];
    for (final w in wells) {
      if (w.wellType == WellType.foundation) {
        foundation.add(w);
      } else {
        bonus.add(w);
      }
    }
    int foundationTotal = 0;
    for (final w in foundation) {
      if (w.expectedAmount == null) continue;
      foundationTotal += converter.toBase(w.expectedAmount!, w.currencyCode);
    }
    int allocatedSoFar = 0;
    for (final p in plots) {
      if (p.isUnplanned) continue;
      if (p.budgetAmount == null) continue;
      allocatedSoFar += converter.toBase(p.budgetAmount!, p.currencyCode);
    }
    int totalSpent = 0;
    for (final v in plotSpends.values) {
      totalSpent += v;
    }
    int totalBonusLogged = 0;
    for (final w in bonus) {
      totalBonusLogged += wellLogged[w.id] ?? 0;
    }
    return builder(
      context,
      _FarmDashboard(
        plots: plots,
        plotSpends: plotSpends,
        foundationWells: foundation,
        bonusWells: bonus,
        wellLogged: wellLogged,
        totalSpent: totalSpent,
        totalBonusLogged: totalBonusLogged,
        foundationTotal: foundationTotal,
        allocatedSoFar: allocatedSoFar,
        baseCurrency: base,
        converter: converter,
        fertilizersByPlot: fertilizersByPlot,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Segmented control — toggles between Crops and Wells. Pairs with PageView
// swipe so either gesture advances the other.

class _SubpageSegmentedControl extends StatelessWidget {
  const _SubpageSegmentedControl({
    required this.index,
    required this.onSelected,
  });

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CropkeepColors.bgPageAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTab(
              label: 'Crops',
              isActive: index == 0,
              onTap: () => onSelected(0),
            ),
          ),
          Expanded(
            child: _SegmentTab(
              label: 'Wells',
              isActive: index == 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

// Two quiet dots under the segment control. Their job is *not* navigation —
// taps go to the segment above. The dots advertise that the PageView swipe
// is a real gesture, which otherwise has no visual signal.
class _PageIndicatorDots extends StatelessWidget {
  const _PageIndicatorDots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: i == index
                  ? CropkeepColors.greenPrimary
                  : CropkeepColors.borderCard,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? CropkeepColors.greenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive
                ? CropkeepColors.textOnGreenBtn
                : CropkeepColors.textNavInactive,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Crops subpage — compact reservoir meter + 2-column plot grid.

class _CropsSubpage extends StatefulWidget {
  const _CropsSubpage();

  @override
  State<_CropsSubpage> createState() => _CropsSubpageState();
}

class _CropsSubpageState extends State<_CropsSubpage> {
  _PlotFilter _filter = _PlotFilter.all;

  List<_SamplePlot> _applyFilter(List<_SamplePlot> source) {
    switch (_filter) {
      case _PlotFilter.all:
        return source;
      case _PlotFilter.spending:
        return source
            .where((p) => p.kind == _PlotKind.discretionary)
            .toList(growable: false);
      case _PlotFilter.bills:
        return source
            .where((p) => p.kind == _PlotKind.fixedObligation)
            .toList(growable: false);
      case _PlotFilter.invest:
        return source
            .where((p) => p.kind == _PlotKind.investment)
            .toList(growable: false);
    }
  }

  Map<_PlotFilter, int> _counts(List<_SamplePlot> source) {
    int spending = 0;
    int bills = 0;
    int invest = 0;
    for (final p in source) {
      switch (p.kind) {
        case _PlotKind.fixedObligation:
          bills++;
        case _PlotKind.investment:
          invest++;
        case _PlotKind.discretionary:
          spending++;
      }
    }
    return {
      _PlotFilter.all: source.length,
      _PlotFilter.spending: spending,
      _PlotFilter.bills: bills,
      _PlotFilter.invest: invest,
    };
  }

  @override
  Widget build(BuildContext context) {
    return _CycleProvider(
      child: _FarmDataBuilder(
        builder: (context, data) {
          final cycle = _CycleScope.of(context);
          final List<_SamplePlot> plots = [
            for (final row in data.plots)
              _plotVmFromRow(
                row,
                spent: data.plotSpends[row.id] ?? 0,
                totalIncome: data.totalIncome,
                converter: data.converter,
              ),
          ];
          final filtered = _applyFilter(plots);
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _CycleStatusStrip(),
                if (cycle.activeCycleId != null) ...[
                  _ReservoirHeroBlock(
                    total: data.totalIncome,
                    totalSpent: data.totalSpent,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GeneralSpendingBreakdownScreen(
                          data: GeneralSpendingBreakdownData(
                            totalIncome: data.totalIncome,
                            reservoirTotal: data.foundationTotal,
                            cycleDay: cycle.cycleDay,
                            cycleLength: cycle.cycleLength,
                            plots: plots
                                .map(_toBreakdownPlot)
                                .toList(growable: false),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PlotFilterChips(
                    active: _filter,
                    counts: _counts(plots),
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  const SizedBox(height: 16),
                ],
                _PlotList(
                  plots: filtered,
                  totalIncome: data.totalIncome,
                  reservoirTotal: data.foundationTotal,
                  allocatedSoFar: data.allocatedSoFar,
                  activeCycleId: cycle.activeCycleId,
                  fertilizersByPlot: data.fertilizersByPlot,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _PlotFilter { all, spending, bills, invest }

// ──────────────────────────────────────────────────────────────────────────
// Wells subpage — detailed reservoir, bonus pool, foundation + bonus lists.

class _WellsSubpage extends StatelessWidget {
  const _WellsSubpage();

  @override
  Widget build(BuildContext context) {
    return _CycleProvider(
      child: _FarmDataBuilder(
        builder: (context, data) {
          final List<_SampleWell> foundationVms = [
            for (final w in data.foundationWells)
              _wellVmFromRow(
                w,
                loggedThisCycle: data.wellLogged[w.id] ?? 0,
                currency: data.baseCurrency,
                converter: data.converter,
              ),
          ];
          final List<_SampleWell> bonusVms = [
            for (final w in data.bonusWells)
              _wellVmFromRow(
                w,
                loggedThisCycle: data.wellLogged[w.id] ?? 0,
                currency: data.baseCurrency,
                converter: data.converter,
              ),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IncomeSummaryBlock(
                  reservoirTotal: data.foundationTotal,
                  bonusLogged: data.totalBonusLogged,
                ),
                const SizedBox(height: 20),
                _WellsSectionCard(
                  title: 'Foundation wells',
                  wells: foundationVms,
                  addLabel: 'Add foundation well',
                  leadingAsset: 'assets/icons/well.svg',
                  addType: WellType.foundation,
                  reservoirTotal: data.foundationTotal,
                  bonusLogged: data.totalBonusLogged,
                ),
                const SizedBox(height: 20),
                _WellsSectionCard(
                  title: 'Bonus wells',
                  wells: bonusVms,
                  addLabel: 'Add bonus well',
                  leadingAsset: 'assets/icons/water-bottle.svg',
                  addType: WellType.bonus,
                  reservoirTotal: data.foundationTotal,
                  bonusLogged: data.totalBonusLogged,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Income summary card — used on the Wells subpage. Mirrors the Crops hero
// pattern ("$X remaining" / "$X this cycle") so the two summary cards
// feel like one design system: hero amount + descriptor word inline, then
// a small subtitle line carrying the breakdown.
//
// "Total" stays textPrimary rather than the green Crops uses for
// "remaining"; remaining is an action signal (room left to spend), total
// is a stated fact. Color stays reserved for things the user can act on.
//
// Plot creation will still enforce sum(plot budgets) ≤ reservoir — this
// card answers "what came in this cycle?", it doesn't change the
// budgeting basis.

// Mirrors _ReservoirHeroBlock: shared _HeroCard chrome (sand wash, deeper
// shadow, generous padding) so both hero blocks read as the same kind of
// object across subpages. No tap target here — the summary states a fact;
// drilling into income happens via the individual well rows below.
class _IncomeSummaryBlock extends StatelessWidget {
  const _IncomeSummaryBlock({
    required this.reservoirTotal,
    required this.bonusLogged,
  });

  final int reservoirTotal;
  final int bonusLogged;

  @override
  Widget build(BuildContext context) {
    final int totalIncome = reservoirTotal + bonusLogged;
    final cur = _BaseCurrencyScope.of(context);
    return _HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _formatMoney(totalIncome, cur.symbol, cur.decimals),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                      height: 1,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const TextSpan(
                    text: ' total',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: CropkeepColors.textSecondaryOnHero,
                      height: 1,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondaryOnHero,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: _formatMoney(reservoirTotal, cur.symbol, cur.decimals),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                  ),
                ),
                const TextSpan(text: ' reservoir + '),
                TextSpan(
                  text: _formatMoney(bonusLogged, cur.symbol, cur.decimals),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textGoldDeep,
                  ),
                ),
                const TextSpan(text: ' bonus'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Reservoir meter — bold single-number hero, simple progress bar, one
// quiet reservoir reference caption. The card is tappable; the breakdown
// (allocated vs unplanned vs overrun split) opens on tap so the daily
// glance stays clean.
//
// "Remaining" tracks actual reservoir drain — total foundation income
// minus everything that's been logged this cycle (plot transactions +
// Unplanned). Budgeted-but-unspent plot money still counts as remaining
// in the reservoir; the budget is just a soft fence for that money, not
// a commitment that's already withdrawn. This matches the water-level
// metaphor more honestly than the "free for allocation" reading.
//
// Design rationale:
//   • Hero is one number + one descriptor word ("$3,725 remaining"). The
//     descriptor flips to "over" with a red hero when spent > total.
//   • Bar reads as a standard progress bar: fill = spent / total. Green
//     while there's room; red when over (fills to 100%). No segments —
//     the allocated / unplanned split lives in the tap-to-open sheet.
//   • One caption: "of $4,800 reservoir" — present in both states so the
//     cap is always available without the user doing mental math.

// Lives inside _HeroCard so the page-defining number reads as a different
// kind of object from the white data cards below. Sand chrome + bigger
// padding/radius/shadow do the work; a labeled "See breakdown ›" link
// sits inline with the reference caption at the bottom as the
// tap-to-breakdown affordance. The label (rather than a bare chevron) is
// what differentiates this hero from the Wells subpage's identical-looking
// summary hero, which is informational and not tappable — without the
// label, "is this clickable?" would be a guessing game between two cards
// of the same shape and tone.
class _ReservoirHeroBlock extends StatelessWidget {
  const _ReservoirHeroBlock({
    required this.total,
    required this.totalSpent,
    required this.onTap,
  });

  final int total;
  // Sum of every non-deleted transaction this cycle, across all plots
  // including Unplanned. The water that has actually left the reservoir.
  final int totalSpent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int remaining = total - totalSpent;
    final bool isOver = remaining < 0;
    final int overrun = isOver ? -remaining : 0;

    return Semantics(
      button: true,
      label: 'View reservoir breakdown',
      child: _HeroCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReservoirHeroLine(
              isOver: isOver,
              remaining: remaining,
              overrun: overrun,
            ),
            const SizedBox(height: 14),
            Builder(builder: (ctx) {
              final cycle = _CycleScope.of(ctx);
              return _ReservoirProgressBar(
                total: total,
                spent: totalSpent,
                isOver: isOver,
                cycleDay: cycle.cycleDay,
                cycleLength: cycle.cycleLength,
              );
            }),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _ReservoirReferenceCaption(total: total)),
                const SizedBox(width: 12),
                const Text(
                  'See breakdown',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CropkeepColors.textSecondaryOnHero,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 2),
                const _ForwardChevron(onHero: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservoirHeroLine extends StatelessWidget {
  const _ReservoirHeroLine({
    required this.isOver,
    required this.remaining,
    required this.overrun,
  });

  final bool isOver;
  final int remaining;
  final int overrun;

  @override
  Widget build(BuildContext context) {
    final int heroAmount = isOver ? overrun : remaining;
    final String descriptor = isOver ? 'over' : 'remaining';
    final cur = _BaseCurrencyScope.of(context);
    // Deep siblings used here because the hero sits on bgHero (warm sand).
    // The bright primaries (textGreen / textRed) have cool undertones that
    // clash against the sand's yellow undertone; the deep variants land
    // like harvest-leaf / brick on linen — same semantic, in-key hue.
    final Color heroColor = isOver
        ? CropkeepColors.textRedDeep
        : CropkeepColors.textGreenDeep;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: _formatMoney(heroAmount, cur.symbol, cur.decimals),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: heroColor,
                height: 1,
                letterSpacing: -0.6,
              ),
            ),
            TextSpan(
              text: ' $descriptor',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textSecondaryOnHero,
                height: 1,
              ),
            ),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}

class _ReservoirProgressBar extends StatelessWidget {
  const _ReservoirProgressBar({
    required this.total,
    required this.spent,
    required this.isOver,
    required this.cycleDay,
    required this.cycleLength,
  });

  final int total;
  final int spent;
  final bool isOver;
  // Day-position within the harvest cycle. The vertical tick at this
  // fraction turns the bar from a "spent vs total" gauge into a "spent vs
  // total vs time" gauge — which is the actual question a daily glance is
  // asking. Distance between fill and tick = pace margin.
  final int cycleDay;
  final int cycleLength;

  static const double _height = 14;

  @override
  Widget build(BuildContext context) {
    final double fraction = total <= 0
        ? 0.0
        : (spent / total).clamp(0.0, 1.0);
    final double tickFraction = cycleLength <= 0
        ? 0.0
        : (cycleDay / cycleLength).clamp(0.0, 1.0);
    // Sand-shadow groove sits under both green-deep (under) and red-deep
    // (over) fills. Single track tone keeps the bar reading as a carved
    // recess in the hero card rather than two competing surfaces.
    const Color trackColor = CropkeepColors.progressTrackOnHero;
    final Color fillColor = isOver
        ? CropkeepColors.textRedDeep
        : CropkeepColors.textGreenDeep;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double tickX = constraints.maxWidth * tickFraction;
            return Stack(
              children: [
                Container(color: trackColor),
                FractionallySizedBox(
                  widthFactor: fraction,
                  alignment: Alignment.centerLeft,
                  child: Container(color: fillColor),
                ),
                Positioned(
                  left: tickX,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1.5,
                    color: CropkeepColors.textSecondaryOnHero
                        .withValues(alpha: 0.60),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Plain caption — the total-this-cycle reference is always available, but
// small enough to stay supportive rather than headline. Uses "this cycle"
// rather than "reservoir" because the total includes logged bonus, which
// isn't part of the reservoir budgeting cap.
class _ReservoirReferenceCaption extends StatelessWidget {
  const _ReservoirReferenceCaption({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final cur = _BaseCurrencyScope.of(context);
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CropkeepColors.textSecondaryOnHero,
          height: 1.3,
        ),
        children: [
          const TextSpan(text: 'of '),
          TextSpan(
            text: _formatMoney(total, cur.symbol, cur.decimals),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textPrimary,
            ),
          ),
          const TextSpan(text: ' this cycle'),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Plot filter chips — three pills above the list. Active chip = filled
// green pill (echoes the Crops/Wells segmented control). Inactive = white
// pill with the standard borderCard outline. Counts are inline so the
// user can see what each filter contains before tapping.

class _PlotFilterChips extends StatelessWidget {
  const _PlotFilterChips({
    required this.active,
    required this.counts,
    required this.onSelected,
  });

  final _PlotFilter active;
  final Map<_PlotFilter, int> counts;
  final ValueChanged<_PlotFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    // Four chips can exceed the page width on smaller phones once "Invest"
    // joins All / Spending / Bills, so the row scrolls horizontally and
    // hides the scrollbar — the count badges already cue the user that
    // chips exist beyond the active selection if anything overflows.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            count: counts[_PlotFilter.all] ?? 0,
            isActive: active == _PlotFilter.all,
            onTap: () => onSelected(_PlotFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Spending',
            count: counts[_PlotFilter.spending] ?? 0,
            isActive: active == _PlotFilter.spending,
            onTap: () => onSelected(_PlotFilter.spending),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Bills',
            count: counts[_PlotFilter.bills] ?? 0,
            isActive: active == _PlotFilter.bills,
            onTap: () => onSelected(_PlotFilter.bills),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Invest',
            count: counts[_PlotFilter.invest] ?? 0,
            isActive: active == _PlotFilter.invest,
            onTap: () => onSelected(_PlotFilter.invest),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? CropkeepColors.greenPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? CropkeepColors.greenPrimary
                : CropkeepColors.borderCard,
            width: 1.5,
          ),
        ),
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? CropkeepColors.textOnGreenBtn
                  : CropkeepColors.textPrimary,
              height: 1,
            ),
            children: [
              TextSpan(text: label),
              TextSpan(
                text: '  $count',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? CropkeepColors.textOnGreenBtn.withValues(alpha: 0.85)
                      : CropkeepColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Plot list — vertical stack of plot row cards, then an "Add plot" footer.
// Each row gives a plot enough horizontal room to show:
//   • crop icon
//   • plot name + a small headline amount on the right ("$X left/over",
//     "$X paid", or "$X spent" for the wild Unplanned patch)
//   • a per-plot progress bar (spent ÷ budget for budgeted plots; income
//     share against the 20% danger threshold for Unplanned)
//   • a one-line status: pace + spent / budget context for discretionary,
//     state + due day for fixed obligation, "X% of income · wild patch"
//     for Unplanned
// State coloring follows the colors.md plot palette. The withering accent
// flips from a top strip (old tile) to a left strip (more natural for
// row layouts).

class _PlotList extends StatelessWidget {
  const _PlotList({
    required this.plots,
    required this.totalIncome,
    required this.reservoirTotal,
    required this.allocatedSoFar,
    required this.activeCycleId,
    required this.fertilizersByPlot,
  });

  final List<_SamplePlot> plots;
  // Cycle's full income (foundation + logged bonus). Plot rows pass it
  // along to PlotBreakdownScreen so the Unplanned drill-down can render
  // "of $X income · X% of income" without re-deriving the figure.
  final int totalIncome;
  // Reservoir cap = sum of foundation expected. Passed down so the
  // New Plot screen's allocation bar reads a coherent number.
  final int reservoirTotal;
  // Sum of every existing non-Unplanned plot budget. Passed down for
  // the same reason.
  final int allocatedSoFar;
  // Active cycle id — null while the cycle row hasn't loaded yet.
  // Plot breakdown taps need it to fetch the cycle's transactions.
  final int? activeCycleId;
  // plotId → fertilizer itemId for the active cycle. Each row reads
  // its own entry to decide whether to paint the corner indicator.
  final Map<int, String> fertilizersByPlot;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < plots.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _PlotRow(
            plot: plots[i],
            fertilizerItemId: fertilizersByPlot[plots[i].plotId],
            onTap: () => _openPlotBreakdown(context, i),
          ),
        ],
        const SizedBox(height: 12),
        _AddPlotRow(
          onTap: () => _openNewPlot(context),
        ),
      ],
    );
  }

  // Reservoir cap = foundation only; bonus never counts toward what plots
  // Reservoir cap = foundation only; bonus never counts toward what plots
  // can be allocated against. The two numbers come from _FarmDataBuilder
  // upstream so the screen header reads the same values the page does.
  void _openNewPlot(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewPlotScreen(
          reservoirTotal: reservoirTotal,
          allocatedSoFar: allocatedSoFar,
        ),
      ),
    );
  }

  Future<void> _openPlotBreakdown(BuildContext context, int index) async {
    final cycleScope = _CycleScope.of(context);
    final plot = plots[index];
    final scope = AppScope.of(context);
    // Find the matching PlotRow id so we can fetch real transactions.
    // The plot list is built from PlotRow + spent, so the order matches
    // _FarmDataBuilder's plots list one-to-one — but we don't have the
    // id here, so re-fetch by name (Unplanned uniqueness is enforced).
    // Simpler: pass the id through. For Phase 1, look it up by name.
    // (Editing the existing _SamplePlot to carry the id is a Phase 2
    // refactor.) Since the active filter may reorder, we re-resolve by
    // matching name on the snapshot returned by watchActivePlots.first.
    final rows = await scope.plots.watchActivePlots().first;
    final row = rows.firstWhere(
      (r) => r.name == plot.name && r.isUnplanned == plot.isUnplanned,
      orElse: () => rows.first,
    );
    final cycleId = cycleScope.activeCycleId;
    final txns = cycleId == null
        ? const <TransactionRow>[]
        : await scope.transactions
            .watchByPlot(plotId: row.id, cycleId: cycleId)
            .first;
    if (!context.mounted) return;
    final start = DateTime.fromMillisecondsSinceEpoch(0);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlotBreakdownScreen(
          data: PlotBreakdownData(
            plotId: row.id,
            plotName: plot.name,
            iconAsset: plot.iconAsset,
            kind: _toBreakdownKind(plot),
            budget: plot.budget,
            cycleDay: cycleScope.cycleDay,
            cycleLength: cycleScope.cycleLength,
            cycleStartWeekday: cycleScope.cycleStartWeekday,
            transactions: txns
                .map((t) => PlotBreakdownTransaction(
                      description: t.note ?? 'Logged expense',
                      amount: t.baseAmount,
                      cycleDay: _cycleDayOfTxn(t, start, cycleScope),
                    ))
                .toList(growable: false),
            reservoirTotal: reservoirTotal,
            allocatedSoFar: allocatedSoFar,
            cycleId: cycleId ?? 0,
            totalIncome: plot.isUnplanned ? totalIncome : null,
            incomeSharePct:
                plot.isUnplanned ? plot.incomeSharePct : null,
          ),
        ),
      ),
    );
  }
}

int _cycleDayOfTxn(
  TransactionRow t,
  DateTime cycleStart,
  _CycleScope cycle,
) {
  // The 1-based cycle day a transaction was logged on. Falls back to
  // the current cycle day if the transaction predates the active cycle
  // (shouldn't happen — log flow stamps cycle_id at write time — but
  // the guard keeps the picker honest if data ever ages out).
  final dt = DateTime.fromMillisecondsSinceEpoch(t.spentAt);
  return dt.day.clamp(1, cycle.cycleLength);
}

class _PlotRow extends StatelessWidget {
  const _PlotRow({
    required this.plot,
    required this.onTap,
    this.fertilizerItemId,
  });

  final _SamplePlot plot;
  final VoidCallback onTap;
  // When non-null, a fertilizer is applied to this plot for the active
  // cycle and a small icon badge paints over the swatch corner. Lookup
  // is by id only — name/description aren't needed at this size.
  final String? fertilizerItemId;

  @override
  Widget build(BuildContext context) {
    final visuals = _PlotVisuals.forState(
      plot.state,
      isUnplanned: plot.isUnplanned,
    );
    final cur = _BaseCurrencyScope.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: visuals.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: visuals.borderColor,
            width: visuals.borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: CropkeepColors.shadowCard,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    // Placeholder until the plot-color picker + Market
                    // unlocks land. Real value will come from
                    // plots.plot_color_id (see database.md). The swatch
                    // lives behind the icon, not as the tile bg, so it
                    // doesn't fight the state-driven background painted
                    // by _PlotVisuals.
                    color: plot.swatch,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SvgPicture.asset(
                    plot.iconAsset,
                    fit: BoxFit.contain,
                  ),
                ),
                // Boost indicator — gold-rimmed badge with the actual
                // fertilizer icon so the row answers "which fertilizer
                // is on which plot" without forcing a drill-in. No tap
                // target: editing lives on the breakdown screen's
                // fertilizer section, keeping the row's status line
                // full-width for the actionable daily-pace number.
                if (!plot.isUnplanned && fertilizerItemId != null)
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: _FertilizerBoostBadge(
                      fertilizerItemId: fertilizerItemId!,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(child: _content(context, visuals, cur)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, _PlotVisuals visuals, _BaseCurrencyScope cur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                plot.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _headlineAmount(cur),
          ],
        ),
        const SizedBox(height: 8),
        _PlotProgressBar(plot: plot),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _statusLine(context, visuals.statusColor, cur)),
            const SizedBox(width: 8),
            const _ForwardChevron(onHero: false),
          ],
        ),
      ],
    );
  }

  Widget _headlineAmount(_BaseCurrencyScope cur) {
    if (plot.isUnplanned) {
      return _amount(
        cur: cur,
        amount: plot.spent,
        descriptor: 'spent',
        amountColor: CropkeepColors.textPrimary,
      );
    }
    if (plot.kind == _PlotKind.fixedObligation) {
      return _amount(
        cur: cur,
        amount: plot.budget ?? 0,
        descriptor: _fixedObligationDescriptor(),
        amountColor: CropkeepColors.textPrimary,
      );
    }
    if (plot.kind == _PlotKind.investment) {
      // Fill-up framing: the headline reads as how much there is left to
      // contribute, never as "spent". Once the target is met or exceeded
      // we flip to "filled" — going over is fine, so no red.
      final int target = plot.budget ?? 0;
      final int remaining = target - plot.spent;
      if (remaining <= 0) {
        return _amount(
          cur: cur,
          amount: plot.spent,
          descriptor: 'filled',
          amountColor: CropkeepColors.textGreenDeep,
        );
      }
      return _amount(
        cur: cur,
        amount: remaining,
        descriptor: 'to go',
        amountColor: CropkeepColors.textPrimary,
      );
    }
    final remaining = (plot.budget ?? 0) - plot.spent;
    final bool isOver = remaining < 0;
    return _amount(
      cur: cur,
      amount: remaining.abs(),
      descriptor: isOver ? 'over' : 'left',
      amountColor:
          isOver ? CropkeepColors.textRed : CropkeepColors.textPrimary,
    );
  }

  Widget _amount({
    required _BaseCurrencyScope cur,
    required int amount,
    required String descriptor,
    required Color amountColor,
  }) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CropkeepColors.textSecondary,
          height: 1.1,
        ),
        children: [
          TextSpan(
            text: _formatMoney(amount, cur.symbol, cur.decimals),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
          TextSpan(text: ' $descriptor'),
        ],
      ),
    );
  }

  String _fixedObligationDescriptor() {
    switch (plot.state) {
      case _PlotVisualState.ready:
        return 'paid';
      case _PlotVisualState.almostFull:
        return 'due';
      case _PlotVisualState.seedling:
        return 'awaiting';
      case _PlotVisualState.withering:
        return 'short';
      case _PlotVisualState.growing:
        return 'partial';
    }
  }

  Widget _statusLine(BuildContext context, Color statusColor, _BaseCurrencyScope cur) {
    final String text;
    if (plot.isUnplanned) {
      final share = plot.incomeSharePct;
      text = share == null
          ? 'Wild patch · awaiting income'
          : '${share.toStringAsFixed(1)}% of income · wild patch';
    } else if (plot.kind == _PlotKind.fixedObligation) {
      text = plot.statusLabel ?? 'Awaiting';
    } else if (plot.kind == _PlotKind.investment) {
      // Investments read as "fill toward a target", not "spend toward a
      // ceiling." Surface progress as a percentage of target so a half-
      // full bar lines up with "50% of target" rather than "50% of cap."
      // Once at or past target, copy switches to a steady "On target".
      final int target = plot.budget ?? 0;
      if (target <= 0) {
        text = 'Set a target';
      } else if (plot.spent >= target) {
        text = 'On target';
      } else {
        final int pct = ((plot.spent / target) * 100).round();
        text =
            '$pct% of ${_formatMoney(target, cur.symbol, cur.decimals)} target';
      }
    } else {
      // Discretionary plots show pace as long as there's budget left to
      // spend — it's the actionable daily target. Once spent ≥ budget the
      // pace is meaningless (zero or negative remaining ÷ days), so fall
      // back to the qualitative state.
      final int budget = plot.budget ?? 0;
      final int remaining = budget - plot.spent;
      if (remaining > 0) {
        final daysLeft = _CycleScope.of(context).daysLeft;
        final pace = remaining ~/ daysLeft;
        text = '≈${_formatMoney(pace, cur.symbol, cur.decimals)}/day to stay on track';
      } else {
        text = 'Withering';
      }
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: statusColor,
        height: 1.2,
      ),
    );
  }
}

// Visual-only "this plot is boosted by X" indicator floating off the
// swatch's bottom-right corner. Naked SVG (no plate, no ring) so it
// reads as a magical effect on the crop rather than a UI notification
// badge. A silhouette shadow — same artwork, dark tint, 1px down —
// gives separation against light swatch colors without adding chrome.
//
// Deliberately not tappable: the status line below carries the
// actionable daily-pace number, and editing fertilizer lives on the
// breakdown screen's dedicated section.
class _FertilizerBoostBadge extends StatelessWidget {
  const _FertilizerBoostBadge({required this.fertilizerItemId});

  final String fertilizerItemId;

  static const double _size = 24;

  @override
  Widget build(BuildContext context) {
    final iconAsset = _fertilizerIconForId(fertilizerItemId);
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          // Shadow layer — same artwork tinted via srcIn so the SVG's
          // own colors are replaced by a single dark tone, then offset
          // 1px down. Mirrors the silhouette rather than painting a
          // rectangular box shadow, which is what makes a non-
          // rectangular icon read as lifted off the page.
          Transform.translate(
            offset: const Offset(0, 1),
            child: SvgPicture.asset(
              iconAsset,
              width: _size,
              height: _size,
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.22),
                BlendMode.srcIn,
              ),
            ),
          ),
          SvgPicture.asset(iconAsset, width: _size, height: _size),
        ],
      ),
    );
  }
}

// Catalog lookup for the boost badge's icon. Plot rows render many at
// once so the lookup needs to be cheap — a linear scan over the
// 8-item static fertilizer list avoids allocating a map on every
// render. Falls back to the generic fertilizer.svg for an id that's
// missing from the catalog (e.g. mid-migration).
String _fertilizerIconForId(String itemId) {
  for (final spec in MarketCatalog.fertilizers) {
    if (spec.itemId == itemId) return spec.iconAsset;
  }
  return 'assets/icons/fertilizers/fertilizer.svg';
}

class _PlotProgressBar extends StatelessWidget {
  const _PlotProgressBar({required this.plot});

  final _SamplePlot plot;

  static const double _height = 8;
  // Unplanned has no budget, so its bar measures income share against the
  // 20% "dead" threshold from the README — 0% leaves the bar empty, ≥20%
  // fills it completely. The fill color still follows the visual state.
  static const double _unplannedDangerCap = 20.0;

  @override
  Widget build(BuildContext context) {
    final double fraction;
    if (plot.isUnplanned) {
      fraction = ((plot.incomeSharePct ?? 0) / _unplannedDangerCap)
          .clamp(0.0, 1.0);
    } else {
      final int budget = plot.budget ?? 0;
      fraction = budget <= 0
          ? 0.0
          : (plot.spent / budget).clamp(0.0, 1.0);
    }

    final Color fill;
    final Color track;
    switch (plot.state) {
      case _PlotVisualState.withering:
        fill = CropkeepColors.redAlert;
        track = CropkeepColors.redAlert.withValues(alpha: 0.18);
        break;
      case _PlotVisualState.almostFull:
        fill = CropkeepColors.goldPrimary;
        track = CropkeepColors.bgGoldWash;
        break;
      case _PlotVisualState.seedling:
      case _PlotVisualState.growing:
      case _PlotVisualState.ready:
        fill = CropkeepColors.greenPrimary;
        track = CropkeepColors.greenHint;
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: _height,
        child: Stack(
          children: [
            Container(color: track),
            FractionallySizedBox(
              widthFactor: fraction,
              alignment: Alignment.centerLeft,
              child: Container(color: fill),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PlotVisualState { seedling, growing, almostFull, ready, withering }

enum _PlotKind { discretionary, fixedObligation, investment }

class _PlotVisuals {
  const _PlotVisuals({
    required this.bg,
    required this.borderColor,
    required this.borderWidth,
    required this.statusColor,
  });

  final Color bg;
  final Color borderColor;
  // 1.5 on state-coded states (ready / almostFull / withering) so the
  // colored border itself carries part of the signal; 1.0 elsewhere so
  // neutral rows feel like quiet containers rather than outlined boxes.
  final double borderWidth;
  final Color statusColor;

  static _PlotVisuals forState(
    _PlotVisualState state, {
    required bool isUnplanned,
  }) {
    if (isUnplanned) {
      // Wild patch — soft tan ground, neutral border, muted status text.
      // Wash sits between bgPlot (#D4C8A8) and the cream page so the row
      // doesn't shout against neighboring white plots.
      return const _PlotVisuals(
        bg: Color(0xFFE0D7BD),
        borderColor: CropkeepColors.borderPlot,
        borderWidth: 1.0,
        statusColor: CropkeepColors.textSecondary,
      );
    }
    switch (state) {
      case _PlotVisualState.seedling:
        return const _PlotVisuals(
          bg: Color(0xFFE0D7BD),
          borderColor: CropkeepColors.borderPlot,
          borderWidth: 1.0,
          statusColor: CropkeepColors.textSecondary,
        );
      case _PlotVisualState.growing:
        return const _PlotVisuals(
          bg: Colors.white,
          borderColor: CropkeepColors.borderCard,
          borderWidth: 1.0,
          statusColor: CropkeepColors.textSecondary,
        );
      case _PlotVisualState.almostFull:
        // Wash halved from #FFFBE8 toward cream so the row reads as a "tint",
        // not a state alert. Deep gold keeps the status text AA on the wash.
        return const _PlotVisuals(
          bg: Color(0xFFFFFCF1),
          borderColor: CropkeepColors.goldPrimary,
          borderWidth: 1.5,
          statusColor: CropkeepColors.textGoldDeep,
        );
      case _PlotVisualState.ready:
        // Wash halved from bgPlotReady (#D6F0C2) toward cream. Deep green
        // keeps the status text AA on the wash.
        return const _PlotVisuals(
          bg: Color(0xFFE4F4D2),
          borderColor: CropkeepColors.borderPlotReady,
          borderWidth: 1.5,
          statusColor: CropkeepColors.textGreenDeep,
        );
      case _PlotVisualState.withering:
        // Match almost-full's pattern: tinted wash bg + full colored border
        // + matching status color. Wash halved from #FDECEC so a list of
        // plots with one withering row doesn't read as alarm-flooded.
        return const _PlotVisuals(
          bg: Color(0xFFFCF4F4),
          borderColor: CropkeepColors.borderPlotWarn,
          borderWidth: 1.5,
          statusColor: CropkeepColors.textRedDeep,
        );
    }
  }
}

// "Add plot" sits in the same list as data rows but should not read as one.
// A dashed border signals "secondary action / placeholder" — universal UX
// convention — so the eye treats it as optional rather than another item to
// scan. Painted via _DashedRoundedBorderPainter (below) so the dash spacing
// is consistent with the row's 16px radius.
class _AddPlotRow extends StatelessWidget {
  const _AddPlotRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        // foregroundPainter (not painter) so the dashes paint OVER the
        // Container's fill — `painter` draws before the child, which the
        // Container then completely covers.
        child: CustomPaint(
          foregroundPainter: const _DashedRoundedBorderPainter(
            color: CropkeepColors.borderPlot,
            strokeWidth: 1.5,
            radius: 16,
            dashLength: 6,
            gapLength: 4,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: CropkeepColors.bgScreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: CropkeepColors.textNavInactive,
                ),
                SizedBox(width: 8),
                Text(
                  'Add plot',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textNavInactive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Paints a dashed rounded-rectangle outline. PathMetrics walks the rounded
// path so dashes hug the curve correctly instead of skipping at the corners.
class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

// ──────────────────────────────────────────────────────────────────────────
// Foundation / bonus wells — vertical list with divider rows + Add footer.

class _WellsSectionCard extends StatelessWidget {
  const _WellsSectionCard({
    required this.title,
    required this.wells,
    required this.addLabel,
    required this.leadingAsset,
    required this.addType,
    required this.reservoirTotal,
    required this.bonusLogged,
  });

  final String title;
  final List<_SampleWell> wells;
  final String addLabel;
  // 18px glyph from the existing illustrative icon set — anchors the
  // section header in the same visual language as the row icons and gives
  // wayfinding a quiet, brand-consistent touch.
  final String leadingAsset;
  // Drives the Add row: which kind of well NewWellScreen lands on, and
  // the context numbers the screen header needs to render the reservoir
  // / bonus-pool headline.
  final WellType addType;
  final int reservoirTotal;
  final int bonusLogged;

  @override
  Widget build(BuildContext context) {
    final int sectionTotal = wells.fold<int>(
      0,
      (sum, w) => sum + w.loggedThisCycle,
    );
    final cur = _BaseCurrencyScope.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _SectionHeader(title, leadingAsset: leadingAsset),
              ),
              // Per-section total — replaces the count badge so each section
              // header carries the answer to "how much is in here this
              // cycle?" without making the summary hero re-do the math.
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    height: 1,
                  ),
                  children: [
                    TextSpan(
                      text: _formatMoney(sectionTotal, cur.symbol, cur.decimals),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CropkeepColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: ' this cycle'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (int i = 0; i < wells.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: CropkeepColors.borderDivider,
              ),
            _WellRow(well: wells[i]),
          ],
          const Divider(
            height: 1,
            thickness: 1,
            color: CropkeepColors.borderDivider,
          ),
          _AddWellRow(
            label: addLabel,
            type: addType,
            reservoirTotal: reservoirTotal,
            bonusLogged: bonusLogged,
          ),
        ],
      ),
    );
  }
}

class _WellRow extends StatelessWidget {
  const _WellRow({required this.well});

  final _SampleWell well;

  @override
  Widget build(BuildContext context) {
    final String trailingCaption =
        well.isCarryover ? 'Rolled over' : 'This cycle';
    final cur = _BaseCurrencyScope.of(context);

    // Row icons were redundant — every foundation row showed the same
    // well.svg, every bonus row the same water-bottle.svg, so the 44×44
    // tinted circle was repeating what the section header glyph + title
    // already said. The header glyph now does the category wayfinding
    // alone; rows lead with their name. The carryover signal that used
    // to ride a corner badge on the icon moves inline as a small ↻ glyph
    // next to the well name (kept tonally via textGoldDeep) so the row
    // still pre-attentively reads as "this is the carryover well."
    return InkWell(
      onTap: () => _comingSoon(
        context,
        well.isCarryover
            ? 'The Carryover well is system-managed.'
            : (well.isBonus
                ? 'Log bonus income — coming soon.'
                : 'Log foundation income — coming soon.'),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (well.isCarryover) ...[
                        SvgPicture.asset(
                          'assets/icons/carryover v2.svg',
                          width: 14,
                          height: 14,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          well.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: CropkeepColors.textPrimary,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (well.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      well.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: CropkeepColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailingCaption,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    letterSpacing: 0.4,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMoney(well.loggedThisCycle, cur.symbol, cur.decimals),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                    height: 1,
                  ),
                ),
              ],
            ),
            // Carryover wells are system-managed (created during cycle
            // transitions), so the overflow affordance is suppressed —
            // there is nothing the user can do to them. For every other
            // well, the trailing ⋮ opens the remove flow. Visual weight
            // is kept light (20px glyph, ~36px hit box, secondary color)
            // so it reads as a quiet secondary action against the
            // amount, not as a peer to the row's primary tap.
            if (!well.isCarryover) ...[
              const SizedBox(width: 4),
              _WellRowOverflowButton(well: well),
            ],
          ],
        ),
      ),
    );
  }
}

// Trailing overflow button on a well row. Lives outside the row's main
// InkWell only by tap dispatch — the IconButton has its own Material ink
// so taps on the glyph open the remove flow instead of the row's primary
// "log income — coming soon" placeholder. Compact (36×36 hit box) so the
// row height stays the same as before the affordance was added.
class _WellRowOverflowButton extends StatelessWidget {
  const _WellRowOverflowButton({required this.well});

  final _SampleWell well;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: 'More',
        padding: EdgeInsets.zero,
        iconSize: 20,
        splashRadius: 18,
        constraints: const BoxConstraints(),
        onPressed: () => _showRemoveWellConfirmSheet(context, well),
        icon: const Icon(
          Icons.more_vert_rounded,
          color: CropkeepColors.textSecondary,
        ),
      ),
    );
  }
}

Future<void> _showRemoveWellConfirmSheet(
  BuildContext context,
  _SampleWell well,
) async {
  // Resolve the currency-formatted shrink string HERE — at the call
  // site, where _BaseCurrencyProvider is still visible. The modal route
  // is pushed onto the Navigator above the Scaffold body, so the sheet's
  // own build context can't reach our InheritedWidget. Doing the format
  // up-front means the sheet stays pure (no scope dependency) and a
  // missing provider can't black-hole the sheet contents.
  String? shrinkText;
  if (!well.isBonus && well.expectedInBase != null) {
    final cur = _BaseCurrencyScope.of(context);
    shrinkText = _formatMoney(well.expectedInBase!, cur.symbol, cur.decimals);
  }
  final bool? confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RemoveWellConfirmSheet(
      well: well,
      shrinkText: shrinkText,
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;
  await AppScope.of(context).wells.archive(well.id);
}

// Direct-confirm sheet (no intermediate action sheet) — wells currently
// expose a single management action, so an action sheet just to relay
// one row through would be extra ceremony. When an Edit-well screen
// ships, promote this to the plot's two-step pattern.
//
// Three rendering modes from one widget so all the "what happens when I
// remove this well" copy lives in one place:
//   • blocked — has income logged this cycle. Removal is gated until the
//     entries are removed or the cycle closes (mirrors the plot
//     "transactions this cycle" gate). Single Close button so the user
//     can't accidentally confirm a no-op.
//   • foundation — emphasizes the reservoir-shrink consequence with the
//     exact base-currency amount, since the expected_amount is what plot
//     budgets are allocated against.
//   • bonus — simple "history stays intact" reassurance; bonus wells
//     just categorize logged income, they don't carry allocation load.
class _RemoveWellConfirmSheet extends StatelessWidget {
  const _RemoveWellConfirmSheet({
    required this.well,
    required this.shrinkText,
  });

  final _SampleWell well;
  // Pre-formatted reservoir-shrink amount, resolved at the call site so
  // the sheet does not need to touch _BaseCurrencyScope (which lives
  // below the Navigator and isn't visible from a modal route). Null for
  // bonus wells or for the blocked variant.
  final String? shrinkText;

  @override
  Widget build(BuildContext context) {
    final bool blocked = well.loggedThisCycle > 0;

    return Container(
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: CropkeepColors.borderDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                ),
                children: [
                  TextSpan(text: blocked ? "Can't remove " : 'Remove '),
                  TextSpan(
                    text: well.name,
                    style: const TextStyle(
                      color: CropkeepColors.textRedDeep,
                    ),
                  ),
                  TextSpan(text: blocked ? '' : '?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _bodyCopy(),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (blocked)
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: CropkeepColors.textPrimary,
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: const BorderSide(
                      color: CropkeepColors.borderCard,
                      width: 1.5,
                    ),
                  ),
                  child: const Text('Close'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: CropkeepColors.textPrimary,
                          textStyle: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(
                            color: CropkeepColors.borderCard,
                            width: 1.5,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: CropkeepColors.redAlert,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Remove'),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _bodyCopy() {
    if (well.loggedThisCycle > 0) {
      return 'It has income logged this cycle. Remove those entries '
          'first, or wait until the cycle closes — past income stays '
          'tied to the well that recorded it.';
    }
    if (shrinkText != null) {
      return 'Your reservoir will shrink by $shrinkText. Plot budgets '
          'you already allocated against the larger reservoir will read '
          'as over-allocated until you rebalance.';
    }
    return 'It will disappear from your Wells list right away. Past '
        'cycles will still reference it in their history.';
  }
}

// Lives inside a bordered card alongside data rows, so a dashed border (as
// used on _AddPlotRow) would over-decorate. Instead the `+` sits inside a
// small cream pill so the row reads as a chip-style CTA rather than another
// list entry.
class _AddWellRow extends StatelessWidget {
  const _AddWellRow({
    required this.label,
    required this.type,
    required this.reservoirTotal,
    required this.bonusLogged,
  });

  final String label;
  final WellType type;
  final int reservoirTotal;
  final int bonusLogged;

  void _openNewWell(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewWellScreen(
          type: type,
          reservoirTotal: reservoirTotal,
          bonusLogged: bonusLogged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openNewWell(context),
      borderRadius: BorderRadius.circular(8),
      // Asymmetric padding (20 top / 4 bottom) so the content sits visually
      // centered between the divider above and the card edge below: the
      // section card adds 16px below this row, so 4 + 16 = 20 matches the
      // 20px top. Symmetric 12/12 looked top-biased because the card's
      // bottom padding wasn't being accounted for.
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: CropkeepColors.bgScreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: CropkeepColors.textNavInactive,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textNavInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// View-model types — populated from PlotRow / WellRow via the factories
// above. The shape is stable so the rendering widgets below don't need
// to know the data layer changed.

class _SamplePlot {
  const _SamplePlot({
    required this.plotId,
    required this.name,
    required this.iconAsset,
    required this.budget,
    required this.spent,
    required this.state,
    required this.kind,
    this.swatch = CropkeepColors.greenHint,
    this.statusLabel,
    this.dueDay,
    this.isUnplanned = false,
    this.incomeSharePct,
  });

  // Source plot row id. Plumbed through so the row can paint
  // per-plot affordances (fertilizer corner indicator) and the
  // breakdown handoff doesn't need to re-resolve by name.
  final int plotId;
  final String name;
  final String iconAsset;
  final int? budget;
  final int spent;
  final _PlotVisualState state;
  final _PlotKind kind;
  final Color swatch;
  final String? statusLabel;
  final int? dueDay;
  final bool isUnplanned;
  final double? incomeSharePct;
}

class _SampleWell {
  const _SampleWell({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.subtitle,
    required this.loggedThisCycle,
    required this.isBonus,
    this.isCarryover = false,
    this.expectedInBase,
  });

  // Source well row id — plumbed so the row's overflow menu can call
  // wells.archive(id) without re-resolving by name.
  final int id;
  final String name;
  final String iconAsset;
  final String? subtitle;
  final int loggedThisCycle;
  final bool isBonus;
  final bool isCarryover;
  // Foundation only: expected_amount converted to base minor so the
  // remove sheet can say "your reservoir shrinks by $X" without redoing
  // the currency math at the leaf. Null for bonus wells (their estimates
  // are advisory, not reservoir-load-bearing).
  final int? expectedInBase;
}

// Maps the local sample types to the breakdown screen's public model. Lives
// at the data-shape boundary so the breakdown screen stays decoupled from
// farm_screen's private types.
BreakdownPlot _toBreakdownPlot(_SamplePlot p) => BreakdownPlot(
      name: p.name,
      iconAsset: p.iconAsset,
      spent: p.spent,
      budget: p.budget,
      kind: _toBreakdownKind(p),
    );

BreakdownPlotKind _toBreakdownKind(_SamplePlot p) {
  if (p.isUnplanned) return BreakdownPlotKind.unplanned;
  switch (p.kind) {
    case _PlotKind.discretionary:
      return BreakdownPlotKind.discretionary;
    case _PlotKind.fixedObligation:
      return BreakdownPlotKind.fixedObligation;
    case _PlotKind.investment:
      return BreakdownPlotKind.investment;
  }
}



// ──────────────────────────────────────────────────────────────────────────
// Shared primitives — mirror of farmer_screen.dart conventions. Once both
// screens settle, lift these into lib/widgets/.

// Hero chrome — distinct from _SectionCard on purpose. The hero blocks (the
// page-defining number you read first) need to feel like a different kind
// of object than the white data cards underneath, otherwise they read as
// peers and the hierarchy flattens. Differential signals:
//   • warm sand wash (bgHero) instead of white
//   • 18px radius vs data 16px — slightly softer corner
//   • 20px padding vs data 16px — more breathing room
//   • stronger ambient lift (12px blur, 3px y) so the card sits "above"
//     the data layer rather than next to it
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  static const RoundedRectangleBorder _shape = RoundedRectangleBorder(
    side: BorderSide(color: CropkeepColors.borderCard, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(18)),
  );
  static const EdgeInsets _padding = EdgeInsets.all(20);
  static const List<BoxShadow> _shadow = [
    BoxShadow(
      color: CropkeepColors.shadowCard,
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Widget inner = Padding(padding: _padding, child: child);
    final Widget card = onTap == null
        ? Material(
            color: CropkeepColors.bgHero,
            shape: _shape,
            child: inner,
          )
        : Material(
            color: CropkeepColors.bgHero,
            shape: _shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(onTap: onTap, child: inner),
          );
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        boxShadow: _shadow,
      ),
      child: card,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  // Single source of truth for the card frame. Putting the border on the
  // Material via `shape` keeps the rounded edge crisp — a Container+border
  // + child Material previously painted the inner Material over the inside
  // of the border, swallowing it at the corners.
  static const RoundedRectangleBorder _shape = RoundedRectangleBorder(
    side: BorderSide(color: CropkeepColors.borderCard, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  static const EdgeInsets _padding = EdgeInsets.all(16);
  // Ambient lift — paints under the Material's rounded bounds so the card
  // separates from the cream page without a heavy outline.
  static const List<BoxShadow> _shadow = [
    BoxShadow(
      color: CropkeepColors.shadowCard,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: _shadow,
      ),
      child: Material(
        color: Colors.white,
        shape: _shape,
        child: Padding(padding: _padding, child: child),
      ),
    );
  }
}

// Trailing affordance on tappable cards. Sits at the bottom-right inline
// with the reference caption / row status line so it never fights the
// headline number for visual weight. Sand-bg cards (hero) use the deeper
// sand-tinted secondary; white/cream data rows use the standard neutral
// secondary. Size tracks the neighboring text size so the chevron reads
// as a peer to the caption rather than a separate UI element.
class _ForwardChevron extends StatelessWidget {
  const _ForwardChevron({required this.onHero});

  final bool onHero;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: onHero ? 20 : 18,
      color: onHero
          ? CropkeepColors.textSecondaryOnHero
          : CropkeepColors.textSecondary,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.leadingAsset});

  final String title;
  // Optional 18px SVG glyph that prefixes the title. Pulls from Cropkeep's
  // illustrative icon set so section headers feel like part of the same
  // visual language as the row icons — quieter than a Material icon would.
  final String? leadingAsset;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      title,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: CropkeepColors.textPrimary,
        letterSpacing: -0.1,
      ),
    );
    if (leadingAsset == null) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: SvgPicture.asset(leadingAsset!, fit: BoxFit.contain),
        ),
        const SizedBox(width: 8),
        label,
      ],
    );
  }
}

void _comingSoon(BuildContext context, String message) {
  CropkeepToast.info(
    context,
    title: message,
    icon: Icons.hourglass_empty_rounded,
    duration: const Duration(seconds: 2),
  );
}

String _formatMoney(int minorUnits, String symbol, int decimals) {
  final int absUnits = minorUnits.abs();
  int divisor = 1;
  for (int i = 0; i < decimals; i++) {
    divisor *= 10;
  }
  final int whole = absUnits ~/ divisor;
  final String wholeStr = _withThousandsSeparator(whole);
  final String sign = minorUnits < 0 ? '-' : '';
  if (decimals == 0) return '$sign$symbol$wholeStr';
  final String frac =
      (absUnits % divisor).toString().padLeft(decimals, '0');
  return '$sign$symbol$wholeStr.$frac';
}

String _withThousandsSeparator(int value) {
  final String s = value.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}

// ──────────────────────────────────────────────────────────────────────
// Cycle status strip
//
// Only renders at cycle boundaries — during an active, in-period cycle
// it returns SizedBox.shrink(). The header's day-X/Y pill carries the
// progress signal while the cycle is running, so showing the strip
// there too would be noise. Three states still surface a CTA:
//
// • No active cycle, no prior cycle → first-time hero ("Begin tracking
//   your first cycle").
// • No active cycle, prior cycle exists → between-cycles hero ("Begin
//   tracking [month]").
// • Active cycle past end_date → full-width primary "Cycle ended"
//   banner — the only path into closeAndStart.

class _CycleStatusStrip extends StatelessWidget {
  const _CycleStatusStrip();

  void _openTransition(BuildContext context, CycleTransitionMode mode) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => CycleTransitionScreen(mode: mode),
      fullscreenDialog: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<CycleRow?>(
      stream: scope.cycles.watchActiveCycle(),
      builder: (context, snap) {
        final active = snap.data;
        if (active == null) {
          return StreamBuilder<bool>(
            stream: scope.cycles.watchHasAnyCycle(),
            builder: (context, hasSnap) {
              final hasAny = hasSnap.data ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _BeginTrackingHero(
                  hasPriorCycle: hasAny,
                  onTap: () => _openTransition(
                    context,
                    CycleTransitionMode.firstCycle,
                  ),
                ),
              );
            },
          );
        }
        // A cycle ends when the calendar month changes. The stored
        // startDate is always the 1st of the cycle's month, so
        // comparing (year, month) is enough — no need to look at
        // endDate's day.
        final now = DateTime.now();
        final cycleStart = DateTime.fromMillisecondsSinceEpoch(active.startDate);
        final pastEnd = now.year != cycleStart.year ||
            now.month != cycleStart.month;
        if (pastEnd) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _CycleEndedBanner(
              onTap: () => _openTransition(
                context,
                CycleTransitionMode.closeAndStart,
              ),
            ),
          );
        }
        // Active cycle, still inside its period — header's pill is the
        // sole progress display, nothing else needs to show here.
        return const SizedBox.shrink();
      },
    );
  }
}

class _BeginTrackingHero extends StatelessWidget {
  const _BeginTrackingHero({
    required this.hasPriorCycle,
    required this.onTap,
  });

  final bool hasPriorCycle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final range = CycleRepository.proposedNextCycleRange();
    final monthName = _monthNameFromInt(range.start.month);
    final startStr = '${_monthAbbrev(range.start.month)} ${range.start.day}';
    final endStr = '${_monthAbbrev(range.end.month)} ${range.end.day}';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: CropkeepColors.bgHero,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CropkeepColors.borderCard, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_rounded,
                  size: 22, color: CropkeepColors.greenPrimary),
              const SizedBox(width: 8),
              Text(
                hasPriorCycle ? 'Ready for $monthName' : 'Welcome to Cropkeep',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasPriorCycle
                ? 'Your previous cycle is sealed in the harvest history. '
                    'Begin tracking $monthName when you\'re ready.'
                : 'Add plots and wells below to map out your spending. '
                    'Press Begin tracking when you want to start logging '
                    'transactions against this cycle.',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: CropkeepColors.textSecondaryOnHero,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '$startStr – $endStr',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CropkeepColors.textGreenDeep,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: CropkeepColors.greenPrimary,
                foregroundColor: CropkeepColors.textOnGreenBtn,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Begin tracking  ▸'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleEndedBanner extends StatelessWidget {
  const _CycleEndedBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CropkeepColors.greenPrimary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.eco_rounded,
                  color: CropkeepColors.textOnGreenBtn, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cycle ended',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textOnGreenBtn,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap to reconcile transactions and harvest',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CropkeepColors.textOnGreenBtn,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  color: CropkeepColors.textOnGreenBtn, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

String _monthNameFromInt(int month) {
  const names = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[month];
}

String _monthAbbrev(int month) {
  const names = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[month];
}
