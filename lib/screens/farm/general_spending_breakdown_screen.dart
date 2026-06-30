import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../theme/colors.dart';
import '../../widgets/breakdown_envelope_header.dart';

// ──────────────────────────────────────────────────────────────────────────
// GeneralSpendingBreakdownScreen — full-screen drill-down pushed from the
// Crops subpage hero card. Answers two complementary cycle-ledger
// questions, one per mode of a segmented toggle:
//   • By spend — how the cycle's outflow distributes across plots
//   • By allocation — how the reservoir splits into plot budgets, with a
//     synthetic Free-reservoir row carrying the unallocated remainder
//
// Same row template across both modes (icon, name, amount, kind label,
// share %, share bar); only the metric, reference total, sort, header
// headline/caption, and the optional Free-reservoir tail row change.
//
// Health (per-plot state) and the bonus pool live elsewhere (Crops and
// Wells subpages). This page is a pure composition view across all plots.
// Per-plot drill-down (which transactions constitute a given plot's spend)
// lives in PlotBreakdownScreen.

// ──────────────────────────────────────────────────────────────────────────
// Public data model.

enum BreakdownPlotKind { discretionary, fixedObligation, investment, unplanned }

class BreakdownPlot {
  const BreakdownPlot({
    required this.name,
    required this.iconAsset,
    required this.spent,
    required this.budget,
    required this.kind,
  });

  final String name;
  final String iconAsset;
  final int spent;
  // Plot budget in base minor units. Null for Unplanned (which has no
  // pre-budget by design) and for any plot the user hasn't budgeted yet.
  final int? budget;
  final BreakdownPlotKind kind;
}

class GeneralSpendingBreakdownData {
  const GeneralSpendingBreakdownData({
    required this.totalIncome,
    required this.reservoirTotal,
    required this.cycleDay,
    required this.cycleLength,
    required this.plots,
  });

  // Spend mode reference: foundation + logged bonus. The full pool the
  // spending column gets compared against.
  final int totalIncome;
  // Allocation mode reference: foundation only — the cap plot budgets are
  // allowed to sum to. Bonus isn't budgeted at plot-creation time.
  final int reservoirTotal;
  final int cycleDay;
  final int cycleLength;
  final List<BreakdownPlot> plots;

  int get totalSpent =>
      plots.fold<int>(0, (sum, p) => sum + p.spent);
  int get totalAllocated =>
      plots.fold<int>(0, (sum, p) => sum + (p.budget ?? 0));
}

// ──────────────────────────────────────────────────────────────────────────
// Screen.

class GeneralSpendingBreakdownScreen extends StatelessWidget {
  const GeneralSpendingBreakdownScreen({super.key, required this.data});

  final GeneralSpendingBreakdownData data;

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
            return _Body(
              data: data,
              symbol: currency?.symbol ?? r'$',
              decimals: currency?.decimalPlaces ?? 2,
            );
          },
        );
      },
    );
  }
}

Stream<CurrencyRow?> _watchBaseCurrency(AppDatabase db, String? code) {
  if (code == null) return Stream<CurrencyRow?>.value(null);
  return (db.select(db.currencies)..where((t) => t.code.equals(code)))
      .watchSingleOrNull();
}

// Page-level mode. The header headline, caption, progress reference, and
// the section card's row metric all swap together — both views share the
// row template but answer different questions, so the toggle controls a
// page-wide state rather than living inside one widget.
enum _BreakdownMode { spend, allocation }

class _Body extends StatefulWidget {
  const _Body({
    required this.data,
    required this.symbol,
    required this.decimals,
  });

