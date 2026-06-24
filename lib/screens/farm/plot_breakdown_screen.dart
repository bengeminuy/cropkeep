import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../theme/colors.dart';
import '../../widgets/breakdown_envelope_header.dart';
import 'general_spending_breakdown_screen.dart' show BreakdownPlotKind;

// ──────────────────────────────────────────────────────────────────────────
// PlotBreakdownScreen — per-plot drill-down pushed from a row on the Crops
// subpage. Sole question this page answers: which transactions constitute
// this plot's spend this cycle, and how do they sit against the plot's
// allocated budget?
//
// Mirror of GeneralSpendingBreakdownScreen, one level deeper: the general
// screen breaks the cycle's spend across plots; this one breaks a single
// plot's spend across its transactions. Same envelope-header chrome (sand
// band that continues the surface the user just tapped on Crops) and the
// same gold share bars, so the visual lineage from "I tapped a plot row,
// this is the inverse view" is obvious.
//
// Plot health, pace nudges, and cross-plot context are intentionally
// absent — those live on the Crops subpage row itself. This page is a
// pure composition view of one plot's transactions.

// ──────────────────────────────────────────────────────────────────────────
// Public data model.

class PlotBreakdownTransaction {
  const PlotBreakdownTransaction({
    required this.description,
    required this.amount,
    required this.cycleDay,
  });

  // Free-text label for the transaction (e.g. "Groceries", "Concert
  // tickets"). The transaction repository populates this from the user's
  // note; an empty string is allowed and renders as "Unlabeled".
  final String description;
  // Amount in base-currency minor units (cents). Always positive — this
  // page only shows outflows from a plot's allocation.
  final int amount;
  // Day-of-cycle the transaction was logged on. Drives the day badge and
  // serves as the secondary sort key when two transactions tie on amount.
  final int cycleDay;
}

class PlotBreakdownData {
  const PlotBreakdownData({
    required this.plotName,
    required this.iconAsset,
    required this.kind,
    required this.budget,
    required this.cycleDay,
    required this.cycleLength,
    required this.cycleStartWeekday,
    required this.transactions,
    this.totalIncome,
    this.incomeSharePct,
  });

  final String plotName;
  final String iconAsset;
  final BreakdownPlotKind kind;
  // Allocated budget for this plot in minor units. Null for the Unplanned
  // wild patch — it has no pre-budget by design (see project memory).
  final int? budget;
  final int cycleDay;
  final int cycleLength;
  // Weekday the cycle started on, using DateTime convention (1 = Mon …
  // 7 = Sun). The calendar tile on each transaction row derives day-of-
  // week from cycleDay + this offset, so the per-transaction data stays
  // free of absolute dates while the rows still surface weekday pattern.
  final int cycleStartWeekday;
  final List<PlotBreakdownTransaction> transactions;

  // Unplanned-only context. The wild patch is measured against total cycle
  // income via the 20% danger threshold rather than a budget cap, so the
  // hero needs the income reference + the precomputed share to render its
  // caption without re-doing the math the Crops row already did.
  final int? totalIncome;
  final double? incomeSharePct;

  int get totalSpent =>
      transactions.fold<int>(0, (sum, t) => sum + t.amount);

  bool get isUnplanned => kind == BreakdownPlotKind.unplanned;
}

// ──────────────────────────────────────────────────────────────────────────
// Screen.

// Unplanned bar measures spend against the 20% income danger threshold —
// same convention as the Crops subpage row, so the two readings agree.
const double _unplannedDangerCap = 20.0;

class PlotBreakdownScreen extends StatelessWidget {
  const PlotBreakdownScreen({super.key, required this.data});

  final PlotBreakdownData data;

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

