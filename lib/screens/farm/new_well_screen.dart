import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../data/currency_catalog.dart';
import '../../data/database.dart' show CurrencyRow, ExchangeRateRow;
import '../../data/tables/wells.dart' show WellType;
import '../../theme/colors.dart';
import '../../widgets/cropkeep_toast.dart';

// ──────────────────────────────────────────────────────────────────────────
// NewWellScreen — well creation flow.
//
// Mirrors NewPlotScreen's grammar: sand-band header, scrolling form,
// sticky green CTA at the bottom. Same spacing rhythm:
//   • label → field         : 8
//   • section → next section: 24
//
// The form adapts to the chosen well type:
//   • Foundation — reliable, recurring income. Requires an `expected_amount`
//     (drives the reservoir / budgeting basis). Header headline = current
//     reservoir total + a live "+ $Y for this well" caption so the user
//     sees how their input grows the budgeting basis.
//   • Bonus — variable, unpredictable income. NO `expected_amount`; instead
//     an optional `estimate_min` / `estimate_max` range for the user's own
//     reference. Header headline = current bonus pool this cycle, with a
//     caption clarifying that bonus wells fill the pool only on log.
//
// `is_carryover` is system-managed (one row, seeded at onboarding) and is
// intentionally not exposed in this flow.

class NewWellScreen extends StatefulWidget {
  const NewWellScreen({
    super.key,
    required this.type,
    required this.reservoirTotal,
    required this.bonusLogged,
  });

  // Foundation or Bonus — decided by which Add row on the Wells subpage
  // the user tapped. The choice isn't re-litigated on this screen because
  // those two rows are the only entry points and they already commit to
  // a kind; an in-form toggle would just be a second knob for a decision
  // the user has already made.
  final WellType type;
  // Sum of every active foundation well's `expected_amount`, converted to
  // base minor units. The current reservoir cap, used as the header
  // headline when creating a foundation well so the user reads the new
  // well as additive to a known number.
  final int reservoirTotal;
  // Sum of non-deleted bonus income entries minus bonus allocations this
  // cycle, in base minor units. The header headline when creating a bonus
  // well — the new well doesn't change this immediately, but it's the
  // context the user is operating in.
  final int bonusLogged;

  @override
  State<NewWellScreen> createState() => _NewWellScreenState();
}