  final GeneralSpendingBreakdownData data;
  final String symbol;
  final int decimals;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  _BreakdownMode _mode = _BreakdownMode.spend;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final _ModeView view = _mode == _BreakdownMode.allocation
        ? _allocationView(data, widget.symbol, widget.decimals)
        : _spendView(data, widget.symbol, widget.decimals);

    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BreakdownEnvelopeHeader(
            eyebrowMarkAsset: 'assets/icons/ledger.svg',
            eyebrowText: 'CYCLE LEDGER',
            title: view.title,
            amountMinor: view.amount,
            amountDescriptor: view.descriptor,
            overrunMinor: view.overrun,
            captionSpans: view.captionSpans,
            progressFraction: view.progressFraction,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BreakdownModeToggle(
                    mode: _mode,
                    onChanged: (m) => setState(() => _mode = m),
                  ),
                  const SizedBox(height: 16),
                  _CategoryBreakdownSection(
                    rows: view.rows,
                    shareLabel: view.shareLabel,
                    emptyMessage: view.emptyMessage,
                    symbol: widget.symbol,
                    decimals: widget.decimals,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Per-mode pre-computed values. Built once per build so the widget tree
// stays a flat composition of header + toggle + section.
class _ModeView {
  const _ModeView({
    required this.title,
    required this.descriptor,
    required this.amount,
    required this.overrun,
    required this.captionSpans,
    required this.progressFraction,
    required this.rows,
    required this.shareLabel,
    required this.emptyMessage,
  });

  final String title;
  final String descriptor;
  final int amount;
  final int overrun;
  final List<InlineSpan> captionSpans;
  final double progressFraction;
  final List<_RowVm> rows;
  final String shareLabel;
  final String emptyMessage;
}

_ModeView _spendView(
  GeneralSpendingBreakdownData data,
  String symbol,
  int decimals,
) {
  final int spent = data.totalSpent;
  final int income = data.totalIncome;
  final int overrun = spent > income ? spent - income : 0;
  final double progress =
      income <= 0 ? 0.0 : (spent / income).clamp(0.0, 1.0);
  // Spent-descending — the biggest absorbers surface first. Zero-spend
  // plots stay in the list at the bottom so the page still reflects the
  // full set of categories even before any of them has been touched.
  final List<_RowVm> rows = [
    for (final p in data.plots)
      _RowVm(
        name: p.name,
        iconAsset: p.iconAsset,
        amount: p.spent,
        subtitleLabel: _kindLabel(p.kind),
        sharePct: spent <= 0 ? 0.0 : (p.spent / spent) * 100.0,
        muted: false,
      ),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  return _ModeView(
    title: 'Spending breakdown',
    descriptor: 'spent',
    amount: spent,
    overrun: overrun,
    progressFraction: progress,
    captionSpans: [
      const TextSpan(text: 'of '),
      TextSpan(
        text: _formatMoney(income, symbol: symbol, decimals: decimals),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      const TextSpan(text: ' income  ·  Day '),
      TextSpan(
        text: '${data.cycleDay}',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      TextSpan(text: ' of ${data.cycleLength}'),
    ],
    rows: rows,
    shareLabel: 'of spend',
    emptyMessage:
        'Nothing spent yet this cycle.\nBars fill in as you log transactions.',
  );
}

_ModeView _allocationView(
  GeneralSpendingBreakdownData data,
  String symbol,
  int decimals,
) {
  final int allocated = data.totalAllocated;
  final int reservoir = data.reservoirTotal;
  final int free = reservoir > allocated ? reservoir - allocated : 0;
  final int overrun = allocated > reservoir ? allocated - reservoir : 0;
  final double progress =
      reservoir <= 0 ? 0.0 : (allocated / reservoir).clamp(0.0, 1.0);

  // All row shares are over the reservoir so the bars sum to the full cap
  // (plot budgets + the synthetic Free row). "X% of allocated" would lose
  // the headroom story; "of reservoir" keeps it.
  double pctOfReservoir(int amount) =>
      reservoir <= 0 ? 0.0 : (amount / reservoir) * 100.0;

  // Unplanned has no pre-budget by design; off-budget plots (budget == 0
  // or null) similarly drop out — the allocation view is strictly the
  // budgeted partition of the reservoir.
  final List<_RowVm> rows = [
    for (final p in data.plots)
      if ((p.budget ?? 0) > 0)
        _RowVm(
          name: p.name,
          iconAsset: p.iconAsset,
          amount: p.budget!,
          subtitleLabel: _kindLabel(p.kind),
          sharePct: pctOfReservoir(p.budget!),
          muted: false,
        ),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  // Synthetic free-reservoir row pinned to the bottom so the picture sums
  // to the cap. Muted styling signals "this is what's still on the table"
  // rather than another committed slice — the answer to "where could I
  // still put money?"
  if (free > 0) {
    rows.add(
      _RowVm(
        name: 'Free reservoir',
        iconAsset: 'assets/icons/well.svg',
        amount: free,
        subtitleLabel: 'Unallocated',
        sharePct: pctOfReservoir(free),
        muted: true,
      ),
    );
  }

  final String emptyMessage = reservoir <= 0
      ? 'No reservoir yet.\nAdd a foundation well to start your cycle.'
      : 'Reservoir is fully unallocated.\nCreate plots with budgets to divide it up.';

  return _ModeView(
    title: 'Allocation breakdown',
    descriptor: 'allocated',
    amount: allocated,
    overrun: overrun,
    progressFraction: progress,
    captionSpans: [
      const TextSpan(text: 'of '),
      TextSpan(
        text: _formatMoney(reservoir, symbol: symbol, decimals: decimals),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      const TextSpan(text: ' reservoir  ·  '),
      TextSpan(
        text: _formatMoney(free, symbol: symbol, decimals: decimals),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      const TextSpan(text: ' free'),
    ],
    rows: rows,
    shareLabel: 'of reservoir',
    emptyMessage: emptyMessage,
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Segmented toggle — page-level mode selector. Mirrors the Farm screen's
// Crops/Wells segmented control style so the affordance reads as native to
// the app's pattern. Sits between the envelope header and the section
// card; controls both the header's headline/caption and the section's row
// metric.

class _BreakdownModeToggle extends StatelessWidget {
  const _BreakdownModeToggle({required this.mode, required this.onChanged});

  final _BreakdownMode mode;
  final ValueChanged<_BreakdownMode> onChanged;

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
            child: _ModeTab(
              label: 'By spend',
              isActive: mode == _BreakdownMode.spend,
              onTap: () => onChanged(_BreakdownMode.spend),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'By allocation',
              isActive: mode == _BreakdownMode.allocation,
              onTap: () => onChanged(_BreakdownMode.allocation),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
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
// Category breakdown — the page's centerpiece. The per-row share bars ARE
// the visualization; no separate stacked bar above. Bar width on each row
// = that row's share of the mode's reference total, so scanning the column
// top-to-bottom reads as a horizontal-bar breakdown chart.

class _RowVm {
  const _RowVm({
    required this.name,
    required this.iconAsset,
    required this.amount,
    required this.subtitleLabel,
    required this.sharePct,
    required this.muted,
  });

  final String name;
  final String iconAsset;
  final int amount;
  final String subtitleLabel;
  final double sharePct;
  // Free-reservoir row only — switches the bar to a muted neutral so it
  // reads as "headroom" rather than another committed slice.
  final bool muted;
}

class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({
    required this.rows,
    required this.shareLabel,
    required this.emptyMessage,
    required this.symbol,
    required this.decimals,
  });

  final List<_RowVm> rows;
  final String shareLabel;
  final String emptyMessage;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    // No dividers between rows: each row already terminates with its
    // amber share bar, which acts as a strong horizontal end-mark. A pale
    // divider line on top of that would read as noise without aiding the
    // scan. Row vertical padding picks up the breathing room instead.
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('By category'),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            _EmptyBreakdownState(message: emptyMessage)
          else
            for (final row in rows)
              _CategoryRow(
                row: row,
                shareLabel: shareLabel,
                symbol: symbol,
                decimals: decimals,
              ),
        ],
      ),
    );
  }
}

class _EmptyBreakdownState extends StatelessWidget {
  const _EmptyBreakdownState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CropkeepColors.textSecondary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.row,
    required this.shareLabel,
    required this.symbol,
    required this.decimals,
  });

  final _RowVm row;
  final String shareLabel;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: SvgPicture.asset(row.iconAsset, fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        row.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: CropkeepColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatMoney(row.amount, symbol: symbol, decimals: decimals),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        row.subtitleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: CropkeepColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatSharePct(row.sharePct)}% $shareLabel',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CropkeepColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ShareBar(sharePct: row.sharePct, muted: row.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Monochrome amber bar — width encodes the row's share of the reference
// total. One color across all rows by design: meaning is in the width, not
// the hue. Gold/amber sits in the "currency" semantic family, which is the
// right register for "money" without conflicting with the green/red plot-
// health palette used on the Crops subpage. The Free-reservoir row passes
// `muted: true` so its bar reads as headroom rather than commitment.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.sharePct, this.muted = false});

  final double sharePct;
  final bool muted;

  static const double _height = 8;

  @override
  Widget build(BuildContext context) {
    final double fraction = (sharePct / 100.0).clamp(0.0, 1.0);
    final Color fill = muted
        ? CropkeepColors.textSecondary
        : CropkeepColors.textGoldDeep;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: _height,
        child: Stack(
          children: [
            Container(color: CropkeepColors.borderDivider),
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

String _kindLabel(BreakdownPlotKind kind) {
  switch (kind) {
    case BreakdownPlotKind.discretionary:
      return 'Spending';
    case BreakdownPlotKind.fixedObligation:
      return 'Bill';
    // "Investment" reads as a different intent from spending/bills — the
    // outflow is directed toward a saving target rather than consumed.
    case BreakdownPlotKind.investment:
      return 'Investment';
    // "Unplanned" is the plot's own name; the kind label has to describe
    // the spending nature without echoing it. "Off-budget" sits cleanly
    // beside "Spending" and "Bill" — same register, distinct fact.
    case BreakdownPlotKind.unplanned:
      return 'Off-budget';
  }
}

// 33.4% → "33", 3.4% → "3.4", 0.0% → "0". Whole numbers above 10 so
// large shares don't look noisy; one decimal under 10 so small shares
// don't all collapse to "0%" or "1%".
String _formatSharePct(double pct) {
  if (pct >= 10) return pct.toStringAsFixed(0);
  if (pct <= 0) return '0';
  return pct.toStringAsFixed(1);
}

// ──────────────────────────────────────────────────────────────────────────
// Section card primitive — mirror of farm_screen.dart so this screen
// doesn't reach across into private types.

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  static const RoundedRectangleBorder _shape = RoundedRectangleBorder(
    side: BorderSide(color: CropkeepColors.borderCard, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  static const EdgeInsets _padding = EdgeInsets.all(16);
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: CropkeepColors.textPrimary,
        letterSpacing: -0.1,
      ),
    );
  }
}

// Minor-units (cents) → "$1,234.56". Matches the farm_screen formatter so
// both screens render the same digits.
String _formatMoney(int minorUnits, {String symbol = r'$', int decimals = 2}) {
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
