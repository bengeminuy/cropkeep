import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../data/currency_catalog.dart';
import '../data/database.dart';
import '../data/tables/cycles.dart' show CycleState;
import '../data/tables/wells.dart' show WellType;
import '../theme/colors.dart';
import '../theme/plot_swatches.dart';

// ──────────────────────────────────────────────────────────────────────────
// LogTransactionSheet — the FAB-launched modal that captures every field
// the schema needs for a transaction or an income entry.
//
// Design contract:
//   • Mode tabs at the top swap target selector and submit copy.
//   • Hero amount field auto-focuses on open.
//   • Currency + date chips below the amount; currency chip hides when
//     only one currency is active.
//   • Source card holds plot chips (expense) or well chips (income),
//     plus a "+ New …" launcher to the existing creation screens.
//   • Emergency card sits in expense mode only; toggling on routes the
//     write to the Unplanned plot with `is_emergency = true`.
//   • Optional single-line note.
//   • Submit is disabled until amount > 0 AND a target is determined
//     (either via chip selection or via the emergency toggle).
//
// All chip / card chrome is inlined here so the Ledger's private widgets
// stay untouched. A future shared-widget refactor can DRY this up.

enum LogTransactionMode { expense, income }

class LogTransactionSheet extends StatefulWidget {
  const LogTransactionSheet({
    super.key,
    this.initialMode = LogTransactionMode.expense,
  });

  final LogTransactionMode initialMode;

  @override
  State<LogTransactionSheet> createState() => _LogTransactionSheetState();
}