class _NewWellScreenState extends State<NewWellScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _expectedCtrl = TextEditingController();
  final TextEditingController _minCtrl = TextEditingController();
  final TextEditingController _maxCtrl = TextEditingController();
  _Currency? _selected;
  List<_Currency> _currencies = const [];
  bool _isReady = false;
  bool _isSubmitting = false;
  bool _dependenciesLoaded = false;

  WellType get _type => widget.type;

  _Currency? get _baseCurrencyOrNull {
    for (final c in _currencies) {
      if (c.isBase) return c;
    }
    return null;
  }

  _Currency get _baseCurrency => _baseCurrencyOrNull!;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onAnyChange);
    _expectedCtrl.addListener(_onAnyChange);
    _minCtrl.addListener(_onAnyChange);
    _maxCtrl.addListener(_onAnyChange);
  }

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
    // Pre-cycle: the cycle-scoped table is empty. Fall back to the
    // disk-backed pending store so non-base wells get a real conversion
    // factor instead of silently defaulting to 1:1.
    final Map<String, double> pendingToBase = activeCycle == null
        ? {
            for (final e in scope.pendingRates.current.entries)
              e.key: e.value.rate,
          }
        : const {};
    final currencyRows = await scope.appSettings.watchCurrencies().first;

    if (!mounted) return;
    setState(() {
      _currencies =
          _buildCurrencies(currencyRows, baseCode, rates, pendingToBase);
      _selected = _baseCurrencyOrNull ??
          (_currencies.isNotEmpty ? _currencies.first : null);
      _isReady = _selected != null;
    });
  }

  List<_Currency> _buildCurrencies(
    List<CurrencyRow> rows,
    String baseCode,
    List<ExchangeRateRow> rates,
    Map<String, double> pendingToBase,
  ) {
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
    _expectedCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _onAnyChange() => setState(() {});

  // Parse a controller's text as a decimal in the selected currency and
  // return minor units in THAT currency. Empty / unparseable → 0 so the
  // live header captions stay meaningful as the user types.
  int _toMinor(TextEditingController ctrl) {
    final selected = _selected;
    if (selected == null) return 0;
    final raw = ctrl.text.trim();
    if (raw.isEmpty) return 0;
    final asDouble = double.tryParse(raw);
    if (asDouble == null || asDouble < 0) return 0;
    final num scale = math.pow(10, selected.decimals);
    return (asDouble * scale).round();
  }

  // Convert minor units in the selected currency to base minor units, per
  // the database.md conversion rule:
  //   sourceMinor * rate * 10^(base.decimals - src.decimals), rounded.
  int _toBase(int sourceMinor) {
    final selected = _selected;
    if (selected == null) return sourceMinor;
    if (selected.isBase) return sourceMinor;
    final num scale =
        math.pow(10, _baseCurrency.decimals - selected.decimals);
    return (sourceMinor * selected.rateToBase * scale).round();
  }

  int get _expectedMinor => _toMinor(_expectedCtrl);
  int get _expectedInBase => _toBase(_expectedMinor);
  int get _minMinor => _toMinor(_minCtrl);
  int get _maxMinor => _toMinor(_maxCtrl);
  int get _minInBase => _toBase(_minMinor);
  int get _maxInBase => _toBase(_maxMinor);

  // True only when both min and max are provided AND min > max. Single-
  // sided ranges ("at least $500", "up to $1500") are valid: leaving one
  // bound blank is fine, it just doesn't show in the header echo.
  bool get _rangeInvalid =>
      _minMinor > 0 && _maxMinor > 0 && _minMinor > _maxMinor;

  bool get _canCreate {
    if (_isSubmitting) return false;
    if (!_isReady) return false;
    if (_nameCtrl.text.trim().isEmpty) return false;
    switch (_type) {
      case WellType.foundation:
        // Foundation wells must have a non-null expected_amount in the
        // schema — required here so the reservoir math has a basis.
        return _expectedMinor > 0;
      case WellType.bonus:
        // Bonus wells need only name + currency; the estimate range is
        // optional. Reject only if the range is logically inverted.
        return !_rangeInvalid;
    }
  }

  Future<void> _onCreate() async {
    if (!_canCreate) return;
    final selected = _selected!;
    setState(() => _isSubmitting = true);
    try {
      await AppScope.of(context).wells.create(
            name: _nameCtrl.text.trim(),
            wellType: _type,
            currencyCode: selected.code,
            expectedAmount:
                _type == WellType.foundation ? _expectedMinor : null,
            estimateMin: _type == WellType.bonus && _minMinor > 0
                ? _minMinor
                : null,
            estimateMax: _type == WellType.bonus && _maxMinor > 0
                ? _maxMinor
                : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      CropkeepToast.error(
        context,
        title: "Couldn't create well",
        flavor: '$e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _onCurrencyChanged(_Currency next) {
    if (next.code == _selected?.code) return;
    setState(() {
      _selected = next;
      // Different currency = different denomination. Carrying "100" from
      // NTD to JPY would silently set the expected at ¥100 (≈$21) when
      // the user meant $100 — clear all numeric inputs so the conversion
      // story stays honest.
      _expectedCtrl.clear();
      _minCtrl.clear();
      _maxCtrl.clear();
    });
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

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: CropkeepColors.bgScreen,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final selectedCurrency = _selected!;
    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              type: _type,
              baseCurrency: _baseCurrency,
              reservoirTotal: widget.reservoirTotal,
              bonusLogged: widget.bonusLogged,
              expectedInBase: _expectedInBase,
              estimateMinInBase: _minInBase,
              estimateMaxInBase: _maxInBase,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionLabel('Name'),
                    const SizedBox(height: 8),
                    _NameField(controller: _nameCtrl, type: _type),
                    const SizedBox(height: 24),
                    if (_type == WellType.foundation) ...[
                      const _SectionLabel('Expected per cycle'),
                      const SizedBox(height: 8),
                      _AmountField(
                        controller: _expectedCtrl,
                        currency: selectedCurrency,
                        baseCurrency: _baseCurrency,
                        amountInBase: _expectedInBase,
                        onCurrencyTap: _openCurrencyPicker,
                        hintZero: true,
                      ),
                    ] else ...[
                      const _SectionLabel('Estimate range'),
                      const SizedBox(height: 4),
                      const _SectionHint(
                        'Optional — just for your reference. Bonus income '
                        'still needs to be logged when it arrives to count.',
                      ),
                      const SizedBox(height: 10),
                      _EstimateRangeFields(
                        minController: _minCtrl,
                        maxController: _maxCtrl,
                        currency: selectedCurrency,
                        baseCurrency: _baseCurrency,
                        minInBase: _minInBase,
                        maxInBase: _maxInBase,
                        rangeInvalid: _rangeInvalid,
                        onCurrencyTap: _openCurrencyPicker,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _StickyCreateBar(enabled: _canCreate, onTap: _onCreate),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Currency wrapper — same shape as NewPlotScreen's `_Currency`. Pairs a
// CurrencyCatalog spec with the cycle-rate info the form needs. Final (not
// const) because we resolve the spec by lookup against the shared catalog.

class _Currency {
  const _Currency({
    required this.spec,
    required this.rateToBase,
    required this.isBase,
  });

  final CurrencySpec spec;
  // 1 source major unit × rateToBase = base major units. Identity for the
  // base row. Prototype rates approximate TWD as base; the data pass will
  // swap for live `exchange_rates` rows.
  final double rateToBase;
  final bool isBase;

  String get code => spec.code;
  String get symbol => spec.symbol;
  String get name => spec.name;
  int get decimals => spec.decimalPlaces;
  String get flagAsset => spec.flagAsset;
}

// ──────────────────────────────────────────────────────────────────────────
// Header — same chrome as NewPlotScreen's header (bgHero, 24px bottom
// radius, shared shadow tokens, 20px bottom padding). The headline + live
// caption swap by type:
//   • Foundation: "$X reservoir" + "+ $Y for this well" caption.
//   • Bonus:      "$X bonus pool" + "≈ $min – $max" caption when the user
//                 has typed an estimate, otherwise a static reminder that
//                 bonus only counts on log.
//
// No allocation bar — wells have no upper cap (income is income; the
// budgeting basis grows with foundation, the bonus pool fills as logged).

class _Header extends StatelessWidget {
  const _Header({
    required this.type,
    required this.baseCurrency,
    required this.reservoirTotal,
    required this.bonusLogged,
    required this.expectedInBase,
    required this.estimateMinInBase,
    required this.estimateMaxInBase,
  });

  final WellType type;
  final _Currency baseCurrency;
  final int reservoirTotal;
  final int bonusLogged;
  final int expectedInBase;
  final int estimateMinInBase;
  final int estimateMaxInBase;

  String get _eyebrowText {
    switch (type) {
      case WellType.foundation:
        return 'ADDITIONAL FIXED INCOME';
      case WellType.bonus:
        return 'ADDITIONAL VARIABLE INCOME';
    }
  }

  String get _titleText {
    switch (type) {
      case WellType.foundation:
        return 'New foundation well';
      case WellType.bonus:
        return 'New bonus well';
    }
  }

  String get _iconAsset {
    switch (type) {
      case WellType.foundation:
        return 'assets/icons/well.svg';
      case WellType.bonus:
        return 'assets/icons/water-bottle.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        titleText: _titleText,
                        iconAsset: _iconAsset,
                      ),
                      const SizedBox(height: 14),
                      _HeadlineRow(
                        type: type,
                        reservoirTotal: reservoirTotal,
                        bonusLogged: bonusLogged,
                        baseCurrency: baseCurrency,
                      ),
                      const SizedBox(height: 8),
                      _HeaderCaption(
                        type: type,
                        baseCurrency: baseCurrency,
                        expectedInBase: expectedInBase,
                        estimateMinInBase: estimateMinInBase,
                        estimateMaxInBase: estimateMaxInBase,
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

class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({
    required this.eyebrowText,
    required this.titleText,
    required this.iconAsset,
  });

  final String eyebrowText;
  final String titleText;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: SvgPicture.asset(iconAsset, fit: BoxFit.contain),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrowText,
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
              const SizedBox(height: 6),
              Text(
                titleText,
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

// Headline — the current reservoir total (foundation) or bonus pool
// (bonus), with the descriptor word inline. Stays a single statement of
// "where the user is" — the additive math lives in the caption beneath.

class _HeadlineRow extends StatelessWidget {
  const _HeadlineRow({
    required this.type,
    required this.reservoirTotal,
    required this.bonusLogged,
    required this.baseCurrency,
  });

  final WellType type;
  final int reservoirTotal;
  final int bonusLogged;
  final _Currency baseCurrency;

  @override
  Widget build(BuildContext context) {
    final int amount =
        type == WellType.foundation ? reservoirTotal : bonusLogged;
    final String descriptor =
        type == WellType.foundation ? 'reservoir' : 'bonus pool';
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: _formatMoney(amount, baseCurrency),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1,
                letterSpacing: -0.4,
              ),
            ),
            TextSpan(
              text: ' $descriptor',
              style: const TextStyle(
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

// Caption — live feedback on what the user is typing.
//   • Foundation: "+ $Y for this well" once expected > 0; static cap
//     reminder otherwise.
//   • Bonus: "≈ $min – $max" once either bound is set; explainer reminder
//     ("bonus needs to be logged to count") otherwise.

class _HeaderCaption extends StatelessWidget {
  const _HeaderCaption({
    required this.type,
    required this.baseCurrency,
    required this.expectedInBase,
    required this.estimateMinInBase,
    required this.estimateMaxInBase,
  });

  final WellType type;
  final _Currency baseCurrency;
  final int expectedInBase;
  final int estimateMinInBase;
  final int estimateMaxInBase;

  @override
  Widget build(BuildContext context) {
    if (type == WellType.foundation) {
      if (expectedInBase <= 0) {
        return const _MutedCaption(
          'Foundation wells grow your reservoir — the basis for plot budgets.',
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
            const TextSpan(text: '+ '),
            TextSpan(
              text: _formatMoney(expectedInBase, baseCurrency),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const TextSpan(text: ' for this well'),
          ],
        ),
      );
    }

    // Bonus
    final bool hasMin = estimateMinInBase > 0;
    final bool hasMax = estimateMaxInBase > 0;
    if (!hasMin && !hasMax) {
      return const _MutedCaption(
        'Bonus wells fill the harvest pool — only when income is logged.',
      );
    }
    final String rangeText;
    if (hasMin && hasMax) {
      rangeText =
          '${_formatMoney(estimateMinInBase, baseCurrency)} – ${_formatMoney(estimateMaxInBase, baseCurrency)}';
    } else if (hasMin) {
      rangeText = 'from ${_formatMoney(estimateMinInBase, baseCurrency)}';
    } else {
      rangeText = 'up to ${_formatMoney(estimateMaxInBase, baseCurrency)}';
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
          const TextSpan(text: '≈ '),
          TextSpan(
            text: rangeText,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textPrimary,
            ),
          ),
          const TextSpan(text: ' estimated'),
        ],
      ),
    );
  }
}

class _MutedCaption extends StatelessWidget {
  const _MutedCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CropkeepColors.textSecondaryOnHero,
        height: 1.3,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Name field — plain text input. Hint copy adapts to type so the user
// sees an example that fits their choice.

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.type});

  final TextEditingController controller;
  final WellType type;

  @override
  Widget build(BuildContext context) {
    final String hint = type == WellType.foundation
        ? 'e.g. Salary, Rental, Pension'
        : 'e.g. Freelance, Side gig, Gifts';
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
// Amount field — large money input with inline currency trigger. Reused
// for the foundation "Expected per cycle" field. Same shape as
// NewPlotScreen's `_BudgetField` minus the over-cap red state — there's
// no upper cap on income.

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.currency,
    required this.baseCurrency,
    required this.amountInBase,
    required this.onCurrencyTap,
    this.hintZero = true,
  });

  final TextEditingController controller;
  final _Currency currency;
  final _Currency baseCurrency;
  final int amountInBase;
  final VoidCallback onCurrencyTap;
  final bool hintZero;

  @override
  Widget build(BuildContext context) {
    final String hintText = !hintZero
        ? ''
        : currency.decimals == 0
            ? '0'
            : '0.${'0' * currency.decimals}';
    final RegExp allow = currency.decimals == 0
        ? RegExp(r'[0-9]')
        : RegExp(r'[0-9.]');
    final bool hasConversion = !currency.isBase && amountInBase > 0;
    return _FieldShell(
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _CurrencyTrigger(currency: currency, onTap: onCurrencyTap),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              key: ValueKey(
                'amount-${currency.code}-${identityHashCode(controller)}',
              ),
              controller: controller,
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
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1,
              ),
            ),
          ),
          if (hasConversion) ...[
            const SizedBox(width: 12),
            Text(
              '≈ ${_formatMoney(amountInBase, baseCurrency)}',
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

// ──────────────────────────────────────────────────────────────────────────
// Estimate range — two amount fields side by side, sharing one currency
// trigger on the left. Both fields are optional. The shared currency
// avoids the ambiguity of "$500 USD – $1500 TWD" which would otherwise
// require a separate cross-currency reconciliation path nothing else
// needs.
//
// Layout: [currency trigger] [min field] – [max field]
//
// The trigger sits on the LEFT (anchoring the currency for the whole
// row) rather than appearing twice. A short en-dash between the two
// fields reads as "to" without consuming a label row.

class _EstimateRangeFields extends StatelessWidget {
  const _EstimateRangeFields({
    required this.minController,
    required this.maxController,
    required this.currency,
    required this.baseCurrency,
    required this.minInBase,
    required this.maxInBase,
    required this.rangeInvalid,
    required this.onCurrencyTap,
  });

  final TextEditingController minController;
  final TextEditingController maxController;
  final _Currency currency;
  final _Currency baseCurrency;
  final int minInBase;
  final int maxInBase;
  final bool rangeInvalid;
  final VoidCallback onCurrencyTap;

  @override
  Widget build(BuildContext context) {
    final RegExp allow = currency.decimals == 0
        ? RegExp(r'[0-9]')
        : RegExp(r'[0-9.]');
    final Color borderColor = rangeInvalid
        ? CropkeepColors.borderPlotWarn
        : CropkeepColors.borderCard;
    final double borderWidth = rangeInvalid ? 1.5 : 1;
    final String minHint =
        currency.decimals == 0 ? 'Min' : 'Min';
    final String maxHint =
        currency.decimals == 0 ? 'Max' : 'Max';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldShell(
          borderColor: borderColor,
          borderWidth: borderWidth,
          padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CurrencyTrigger(
                currency: currency,
                onTap: onCurrencyTap,
                compact: true,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RangeAmountField(
                  controller: minController,
                  hint: minHint,
                  allow: allow,
                  decimals: currency.decimals,
                  currencyCode: currency.code,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '–',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: CropkeepColors.textSecondary,
                    height: 1,
                  ),
                ),
              ),
              Expanded(
                child: _RangeAmountField(
                  controller: maxController,
                  hint: maxHint,
                  allow: allow,
                  decimals: currency.decimals,
                  currencyCode: currency.code,
                ),
              ),
            ],
          ),
        ),
        if (rangeInvalid)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: const [
                Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: CropkeepColors.textRedDeep,
                ),
                SizedBox(width: 6),
                Text(
                  'Min should be less than max.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textRedDeep,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RangeAmountField extends StatelessWidget {
  const _RangeAmountField({
    required this.controller,
    required this.hint,
    required this.allow,
    required this.decimals,
    required this.currencyCode,
  });

  final TextEditingController controller;
  final String hint;
  final RegExp allow;
  final int decimals;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: ValueKey(
        'range-$currencyCode-${identityHashCode(controller)}',
      ),
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
      inputFormatters: [
        FilteringTextInputFormatter.allow(allow),
        _DecimalDigitsFormatter(decimals),
      ],
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: CropkeepColors.textSecondary,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: CropkeepColors.textPrimary,
        height: 1,
      ),
    );
  }
}

// Compact pill sitting inside an amount field. Mirrors the trigger
// styling from NewPlotScreen; `compact` shaves a bit of padding so it
// fits in the estimate-range row without crowding the two fields.

class _CurrencyTrigger extends StatelessWidget {
  const _CurrencyTrigger({
    required this.currency,
    required this.onTap,
    this.compact = false,
  });

  final _Currency currency;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Change currency, ${currency.name}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 6 : 8,
          ),
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
                width: compact ? 18 : 22,
                height: compact ? 18 : 22,
                fit: BoxFit.contain,
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                currency.code,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: compact ? 14 : 16,
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
// digits. Matches the formatter on NewPlotScreen so the input feel stays
// consistent across creation flows.
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
// Currency picker sheet — same functional list as NewPlotScreen. Polished
// pass lands when the rest of the currency story stabilises.

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

// ──────────────────────────────────────────────────────────────────────────
// Sticky Create bar — same disabled-with-outline treatment as
// NewPlotScreen so the primary action reads the same across creation
// flows.

class _StickyCreateBar extends StatelessWidget {
  const _StickyCreateBar({required this.enabled, required this.onTap});

  final bool enabled;
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
            label: 'Create well',
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
                  'Create well',
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
// Section label / hint — small reusable bits matching NewPlotScreen's
// section header weight + color.

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

class _SectionHint extends StatelessWidget {
  const _SectionHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: CropkeepColors.textSecondary,
        height: 1.35,
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

// Minor-units → "$1,234.56" / "¥30,000". Same formatter as
// NewPlotScreen — kept local so this file stays self-contained.
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
