import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../theme/colors.dart';
import '../../widgets/apply_fertilizer_sheet.dart';
import '../../widgets/breakdown_envelope_header.dart';
import '../market/market_catalog.dart';
import 'general_spending_breakdown_screen.dart' show BreakdownPlotKind;
import 'new_plot_screen.dart';

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
    required this.plotId,
    required this.plotName,
    required this.iconAsset,
    required this.kind,
    required this.budget,
    required this.cycleDay,
    required this.cycleLength,
    required this.cycleStartWeekday,
    required this.transactions,
    required this.reservoirTotal,
    required this.allocatedSoFar,
    required this.cycleId,
    this.totalIncome,
    this.incomeSharePct,
  });

  // Active cycle id — needed so the Apply Fertilizer action sheet can
  // scope its write to the current cycle (one pack per plot per cycle).
  // Always set when the breakdown is opened from the Crops subpage,
  // which only routes to this screen with an active cycle present.
  final int cycleId;

  // Row id from `plots`. Needed so the overflow menu's Remove action
  // can call PlotRepository.archive — Unplanned still surfaces an id but
  // the menu refuses to act on it.
  final int plotId;
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

  // Cycle reservoir context — carry-throughs from the Crops page so the
  // Edit-plot flow can reuse NewPlotScreen's allocation bar without
  // re-fetching plots + rates from this screen. reservoirTotal is the
  // foundation cap; allocatedSoFar is the sum of all active non-Unplanned
  // plot budgets converted to base. Both in base minor units.
  final int reservoirTotal;
  final int allocatedSoFar;

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
    // For investment plots the "budget" is a fill-up target, not a ceiling.
    // Going past the target is virtuous — overage shouldn't paint as a
    // red over-cap warning, so we don't compute an overrun for investments.
    final bool isInvestment = data.kind == BreakdownPlotKind.investment;
    final bool isOver = !isInvestment && budget != null && spent > budget;
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

    // Unplanned is undeletable per project memory; everything else can
    // be archived as long as no live transaction was logged against it
    // this cycle. Soft-deleted transactions don't count — `data.transactions`
    // is already filtered to deletedAt IS NULL upstream in watchByPlot, so
    // emptiness here is the exact "no live txns this cycle" signal.
    final bool canRemove =
        !data.isUnplanned && data.transactions.isEmpty;
    final bool showMenu = !data.isUnplanned;

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
            trailing: showMenu
                ? _PlotOverflowMenu(
                    plotId: data.plotId,
                    plotName: data.plotName,
                    canRemove: canRemove,
                    reservoirTotal: data.reservoirTotal,
                    allocatedSoFar: data.allocatedSoFar,
                    cycleId: data.cycleId,
                    cycleDay: data.cycleDay,
                    cycleLength: data.cycleLength,
                  )
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fertilizer is a per-cycle modifier the player should
                  // see and edit at a glance, not bury behind ⋮. Renders
                  // above the transaction list because it's small and
                  // sets the harvest plan context before the user dives
                  // into the spending detail.
                  //
                  // Hidden for Unplanned (wild patch isn't fertilizable
                  // per project memory) and when no active cycle exists
                  // (nothing to scope the application to).
                  if (!data.isUnplanned && data.cycleId > 0) ...[
                    _FertilizerSection(
                      plotId: data.plotId,
                      cycleId: data.cycleId,
                      plotName: data.plotName,
                      cycleDay: data.cycleDay,
                      cycleLength: data.cycleLength,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _TransactionsSection(
                    transactionsSorted: txSorted,
                    totalSpent: data.totalSpent,
                    cycleStartWeekday: data.cycleStartWeekday,
                    symbol: symbol,
                    decimals: decimals,
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
    // Investments fill toward a target instead of spending against a
    // budget — same number, different word — so the caption reads
    // "of $X target" for investment plots and "of $X budget" otherwise.
    final bool isInvestment = data.kind == BreakdownPlotKind.investment;
    spans.addAll([
      const TextSpan(text: 'of '),
      TextSpan(
        text: _formatMoney(data.budget ?? 0, symbol: symbol, decimals: decimals),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      TextSpan(text: isInvestment ? ' target' : ' budget'),
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
// Overflow control — top-right ⋮ on the envelope header. The button itself
// is a plain glyph tinted to match the back arrow so the two corner
// affordances read as a pair, not as one custom + one Material control.
//
// Tap opens a Cropkeep-styled action sheet rather than the stock
// PopupMenuButton: a Material popup card collides with the sand/cream
// palette, and the app already speaks bottom-sheet for every meaningful
// action (log expense, confirm cycle close, etc.) — using the same
// vocabulary here keeps the chrome consistent.
//
// The blocked-state explanation lives INSIDE the action sheet on the
// disabled row rather than as a separate "blocked" sheet you reach by
// tapping a disabled item. One tap, one surface, with the rule visible
// up front — the user learns why the action is gated without having to
// poke at it.

class _PlotOverflowMenu extends StatelessWidget {
  const _PlotOverflowMenu({
    required this.plotId,
    required this.plotName,
    required this.canRemove,
    required this.reservoirTotal,
    required this.allocatedSoFar,
    required this.cycleId,
    required this.cycleDay,
    required this.cycleLength,
  });

  final int plotId;
  final String plotName;
  // True iff the plot has no live transactions this cycle. Gates the
  // destructive Remove action AND the financial fields in Edit (kind,
  // budget, currency) — same rule, same source of truth.
  final bool canRemove;
  // Carry-throughs for the Edit flow: NewPlotScreen needs the cycle's
  // reservoir context to render its allocation bar.
  final int reservoirTotal;
  final int allocatedSoFar;
  // Cycle context for the Apply fertilizer flow — scopes the write to
  // the active cycle and supplies the "Day n of N" hint in the sheet.
  final int cycleId;
  final int cycleDay;
  final int cycleLength;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'More',
      onPressed: () => _open(context),
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 26,
        color: CropkeepColors.textSecondaryOnHero,
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final action = await showModalBottomSheet<_PlotMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PlotActionSheet(
        plotName: plotName,
        canEditFinancials: canRemove,
      ),
    );
    if (action == null) return;
    switch (action) {
      case _PlotMenuAction.edit:
        if (!context.mounted) return;
        await _openEdit(context);
      case _PlotMenuAction.remove:
        if (!context.mounted) return;
        final confirmed = await _showRemoveConfirmSheet(context, plotName);
        if (confirmed != true) return;
        if (!context.mounted) return;
        await AppScope.of(context).plots.archive(plotId);
        if (!context.mounted) return;
        Navigator.of(context).maybePop();
    }
  }

  // Fetches the freshest plot row right before opening the editor so the
  // form hydrates from current values (the breakdown screen was opened
  // with a snapshot; the row may have been edited from another flow
  // since). On successful save the breakdown pops too — its snapshot is
  // now stale, and the Crops list is live-queried so the user lands on
  // up-to-date data.
  Future<void> _openEdit(BuildContext context) async {
    final scope = AppScope.of(context);
    final PlotRow? row =
        await scope.plots.watchById(plotId).first;
    if (row == null || !context.mounted) return;
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NewPlotScreen(
          reservoirTotal: reservoirTotal,
          allocatedSoFar: allocatedSoFar,
          existingPlot: row,
          canEditFinancials: canRemove,
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    Navigator.of(context).maybePop();
  }
}

enum _PlotMenuAction { edit, remove }

Future<bool?> _showRemoveConfirmSheet(BuildContext context, String name) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _RemovePlotConfirmSheet(plotName: name),
  );
}

// Cropkeep-styled action sheet. Shape and chrome mirror
// LedgerEntryDetailSheet / log_transaction_sheet so the user reads it as
// "the same kind of surface" the rest of the app uses.
class _PlotActionSheet extends StatelessWidget {
  const _PlotActionSheet({
    required this.plotName,
    required this.canEditFinancials,
  });

  final String plotName;
  // Same gate as Remove (no live transactions this cycle). Edit is always
  // available — this flag only changes its caption to flag what will be
  // locked once the editor opens. Remove uses this flag directly as its
  // enabled state.
  final bool canEditFinancials;

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 14),
            // Small eyebrow + plot name so the sheet anchors back to which
            // plot is being acted on (without re-stating the breakdown
            // hero — that would feel echoey).
            Text(
              plotName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            _ActionRow(
              icon: Icons.edit_outlined,
              label: 'Edit plot',
              caption: canEditFinancials
                  ? 'Change the name, budget, kind, crop, color, or due day.'
                  : 'Change name, crop, color, or due day. Budget and kind '
                      'stay locked while transactions exist this cycle.',
              destructive: false,
              enabled: true,
              onTap: () =>
                  Navigator.of(context).pop(_PlotMenuAction.edit),
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.delete_outline_rounded,
              label: 'Remove plot',
              caption: canEditFinancials
                  ? 'Archived from your Crops list. History stays intact.'
                  : 'Has transactions this cycle — remove them first or '
                      'wait until the cycle closes.',
              destructive: true,
              enabled: canEditFinancials,
              onTap: () =>
                  Navigator.of(context).pop(_PlotMenuAction.remove),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
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
          ],
        ),
      ),
    );
  }
}

