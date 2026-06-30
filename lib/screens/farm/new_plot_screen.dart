import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../data/currency_catalog.dart';
import '../../data/database.dart' show CurrencyRow, ExchangeRateRow, PlotRow;
import '../../data/repositories/market_repository.dart' show CropPickerEntry;
import '../../data/tables/plots.dart' show PlotKind;
import '../../theme/colors.dart';
import '../../widgets/cropkeep_toast.dart';

// ──────────────────────────────────────────────────────────────────────────
// NewPlotScreen — plot creation flow.
//
// Layout: sand-band header (back + title only), scrolling form, sticky
// green CTA bar at the bottom. The CTA sits at the bottom because the
// form runs long enough that a top-right Create button would be hidden
// behind the keyboard the moment the user is finalising the amount.
//
// Spacing rhythm (applied throughout):
//   • label → field        : 8
//   • label → hint         : 4
//   • hint  → field        : 10
//   • section → next section: 24

class NewPlotScreen extends StatefulWidget {
  const NewPlotScreen({
    super.key,
    required this.reservoirTotal,
    required this.allocatedSoFar,
    this.existingPlot,
    this.canEditFinancials = true,
  });

  // Total foundation income for the active cycle, in base minor units.
  // The hard cap that `sum(plot.budget_amount converted to base)` cannot
  // exceed. Foundation only — bonus income never widens this cap.
  final int reservoirTotal;
  // Sum of every existing non-Unplanned plot budget this cycle, already
  // converted to base minor units. The new plot's base-equivalent budget
  // is added to this and compared against `reservoirTotal`. In edit mode
  // the screen subtracts the existing plot's own contribution before
  // rendering the allocation bar, so callers always pass the same
  // "everything currently allocated" number whether new or edit.
  final int allocatedSoFar;
  // Edit mode: when non-null, the form hydrates from this row and the
  // submit handler calls PlotRepository.update instead of .create.
  // The screen pops with `true` on save so callers can decide whether
  // to refresh stale snapshots upstream.
  final PlotRow? existingPlot;
  // False when the plot has live transactions this cycle. Locks the
  // kind toggle + budget field (changing kind or budget mid-cycle would
  // re-interpret already-logged transactions under different math).
  // The other fields (name, crop, color, due day) stay editable.
  final bool canEditFinancials;

  bool get isEditing => existingPlot != null;

  @override
  State<NewPlotScreen> createState() => _NewPlotScreenState();
}

enum _PlotKind { discretionary, fixedObligation, investment }

// `_dueDay` holds a raw day-of-month (1–31). Months shorter than the
// chosen day are clamped at evaluation time — picking 31 for a Feb
// cycle fires on Feb 28/29, picking 31 for an April cycle fires on
// Apr 30, and so on. This means there's no separate "last day of
// month" sentinel: the model is just one rule (day + clamp) instead
// of two semantics (specific day vs. always-last) that the UI couldn't
// honestly distinguish anyway.

// Pastel swatches the user picks from when creating a plot. Tuned around
// HSL L≈80% / S≈50% so the 12 hues read as one coherent family — no
// single swatch dominates next to the others in the 3×4 grid, and every
// one stays light enough that plot labels remain legible when painted
// on top. Names lean farm/garden since they double as the picker labels.
typedef _PlotColor = ({String name, Color color});

const List<_PlotColor> _plotColors = [
  (name: 'Tomato', color: Color(0xFFFFB5B5)),
  (name: 'Carrot', color: Color(0xFFFFCEA8)),
  (name: 'Honey', color: Color(0xFFFFE3A8)),
  (name: 'Butter', color: Color(0xFFFFF5B0)),
  (name: 'Lettuce', color: Color(0xFFD4ECA8)),
  (name: 'Mint', color: Color(0xFFB5E6B8)),
  (name: 'Sage', color: Color(0xFFA8D8C2)),
  (name: 'Sky', color: Color(0xFFB5DCEB)),
  (name: 'Cornflower', color: Color(0xFFB5C5F0)),
  (name: 'Lavender', color: Color(0xFFC9B5F0)),
  (name: 'Lilac', color: Color(0xFFE6B5E6)),
  (name: 'Rose', color: Color(0xFFF5B5D5)),
];

// Index of the default selection. Mint is the green-family pastel and
// reads closest to the brand green the rest of the app already uses.
const int _defaultPlotColorIndex = 5;

// The crop catalog the user picks from when creating a plot. Mirrors the
// `crops_catalog` table in database.md: three permanent starters (free
// at onboarding) plus consumable seed packs whose `quantity` in
// `owned_items` ticks down each cycle.
//
// `stock` is null for starters (permanent unlocks, no inventory concept)
// and an int for seed packs (current `owned_items.quantity`). A stock
// of 0 means the user is out of seeds — the tile is still rendered (so
// the user knows the crop exists) but tapping fires a Market prompt
// instead of selecting.
typedef _CropOption = ({
  String id,
  String name,
  String iconAsset,
  bool isStarter,
  int? stock,
});

// Maps a crops_catalog row to the asset path the picker tile renders.
// Starters use the plain SVG name; consumable seed packs use the
// `icons8-` prefix with underscores swapped to hyphens. Centralised
// here so any future asset rename only touches one file.
String _cropIconAsset(String cropId, {required bool isStarter}) {
  if (isStarter) return 'assets/icons/crops/$cropId.svg';
  final dashed = cropId.replaceAll('_', '-');
  return 'assets/icons/crops/icons8-$dashed.svg';
}

// Builds the picker option list off live catalog + ownership state.
// Filters out the `unplanned` catalog entry — it's the wildflower
// fallback for the system-managed Unplanned plot, never a real
// user-pickable crop.
List<_CropOption> _cropOptionsFromEntries(List<CropPickerEntry> entries) {
  return [
    for (final e in entries)
      if (e.crop.cropId != 'unplanned')
        (
          id: e.crop.cropId,
          name: e.crop.name,
          iconAsset: _cropIconAsset(e.crop.cropId, isStarter: e.crop.isStarter),
          isStarter: e.crop.isStarter,
          stock: e.stock,
        ),
  ];
}

