import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../data/currency_catalog.dart';
import '../data/database.dart';
import '../data/tables/cycles.dart' show CycleState;
import '../data/tables/plots.dart' show PlotKind;
import '../data/tables/wells.dart' show WellType;
import '../theme/colors.dart';
import '../theme/plot_swatches.dart';
import 'cropkeep_toast.dart';
import 'cycle_rates_sheet.dart';

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
    // Source currency must have a rate (or be base). Without one we'd
    // silently default to 1:1 conversion.
    final sourceCode = _currencyCode ?? data.baseCurrency.code;
    if (data.rateToBase(sourceCode) == null) return false;
    if (_mode == LogTransactionMode.expense) {
      if (_isEmergency) {
        // Emergency always lands on Unplanned — valid even with no chip.
        return data.unplannedPlot != null;
      }
      if (_selectedPlotId == null) return false;
      // Plot currency rate must also exist — the plotAmount column needs
      // it for the base→plot leg of the conversion.
      final plot = data.plotById(_selectedPlotId!);
      final plotCode = plot?.currencyCode ?? data.baseCurrency.code;
      if (data.rateToBase(plotCode) == null) return false;
      return true;
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
    if (rateToBase == null) return; // _validate already gated this.
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
        final plotRate = data.rateToBase(plotCurrency.code);
        if (plotRate == null) return; // _validate already gated this.
        final plotAmountMinor = _convertMinor(
          baseAmountMinor,
          sourceDecimals: data.baseCurrency.decimalPlaces,
          targetDecimals: plotCurrency.decimalPlaces,
          rate: 1.0 / plotRate,
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
      CropkeepToast.success(
        context,
        title: _mode == LogTransactionMode.expense
            ? 'Expense logged'
            : 'Income logged',
        duration: const Duration(seconds: 2),
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
    final baseMinor = (rateToBase == null)
        ? 0
        : _convertMinor(
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
                    if (currency.code != data.baseCurrency.code) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: rateToBase == null
                            ? _MissingRatePill(code: currency.code)
                            : Text(
                                amountMinor > 0
                                    ? '≈ ${_formatMinor(baseMinor, data.baseCurrency)}'
                                        ' · 1 ${data.baseCurrency.code}'
                                        ' = ${_formatPerBase(1.0 / rateToBase)} ${currency.code}'
                                    : '1 ${data.baseCurrency.code}'
                                        ' = ${_formatPerBase(1.0 / rateToBase)} ${currency.code}',
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
                              plotLastUsed: data.plotLastUsed,
                              onSelect: (id) =>
                                  setState(() => _selectedPlotId = id),
                            )
                    else
                      _WellChips(
                        wells: data.wellsSorted,
                        selectedId: _selectedWellId,
                        wellLastUsed: data.wellLastUsed,
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
    required this.plotLastUsed,
    required this.wellLastUsed,
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
  // plotId → most recent transaction createdAt (epoch ms). Missing keys
  // mean the plot has never been used. Powers the "recents first" chip
  // row and the ranking inside the browse-all sheet.
  final Map<int, int> plotLastUsed;
  final Map<int, int> wellLastUsed;

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

  // Returns null when the currency is a non-base currency with no rate
  // row in the active cycle. The log sheet treats this as "submit blocked"
  // rather than silently fabricating a 1.0 fallback (which used to mask
  // missing-rate bugs end-to-end).
  double? rateToBase(String code) {
    if (code == baseCurrency.code) return 1.0;
    return ratesByCode[code];
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
  // Recency is derived, not stored: MAX(createdAt) per plot/well over
  // live (non-deleted) rows. Uses createdAt (log timestamp) rather than
  // spentAt/receivedAt so a backdated entry from a week ago doesn't
  // pretend the plot is "not recently used".
  final plotRecency = db
      .customSelect(
        'SELECT plot_id, MAX(created_at) AS last_used '
        'FROM transactions WHERE deleted_at IS NULL GROUP BY plot_id',
        readsFrom: {db.transactions},
      )
      .watch()
      .map((rows) => <int, int>{
            for (final r in rows)
              r.data['plot_id'] as int: r.data['last_used'] as int,
          });
  final wellRecency = db
      .customSelect(
        'SELECT well_id, MAX(created_at) AS last_used '
        'FROM income_entries WHERE deleted_at IS NULL GROUP BY well_id',
        readsFrom: {db.incomeEntries},
      )
      .watch()
      .map((rows) => <int, int>{
            for (final r in rows)
              r.data['well_id'] as int: r.data['last_used'] as int,
          });

  return _combine7(activeCycle, currencies, plots, wells, rates,
      plotRecency, wellRecency, (
    CycleRow? cycle,
    List<CurrencyRow> curs,
    List<PlotRow> ps,
    List<WellRow> ws,
    List<ExchangeRateRow> rs,
    Map<int, int> plotLastUsed,
    Map<int, int> wellLastUsed,
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
      plotLastUsed: plotLastUsed,
      wellLastUsed: wellLastUsed,
    );
  }).where((d) => d != null).cast<_LogSheetData>();
}

Stream<R> _combine7<A, B, C, D, E, F, G, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  Stream<E> e,
  Stream<F> f,
  Stream<G> g,
  R Function(A, B, C, D, E, F, G) combiner,
) {
  late StreamController<R> controller;
  A? va;
  B? vb;
  C? vc;
  D? vd;
  E? ve;
  F? vf;
  G? vg;
  bool ha = false;
  bool hb = false;
  bool hc = false;
  bool hd = false;
  bool he = false;
  bool hf = false;
  bool hg = false;
  final subs = <StreamSubscription<dynamic>>[];

  void maybeEmit() {
    if (ha && hb && hc && hd && he && hf && hg) {
      controller.add(combiner(
        va as A,
        vb as B,
        vc as C,
        vd as D,
        ve as E,
        vf as F,
        vg as G,
      ));
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
      subs.add(f.listen((v) {
        vf = v;
        hf = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(g.listen((v) {
        vg = v;
        hg = true;
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
// + filter sheet use.
//
// Below the inline-threshold (5 plots), we show every plot as a wrap —
// same behavior as before. Above it, we switch to a recents-first row:
// top 3 by MAX(createdAt), the pinned Unplanned chip, then a "More…"
// chip that opens the browse-all sheet. The currently selected plot is
// always kept visible even if it's not in the top 3 — otherwise the row
// would silently drop the user's own choice.

const int _inlineChipThreshold = 5;

class _PlotChips extends StatelessWidget {
  const _PlotChips({
    required this.plots,
    required this.unplannedId,
    required this.selectedId,
    required this.plotLastUsed,
    required this.onSelect,
  });

  final List<PlotRow> plots;
  final int? unplannedId;
  final int? selectedId;
  final Map<int, int> plotLastUsed;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (plots.length <= _inlineChipThreshold) {
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

    final unplanned = unplannedId == null
        ? null
        : plots.firstWhere(
            (p) => p.id == unplannedId,
            orElse: () => plots.first,
          );
    // Rank everything except Unplanned by recency, then displayOrder for
    // ties (unranked plots still land in a stable order).
    final ranked = plots
        .where((p) => p.id != unplannedId)
        .toList()
      ..sort((a, b) {
        final ta = plotLastUsed[a.id];
        final tb = plotLastUsed[b.id];
        if (ta != null && tb != null) return tb.compareTo(ta);
        if (ta != null) return -1;
        if (tb != null) return 1;
        return a.displayOrder.compareTo(b.displayOrder);
      });
    const slots = 3;
    final topRecents = ranked.take(slots).toList();
    // If the user has already picked a plot outside the top slots, hoist
    // it into the row so the selection stays visible when the sheet
    // closes and the row rebuilds.
    PlotRow? pinnedSelected;
    if (selectedId != null &&
        selectedId != unplannedId &&
        !topRecents.any((p) => p.id == selectedId)) {
      pinnedSelected = plots.firstWhere(
        (p) => p.id == selectedId,
        orElse: () => plots.first,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (pinnedSelected != null)
          _SourceChip(
            label: pinnedSelected.name,
            selected: true,
            leading: _PlotSwatchDot(colorId: pinnedSelected.plotColorId),
            onTap: () => onSelect(pinnedSelected!.id),
          ),
        for (final p in topRecents)
          _SourceChip(
            label: p.name,
            selected: p.id == selectedId,
            leading: _PlotSwatchDot(colorId: p.plotColorId),
            onTap: () => onSelect(p.id),
          ),
        if (unplanned != null)
          _SourceChip(
            label: unplanned.name,
            selected: unplanned.id == selectedId,
            leading: _PlotSwatchDot(colorId: unplanned.plotColorId),
            onTap: () => onSelect(unplanned.id),
          ),
        _MoreChip(
          onTap: () async {
            final picked = await _showPlotPickerSheet(
              context: context,
              plots: plots,
              selectedId: selectedId,
              unplannedId: unplannedId,
              plotLastUsed: plotLastUsed,
            );
            if (picked != null) onSelect(picked);
          },
        ),
      ],
    );
  }
}

// Well chips (income mode) — grouped by foundation vs bonus when the
// total fits inline. Above the threshold we switch to the same
// recency-first row + More… sheet the plot picker uses.

class _WellChips extends StatelessWidget {
  const _WellChips({
    required this.wells,
    required this.selectedId,
    required this.wellLastUsed,
    required this.onSelect,
  });

  final List<WellRow> wells;
  final int? selectedId;
  final Map<int, int> wellLastUsed;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    // Carryover is system-managed — the only writer is the cycle-close
    // rollover, never user input. Hide it from the picker entirely so
    // it doesn't read as an option the user is meant to consider.
    final visible = wells.where((w) => !w.isCarryover).toList();
    if (visible.length <= _inlineChipThreshold) {
      final foundation = visible
          .where((w) => w.wellType == WellType.foundation)
          .toList();
      final bonus =
          visible.where((w) => w.wellType == WellType.bonus).toList();
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

    final ranked = visible.toList()
      ..sort((a, b) {
        final ta = wellLastUsed[a.id];
        final tb = wellLastUsed[b.id];
        if (ta != null && tb != null) return tb.compareTo(ta);
        if (ta != null) return -1;
        if (tb != null) return 1;
        return a.displayOrder.compareTo(b.displayOrder);
      });
    const slots = 4;
    final topRecents = ranked.take(slots).toList();
    WellRow? pinnedSelected;
    if (selectedId != null &&
        !topRecents.any((w) => w.id == selectedId)) {
      pinnedSelected = visible.firstWhere(
        (w) => w.id == selectedId,
        orElse: () => visible.first,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (pinnedSelected != null)
          _SourceChip(
            label: pinnedSelected.name,
            selected: true,
            leading: _WellIconGlyph(iconId: pinnedSelected.wellIconId),
            onTap: () => onSelect(pinnedSelected!.id),
          ),
        for (final w in topRecents)
          _SourceChip(
            label: w.name,
            selected: w.id == selectedId,
            leading: _WellIconGlyph(iconId: w.wellIconId),
            onTap: () => onSelect(w.id),
          ),
        _MoreChip(
          onTap: () async {
            final picked = await _showWellPickerSheet(
              context: context,
              wells: visible,
              selectedId: selectedId,
              wellLastUsed: wellLastUsed,
            );
            if (picked != null) onSelect(picked);
          },
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Browse-all pickers — modal bottom sheet with a search field at the top
// and grouped rows below (plot kind for expenses, foundation/bonus for
// wells). Opened from the "More…" chip in the recents row.

Future<int?> _showPlotPickerSheet({
  required BuildContext context,
  required List<PlotRow> plots,
  required int? selectedId,
  required int? unplannedId,
  required Map<int, int> plotLastUsed,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: CropkeepColors.bgScreen,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _PlotPickerSheet(
      plots: plots,
      selectedId: selectedId,
      unplannedId: unplannedId,
      plotLastUsed: plotLastUsed,
    ),
  );
}

Future<int?> _showWellPickerSheet({
  required BuildContext context,
  required List<WellRow> wells,
  required int? selectedId,
  required Map<int, int> wellLastUsed,
}) {
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: CropkeepColors.bgScreen,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _WellPickerSheet(
      wells: wells,
      selectedId: selectedId,
      wellLastUsed: wellLastUsed,
    ),
  );
}

class _PlotPickerSheet extends StatefulWidget {
  const _PlotPickerSheet({
    required this.plots,
    required this.selectedId,
    required this.unplannedId,
    required this.plotLastUsed,
  });

  final List<PlotRow> plots;
  final int? selectedId;
  final int? unplannedId;
  final Map<int, int> plotLastUsed;

  @override
  State<_PlotPickerSheet> createState() => _PlotPickerSheetState();
}

class _PlotPickerSheetState extends State<_PlotPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final next = _search.text.trim().toLowerCase();
      if (next != _query) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final filtered = _query.isEmpty
        ? widget.plots
        : widget.plots
            .where((p) => p.name.toLowerCase().contains(_query))
            .toList();
    // Sort within-group by recency, then displayOrder — matches how the
    // recents row ranks, so users see the same ordering conventions.
    int rank(PlotRow a, PlotRow b) {
      final ta = widget.plotLastUsed[a.id];
      final tb = widget.plotLastUsed[b.id];
      if (ta != null && tb != null) return tb.compareTo(ta);
      if (ta != null) return -1;
      if (tb != null) return 1;
      return a.displayOrder.compareTo(b.displayOrder);
    }

    final fixedObligations = filtered
        .where((p) => p.kind == PlotKind.fixedObligation)
        .toList()
      ..sort(rank);
    final discretionary = filtered
        .where((p) => p.kind == PlotKind.discretionary && !p.isUnplanned)
        .toList()
      ..sort(rank);
    final investments = filtered
        .where((p) => p.kind == PlotKind.investment)
        .toList()
      ..sort(rank);
    // Unplanned always sits at the very top of the discretionary group
    // so it never disappears when the list is long.
    final unplanned = filtered
        .where((p) => p.isUnplanned)
        .toList()
      ..sort(rank);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.78),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 2, 20, 12),
                child: Text(
                  'Choose a plot',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _SearchField(
                  controller: _search,
                  hint: 'Search plots',
                ),
              ),
              Expanded(
                child: _PickerList(
                  isEmpty: filtered.isEmpty,
                  emptyMessage: 'No plots match "${_search.text.trim()}".',
                  children: [
                    if (unplanned.isNotEmpty || discretionary.isNotEmpty)
                      _PickerGroup(
                        label: 'Discretionary',
                        children: [
                          for (final p in unplanned)
                            _PlotPickerRow(
                              plot: p,
                              selected: p.id == widget.selectedId,
                              onTap: () =>
                                  Navigator.of(context).pop(p.id),
                            ),
                          for (final p in discretionary)
                            _PlotPickerRow(
                              plot: p,
                              selected: p.id == widget.selectedId,
                              onTap: () =>
                                  Navigator.of(context).pop(p.id),
                            ),
                        ],
                      ),
                    if (fixedObligations.isNotEmpty)
                      _PickerGroup(
                        label: 'Fixed obligations',
                        children: [
                          for (final p in fixedObligations)
                            _PlotPickerRow(
                              plot: p,
                              selected: p.id == widget.selectedId,
                              onTap: () =>
                                  Navigator.of(context).pop(p.id),
                            ),
                        ],
                      ),
                    if (investments.isNotEmpty)
                      _PickerGroup(
                        label: 'Investments',
                        children: [
                          for (final p in investments)
                            _PlotPickerRow(
                              plot: p,
                              selected: p.id == widget.selectedId,
                              onTap: () =>
                                  Navigator.of(context).pop(p.id),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WellPickerSheet extends StatefulWidget {
  const _WellPickerSheet({
    required this.wells,
    required this.selectedId,
    required this.wellLastUsed,
  });

  final List<WellRow> wells;
  final int? selectedId;
  final Map<int, int> wellLastUsed;

  @override
  State<_WellPickerSheet> createState() => _WellPickerSheetState();
}

class _WellPickerSheetState extends State<_WellPickerSheet> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final next = _search.text.trim().toLowerCase();
      if (next != _query) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final filtered = _query.isEmpty
        ? widget.wells
        : widget.wells
            .where((w) => w.name.toLowerCase().contains(_query))
            .toList();
    int rank(WellRow a, WellRow b) {
      final ta = widget.wellLastUsed[a.id];
      final tb = widget.wellLastUsed[b.id];
      if (ta != null && tb != null) return tb.compareTo(ta);
      if (ta != null) return -1;
      if (tb != null) return 1;
      return a.displayOrder.compareTo(b.displayOrder);
    }

    final foundation = filtered
        .where((w) => w.wellType == WellType.foundation)
        .toList()
      ..sort(rank);
    final bonus = filtered
        .where((w) => w.wellType == WellType.bonus)
        .toList()
      ..sort(rank);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.78),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 2, 20, 12),
                child: Text(
                  'Choose a well',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _SearchField(
                  controller: _search,
                  hint: 'Search wells',
                ),
              ),
              Expanded(
                child: _PickerList(
                  isEmpty: filtered.isEmpty,
                  emptyMessage: 'No wells match "${_search.text.trim()}".',
                  children: [
                    if (foundation.isNotEmpty)
                      _PickerGroup(
                        label: 'Foundation',
                        children: [
                          for (final w in foundation)
                            _WellPickerRow(
                              well: w,
                              selected: w.id == widget.selectedId,
                              onTap: () =>
                                  Navigator.of(context).pop(w.id),
                            ),
                        ],
                      ),
                    if (bonus.isNotEmpty)
                      _PickerGroup(
                        label: 'Bonus',
                        children: [
                          for (final w in bonus)
                            _WellPickerRow(
                              well: w,
                              selected: w.id == widget.selectedId,
                              onTap: () =>
                                  Navigator.of(context).pop(w.id),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: CropkeepColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textPrimary,
                height: 1.2,
              ),
              cursorColor: CropkeepColors.greenPrimary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CropkeepColors.textSecondary,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => controller.clear(),
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: CropkeepColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PickerList extends StatelessWidget {
  const _PickerList({
    required this.isEmpty,
    required this.emptyMessage,
    required this.children,
  });

  final bool isEmpty;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CropkeepColors.textSecondary,
            height: 1.3,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: children,
    );
  }
}

class _PickerGroup extends StatelessWidget {
  const _PickerGroup({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: _SubEyebrow(label),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _PlotPickerRow extends StatelessWidget {
  const _PlotPickerRow({
    required this.plot,
    required this.selected,
    required this.onTap,
  });

  final PlotRow plot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PickerRow(
      selected: selected,
      leading: _PlotSwatchDot(colorId: plot.plotColorId),
      label: plot.name,
      onTap: onTap,
    );
  }
}

class _WellPickerRow extends StatelessWidget {
  const _WellPickerRow({
    required this.well,
    required this.selected,
    required this.onTap,
  });

  final WellRow well;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PickerRow(
      selected: selected,
      leading: _WellIconGlyph(iconId: well.wellIconId),
      label: well.name,
      onTap: onTap,
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.selected,
    required this.leading,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final Widget leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 16, child: Center(child: leading)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  color: selected
                      ? CropkeepColors.textGreenDeep
                      : CropkeepColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: CropkeepColors.greenPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

// The "More…" chip is intentionally styled a shade lighter than the
// primary source chips so the recents feel like the emphasised path
// and the browse-all is a quieter escape hatch.
class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CropkeepColors.bgPageAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CropkeepColors.borderDivider,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'More',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textSecondary,
                height: 1.1,
              ),
            ),
            SizedBox(width: 4),
            Icon(
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

// Display helper for the conversion preview: shows "1 USD = N PHP" where
// `perBase` is the foreign-per-base value (inverse of the storage rate).
// Picks a decimal width that keeps small currencies (EUR/GBP) readable
// without padding huge-magnitude ones (KRW, JPY) with noise.
String _formatPerBase(double perBase) {
  if (perBase >= 100) return perBase.toStringAsFixed(2);
  if (perBase >= 1) return perBase.toStringAsFixed(3);
  return perBase.toStringAsFixed(5);
}

// Surface-of-failure for missing-rate state in the conversion preview.
// We never silently default to 1.0 anymore, so when a non-base currency
// has no rate row for the active cycle the user gets a clear pill they
// can tap to open the cycle rates sheet and set one.
class _MissingRatePill extends StatelessWidget {
  const _MissingRatePill({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFDECEC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const CycleRatesSheet(),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No rate set for $code · tap to set',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textRedDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