  final PlotBreakdownData data;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    // Amount-descending — biggest individual expenses surface first, which
    // matches the general breakdown's "biggest absorbers first" principle
    // and answers "what's bloating this plot?" at a glance. Day desc as
    // the tiebreaker so two equal-amount transactions still order most
    // recent first.
    final List<PlotBreakdownTransaction> txSorted = [...data.transactions]
      ..sort((a, b) {
        final int byAmount = b.amount.compareTo(a.amount);
        if (byAmount != 0) return byAmount;
        return b.cycleDay.compareTo(a.cycleDay);
      });

    final int spent = data.totalSpent;
    final int? budget = data.budget;
    final bool isOver = budget != null && spent > budget;
    final int overrun = isOver ? spent - budget : 0;

    final double progressFraction;
    if (data.isUnplanned) {
      progressFraction =
          ((data.incomeSharePct ?? 0) / _unplannedDangerCap).clamp(0.0, 1.0);
    } else {
      final int b = budget ?? 0;
      progressFraction =
          b <= 0 ? 0.0 : (spent / b).clamp(0.0, 1.0);
    }

    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BreakdownEnvelopeHeader(
            iconAsset: data.iconAsset,
            eyebrowText: _kindLabel(data.kind),
            title: data.plotName,
            amountMinor: spent,
            overrunMinor: overrun,
            captionSpans: _buildCaptionSpans(data, symbol, decimals),
            progressFraction: progressFraction,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: _TransactionsSection(
                transactionsSorted: txSorted,
                totalSpent: data.totalSpent,
                cycleStartWeekday: data.cycleStartWeekday,
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

// Reference value + cycle position. Reference depends on plot kind:
// budgeted plots show "of $X budget", Unplanned shows "of $X income · Y%
// of income" since it has no budget to compare against.
List<InlineSpan> _buildCaptionSpans(
  PlotBreakdownData data,
  String symbol,
  int decimals,
) {
  final List<InlineSpan> spans = [];
  if (data.isUnplanned && data.totalIncome != null) {
    spans.addAll([
      const TextSpan(text: 'of '),
      TextSpan(
        text: _formatMoney(data.totalIncome!, symbol: symbol, decimals: decimals),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      const TextSpan(text: ' income  ·  '),
      TextSpan(
        text: '${(data.incomeSharePct ?? 0).toStringAsFixed(1)}%',
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      const TextSpan(text: ' of income'),
    ]);
  } else {
    spans.addAll([
      const TextSpan(text: 'of '),
      TextSpan(
        text: _formatMoney(data.budget ?? 0, symbol: symbol, decimals: decimals),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      const TextSpan(text: ' budget'),
    ]);
  }
  spans.addAll([
    const TextSpan(text: '  ·  Day '),
    TextSpan(
      text: '${data.cycleDay}',
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: CropkeepColors.textPrimary,
      ),
    ),
    TextSpan(text: ' of ${data.cycleLength}'),
  ]);
  return spans;
}

// ──────────────────────────────────────────────────────────────────────────
// Transactions — the page's centerpiece. Per-row share bars ARE the
// visualization; width on each row = that transaction's share of the
// plot's spend, so scanning top-to-bottom reads as a horizontal-bar
// composition of where the money went.

class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection({
    required this.transactionsSorted,
    required this.totalSpent,
    required this.cycleStartWeekday,
    required this.symbol,
    required this.decimals,
  });

  final List<PlotBreakdownTransaction> transactionsSorted;
  final int totalSpent;
  final int cycleStartWeekday;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('By transaction'),
          const SizedBox(height: 8),
          if (totalSpent == 0 || transactionsSorted.isEmpty)
            const _EmptyTransactionsState()
          else
            for (final tx in transactionsSorted)
              _TransactionRow(
                tx: tx,
                totalSpent: totalSpent,
                cycleStartWeekday: cycleStartWeekday,
                symbol: symbol,
                decimals: decimals,
              ),
        ],
      ),
    );
  }
}

