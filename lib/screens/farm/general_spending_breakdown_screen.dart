import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../theme/colors.dart';
import '../../widgets/breakdown_envelope_header.dart';

// ──────────────────────────────────────────────────────────────────────────
// GeneralSpendingBreakdownScreen — full-screen drill-down pushed from the
// Crops subpage hero card. Sole question this page answers: how is the
// cycle's spending distributed across categories (plots)?
//
// Health (per-plot state), budget compliance, projection, and the
// reservoir/bonus split are intentionally absent — they're answered on
// the Crops subpage and the (forthcoming) Wells subpage. This page is a
// pure composition view across all plots. The per-plot drill-down (which
// transactions constitute a given plot's spend) lives in PlotBreakdownScreen.

// ──────────────────────────────────────────────────────────────────────────
// Public data model.

enum BreakdownPlotKind { discretionary, fixedObligation, unplanned }

class BreakdownPlot {
  const BreakdownPlot({
    required this.name,
    required this.iconAsset,
    required this.spent,
    required this.kind,
  });

  final String name;
  final String iconAsset;
  final int spent;
  final BreakdownPlotKind kind;
}

class GeneralSpendingBreakdownData {
  const GeneralSpendingBreakdownData({
    required this.totalIncome,
    required this.cycleDay,
    required this.cycleLength,
    required this.plots,
  });

  // Total cycle income (foundation + logged bonus). The reservoir/bonus
  // split lives on the Wells subpage; this page only needs the combined
  // ceiling to contextualize "spent of available."
  final int totalIncome;
  final int cycleDay;
  final int cycleLength;
  final List<BreakdownPlot> plots;

  int get totalSpent =>
      plots.fold<int>(0, (sum, p) => sum + p.spent);
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

class _Body extends StatelessWidget {
  const _Body({
    required this.data,
    required this.symbol,
    required this.decimals,
  });

  final GeneralSpendingBreakdownData data;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    // Spent-descending — the biggest absorbers surface first. Zero-spend
    // plots stay in the list at the bottom so the page still reflects the
    // full set of categories even before any of them has been touched.
    final List<BreakdownPlot> plotsSorted = [...data.plots]
      ..sort((a, b) => b.spent.compareTo(a.spent));

    final int spent = data.totalSpent;
    final int income = data.totalIncome;
    final bool isOver = spent > income;
    final int overrun = isOver ? spent - income : 0;
    final double progressFraction =
        income <= 0 ? 0.0 : (spent / income).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BreakdownEnvelopeHeader(
            eyebrowMarkAsset: 'assets/icons/ledger.svg',
            eyebrowText: 'CYCLE LEDGER',
            title: 'Spending breakdown',
            amountMinor: spent,
            overrunMinor: overrun,
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
            progressFraction: progressFraction,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: _CategoryBreakdownSection(
                plotsSorted: plotsSorted,
                totalSpent: data.totalSpent,
                symbol: symbol,
                decimals: decimals,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Category breakdown — the page's centerpiece. The per-row share bars
// ARE the visualization; no separate stacked bar above. Bar width on each
// row = that plot's share of total spend, so scanning the column
// top-to-bottom reads as a horizontal-bar breakdown chart.

class _CategoryBreakdownSection extends StatelessWidget {
  const _CategoryBreakdownSection({
    required this.plotsSorted,
    required this.totalSpent,
    required this.symbol,
    required this.decimals,
  });

  final List<BreakdownPlot> plotsSorted;
  final int totalSpent;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    // No dividers between rows: each row already terminates with its
    // amber share bar, which acts as a strong horizontal end-mark. The
    // pale divider line on top of that read as noise without aiding the
    // scan. Row vertical padding picks up the breathing room instead.
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('By category'),
          const SizedBox(height: 8),
          if (totalSpent == 0)
            const _EmptyBreakdownState()
          else
            for (final plot in plotsSorted)
              _CategoryRow(
                plot: plot,
                totalSpent: totalSpent,
                symbol: symbol,
                decimals: decimals,
              ),
        ],
      ),
    );
  }
}

class _EmptyBreakdownState extends StatelessWidget {
  const _EmptyBreakdownState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Nothing spent yet this cycle.\n'
          'Bars fill in as you log transactions.',
          textAlign: TextAlign.center,
          style: TextStyle(
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
    required this.plot,
    required this.totalSpent,
    required this.symbol,
    required this.decimals,
  });

  final BreakdownPlot plot;
  final int totalSpent;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final double sharePct =
        totalSpent <= 0 ? 0 : (plot.spent / totalSpent) * 100.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: SvgPicture.asset(plot.iconAsset, fit: BoxFit.contain),
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
                        plot.name,
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
                      _formatMoney(plot.spent, symbol: symbol, decimals: decimals),
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
                        _kindLabel(plot.kind),
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
                      '${_formatSharePct(sharePct)}% of spend',
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
                _ShareBar(sharePct: sharePct),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Monochrome amber bar — width encodes the plot's share of total spend.
// One color across all rows by design: meaning is in the width, not the
// hue. Gold/amber sits in the "currency" semantic family, which is the
// right register for "money spent" without conflicting with the green/
// red plot-health palette used on the Crops subpage.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.sharePct});

  final double sharePct;

  static const double _height = 8;

  @override
  Widget build(BuildContext context) {
    final double fraction = (sharePct / 100.0).clamp(0.0, 1.0);
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
              child: Container(color: CropkeepColors.textGoldDeep),
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