class _LogTransactionSheetState extends State<LogTransactionSheet> {
  late LogTransactionMode _mode = widget.initialMode;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  // Selection state. Currency is initialised from the data stream's
  // first emit (to the base currency). Plot / well selection is null
  // until the user picks. Date defaults to today (midnight + current
  // wall-clock time at submit so day grouping stays right).
  String? _currencyCode;
  int? _selectedPlotId;
  int? _selectedWellId;
  DateTime _date = _todayStart();
  bool _isEmergency = false;
  bool _submitting = false;
  bool _attemptedSubmit = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAnyChange);
    // Autofocus on the next frame so the keyboard isn't fighting the
    // sheet's slide-in transition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAnyChange);
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onAnyChange() {
    if (mounted) setState(() {});
  }

  void _setMode(LogTransactionMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      // Targets are mode-specific; reset on swap. Amount / currency /
      // date / note all carry across — the user usually knows what
      // they spent, just realised they hit the wrong tab.
      _selectedPlotId = null;
      _selectedWellId = null;
      _isEmergency = false;
    });
  }

  void _setEmergency(bool value) {
    setState(() => _isEmergency = value);
  }

  Future<void> _pickDate(DateTime cycleStart) async {
    final today = _todayStart();
    final initial = _date.isAfter(today) ? today : _date;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: cycleStart,
      lastDate: today,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;
    setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _pickCurrency(List<CurrencyRow> options) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CropkeepColors.bgScreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                const Text(
                  'Currency',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                for (final row in options)
                  _CurrencyPickerRow(
                    row: row,
                    selected: row.code == _currencyCode,
                    onTap: () => Navigator.of(sheetContext).pop(row.code),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() => _currencyCode = picked);
  }

  bool _validate({required _LogSheetData data}) {
    final raw = _amountController.text.trim();
    if (raw.isEmpty) return false;
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) return false;
    if (_mode == LogTransactionMode.expense) {
      if (_isEmergency) {
        // Emergency always lands on Unplanned — valid even with no chip.
        return data.unplannedPlot != null;
      }
      return _selectedPlotId != null;
    } else {
      return _selectedWellId != null;
    }
  }

  Future<void> _submit(_LogSheetData data) async {
    setState(() => _attemptedSubmit = true);
    if (!_validate(data: data)) return;
    final scope = AppScope.of(context);
    final currencyCode = _currencyCode ?? data.baseCurrency.code;
    final currency = data.currencyByCode[currencyCode] ?? data.baseCurrency;
    final amountMinor = _parseAmountToMinor(
      _amountController.text.trim(),
      currency.decimalPlaces,
    );
    if (amountMinor == null || amountMinor <= 0) return;

    final rateToBase = data.rateToBase(currencyCode);
    final baseAmountMinor = _convertMinor(
      amountMinor,
      sourceDecimals: currency.decimalPlaces,
      targetDecimals: data.baseCurrency.decimalPlaces,
      rate: rateToBase,
    );
    // Compose a timestamp on the chosen date with the current wall-clock
    // time so same-day logs still sort within their day naturally.
    final now = DateTime.now();
    final stamp = DateTime(
      _date.year,
      _date.month,
      _date.day,
      now.hour,
      now.minute,
      now.second,
    );
    final note = _noteController.text.trim();

    setState(() => _submitting = true);
    try {
      if (_mode == LogTransactionMode.expense) {
        final plotId = _isEmergency
            ? data.unplannedPlot!.id
            : _selectedPlotId!;
        final plot = data.plotById(plotId);
        final plotCurrency = plot == null
            ? data.baseCurrency
            : (data.currencyByCode[plot.currencyCode] ?? data.baseCurrency);
        final plotAmountMinor = _convertMinor(
          baseAmountMinor,
          sourceDecimals: data.baseCurrency.decimalPlaces,
          targetDecimals: plotCurrency.decimalPlaces,
          rate: 1 / data.rateToBase(plotCurrency.code).clamp(1e-9, 1e9),
        );
        await scope.transactions.logExpense(
          plotId: plotId,
          cycleId: data.activeCycle.id,
          amountMinor: amountMinor,
          currencyCode: currencyCode,
          baseAmountMinor: baseAmountMinor,
          plotAmountMinor: plotAmountMinor,
          exchangeRate: rateToBase,
          spentAt: stamp,
          note: note.isEmpty ? null : note,
          isEmergency: _isEmergency,
        );
      } else {
        await scope.incomeEntries.logIncome(
          wellId: _selectedWellId!,
          cycleId: data.activeCycle.id,
          amountMinor: amountMinor,
          currencyCode: currencyCode,
          baseAmountMinor: baseAmountMinor,
          exchangeRate: rateToBase,
          receivedAt: stamp,
          note: note.isEmpty ? null : note,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == LogTransactionMode.expense
                ? 'Expense logged.'
                : 'Income logged.',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: media.size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: StreamBuilder<_LogSheetData>(
        stream: _watchLogSheetData(scope.database),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const _LoadingPlaceholder();
          }
          final data = snap.data!;
          // Initialise selected currency on first emit.
          _currencyCode ??= data.baseCurrency.code;
          return _buildForm(data);
        },
      ),
    );
  }

  Widget _buildForm(_LogSheetData data) {
    final currency = data.currencyByCode[_currencyCode] ?? data.baseCurrency;
    final amountText = _amountController.text.trim();
    final parsedAmount = double.tryParse(amountText) ?? 0;
    final amountMinor = parsedAmount <= 0
        ? 0
        : _parseAmountToMinor(amountText, currency.decimalPlaces) ?? 0;
    final rateToBase = data.rateToBase(currency.code);
    final baseMinor = _convertMinor(
      amountMinor,
      sourceDecimals: currency.decimalPlaces,
      targetDecimals: data.baseCurrency.decimalPlaces,
      rate: rateToBase,
    );
    final isExpense = _mode == LogTransactionMode.expense;
    final hasMultiCurrency = data.currencies.length > 1;
    final canSubmit = _validate(data: data) && !_submitting;

    final selectedPlotName = _selectedPlotId == null
        ? null
        : data.plotById(_selectedPlotId!)?.name;
    final selectedWellName = _selectedWellId == null
        ? null
        : data.wellById(_selectedWellId!)?.name;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetHandle(),
            _HeaderRow(
              mode: _mode,
              onModeChanged: _setMode,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Typographic hero — no card, no border. Currency
                    // symbol is rendered smaller (28sp) so the number
                    // stays the dominant element. Tap anywhere in the
                    // row to focus the field.
                    _AmountHero(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      currency: currency,
                      hasError: _attemptedSubmit && (amountMinor <= 0),
                    ),
                    if (currency.code != data.baseCurrency.code &&
                        amountMinor > 0) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          '≈ ${_formatMinor(baseMinor, data.baseCurrency)}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CropkeepColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Center(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (hasMultiCurrency)
                            _PillButton(
                              leading: _CurrencyFlag(code: currency.code),
                              label: currency.code,
                              onTap: () => _pickCurrency(data.currencies),
                            ),
                          _PillButton(
                            leading: const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: CropkeepColors.textSecondary,
                            ),
                            label: _formatDateChip(_date),
                            onTap: () => _pickDate(
                              DateTime.fromMillisecondsSinceEpoch(
                                data.activeCycle.startDate,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _RuleEyebrow(
                      label: isExpense ? 'from' : 'source',
                      suffix: isExpense
                          ? (_isEmergency
                              ? 'unplanned · emergency'
                              : selectedPlotName?.toLowerCase())
                          : selectedWellName?.toLowerCase(),
                    ),
                    const SizedBox(height: 12),
                    if (isExpense)
                      _isEmergency
                          ? _EmergencyRoutedBanner()
                          : _PlotChips(
                              plots: data.plotsSorted,
                              unplannedId: data.unplannedPlot?.id,
                              selectedId: _selectedPlotId,
                              onSelect: (id) =>
                                  setState(() => _selectedPlotId = id),
                            )
                    else
                      _WellChips(
                        wells: data.wellsSorted,
                        selectedId: _selectedWellId,
                        onSelect: (id) =>
                            setState(() => _selectedWellId = id),
                      ),
                    if (_attemptedSubmit &&
                        !_isEmergency &&
                        ((isExpense && _selectedPlotId == null) ||
                            (!isExpense && _selectedWellId == null))) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          isExpense ? 'Pick a plot.' : 'Pick a well.',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CropkeepColors.textRedDeep,
                          ),
                        ),
                      ),
                    ],
                    if (isExpense) ...[
                      const SizedBox(height: 28),
                      _RuleEyebrow(label: 'emergency'),
                      const SizedBox(height: 12),
                      _EmergencyToggleRow(
                        value: _isEmergency,
                        onChanged: _setEmergency,
                      ),
                    ],
                    const SizedBox(height: 28),
                    _RuleEyebrow(label: 'note'),
                    const SizedBox(height: 12),
                    _NoteField(controller: _noteController),
                  ],
                ),
              ),
            ),
            _SubmitFooter(
              isExpense: isExpense,
              canSubmit: canSubmit,
              submitting: _submitting,
              onCancel: () => Navigator.of(context).maybePop(),
              onSubmit: () => _submit(data),
            ),
          ],
        ),
      ),
    );
  }

}