class _NewPlotScreenState extends State<NewPlotScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  _PlotKind _kind = _PlotKind.discretionary;
  int? _dueDay;
  _Currency? _selected;
  _PlotColor _selectedColor = _plotColors[_defaultPlotColorIndex];
  _CropOption? _selectedCrop;

  // Resolved on first didChangeDependencies via AppScope. Until both
  // lists arrive the screen renders a loading scaffold so the form
  // never reads a null selected currency / crop. Subsequent rebuilds
  // (currency added in Settings, seed pack bought in Market mid-flow)
  // reconcile via _reconcileSelections.
  List<_Currency> _currencies = const [];
  List<_CropOption> _cropOptions = const [];
  bool _isReady = false;
  bool _isSubmitting = false;

  _Currency? get _baseCurrencyOrNull {
    for (final c in _currencies) {
      if (c.isBase) return c;
    }
    return null;
  }

  // Throwing fallback: only call after _isReady is true. Used by the
  // header / formatter helpers that always run inside a ready frame.
  _Currency get _baseCurrency => _baseCurrencyOrNull!;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onAnyChange);
    _amountCtrl.addListener(_onAnyChange);
  }

  bool _dependenciesLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesLoaded) return;
    _dependenciesLoaded = true;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final scope = AppScope.of(context);
    final settings = await scope.appSettings.watch().first;
    final baseCode = settings?.baseCurrencyCode ?? 'USD';
    final activeCycle = await scope.cycles.watchActiveCycle().first;
    final rates = activeCycle == null
        ? const <ExchangeRateRow>[]
        : await scope.cycles.watchRatesFor(activeCycle.id).first;
    final Map<String, double> pendingToBase = activeCycle == null
        ? {
            for (final e in scope.pendingRates.current.entries)
              e.key: e.value.rate,
          }
        : const {};
    final currencyRows = await scope.appSettings.watchCurrencies().first;
    final cropEntries = await scope.market.watchCropPicker().first;

    if (!mounted) return;
    setState(() {
      _currencies =
          _buildCurrencies(currencyRows, baseCode, rates, pendingToBase);
      _cropOptions = _cropOptionsFromEntries(cropEntries);
      _selected = _baseCurrencyOrNull ??
          (_currencies.isNotEmpty ? _currencies.first : null);
      _selectedCrop = _cropOptions.isEmpty
          ? null
          : _cropOptions.firstWhere(
              (c) => c.id == 'wheat',
              orElse: () => _cropOptions.first,
            );
      _hydrateFromExisting();
      _isReady = _selected != null && _selectedCrop != null;
    });
  }

  // Edit-mode initial fill. Runs once inside _loadInitialData, after the
  // currency + crop lists are populated so the existing plot's currency
  // and crop can resolve to the same instances the pickers use. Falls
  // back to base / first option when a referenced id has since been
  // removed (e.g. the user disabled the currency, or the crop pack
  // sold out from inventory) so the form never lands in a broken state.
  void _hydrateFromExisting() {
    final PlotRow? edit = widget.existingPlot;
    if (edit == null) return;
    _nameCtrl.text = edit.name;
    _kind = _fromRepoKind(edit.kind);
    _dueDay = edit.dueDay;
    if (edit.budgetAmount != null) {
      final _Currency cur = _currencies.firstWhere(
        (c) => c.code == edit.currencyCode,
        orElse: () => _selected ?? _currencies.first,
      );
      _selected = cur;
      _amountCtrl.text = _formatAmountForEdit(edit.budgetAmount!, cur);
    }
    if (edit.plotColorId != null) {
      for (final color in _plotColors) {
        if (color.name == edit.plotColorId) {
          _selectedColor = color;
          break;
        }
      }
    }
    if (_cropOptions.isNotEmpty) {
      _selectedCrop = _cropOptions.firstWhere(
        (c) => c.id == edit.cropTypeId,
        orElse: () => _selectedCrop ?? _cropOptions.first,
      );
    }
  }

  _PlotKind _fromRepoKind(PlotKind kind) {
    switch (kind) {
      case PlotKind.discretionary:
        return _PlotKind.discretionary;
      case PlotKind.fixedObligation:
        return _PlotKind.fixedObligation;
      case PlotKind.investment:
        return _PlotKind.investment;
    }
  }

  // Minor units → "1234.56" style decimal string that round-trips
  // through this screen's _budgetMinor parser. JPY-style zero-decimal
  // currencies drop the dot entirely.
  String _formatAmountForEdit(int minor, _Currency cur) {
    if (cur.decimals == 0) return minor.toString();
    final num scale = math.pow(10, cur.decimals);
    final int divisor = scale.toInt();
    final int whole = minor ~/ divisor;
    final String frac =
        (minor % divisor).toString().padLeft(cur.decimals, '0');
    return '$whole.$frac';
  }

  List<_Currency> _buildCurrencies(
    List<CurrencyRow> rows,
    String baseCode,
    List<ExchangeRateRow> rates,
    Map<String, double> pendingToBase,
  ) {
    // Build a code → rate map keyed on `from_currency_code` for rates
    // converting INTO the base. Pre-cycle, fall back to the pending
    // store; only then default to 1.0 so a non-base plot picked before
    // any rate is entered still renders without dividing by zero.
    final Map<String, double> toBase = {
      for (final r in rates)
        if (r.toCurrencyCode == baseCode) r.fromCurrencyCode: r.rate,
    };
    return [
      for (final row in rows)
        if (row.isActive)
          if (CurrencyCatalog.findByCode(row.code) case final spec?)
            _Currency(
              spec: spec,
              rateToBase: row.code == baseCode
                  ? 1.0
                  : (toBase[row.code] ?? pendingToBase[row.code] ?? 1.0),
              isBase: row.code == baseCode,
            ),
    ];
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onAnyChange() => setState(() {});

  // Parse the amount field as decimal in the selected currency and return
  // minor units in THAT currency. Empty / unparseable → 0 so the live
  // pressure caption stays meaningful as the user types.
  int get _budgetMinor {
    final selected = _selected;
    if (selected == null) return 0;
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return 0;
    final asDouble = double.tryParse(raw);
    if (asDouble == null || asDouble < 0) return 0;
    final num scale = math.pow(10, selected.decimals);
    return (asDouble * scale).round();
  }

  // Convert the typed amount to base minor units using the selected
  // currency's cycle rate. Identity when selected is base. Matches the
  // database.md spec: `sourceMinor * rate * 10^(base.decimals - src.decimals)`,
  // rounded to nearest base minor.
  int get _budgetInBase {
    final selected = _selected;
    if (selected == null) return _budgetMinor;
    if (selected.isBase) return _budgetMinor;
    final num scale =
        math.pow(10, _baseCurrency.decimals - selected.decimals);
    return (_budgetMinor * selected.rateToBase * scale).round();
  }

  // In edit mode, allocatedSoFar from the caller still includes THIS
  // plot's existing contribution. Subtract it (converted at current rates,
  // same as the caller used) so the header reads "everything else
  // allocated + this plot's NEW claim" with no double-count.
  int get _effectiveAllocatedSoFar {
    final PlotRow? edit = widget.existingPlot;
    if (edit == null || edit.budgetAmount == null) {
      return widget.allocatedSoFar;
    }
    final _Currency? cur = _currencyFor(edit.currencyCode);
    if (cur == null) return widget.allocatedSoFar;
    final num scale =
        math.pow(10, _baseCurrency.decimals - cur.decimals);
    final int existingInBase =
        (edit.budgetAmount! * cur.rateToBase * scale).round();
    final int adjusted = widget.allocatedSoFar - existingInBase;
    return adjusted < 0 ? 0 : adjusted;
  }

  _Currency? _currencyFor(String code) {
    for (final c in _currencies) {
      if (c.code == code) return c;
    }
    return null;
  }

  int get _freeBefore => widget.reservoirTotal - _effectiveAllocatedSoFar;
  int get _freeAfter => _freeBefore - _budgetInBase;
  bool get _exceedsReservoir => _freeAfter < 0;

  bool get _canCreate {
    if (_isSubmitting) return false;
    if (!_isReady) return false;
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_budgetMinor <= 0) return false;
    if (_exceedsReservoir) return false;
    if (_kind == _PlotKind.fixedObligation && _dueDay == null) return false;
    return true;
  }

  Future<void> _onCreate() async {
    if (!_canCreate) return;
    final selected = _selected!;
    final crop = _selectedCrop!;
    final PlotRow? edit = widget.existingPlot;
    setState(() => _isSubmitting = true);
    try {
      final scope = AppScope.of(context);
      if (edit != null) {
        // Locked-financials path: re-supply the existing kind/budget/
        // currency unchanged. The form fields render disabled in this
        // mode but their state may not match the row exactly (e.g. if
        // currency catalog changed), so authoritative values come from
        // the row itself.
        final bool financialsEditable = widget.canEditFinancials;
        await scope.plots.update(
          id: edit.id,
          name: _nameCtrl.text.trim(),
          kind: financialsEditable ? _toRepoKind(_kind) : edit.kind,
          budgetAmountMinor:
              financialsEditable ? _budgetMinor : (edit.budgetAmount ?? 0),
          currencyCode:
              financialsEditable ? selected.code : edit.currencyCode,
          cropTypeId: crop.id,
          colorId: _selectedColor.name,
          dueDay: _resolvedKind(edit) == PlotKind.fixedObligation
              ? _dueDay
              : null,
        );
      } else {
        await scope.plots.create(
          name: _nameCtrl.text.trim(),
          kind: _toRepoKind(_kind),
          budgetAmountMinor: _budgetMinor,
          currencyCode: selected.code,
          cropTypeId: crop.id,
          colorId: _selectedColor.name,
          dueDay: _kind == _PlotKind.fixedObligation ? _dueDay : null,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      CropkeepToast.error(
        context,
        title: edit != null ? "Couldn't save plot" : "Couldn't create plot",
        flavor: '$e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  // Effective kind after submit: in edit mode with locked financials the
  // kind toggle is dormant, so the kind stays whatever the row already
  // had (we still respect "fixed-obligation needs a due day" against the
  // row's kind, not the toggle state).
  PlotKind _resolvedKind(PlotRow edit) {
    return widget.canEditFinancials ? _toRepoKind(_kind) : edit.kind;
  }

  void _onCurrencyChanged(_Currency next) {
    if (next.code == _selected?.code) return;
    setState(() {
      _selected = next;
      // Different currency = different denomination. Carrying "100" from
      // NTD to JPY would silently allocate ¥100 (≈$21) when the user meant
      // $100 — clearing avoids that whole class of confusion.
      _amountCtrl.clear();
    });
  }

  PlotKind _toRepoKind(_PlotKind kind) {
    switch (kind) {
      case _PlotKind.discretionary:
        return PlotKind.discretionary;
      case _PlotKind.fixedObligation:
        return PlotKind.fixedObligation;
      case _PlotKind.investment:
        return PlotKind.investment;
    }
  }

  Future<void> _openCurrencyPicker() async {
    final selected = _selected;
    if (selected == null) return;
    FocusScope.of(context).unfocus();
    final _Currency? picked = await showModalBottomSheet<_Currency>(
      context: context,
      backgroundColor: CropkeepColors.bgScreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CurrencyPickerSheet(
        currencies: _currencies,
        selected: selected,
      ),
    );
    if (picked != null) _onCurrencyChanged(picked);
  }

  // Section label above the amount field. Investment plots use "target" —
  // the number is what we want to fill *up to*, not a ceiling we're
  // spending *down*. Bills use "expected payment" (a known due figure);
  // spending uses "monthly budget" (the soft cap).
  String _budgetSectionLabel(_PlotKind kind) {
    switch (kind) {
      case _PlotKind.fixedObligation:
        return 'Expected payment';
      case _PlotKind.investment:
        return 'Monthly contribution target';
      case _PlotKind.discretionary:
        return 'Monthly budget';
    }
  }

  // Form-side label for the inline due-day row. "Pick a day" reads as a
  // call to action when no day is set; "Day N" is the concrete answer.
  String _dueDayLabel(int? day) {
    if (day == null) return 'Pick a day';
    return 'Day $day';
  }

  Future<void> _openDueDayPicker() async {
    FocusScope.of(context).unfocus();
    final int? picked = await showModalBottomSheet<int>(
      context: context,
      // Calendar grid + hint + confirm overruns the default ~50% modal
      // cap on shorter phones; isScrollControlled lets the sheet size
      // to content and the inner SingleChildScrollView handles overflow.
      isScrollControlled: true,
      backgroundColor: CropkeepColors.bgScreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DueDayPickerSheet(selected: _dueDay),
    );
    if (picked != null) setState(() => _dueDay = picked);
  }

  // Sublabel for the inline Crop picker row. Surfaces the inventory
  // state on the form itself so the user sees seed-pack scarcity before
  // they even open the picker — important because picking a 0-stock
  // seed pack is impossible (it auto-reverts to wheat at cycle start
  // per the spec).
  String _cropSublabel(_CropOption crop) {
    if (crop.isStarter) return 'Starter crop';
    final int stock = crop.stock ?? 0;
    if (stock == 0) return 'Seed pack · Out of stock';
    return 'Seed pack · $stock left';
  }

  Future<void> _openCropPicker() async {
    FocusScope.of(context).unfocus();
    final _CropOption? picked = await showModalBottomSheet<_CropOption>(
      context: context,
      // Sectioned content (starters row + 5×3 seed-pack grid + confirm)
      // pushes the sheet past the default ~50% cap on shorter phones;
      // isScrollControlled lets it size to content and the inner
      // SingleChildScrollView handles the rare overflow case.
      isScrollControlled: true,
      backgroundColor: CropkeepColors.bgScreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CropPickerSheet(
        options: _cropOptions,
        selected: _selectedCrop!,
      ),
    );
    if (picked != null) setState(() => _selectedCrop = picked);
  }

  Future<void> _openColorPicker() async {
    FocusScope.of(context).unfocus();
    final _PlotColor? picked = await showModalBottomSheet<_PlotColor>(
      context: context,
      // The 3×4 swatch grid + headers + confirm button exceeds the
      // default modal-sheet half-screen cap on shorter phones. Lifting
      // the cap lets the sheet size to its content; the inner
      // SingleChildScrollView then handles the rare case where even
      // that intrinsic height exceeds the available area.
      isScrollControlled: true,
      backgroundColor: CropkeepColors.bgScreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ColorPickerSheet(selected: _selectedColor),
    );
    if (picked != null) setState(() => _selectedColor = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: CropkeepColors.bgScreen,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final selectedCurrency = _selected!;
    final selectedCrop = _selectedCrop!;
    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      // resizeToAvoidBottomInset stays on so the form shrinks when the
      // keyboard appears — the sticky CTA stays pinned above the inset
      // because it lives at the bottom of the same Column.
      body: GestureDetector(
        // Tap-outside dismisses the keyboard. Standard form affordance the
        // TextField hit targets otherwise keep from happening.
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          // Stretch so the header band and the sticky CTA paint edge-to-edge.
          // Without this, the Column defaults to center alignment and the
          // header collapses to the width of the back arrow + title now that
          // the Create button no longer forces the row wide.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              kind: _kind,
              baseCurrency: _baseCurrency,
              reservoirTotal: widget.reservoirTotal,
              allocatedSoFar: _effectiveAllocatedSoFar,
              budgetInBase: _budgetInBase,
              isOver: _exceedsReservoir,
              isEditing: widget.isEditing,
              editingTitle: widget.existingPlot?.name,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionLabel('What are you tracking?'),
                    const SizedBox(height: 8),
                    _KindToggle(
                      kind: _kind,
                      enabled: widget.canEditFinancials,
                      onChanged: (k) => setState(() {
                        _kind = k;
                        // Only fixed_obligation carries a due_day; clear it
                        // when switching to any other kind so toggling
                        // doesn't leave stale state behind the picker.
                        if (k != _PlotKind.fixedObligation) _dueDay = null;
                      }),
                    ),
                    if (widget.isEditing && !widget.canEditFinancials) ...[
                      const SizedBox(height: 8),
                      const _LockedHint(
                        'Locked — this plot has transactions this cycle.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    const _SectionLabel('Name'),
                    const SizedBox(height: 8),
                    _NameField(controller: _nameCtrl, kind: _kind),
                    const SizedBox(height: 24),
                    _SectionLabel(_budgetSectionLabel(_kind)),
                    const SizedBox(height: 8),
                    _BudgetField(
                      controller: _amountCtrl,
                      currency: selectedCurrency,
                      isOver: _exceedsReservoir,
                      enabled: widget.canEditFinancials,
                      onCurrencyTap: _openCurrencyPicker,
                      budgetInBase: _budgetInBase,
                      baseCurrency: _baseCurrency,
                    ),
                    if (widget.isEditing && !widget.canEditFinancials) ...[
                      const SizedBox(height: 8),
                      const _LockedHint(
                        'Locked — remove this cycle’s transactions or '
                        'wait for cycle close to change the amount.',
                      ),
                    ],
                    if (_kind == _PlotKind.fixedObligation) ...[
                      const SizedBox(height: 24),
                      const _SectionLabel('Due day'),
                      const SizedBox(height: 8),
                      _PickerRow(
                        iconWidget: _DueDayRowIcon(day: _dueDay),
                        label: _dueDayLabel(_dueDay),
                        sublabel: _dueDay == null
                            ? 'Tap to choose'
                            : 'Tap to change',
                        onTap: _openDueDayPicker,
                      ),
                    ],
                    const SizedBox(height: 24),
                    const _SectionLabel('Crop'),
                    const SizedBox(height: 8),
                    _PickerRow(
                      iconAsset: selectedCrop.iconAsset,
                      label: selectedCrop.name,
                      sublabel: _cropSublabel(selectedCrop),
                      onTap: _openCropPicker,
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('Color'),
                    const SizedBox(height: 8),
                    _PickerRow(
                      colorSwatch: _selectedColor.color,
                      label: _selectedColor.name,
                      sublabel: 'Tap to pick a swatch',
                      onTap: _openColorPicker,
                    ),
                  ],
                ),
              ),
            ),
            _StickyCreateBar(
              enabled: _canCreate,
              onTap: _onCreate,
              label: widget.isEditing ? 'Save changes' : 'Create plot',
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Currency wrapper — pairs a CurrencyCatalog spec (code/symbol/name/
// decimals/flag) with the cycle-rate info this screen needs. The catalog
// is the visual + identity source of truth shared with onboarding and
// the secondary picker; rateToBase comes from the prototype until the
// real `exchange_rates` table is wired.

class _Currency {
  const _Currency({
    required this.spec,
    required this.rateToBase,
    required this.isBase,
  });

  final CurrencySpec spec;
  // 1 source major unit × rateToBase = base major units. Identity for the
  // base row. Prototype rates approximate TWD as base: 1 USD ≈ NT$30, 1
  // JPY ≈ NT$0.21. The data pass will swap these for live `exchange_rates`
  // rows that the user reviews each harvest transition.
  final double rateToBase;
  final bool isBase;

  String get code => spec.code;
  String get symbol => spec.symbol;
  String get name => spec.name;
  int get decimals => spec.decimalPlaces;
  String get flagAsset => spec.flagAsset;
}

// ──────────────────────────────────────────────────────────────────────────
// Header — sand band that mirrors BreakdownEnvelopeHeader's grammar
// (bgHero, 24px bottom radius, shared shadow tokens, 20px bottom
// padding). Where the breakdown header tells the story of money
// already spent, this one tells the story of money about to be
// committed: a crop icon + kind-tracking eyebrow + title, the cycle's
// free reservoir as the headline with an inline "for this plot" chip
// that materialises once the user types, the cycle-position caption,
// and a two-segment allocation bar (gold for existing allocations,
// green for this plot's claim, turning red when over).
//
// The chip and the green bar segment are the live form feedback — the
// user can SEE the reservoir being claimed as they type, which is why
// the budget field below no longer carries a separate caption.

class _Header extends StatelessWidget {
  const _Header({
    required this.kind,
    required this.baseCurrency,
    required this.reservoirTotal,
    required this.allocatedSoFar,
    required this.budgetInBase,
    required this.isOver,
    this.isEditing = false,
    this.editingTitle,
  });

  final _PlotKind kind;
  final _Currency baseCurrency;
  final int reservoirTotal;
  final int allocatedSoFar;
  final int budgetInBase;
  final bool isOver;
  // Edit-mode swaps: eyebrow says "EDIT BUDGET" etc and the title is the
  // plot's actual name instead of the generic "New plot". The reservoir
  // headline / caption / bar are unchanged — same allocation grammar,
  // just with the existing plot's own contribution excluded upstream so
  // the bar reads "other plots + this plot's revised claim".
  final bool isEditing;
  final String? editingTitle;

  String get _eyebrowText {
    if (isEditing) {
      switch (kind) {
        case _PlotKind.discretionary:
          return 'EDIT BUDGET ALLOCATION';
        case _PlotKind.fixedObligation:
          return 'EDIT BILL';
        case _PlotKind.investment:
          return 'EDIT INVESTMENT';
      }
    }
    switch (kind) {
      case _PlotKind.discretionary:
        return 'NEW BUDGET ALLOCATION';
      case _PlotKind.fixedObligation:
        return 'NEW BILL';
      case _PlotKind.investment:
        return 'NEW INVESTMENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final int freeBefore = reservoirTotal - allocatedSoFar;
    final int overBy = budgetInBase - freeBefore;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: CropkeepColors.bgHero,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: CropkeepColors.shadowCard,
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/back.svg',
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      CropkeepColors.textSecondaryOnHero,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IdentityStrip(
                        eyebrowText: _eyebrowText,
                        title: editingTitle ?? 'New plot',
                      ),
                      const SizedBox(height: 14),
                      _HeadlineRow(
                        freeBefore: freeBefore,
                        baseCurrency: baseCurrency,
                      ),
                      const SizedBox(height: 8),
                      // Caption is always rendered — even at $0 — so the
                      // user sees the math relationship before they start
                      // typing. Removes the first-keystroke height jump
                      // and turns the header into a constant equation
                      // (free reservoir, minus this plot's claim, visible
                      // in the bar). Content swaps to a red over-cap
                      // warning when the typed claim breaches the cap.
                      _ThisPlotCaption(
                        budgetInBase: budgetInBase,
                        baseCurrency: baseCurrency,
                        isOver: isOver,
                        overBy: overBy,
                      ),
                      const SizedBox(height: 12),
                      _AllocationBar(
                        reservoirTotal: reservoirTotal,
                        allocatedSoFar: allocatedSoFar,
                        budgetInBase: budgetInBase,
                        isOver: isOver,
                      ),
                    ],
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

// Identity strip — generic farm icon (the crop picker hasn't run yet,
// so we don't pretend to know the crop) + kind-tracking eyebrow +
// static title. The eyebrow swaps through AnimatedSwitcher so the link
// between the kind toggle below and the header reads as one continuous
// gesture.

class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({
    required this.eyebrowText,
    this.title = 'New plot',
  });

  final String eyebrowText;
  // Title shown beneath the eyebrow. Defaults to "New plot" for the
  // creation flow; edit mode supplies the existing plot's name so the
  // user can see at a glance which plot they're editing.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: SvgPicture.asset(
            'assets/icons/farm.svg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  eyebrowText,
                  key: ValueKey(eyebrowText),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textGoldDeep,
                    letterSpacing: 0.8,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1.1,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Headline — "$X free" only. The live "for this plot" / "over" info
// lives in the caption beneath, so the headline stays a single clean
// statement of how much reservoir there is to work with.

class _HeadlineRow extends StatelessWidget {
  const _HeadlineRow({
    required this.freeBefore,
    required this.baseCurrency,
  });

  final int freeBefore;
  final _Currency baseCurrency;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: _formatMoney(freeBefore, baseCurrency),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1,
                letterSpacing: -0.4,
              ),
            ),
            const TextSpan(
              text: ' free',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
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

// Caption — surfaces this plot's claim against the reservoir as the
// user types. Hidden in the empty state (the headline + bar carry
// enough context). Becomes a red warning when the typed claim exceeds
// the free reservoir.

class _ThisPlotCaption extends StatelessWidget {
  const _ThisPlotCaption({
    required this.budgetInBase,
    required this.baseCurrency,
    required this.isOver,
    required this.overBy,
  });

  final int budgetInBase;
  final _Currency baseCurrency;
  final bool isOver;
  final int overBy;

  @override
  Widget build(BuildContext context) {
    if (isOver) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 14,
            color: CropkeepColors.textRedDeep,
          ),
          const SizedBox(width: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textRedDeep,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: _formatMoney(overBy, baseCurrency),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: ' over reservoir cap'),
              ],
            ),
          ),
        ],
      );
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: CropkeepColors.textSecondaryOnHero,
          height: 1.3,
        ),
        children: [
          const TextSpan(text: '− '),
          TextSpan(
            text: _formatMoney(budgetInBase, baseCurrency),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textPrimary,
            ),
          ),
          const TextSpan(text: ' for this plot'),
        ],
      ),
    );
  }
}

// Two-segment allocation bar. Gold fill = budget already allocated to
// other plots this cycle. Green segment = this plot's claim as the
// user types. Track is the sand-shadow groove shared with the
// breakdown header. When the user types past the free reservoir, the
// green segment turns red and clamps to 100% — the headline chip
// carries the specific over-amount.
//
// Stack order: track → combined fill (green/red) → gold. Drawing gold
// on top of the combined fill means [0, allocated] reads as gold and
// [allocated, allocated+budget] reads as the live claim, with no
// per-segment math.

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({
    required this.reservoirTotal,
    required this.allocatedSoFar,
    required this.budgetInBase,
    required this.isOver,
  });

  final int reservoirTotal;
  final int allocatedSoFar;
  final int budgetInBase;
  final bool isOver;

  static const double _height = 10;

  @override
  Widget build(BuildContext context) {
    final double allocatedFraction = reservoirTotal <= 0
        ? 0.0
        : (allocatedSoFar / reservoirTotal).clamp(0.0, 1.0);
    final double combinedFraction = reservoirTotal <= 0
        ? 0.0
        : ((allocatedSoFar + budgetInBase) / reservoirTotal)
            .clamp(0.0, 1.0);
    final Color thisPlotColor = isOver
        ? CropkeepColors.textRedDeep
        : CropkeepColors.greenPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: _height,
        child: Stack(
          children: [
            Container(color: CropkeepColors.progressTrackOnHero),
            FractionallySizedBox(
              widthFactor: combinedFraction,
              alignment: Alignment.centerLeft,
              child: Container(color: thisPlotColor),
            ),
            FractionallySizedBox(
              widthFactor: allocatedFraction,
              alignment: Alignment.centerLeft,
              child: Container(color: CropkeepColors.textGoldDeep),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Sticky Create bar — pinned to the bottom of the screen. Stays above the
// keyboard because it lives at the tail of the Scaffold body's Column and
// resizeToAvoidBottomInset shrinks the scroll area above it.
//
// Disabled state keeps the faint mint fill but adds a green outline.
// Without the outline the fill blends into the sand bg and the pill
// disappears — the outline gives it visible edges while the fill keeps
// it reading as "the primary green action, currently dormant" rather
// than "an unrelated outlined button".

class _StickyCreateBar extends StatelessWidget {
  const _StickyCreateBar({
    required this.enabled,
    required this.onTap,
    this.label = 'Create plot',
  });

  final bool enabled;
  final VoidCallback onTap;
  // Swapped to "Save changes" by the edit-mode caller. Default keeps the
  // creation flow's wording so existing call sites need no change.
  final String label;

  @override
  Widget build(BuildContext context) {
    final Color bg = enabled
        ? CropkeepColors.greenPrimary
        : CropkeepColors.greenHint;
    final Color fg = enabled
        ? CropkeepColors.textOnGreenBtn
        : CropkeepColors.textGreenDeep;
    final BoxBorder? border = enabled
        ? null
        : Border.all(color: CropkeepColors.greenPrimary, width: 1.5);
    return Container(
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        border: Border(
          top: BorderSide(color: CropkeepColors.borderDivider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Semantics(
            button: true,
            enabled: enabled,
            label: label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? onTap : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 52,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                  border: border,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: fg,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Section label + hint — small reusable bits so every section header
// reads with the same weight and color. Subhead style (15/w800, no
// letter-spacing) so labels feel like content groups in a form rather
// than the uppercase eyebrows we use on hero surfaces.

// Small caption rendered beneath a locked field in edit mode. Lock icon
// + secondary copy keeps the affordance unambiguous without needing a
// disabled tooltip or a separate sheet — the user sees the gate AND the
// reason in one line at the field's natural read position.
class _LockedHint extends StatelessWidget {
  const _LockedHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.lock_outline_rounded,
              size: 13,
              color: CropkeepColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: CropkeepColors.textPrimary,
        height: 1.2,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Kind toggle — single-row segmented control + animated blurb. Compact
// (~80px total vs ~150px of stacked cards) but still surfaces the kind's
// accent color (green/gold/blue) and a one-line explainer for the active
// kind. The blurb fades on change so the user gets feedback on every
// toggle without a tutorial-block weight running on every plot creation.
//
// The choice is conceptually load-bearing: discretionary uses rolling
// pace scoring, fixed obligation uses logged-vs-expected, investment
// uses fill-up scoring (overage never penalized). The blurb earns its
// keep first-time; the accent + label is enough once the user knows.

class _KindToggle extends StatelessWidget {
  const _KindToggle({
    required this.kind,
    required this.onChanged,
    this.enabled = true,
  });

  final _PlotKind kind;
  final ValueChanged<_PlotKind> onChanged;
  // When false, segments still render the current selection (so the user
  // can SEE what the plot's kind is) but tapping is a no-op. The blurb
  // beneath stays visible so the user can still read what the active
  // kind means.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _KindSegment(
                icon: Icons.shopping_basket_outlined,
                label: 'Spending',
                accent: CropkeepColors.greenPrimary,
                selected: kind == _PlotKind.discretionary,
                enabled: enabled,
                onTap: () => onChanged(_PlotKind.discretionary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KindSegment(
                icon: Icons.receipt_long_outlined,
                label: 'Bill',
                accent: CropkeepColors.goldPrimary,
                selected: kind == _PlotKind.fixedObligation,
                enabled: enabled,
                onTap: () => onChanged(_PlotKind.fixedObligation),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _KindSegment(
                icon: Icons.trending_up_rounded,
                label: 'Invest',
                accent: CropkeepColors.bluePremium,
                selected: kind == _PlotKind.investment,
                enabled: enabled,
                onTap: () => onChanged(_PlotKind.investment),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Contextual blurb — only the active kind's description shows.
        // AnimatedSwitcher fades between blurbs so the user sees a small
        // confirming motion when toggling. AnimatedSize absorbs the
        // 1- vs 2-line height delta so siblings beneath don't jump.
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Padding(
              key: ValueKey(kind),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                _blurbFor(kind),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CropkeepColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _blurbFor(_PlotKind kind) {
  switch (kind) {
    case _PlotKind.discretionary:
      return 'Money you spend down across the month — food, fun, transport.';
    case _PlotKind.fixedObligation:
      return 'A known amount paid in one or a few transactions — rent, loans, subscriptions.';
    case _PlotKind.investment:
      return 'Money you put away toward a target — retirement, brokerage deposits, emergency fund top-ups.';
  }
}

// One segment in the kind picker. Visual contract:
//   • Inactive: white bg, light borderCard, muted secondary text + icon.
//   • Active:  accent-tinted bg (10% alpha), 1.5px accent border, accent
//              icon, textPrimary label.
// The 10% alpha wash lets the segment carry color signal without
// fighting nearby form chrome; the icon-then-label inline layout keeps
// the chip short enough that all three fit on a 360px-wide phone.
class _KindSegment extends StatelessWidget {
  const _KindSegment({
    required this.icon,
    required this.label,
    required this.accent,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;
  // When false, the segment renders normally (still reads as selected /
  // unselected so the user can see the current kind) but taps are
  // swallowed. We don't grey the selected segment because the kind is
  // load-bearing information — even when locked, the user needs to
  // recognise which kind their plot is.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : CropkeepColors.borderCard,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Opacity(
          opacity: enabled || selected ? 1.0 : 0.55,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? accent : CropkeepColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected
                        ? CropkeepColors.textPrimary
                        : CropkeepColors.textSecondary,
                    height: 1,
                  ),
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
// Name field — plain text input. Hint copy adapts to kind so the user
// sees the kind of example that fits their selection.

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.kind});

  final TextEditingController controller;
  final _PlotKind kind;

  @override
  Widget build(BuildContext context) {
    final String hint;
    switch (kind) {
      case _PlotKind.fixedObligation:
        hint = 'e.g. Rent, Phone bill, Gym';
      case _PlotKind.investment:
        hint = 'e.g. Retirement, Brokerage, Emergency fund';
      case _PlotKind.discretionary:
        hint = 'e.g. Groceries, Transport, Coffee';
    }
    return _FieldShell(
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.sentences,
        maxLength: 40,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          counterText: '',
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: CropkeepColors.textSecondary,
          ),
        ),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: CropkeepColors.textPrimary,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Budget field — large-feeling money input with an inline currency
// trigger on the left. Tapping the trigger opens the currency picker
// sheet; the input itself respects the selected currency's decimals (no
// dot at all for JPY-style 0-decimal). When the selected currency isn't
// base AND the user has typed something, a small "≈ NT$X" echo appears
// right-aligned on the same row as the amount — the field never
// reserves vertical space for it, so the empty state stays compact and
// the typed amount never shifts. When `isOver` we paint the border red
// AND tint the amount red so the over-cap state reads as one unified
// warning across the field and the caption.

class _BudgetField extends StatelessWidget {
  const _BudgetField({
    required this.controller,
    required this.currency,
    required this.isOver,
    required this.onCurrencyTap,
    required this.budgetInBase,
    required this.baseCurrency,
    this.enabled = true,
  });

  final TextEditingController controller;
  final _Currency currency;
  final bool isOver;
  final VoidCallback onCurrencyTap;
  // The typed amount converted to base minor units. Used to render the
  // in-field conversion echo when the selected currency isn't base.
  final int budgetInBase;
  final _Currency baseCurrency;
  // Edit-mode lock. When false the amount is read-only and the currency
  // trigger is non-interactive — the typed value still renders so the
  // user can see what the existing budget is.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final String hintText = currency.decimals == 0
        ? '0'
        : '0.${'0' * currency.decimals}';
    // Strip the decimal point entirely when the currency has 0 decimals,
    // so the user can't even type the dot for JPY-style amounts.
    final RegExp allow = currency.decimals == 0
        ? RegExp(r'[0-9]')
        : RegExp(r'[0-9.]');
    final Color valueColor = isOver
        ? CropkeepColors.textRedDeep
        : enabled
            ? CropkeepColors.textPrimary
            : CropkeepColors.textSecondary;
    // The conversion echo lives on the SAME ROW as the amount, right of
    // the TextField, and only enters the tree when it's meaningful. No
    // vertical reservation, no dead space — when the field is empty or
    // the currency is base, the TextField gets the full width back and
    // the field stays a single tight row.
    final bool hasConversion = !currency.isBase && budgetInBase > 0;
    return _FieldShell(
      borderColor: isOver
          ? CropkeepColors.borderPlotWarn
          : CropkeepColors.borderCard,
      borderWidth: isOver ? 1.5 : 1,
      // Slimmer horizontal pad on the leading edge so the currency
      // trigger doesn't end up double-inset; the trigger carries its own
      // padding inside its pill.
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CurrencyTrigger(
            currency: currency,
            onTap: onCurrencyTap,
            enabled: enabled,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              // The Key forces Flutter to rebuild the underlying field
              // when the currency's decimal mode changes — otherwise the
              // attached input formatters would stick around stale
              // across a TWD → JPY switch.
              key: ValueKey('budget-${currency.code}'),
              controller: controller,
              enabled: enabled,
              keyboardType: TextInputType.numberWithOptions(
                decimal: currency.decimals > 0,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(allow),
                _DecimalDigitsFormatter(currency.decimals),
              ],
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textSecondary,
                ),
              ),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: valueColor,
                height: 1,
              ),
            ),
          ),
          if (hasConversion) ...[
            const SizedBox(width: 12),
            Text(
              '≈ ${_formatMoney(budgetInBase, baseCurrency)}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textSecondary,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Compact pill sitting inside the budget field. Flag + code + caret so
// the currency identity reads visually (matching how onboarding and the
// secondary-currency sheet present currencies) and the affordance
// "tap to change" is unambiguous. Sand fill so it reads as a separate
// touchable object against the white field shell.

class _CurrencyTrigger extends StatelessWidget {
  const _CurrencyTrigger({
    required this.currency,
    required this.onTap,
    this.enabled = true,
  });

  final _Currency currency;
  final VoidCallback onTap;
  // Disabled in edit mode when the plot has live transactions — the user
  // still sees the locked currency but can't open the picker.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Change currency, ${currency.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: CropkeepColors.bgScreen,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: CropkeepColors.borderCard,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                currency.flagAsset,
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                currency.code,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: CropkeepColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Caps the input to a single '.' and at most `maxDecimals` fractional
// digits. When maxDecimals == 0 the formatter rejects any '.' outright —
// the FilteringTextInputFormatter upstream also strips it from the
// whitelist, but the belt-and-suspenders is cheap and clear.
class _DecimalDigitsFormatter extends TextInputFormatter {
  const _DecimalDigitsFormatter(this.maxDecimals);

  final int maxDecimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    if (maxDecimals == 0) {
      if (text.contains('.')) return oldValue;
      return newValue;
    }
    final firstDot = text.indexOf('.');
    if (firstDot == -1) return newValue;
    if (text.indexOf('.', firstDot + 1) != -1) return oldValue;
    final fractionLength = text.length - firstDot - 1;
    if (fractionLength > maxDecimals) return oldValue;
    return newValue;
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Due-day picker — modal sheet built around a calendar-style grid.
//
// The earlier version paired five shortcut chips (1, 5, 15, 25, Last)
// with an "Other…" chip that opened a separate 1–31 grid sheet. That
// split made shortcut days feel arbitrary (why those five?) and made
// every non-shortcut day a two-step gesture. Worse, it was the only
// picker on the form that wasn't a modal sheet, so it felt out of place
// next to the color and crop pickers.
//
// The replacement is one screen: a 7-column calendar grid showing every
// day 1–31, with "Last day" as a wider chip filling row 5's remaining
// four cells. The grid layout matches the mental model users already
// hold for "day of month" (they see this shape on their phone calendar
// every day); the wider Last-day chip signals "this is a different kind
// of choice" through its shape without needing a separate section.
//
// Cells size responsively via LayoutBuilder — ~39px on iPhone SE,
// ~52px on iPhone Pro Max — so taps stay comfortable across screens
// without the grid spilling sideways on the narrow end.

// Inline form row's leading visual. A miniature day cell shows the
// selected day's number; the calendar icon stands in for the unset
// state. Mirrors the day-cell aesthetic from inside the picker so the
// user can tell at a glance that tapping the row opens "more of these."

class _DueDayRowIcon extends StatelessWidget {
  const _DueDayRowIcon({required this.day});

  final int? day;

  @override
  Widget build(BuildContext context) {
    final bool isNumeric = day != null;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CropkeepColors.borderCard,
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: isNumeric
          ? Text(
              '$day',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1,
              ),
            )
          : const Icon(
              Icons.event_rounded,
              size: 16,
              color: CropkeepColors.textSecondary,
            ),
    );
  }
}

class _DueDayPickerSheet extends StatefulWidget {
  const _DueDayPickerSheet({required this.selected});

  final int? selected;

  @override
  State<_DueDayPickerSheet> createState() => _DueDayPickerSheetState();
}

class _DueDayPickerSheetState extends State<_DueDayPickerSheet> {
  int? _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      // Defensive scroll wrapper: on tall phones the sheet sizes to
      // content, but on very short phones (or with large dynamic type)
      // the hint + grid + confirm stack can outrun the available height.
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 14),
                  decoration: BoxDecoration(
                    color: CropkeepColors.borderCard,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Pick a due day',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The day this bill is expected. Drives the gentle “Due” nudge on the plot tile once that day passes unpaid. Picks past a month’s end roll to that month’s last day — picking 31 works for every month.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CropkeepColors.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              _DueDayGrid(
                selected: _picked,
                onChanged: (d) => setState(() => _picked = d),
              ),
              const SizedBox(height: 22),
              _SheetConfirmButton(
                enabled: _picked != null,
                label: 'Use this day',
                onTap: () => Navigator.of(context).pop(_picked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 7-column calendar layout for days 1–31. Sizes itself to whatever
// horizontal space its parent offers: cells stay square, gaps stay at
// 6px, and row 5 is left-anchored with only [29][30][31] — like the
// incomplete final week of a real calendar month. That visual shape is
// itself a hint: yes, the month ends here, and shorter months will end
// earlier (the scheduler clamps at evaluation).

class _DueDayGrid extends StatelessWidget {
  const _DueDayGrid({
    required this.selected,
    required this.onChanged,
  });

  final int? selected;
  final ValueChanged<int> onChanged;

  static const double _gap = 6;
  static const int _cols = 7;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellSize =
            (constraints.maxWidth - (_cols - 1) * _gap) / _cols;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int row = 0; row < 4; row++) ...[
              if (row > 0) const SizedBox(height: _gap),
              Row(
                children: [
                  for (int col = 0; col < _cols; col++) ...[
                    if (col > 0) const SizedBox(width: _gap),
                    _DueDayCell(
                      day: row * _cols + col + 1,
                      size: cellSize,
                      isSelected:
                          selected == row * _cols + col + 1,
                      onTap: () => onChanged(row * _cols + col + 1),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: _gap),
            // Row 5 — three cells, left-anchored. Trailing space is
            // deliberate: it reads as "the month ends here" rather than
            // "we have an incomplete grid."
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DueDayCell(
                  day: 29,
                  size: cellSize,
                  isSelected: selected == 29,
                  onTap: () => onChanged(29),
                ),
                const SizedBox(width: _gap),
                _DueDayCell(
                  day: 30,
                  size: cellSize,
                  isSelected: selected == 30,
                  onTap: () => onChanged(30),
                ),
                const SizedBox(width: _gap),
                _DueDayCell(
                  day: 31,
                  size: cellSize,
                  isSelected: selected == 31,
                  onTap: () => onChanged(31),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DueDayCell extends StatelessWidget {
  const _DueDayCell({
    required this.day,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final int day;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? CropkeepColors.greenPrimary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? CropkeepColors.greenPrimary
                : CropkeepColors.borderCard,
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? CropkeepColors.textOnGreenBtn
                : CropkeepColors.textPrimary,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Color picker sheet — 3×4 grid of pastel swatches with a labelled name
// under each tile. Follows the same tap-to-preview + confirm pattern as
// the day picker so the user can compare swatches against each other
// before committing. Confirm is always enabled because there's always a
// valid selection in flight (we seed `_picked` from the screen's current
// selection on open).

class _ColorPickerSheet extends StatefulWidget {
  const _ColorPickerSheet({required this.selected});

  final _PlotColor selected;

  @override
  State<_ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<_ColorPickerSheet> {
  late _PlotColor _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      // SingleChildScrollView is defensive: with `isScrollControlled`
      // the sheet sizes to content, so on normal phones nothing scrolls
      // — but if a future palette extension or a particularly short
      // screen pushes the column past available height, it scrolls
      // gracefully instead of throwing a yellow-stripe overflow.
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 14),
                  decoration: BoxDecoration(
                    color: CropkeepColors.borderCard,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Pick a color',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              // Explicit 3 rows × 4 columns rather than a Wrap. A Wrap
              // packs as many tiles per row as fit, which means wider
              // phones get 5/5/2 and the grid stops feeling deliberate.
              // Center alignment + a fixed 12px gap between tiles keeps
              // the row visually anchored in the sheet's whitespace, and
              // the 18px vertical gap between rows matches the inter-tile
              // horizontal rhythm visually (vertical eyes feel ~1.5×
              // tighter than horizontal at the same pixel count).
              for (int row = 0; row < 3; row++) ...[
                if (row > 0) const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int col = 0; col < 4; col++) ...[
                      if (col > 0) const SizedBox(width: 12),
                      _ColorSwatchTile(
                        plotColor: _plotColors[row * 4 + col],
                        isSelected:
                            _plotColors[row * 4 + col] == _picked,
                        onTap: () => setState(
                            () => _picked = _plotColors[row * 4 + col]),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 22),
              _SheetConfirmButton(
                enabled: true,
                label: 'Use this color',
                onTap: () => Navigator.of(context).pop(_picked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// One swatch + label cell in the picker grid. Two stacked circles:
//
//   • Outer 56×56 "ring slot" — always reserved, painted greenPrimary
//     when selected and transparent otherwise. Reserving the slot at all
//     times means the inner swatch never shifts when selection changes,
//     so the eye can compare adjacent swatches without anything jumping.
//   • Inner 50×50 swatch — the actual color, always 50px regardless of
//     selection. A 1px borderCard ring gives it definition against the
//     sheet background.
//
// The 3px gap between them (56 − 50, halved) is the visible ring width
// when selected. Selection cross-fades the outer disc in via opacity so
// the ring blooms in without any layout work.
//
// Column width is fixed at 68 so every tile in the Wrap has the same
// footprint and longer names like "Cornflower" fit at 11pt without
// ellipsizing — ellipsis on a picker label would read as "broken".

class _ColorSwatchTile extends StatelessWidget {
  const _ColorSwatchTile({
    required this.plotColor,
    required this.isSelected,
    required this.onTap,
  });

  static const double _ringSize = 56;
  static const double _swatchSize = 50;
  static const double _tileWidth = 68;

  final _PlotColor plotColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: _tileWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: _ringSize,
              height: _ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    opacity: isSelected ? 1 : 0,
                    child: Container(
                      width: _ringSize,
                      height: _ringSize,
                      decoration: const BoxDecoration(
                        color: CropkeepColors.greenPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Container(
                    width: _swatchSize,
                    height: _swatchSize,
                    decoration: BoxDecoration(
                      color: plotColor.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: CropkeepColors.borderCard,
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plotColor.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: CropkeepColors.textPrimary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Crop picker sheet — same visual language as the color picker (modal
// sheet, drag handle, fade-in selection ring on a fixed-size tile, tap
// to preview + confirm to commit) but sectioned because the catalog
// splits cleanly into the spec's two semantic groups:
//
//   • Starters (3) — permanent, free at onboarding. One centered row.
//   • Seed packs (15) — consumable, bought from the Market. 5 × 3 grid,
//     each row centered for balance.
//
// 18 items don't fit a uniform 4-wide grid (4/4/4/4/2 would repeat the
// "off last row" feel that the color picker had to fix); 5×3 = 15 lands
// exactly, and the 3 starters in their own row above feel deliberate
// rather than orphaned. Tile column shrinks 68 → 60 to fit 5-wide on
// iPhone SE, but the ring + inner swatch dimensions stay at 56/50 so the
// shape language matches the color picker swatch-for-swatch.

class _CropPickerSheet extends StatefulWidget {
  const _CropPickerSheet({required this.options, required this.selected});

  final List<_CropOption> options;
  final _CropOption selected;

  @override
  State<_CropPickerSheet> createState() => _CropPickerSheetState();
}

class _CropPickerSheetState extends State<_CropPickerSheet> {
  late _CropOption _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.selected;
  }

  // Single entry point for every tile tap. Starters and in-stock seed
  // packs select; 0-stock seed packs surface a Market prompt instead.
  // Routing through one method keeps the row builders inside `build`
  // short and makes the "this tile is alive vs informational" branch
  // explicit in one place.
  void _onTileTap(_CropOption crop) {
    if (!crop.isStarter && (crop.stock ?? 0) == 0) {
      CropkeepToast.warning(
        context,
        title: 'Out of ${crop.name} seeds',
        flavor: 'Visit the Market to restock.',
        duration: const Duration(seconds: 2),
      );
      return;
    }
    setState(() => _picked = crop);
  }

  @override
  Widget build(BuildContext context) {
    final List<_CropOption> starters =
        widget.options.where((c) => c.isStarter).toList();
    final List<_CropOption> seedPacks =
        widget.options.where((c) => !c.isStarter).toList();

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 14),
                  decoration: BoxDecoration(
                    color: CropkeepColors.borderCard,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Pick a crop',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 20),
              const _CropSectionEyebrow('STARTERS'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < starters.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _CropTile(
                      crop: starters[i],
                      isSelected: starters[i].id == _picked.id,
                      onTap: () => _onTileTap(starters[i]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              const _CropSectionEyebrow('SEED PACKS'),
              const SizedBox(height: 10),
              // Explicit 5-column rows for the same reason the color
              // picker uses explicit rows: a Wrap would let wider phones
              // fit 6 per row and the deliberate column rhythm would be
              // lost. Row count is derived from the actual list length
              // so a catalog that isn't fully seeded yet (cold-start
              // race) — or a future catalog with more or fewer paid
              // crops — won't index past the end and crash the picker.
              for (int row = 0;
                  row < (seedPacks.length / 5).ceil();
                  row++) ...[
                if (row > 0) const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int col = 0; col < 5; col++)
                      if (row * 5 + col < seedPacks.length) ...[
                        if (col > 0) const SizedBox(width: 8),
                        _CropTile(
                          crop: seedPacks[row * 5 + col],
                          isSelected:
                              seedPacks[row * 5 + col].id == _picked.id,
                          onTap: () =>
                              _onTileTap(seedPacks[row * 5 + col]),
                        ),
                      ],
                  ],
                ),
              ],
              const SizedBox(height: 22),
              _SheetConfirmButton(
                enabled: true,
                label: 'Use this crop',
                onTap: () => Navigator.of(context).pop(_picked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small uppercase section header used to split the picker into the two
// catalog groups. Gold-deep matches the eyebrow color used on the page
// header ("NEW BUDGET ALLOCATION") so the typographic language stays
// consistent across the screen.

class _CropSectionEyebrow extends StatelessWidget {
  const _CropSectionEyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textGoldDeep,
          letterSpacing: 0.8,
          height: 1,
        ),
      ),
    );
  }
}

// Crop equivalent of `_ColorSwatchTile`. Same Stack-with-ring-and-inner
// pattern (so the selection ring blooms in without shifting the inner
// circle), but the inner circle is a white badge with the crop's SVG
// icon centered inside rather than a solid pastel fill. Column shrinks
// to 60 so 5 fit per row on iPhone SE; ring (56) and inner (50) stay
// identical to the color picker for cross-picker rhythm.
//
// Seed packs additionally render a small inventory badge in the top-
// right of the swatch (the spec's `owned_items.quantity` — how many
// cycles the user can still plant this crop). Starters skip the badge
// because they're permanent unlocks with no inventory concept. Tiles
// with stock == 0 fade to 0.4 to communicate "informational only" — the
// parent's `_onTileTap` reroutes their taps to a Market prompt instead
// of selection, so the user sees the crop exists but understands they
// can't pick it until they restock.

class _CropTile extends StatelessWidget {
  const _CropTile({
    required this.crop,
    required this.isSelected,
    required this.onTap,
  });

  static const double _ringSize = 56;
  static const double _swatchSize = 50;
  static const double _iconSize = 32;
  static const double _tileWidth = 60;

  final _CropOption crop;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock =
        !crop.isStarter && (crop.stock ?? 0) == 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: isOutOfStock ? 0.4 : 1.0,
        child: SizedBox(
          width: _tileWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: _ringSize,
                height: _ringSize,
                // Clip.none so the inventory badge can sit at the very
                // edge of the ring slot (or overhang slightly) without
                // being clipped by the Stack's default hardEdge.
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      opacity: isSelected ? 1 : 0,
                      child: Container(
                        width: _ringSize,
                        height: _ringSize,
                        decoration: const BoxDecoration(
                          color: CropkeepColors.greenPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Container(
                      width: _swatchSize,
                      height: _swatchSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CropkeepColors.borderCard,
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: _iconSize,
                        height: _iconSize,
                        child: SvgPicture.asset(
                          crop.iconAsset,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    if (!crop.isStarter)
                      Positioned(
                        top: -2,
                        right: -4,
                        child: _CropStockBadge(count: crop.stock ?? 0),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                crop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10.5,
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: CropkeepColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small white pill stuck on the top-right of a seed-pack swatch, showing
// the remaining inventory count. White-with-shadow so it reads as a
// "sticker" on top of the swatch regardless of whether the selection
// ring is in or out. Auto-widens for double-digit counts via a minimum
// constraint plus horizontal padding.

class _CropStockBadge extends StatelessWidget {
  const _CropStockBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: CropkeepColors.borderCard,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: CropkeepColors.shadowCard,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
          height: 1,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Currency picker sheet — basic functional list of currencies. The
// polished design lands in a follow-up pass; this version exists so the
// inline currency trigger has somewhere to go and the form remains
// usable end-to-end.

class _CurrencyPickerSheet extends StatelessWidget {
  const _CurrencyPickerSheet({
    required this.currencies,
    required this.selected,
  });

  final List<_Currency> currencies;
  final _Currency selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 4, bottom: 14),
                decoration: BoxDecoration(
                  color: CropkeepColors.borderCard,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Pick a currency',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            for (final c in currencies)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _CurrencyRow(
                  currency: c,
                  isSelected: c.code == selected.code,
                  onTap: () => Navigator.of(context).pop(c),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  final _Currency currency;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? CropkeepColors.greenPrimary
                : CropkeepColors.borderCard,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              currency.flagAsset,
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        currency.code,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CropkeepColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      if (currency.isBase) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: CropkeepColors.goldWash,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Base',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: CropkeepColors.textGoldDeep,
                              letterSpacing: 0.4,
                              height: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currency.name,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CropkeepColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                size: 22,
                color: CropkeepColors.greenPrimary,
              ),
          ],
        ),
      ),
    );
  }
}

// Shared confirm button used inside bottom sheets — matches the sticky
// CTA's outline-when-disabled treatment so the disabled pattern is
// consistent across the flow.

class _SheetConfirmButton extends StatelessWidget {
  const _SheetConfirmButton({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg = enabled
        ? CropkeepColors.greenPrimary
        : CropkeepColors.greenHint;
    final Color fg = enabled
        ? CropkeepColors.textOnGreenBtn
        : CropkeepColors.textGreenDeep;
    final BoxBorder? border = enabled
        ? null
        : Border.all(color: CropkeepColors.greenPrimary, width: 1.5);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: fg,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Picker row — tappable shell shared by the Crop and Color selectors.
// Same `_FieldShell` chrome as the input fields so the form reads as a
// stack of one consistent container, with a trailing chevron to signal
// "tap to open picker." The real picker sheets land in a follow-up pass;
// for now the tap surfaces a snackbar so the affordance isn't broken.

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    this.iconAsset,
    this.colorSwatch,
    this.iconWidget,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  final String? iconAsset;
  final Color? colorSwatch;
  // Escape hatch for selectors that need a non-standard leading visual
  // — e.g. the due-day picker, where the "icon" is a mini date tile
  // showing the selected day's number. Caller is responsible for sizing
  // it to match the 28-ish px footprint the other two variants use.
  final Widget? iconWidget;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: _FieldShell(
        child: Row(
          children: [
            if (iconAsset != null)
              SizedBox(
                width: 32,
                height: 32,
                child: SvgPicture.asset(iconAsset!, fit: BoxFit.contain),
              )
            else if (colorSwatch != null)
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colorSwatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CropkeepColors.borderCard,
                    width: 1,
                  ),
                ),
              )
            else
              ?iconWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: CropkeepColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: CropkeepColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: CropkeepColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Reusable shell — white card chrome shared by every field/picker row on
// this screen so the form reads as a stack of one consistent container.

class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.child,
    this.borderColor = CropkeepColors.borderCard,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  });

  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: const [
          BoxShadow(
            color: CropkeepColors.shadowCard,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Minor-units → "$1,234.56" / "¥30,000". Pulls the symbol AND decimal
// places off the currency so JPY-style 0-decimal amounts don't get a
// ghost ".00".
String _formatMoney(int minorUnits, _Currency currency) {
  final int absUnits = minorUnits.abs();
  final int divisor =
      currency.decimals == 0 ? 1 : math.pow(10, currency.decimals).toInt();
  final int whole = currency.decimals == 0 ? absUnits : absUnits ~/ divisor;
  final String wholeStr = _withThousandsSeparator(whole);
  final String sign = minorUnits < 0 ? '-' : '';
  if (currency.decimals == 0) return '$sign${currency.symbol}$wholeStr';
  final String frac =
      (absUnits % divisor).toString().padLeft(currency.decimals, '0');
  return '$sign${currency.symbol}$wholeStr.$frac';
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