// White card row inside the action sheet — same card grammar as
// _DetailCard / _SectionCard so an "action you can take" reads as a
// peer of "info you can look at." Naked leading icon (no tinted-square
// chiclet) keeps the row light enough to scale to more actions later;
// color carries the destructive signal so the chrome stays calm. A
// trailing chevron marks navigable rows ("tap leads to another
// surface") and is omitted on destructive rows so they read as
// terminal intent rather than "go somewhere." Disabled state mutes
// the colors and drops the tap target + the chevron rather than
// offering a separate blocked sheet — the caption carries the rule.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.caption,
    required this.destructive,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final bool destructive;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = destructive
        ? CropkeepColors.textRedDeep
        : CropkeepColors.textPrimary;
    final Color labelColor =
        enabled ? accent : CropkeepColors.textSecondary;
    final Color iconColor =
        enabled ? accent : CropkeepColors.textSecondary;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          color: CropkeepColors.borderCard,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: labelColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      caption,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CropkeepColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled && !destructive) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: CropkeepColors.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RemovePlotConfirmSheet extends StatelessWidget {
  const _RemovePlotConfirmSheet({required this.plotName});

  final String plotName;

  @override
  Widget build(BuildContext context) {
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
                  const TextSpan(text: 'Remove '),
                  TextSpan(
                    text: plotName,
                    style: const TextStyle(
                      color: CropkeepColors.textRedDeep,
                    ),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'It will disappear from your Crops list right away. Past '
              'cycles will still reference it in their history.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
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
    case BreakdownPlotKind.investment:
      return 'INVESTMENT PLOT';
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
// Fertilizer section — first-class affordance on the breakdown page.
//
// Two visual states share the section card chrome:
//   • Empty   — leaf glyph + "No fertilizer applied" + brief hint + a
//               full-width green "Apply fertilizer" button.
//   • Applied — SVG art + name + effect description + two side-by-side
//               buttons (Swap, Remove).
//
// Lives ABOVE the transactions card. Fertilizer is a per-cycle modifier
// that sets the harvest plan; transactions are the per-cycle ledger.
// Surfacing the modifier first orients the reader before they scan
// the transaction detail.
//
// Watches `fertilizers.watchByPlotAndCycle` so apply/remove from the
// sheet shows up in the section instantly without manual refresh.

class _FertilizerSection extends StatelessWidget {
  const _FertilizerSection({
    required this.plotId,
    required this.cycleId,
    required this.plotName,
    required this.cycleDay,
    required this.cycleLength,
  });

  final int plotId;
  final int cycleId;
  final String plotName;
  final int cycleDay;
  final int cycleLength;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<PlotFertilizerApplicationRow?>(
      stream: scope.fertilizers
          .watchByPlotAndCycle(cycleId: cycleId, plotId: plotId),
      builder: (context, snap) {
        final row = snap.data;
        MarketItemSpec? spec;
        if (row != null) {
          for (final s in MarketCatalog.fertilizers) {
            if (s.itemId == row.fertilizerItemId) {
              spec = s;
              break;
            }
          }
        }
        return _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const _SectionHeader('Fertilizer'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      spec == null
                          ? 'Optional · 1 pack per cycle'
                          : 'Boosting this cycle',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: CropkeepColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (spec == null)
                _FertilizerEmptyBody(
                  onApply: () => _openApplySheet(context),
                )
              else
                _FertilizerAppliedBody(
                  spec: spec,
                  onSwap: () => _openApplySheet(context),
                  onRemove: () => _confirmRemove(context),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openApplySheet(BuildContext context) async {
    await showApplyFertilizerSheetLive(
      context,
      plotId: plotId,
      cycleId: cycleId,
      plotName: plotName,
      cycleDay: cycleDay,
      cycleLength: cycleLength,
    );
  }

  // Same forfeit-on-remove policy as the sheet's Remove path. Lives
  // here so the section's Remove button doesn't have to bounce through
  // the sheet just to access the confirm; consistent confirm copy
  // ("pack forfeited") keeps the two surfaces in sync.
  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _RemoveFertilizerConfirmSheet(),
    );
    if (confirmed != true || !context.mounted) return;
    final scope = AppScope.of(context);
    await scope.fertilizers.removeFromPlot(
      cycleId: cycleId,
      plotId: plotId,
    );
  }
}

class _FertilizerEmptyBody extends StatelessWidget {
  const _FertilizerEmptyBody({required this.onApply});
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: CropkeepColors.bgHero,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: CropkeepColors.borderCard,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.local_florist_outlined,
                size: 22,
                color: CropkeepColors.textSecondaryOnHero,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No fertilizer applied',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Boost yield or rescue a stressed crop. One pack '
                    'per plot per cycle — no refund on swap.',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CropkeepColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            onPressed: onApply,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Apply fertilizer'),
            style: FilledButton.styleFrom(
              backgroundColor: CropkeepColors.greenPrimary,
              foregroundColor: CropkeepColors.textOnGreenBtn,
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FertilizerAppliedBody extends StatelessWidget {
  const _FertilizerAppliedBody({
    required this.spec,
    required this.onSwap,
    required this.onRemove,
  });

  final MarketItemSpec spec;
  final VoidCallback onSwap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: CropkeepColors.greenHint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CropkeepColors.greenPrimary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(spec.iconAsset, width: 36, height: 36),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    spec.name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    spec.description,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CropkeepColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onSwap,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Swap'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CropkeepColors.textPrimary,
                    side: const BorderSide(
                      color: CropkeepColors.borderCard,
                      width: 1.5,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CropkeepColors.textRedDeep,
                    side: BorderSide(
                      color:
                          CropkeepColors.redAlert.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RemoveFertilizerConfirmSheet extends StatelessWidget {
  const _RemoveFertilizerConfirmSheet();

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Remove fertilizer?',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The pack is forfeited — no refund. The plot reverts to '
              'its unboosted yield for this cycle.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
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