// ──────────────────────────────────────────────────────────────────────────
// Data layer — composite stream of everything the sheet needs.

class _LogSheetData {
  const _LogSheetData({
    required this.activeCycle,
    required this.currencies,
    required this.baseCurrency,
    required this.currencyByCode,
    required this.ratesByCode,
    required this.plotsSorted,
    required this.wellsSorted,
    required this.unplannedPlot,
  });

  final CycleRow activeCycle;
  final List<CurrencyRow> currencies;
  final CurrencyRow baseCurrency;
  final Map<String, CurrencyRow> currencyByCode;
  // Source-currency-code → rate-to-base for the active cycle. Identity
  // (1.0) when source == base; missing entries fall back to 1.0.
  final Map<String, double> ratesByCode;
  final List<PlotRow> plotsSorted;
  final List<WellRow> wellsSorted;
  final PlotRow? unplannedPlot;

  PlotRow? plotById(int id) {
    for (final p in plotsSorted) {
      if (p.id == id) return p;
    }
    return null;
  }

  WellRow? wellById(int id) {
    for (final w in wellsSorted) {
      if (w.id == id) return w;
    }
    return null;
  }

  double rateToBase(String code) {
    if (code == baseCurrency.code) return 1.0;
    return ratesByCode[code] ?? 1.0;
  }
}