class _EmptyTransactionsState extends StatelessWidget {
  const _EmptyTransactionsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'No transactions logged for this plot yet.\n'
          'Each entry you log this cycle will appear here.',
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

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.tx,
    required this.totalSpent,
    required this.cycleStartWeekday,
    required this.symbol,
    required this.decimals,
  });

  final PlotBreakdownTransaction tx;
  final int totalSpent;
  final int cycleStartWeekday;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final double sharePct =
        totalSpent <= 0 ? 0 : (tx.amount / totalSpent) * 100.0;
    final String description =
        tx.description.trim().isEmpty ? 'Unlabeled' : tx.description;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CalendarTile(
            day: tx.cycleDay,
            cycleStartWeekday: cycleStartWeekday,
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
                        description,
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
                      _formatMoney(tx.amount, symbol: symbol, decimals: decimals),
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
                // Caption row reduced to a single right-aligned share figure
                // now that the calendar tile carries day-of-week + day. The
                // tile lives outside this Expanded column, so without the
                // tile's height contribution the title→bar gap was tightening;
                // the share line preserves the row's vertical rhythm and
                // keeps the composition reading aligned with the general
                // breakdown's "X% of spend" caption.
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_formatSharePct(sharePct)}% of spend',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CropkeepColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
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

// Calendar tile — small tear-off-style page on the left of each transaction
// row. Carries day-of-week + day-of-cycle in the icon-column slot used by
// the general breakdown, so a list of transactions reads as a calendar
// scan rather than a column of bare numbers. Day-of-week surfaces the
// pattern a plain day index can't (weekday vs weekend spending) which is
// the actionable signal for plots that vary day to day (Food, Transport).
//
// Chrome: white tile + 1px borderCard so the tile sits cleanly on the
// section card body; sand-wash band at the top carries the weekday label
// (mirrors hero card chrome). Weekend labels switch to textGoldDeep so
// weekend transactions cluster pre-attentively when scanning a long list.
class _CalendarTile extends StatelessWidget {
  const _CalendarTile({
    required this.day,
    required this.cycleStartWeekday,
  });

  final int day;
  final int cycleStartWeekday;

  // 3-letter labels keep the tile readable at 40px wide. Indexed 0..6 from
  // Monday — matches DateTime.monday(1)..sunday(7) when you subtract 1.
  static const List<String> _weekdayLabels = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN',
  ];

  int _weekdayIndex(int day) {
    // Day 1 of the cycle maps to cycleStartWeekday; subsequent days advance
    // by 1. Subtract 1 from each to land in 0..6 space, mod by 7, and the
    // result is a Monday-indexed weekday slot.
    return ((cycleStartWeekday - 1) + (day - 1)) % 7;
  }

  @override
  Widget build(BuildContext context) {
    final int idx = _weekdayIndex(day);
    final bool isWeekend = idx >= 5; // SAT (5) or SUN (6)
    final Color weekdayColor = isWeekend
        ? CropkeepColors.textGoldDeep
        : CropkeepColors.textSecondary;
    return Container(
      width: 40,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Top band — sand wash, 13px tall. The slight color shift from the
          // white body is what makes the tile pre-attentively read as a
          // calendar page rather than a generic chip.
          Container(
            height: 14,
            color: CropkeepColors.bgHero,
            alignment: Alignment.center,
            child: Text(
              _weekdayLabels[idx],
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: weekdayColor,
                letterSpacing: 0.6,
                height: 1,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$day',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Monochrome amber bar — width encodes the transaction's share of the
// plot's total spend. One color across all rows by design: meaning is in
// the width, not the hue. Identical to the general breakdown's _ShareBar
// so the two screens share one visualization grammar.
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
      return 'SPENDING PLOT';
    case BreakdownPlotKind.fixedObligation:
      return 'BILL';
    case BreakdownPlotKind.unplanned:
      return 'WILD PATCH · OFF-BUDGET';
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
// Section card primitive — mirror of general_spending_breakdown_screen.dart
// so this screen doesn't reach across into private types.

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

// Minor-units (cents) → "$1,234.56". Matches the general breakdown's
// formatter so both screens render the same digits.
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