Stream<_LogSheetData> _watchLogSheetData(AppDatabase db) {
  final activeCycle = (db.select(db.cycles)
        ..where((t) => t.state.equalsValue(CycleState.active)))
      .watchSingleOrNull();
  final currencies = (db.select(db.currencies)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([
          (t) => drift.OrderingTerm(expression: t.isBase, mode: drift.OrderingMode.desc),
          (t) => drift.OrderingTerm(expression: t.displayOrder),
          (t) => drift.OrderingTerm(expression: t.code),
        ]))
      .watch();
  final plots = (db.select(db.plots)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([
          (t) => drift.OrderingTerm(expression: t.isUnplanned, mode: drift.OrderingMode.asc),
          (t) => drift.OrderingTerm(expression: t.displayOrder),
          (t) => drift.OrderingTerm(expression: t.name),
        ]))
      .watch();
  final wells = (db.select(db.wells)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([
          (t) => drift.OrderingTerm(expression: t.wellType),
          (t) => drift.OrderingTerm(expression: t.isCarryover, mode: drift.OrderingMode.asc),
          (t) => drift.OrderingTerm(expression: t.displayOrder),
          (t) => drift.OrderingTerm(expression: t.name),
        ]))
      .watch();
  final rates = db.select(db.exchangeRates).watch();

  return _combine5(activeCycle, currencies, plots, wells, rates, (
    CycleRow? cycle,
    List<CurrencyRow> curs,
    List<PlotRow> ps,
    List<WellRow> ws,
    List<ExchangeRateRow> rs,
  ) {
    if (cycle == null || curs.isEmpty) return null;
    final base = curs.firstWhere(
      (c) => c.isBase,
      orElse: () => curs.first,
    );
    final ratesByCode = <String, double>{};
    for (final r in rs) {
      if (r.cycleId == cycle.id && r.toCurrencyCode == base.code) {
        ratesByCode[r.fromCurrencyCode] = r.rate;
      }
    }
    return _LogSheetData(
      activeCycle: cycle,
      currencies: curs,
      baseCurrency: base,
      currencyByCode: {for (final c in curs) c.code: c},
      ratesByCode: ratesByCode,
      plotsSorted: ps,
      wellsSorted: ws,
      unplannedPlot: ps.firstWhere(
        (p) => p.isUnplanned,
        orElse: () => ps.isEmpty
            ? throw StateError('No plots in database')
            : ps.first,
      ),
    );
  }).where((d) => d != null).cast<_LogSheetData>();
}

Stream<R> _combine5<A, B, C, D, E, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  Stream<E> e,
  R Function(A, B, C, D, E) combiner,
) {
  late StreamController<R> controller;
  A? va;
  B? vb;
  C? vc;
  D? vd;
  E? ve;
  bool ha = false;
  bool hb = false;
  bool hc = false;
  bool hd = false;
  bool he = false;
  final subs = <StreamSubscription<dynamic>>[];

  void maybeEmit() {
    if (ha && hb && hc && hd && he) {
      controller.add(combiner(va as A, vb as B, vc as C, vd as D, ve as E));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subs.add(a.listen((v) {
        va = v;
        ha = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(b.listen((v) {
        vb = v;
        hb = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(c.listen((v) {
        vc = v;
        hc = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(d.listen((v) {
        vd = v;
        hd = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(e.listen((v) {
        ve = v;
        he = true;
        maybeEmit();
      }, onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
    },
  );
  return controller.stream;
}

// ──────────────────────────────────────────────────────────────────────────
// Layout helpers / leaf widgets.

class _SheetHandle extends StatelessWidget {
  // ignore: unused_element_parameter
  const _SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Center(
        child: Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: CropkeepColors.borderDivider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.mode,
    required this.onModeChanged,
    required this.onClose,
  });

  final LogTransactionMode mode;
  final ValueChanged<LogTransactionMode> onModeChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            // Mode segment is the focal point of the header — sized to
            // its content and centered on the sheet's horizontal axis,
            // regardless of where the close button sits. Stack keeps
            // it visually anchored on the centerline.
            Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: _ModeSegment(mode: mode, onChanged: onModeChanged),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close_rounded),
                color: CropkeepColors.textSecondary,
                onPressed: onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({required this.mode, required this.onChanged});

  final LogTransactionMode mode;
  final ValueChanged<LogTransactionMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: CropkeepColors.bgPageAlt,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          for (final m in LogTransactionMode.values)
            Expanded(
              child: _ModeTab(
                label: m == LogTransactionMode.expense ? 'Expense' : 'Income',
                isActive: m == mode,
                onTap: () => onChanged(m),
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
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 30,
        decoration: BoxDecoration(
          color: isActive ? CropkeepColors.greenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
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

class _SubEyebrow extends StatelessWidget {
  const _SubEyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: CropkeepColors.textSecondary,
        letterSpacing: 0.6,
        height: 1,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Amount hero — typographic, no card. Currency symbol at 28sp, number
// at 40sp. The row is centered horizontally, sized to its content via
// IntrinsicWidth on the TextField so the centerline stays right when
// digits grow. Tap anywhere in the surrounding tap target to focus.
// Error state: a soft red 1px hairline rule under the number; no box.

class _AmountHero extends StatelessWidget {
  const _AmountHero({
    required this.controller,
    required this.focusNode,
    required this.currency,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final CurrencyRow currency;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final hint = currency.decimalPlaces == 0 ? '0' : '0.00';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => focusNode.requestFocus(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  currency.symbol,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textSecondary,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 10),
                IntrinsicWidth(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 56),
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      textAlign: TextAlign.left,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: currency.decimalPlaces > 0,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textPrimary,
                        height: 1.05,
                      ),
                      cursorColor: CropkeepColors.greenPrimary,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: hint,
                        hintStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: CropkeepColors.borderCard,
                          height: 1.05,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (hasError) ...[
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 1.5,
                color: CropkeepColors.redAlert,
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter an amount greater than zero.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CropkeepColors.textRedDeep,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Rule eyebrow — short hairline rules flanking a soft lowercase label.
// Optional suffix appears in the same line as `· something` so the user
// sees the current selection without a separate count label.

class _RuleEyebrow extends StatelessWidget {
  const _RuleEyebrow({required this.label, this.suffix});

  final String label;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final hasSuffix = suffix != null && suffix!.isNotEmpty;
    final text = hasSuffix ? '$label · ${suffix!}' : label;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: CropkeepColors.borderDivider,
            margin: const EdgeInsets.only(right: 12),
          ),
        ),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: CropkeepColors.textSecondary,
            letterSpacing: 0.2,
            height: 1,
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: CropkeepColors.borderDivider,
            margin: const EdgeInsets.only(left: 12),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Pill button used for the currency + date chips beneath the amount.

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.onTap,
    this.leading,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CropkeepColors.borderCard, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: CropkeepColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Plot chips (expense mode) — same swatch-dot + name pattern the Ledger
// + filter sheet use. Trailing "+ New plot" chip launches the inline
// creation flow (placeholder snackbar for now).

class _PlotChips extends StatelessWidget {
  const _PlotChips({
    required this.plots,
    required this.unplannedId,
    required this.selectedId,
    required this.onSelect,
  });

  final List<PlotRow> plots;
  final int? unplannedId;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in plots)
          _SourceChip(
            label: p.name,
            selected: p.id == selectedId,
            leading: _PlotSwatchDot(colorId: p.plotColorId),
            onTap: () => onSelect(p.id),
          ),
      ],
    );
  }
}

// Well chips (income mode) — grouped by foundation vs bonus.

class _WellChips extends StatelessWidget {
  const _WellChips({
    required this.wells,
    required this.selectedId,
    required this.onSelect,
  });

  final List<WellRow> wells;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Carryover is system-managed — the only writer is the cycle-close
    // rollover, never user input. Hide it from the picker entirely so
    // it doesn't read as an option the user is meant to consider.
    final foundation = wells
        .where((w) => w.wellType == WellType.foundation && !w.isCarryover)
        .toList();
    final bonus = wells
        .where((w) => w.wellType == WellType.bonus && !w.isCarryover)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (foundation.isNotEmpty) ...[
          _SubEyebrow('Foundation'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in foundation)
                _SourceChip(
                  label: w.name,
                  selected: w.id == selectedId,
                  leading: _WellIconGlyph(iconId: w.wellIconId),
                  onTap: () => onSelect(w.id),
                ),
            ],
          ),
        ],
        if (bonus.isNotEmpty) ...[
          if (foundation.isNotEmpty) const SizedBox(height: 14),
          _SubEyebrow('Bonus'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in bonus)
                _SourceChip(
                  label: w.name,
                  selected: w.id == selectedId,
                  leading: _WellIconGlyph(iconId: w.wellIconId),
                  onTap: () => onSelect(w.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Chip primitives.

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? CropkeepColors.greenLight : Colors.white;
    final borderColor =
        selected ? CropkeepColors.greenPrimary : CropkeepColors.borderCard;
    final textColor = selected
        ? CropkeepColors.textGreenDeep
        : CropkeepColors.textPrimary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _PlotSwatchDot extends StatelessWidget {
  const _PlotSwatchDot({required this.colorId});
  final String? colorId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: plotSwatchFor(colorId),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _WellIconGlyph extends StatelessWidget {
  const _WellIconGlyph({required this.iconId});
  final String iconId;

  @override
  Widget build(BuildContext context) {
    final asset = _wellIconAssetFor(iconId);
    if (asset == null) {
      return const Icon(
        Icons.savings_outlined,
        size: 14,
        color: CropkeepColors.textNavInactive,
      );
    }
    return SvgPicture.asset(asset, width: 14, height: 14);
  }
}

class _CurrencyFlag extends StatelessWidget {
  const _CurrencyFlag({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final spec = CurrencyCatalog.findByCode(code);
    final asset = spec?.flagAsset;
    if (asset == null) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: CropkeepColors.bgGoldWash,
          shape: BoxShape.circle,
          border: Border.all(
            color: CropkeepColors.borderGoldPill,
            width: 1,
          ),
        ),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: 14,
        height: 14,
        child: SvgPicture.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Emergency section — when toggled on, the "From" card swaps to a calm
// routed banner so the user sees exactly what's about to be written.

class _EmergencyToggleRow extends StatelessWidget {
  const _EmergencyToggleRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: Row(
            children: [
              // Same red dot the Ledger row badge + filter sheet use,
              // inline so the toggle reads as "emergency thing" without
              // a card header.
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: CropkeepColors.redAlert,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Log this as an emergency',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: CropkeepColors.greenPrimary,
              ),
            ],
          ),
        ),
        if (value) ...[
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              'Routes to the Unplanned plot and is excluded from recurring-category suggestions.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _EmergencyRoutedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: CropkeepColors.bgGoldWash,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CropkeepColors.borderGoldPill, width: 1),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: CropkeepColors.textOnGoldPill,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unplanned plot · tagged emergency',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textOnGoldPill,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Note + submit footer.

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        maxLength: 80,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CropkeepColors.textPrimary,
          height: 1.25,
        ),
        cursorColor: CropkeepColors.greenPrimary,
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          counterText: '',
          hintText: 'e.g., Costco run, Tuesday lunch, paycheck',
          hintStyle: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CropkeepColors.textSecondary,
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _SubmitFooter extends StatelessWidget {
  const _SubmitFooter({
    required this.isExpense,
    required this.canSubmit,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

  final bool isExpense;
  final bool canSubmit;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        border: Border(
          top: BorderSide(color: CropkeepColors.borderDivider, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          TextButton(
            onPressed: submitting ? null : onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textSecondary,
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: (canSubmit && !submitting) ? onSubmit : null,
            style: FilledButton.styleFrom(
              backgroundColor: CropkeepColors.greenPrimary,
              disabledBackgroundColor:
                  CropkeepColors.greenPrimary.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 13,
              ),
            ),
            child: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: CropkeepColors.textOnGreenBtn,
                    ),
                  )
                : Text(
                    isExpense ? 'Log expense' : 'Log income',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textOnGreenBtn,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      top: false,
      child: SizedBox(
        height: 240,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: CropkeepColors.greenPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyPickerRow extends StatelessWidget {
  const _CurrencyPickerRow({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final CurrencyRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _CurrencyFlag(code: row.code),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.code,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                    ),
                  ),
                  Text(
                    row.name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CropkeepColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: CropkeepColors.greenPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Helpers.

DateTime _todayStart() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

const Map<String, String> _wellIconIdToAsset = {
  'default': 'assets/icons/well.svg',
  'well': 'assets/icons/well.svg',
  'treasure': 'assets/icons/treasure.svg',
  'carryover': 'assets/icons/carryover.svg',
  'water': 'assets/icons/water.svg',
  'water-bottle': 'assets/icons/water-bottle.svg',
};

String? _wellIconAssetFor(String iconId) =>
    _wellIconIdToAsset[iconId] ?? 'assets/icons/well.svg';

String _formatDateChip(DateTime date) {
  final today = _todayStart();
  final delta = today.difference(date).inDays;
  if (delta == 0) return 'Today';
  if (delta == 1) return 'Yesterday';
  return '${_monthShort(date.month)} ${date.day}';
}

String _monthShort(int m) {
  const names = [
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
  return names[m - 1];
}

// Parse a typed decimal in the source currency's precision into an
// integer count of minor units. Returns null if unparseable.
int? _parseAmountToMinor(String raw, int decimalPlaces) {
  final value = double.tryParse(raw);
  if (value == null || value < 0) return null;
  final num scale = math.pow(10, decimalPlaces);
  return (value * scale).round();
}

int _convertMinor(
  int sourceMinor, {
  required int sourceDecimals,
  required int targetDecimals,
  required double rate,
}) {
  if (sourceMinor == 0) return 0;
  final num scale = math.pow(10, targetDecimals - sourceDecimals);
  return (sourceMinor * rate * scale).round();
}

String _formatMinor(int minor, CurrencyRow currency) {
  final abs = minor.abs();
  final dp = currency.decimalPlaces;
  String body;
  if (dp == 0) {
    body = _withThousands(abs.toString());
  } else {
    final scale = math.pow(10, dp).toInt();
    final whole = abs ~/ scale;
    final frac = abs % scale;
    body = '${_withThousands(whole.toString())}'
        '.${frac.toString().padLeft(dp, '0')}';
  }
  return '${minor < 0 ? '−' : ''}${currency.symbol}$body';
}

String _withThousands(String digits) {
  if (digits.length <= 3) return digits;
  final buf = StringBuffer();
  final start = digits.length % 3;
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (i - start) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}
