import 'dart:math' as math;

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../data/database.dart';
import '../../data/repositories/cycle_repository.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/tables/cycle_summaries.dart';
import '../../data/tables/plot_cycle_results.dart';
import '../../services/fx_rates_service.dart';
import '../../theme/colors.dart';
import '../../widgets/apply_fertilizer_sheet.dart';
import '../../widgets/edit_ledger_entry_sheet.dart';
import '../../widgets/log_transaction_sheet.dart';
import '../market/market_catalog.dart' show MarketCatalog, MarketItemSpec;

// The unified cycle-transition flow.
//
// • firstCycle  — fresh install or post-onboarding setup, no prior cycle.
//                 Skips reconcile + summary + split, jumps straight to the
//                 begin-next confirmation.
// • closeAndStart — normal end-of-month flow. Triggered only once today
//                 is past the active cycle's end_date. Reconcile →
//                 preview → split (if surplus > 0) → confirm next dates.
enum CycleTransitionMode { firstCycle, closeAndStart }

class CycleTransitionScreen extends StatefulWidget {
  const CycleTransitionScreen({super.key, required this.mode});

  final CycleTransitionMode mode;

  @override
  State<CycleTransitionScreen> createState() => _CycleTransitionScreenState();
}

class _CycleTransitionScreenState extends State<CycleTransitionScreen> {
  int _step = 0;
  CyclePreview? _preview;
  bool _previewLoading = false;
  String? _previewError;

  // Surplus split (positive surplus only). Slider value 0..1 of surplus
  // goes to barn (saved); the rest rolls into the Carryover well. The
  // slider + the inline-editable Save amount field share this single
  // source of truth — both write to _savedFraction, both read from it.
  double _savedFraction = 1.0;
  late final TextEditingController _savedController;
  late final FocusNode _savedFocus;

  // Crop swaps the user has staged on the planting-plan step but not
  // yet committed. plotId → desired new cropTypeId. Applied atomically
  // inside closeAndStartNext when the user taps Begin tracking;
  // discarded if the cycle close is abandoned. Staging-only (no DB
  // writes mid-flow) means seed deduction lands exactly once per
  // plot — at cycle start, via _consumeCycleStartSeeds — instead of
  // double-charging through PlotRepository.update's mid-cycle path.
  final Map<int, String> _pendingCropSwaps = <int, String>{};

  // Fertilizer applications the user has staged on the planting-plan
  // step but not yet committed. plotId → fertilizer itemId. Mirror of
  // _pendingCropSwaps: held in memory until closeAndStartNext writes
  // the rows (and decrements owned_items.quantity) atomically against
  // the NEW cycle id. Abandoning the close discards staged picks
  // cleanly — no packs forfeited.
  final Map<int, String> _pendingFertilizers = <int, String>{};

  late final DateTime _nextStart;
  late final DateTime _nextEnd;

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final range = CycleRepository.proposedNextCycleRange();
    _nextStart = range.start;
    _nextEnd = range.end;
    _savedController = TextEditingController();
    _savedFocus = FocusNode();
    if (widget.mode != CycleTransitionMode.firstCycle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
    }
  }

  @override
  void dispose() {
    _savedController.dispose();
    _savedFocus.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _previewLoading = true;
      _previewError = null;
    });
    try {
      final preview = await AppScope.of(context).cycles.previewClose();
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _previewLoading = false;
      });
      // Sync the inline Save field to the current fraction × new surplus,
      // unless the user is mid-edit (focus active). Skip when surplus is
      // non-positive — the split step won't render anyway.
      if (preview != null &&
          preview.surplus > 0 &&
          !_savedFocus.hasFocus) {
        final saved = (preview.surplus * _savedFraction).round();
        _setSavedFieldText(saved, preview.baseCurrencyDecimals);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = '$e';
        _previewLoading = false;
      });
    }
  }

  // Writes a formatted value into the Save field, keeping the cursor at
  // the end. Used by the slider and by preview reloads; never called
  // while the user is focused in the field (caller checks focus).
  void _setSavedFieldText(int savedMinor, int decimals) {
    final text = _formatMinorPlain(savedMinor, decimals);
    _savedController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  // Steps for closeAndStart:
  //   0 reconcile, 1 harvest preview, 2 surplus split (skipped if surplus≤0),
  //   3 begin next.
  // For firstCycle: only step 3 is shown.

  bool get _surplusSliderShown =>
      widget.mode != CycleTransitionMode.firstCycle &&
      (_preview?.surplus ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    // Status-bar icons read dark across all four steps (sand or cream
    // surface at the very top). AnnotatedRegion takes the AppBar's place
    // since the Scaffold no longer has one.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: CropkeepColors.bgScreen,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Every step now owns its own SafeArea + back/close affordance via a
    // sand hero band. _wrapPlainStep is reserved for the loading/error/
    // no-cycle fallback states that don't have a hero of their own.
    if (widget.mode == CycleTransitionMode.firstCycle) {
      return _buildBeginNextStep();
    }
    switch (_step) {
      case 0:
        return _ReconcileBody(onContinue: _advanceToPreview);
      case 1:
        return _buildPreviewStep();
      case 2:
        return _buildSurplusSplitStep();
      case 3:
        return _buildBeginNextStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0 → Step 1: re-trigger the preview so any edits the user just
  // made on the reconcile list are reflected in the harvest numbers. The
  // user can step back to reconcile, fix typos, and the preview rebuilds
  // when they advance forward again.
  void _advanceToPreview() {
    setState(() => _step = 1);
    _loadPreview();
  }

  // Steps without a sand hero (surplus split, begin next) sit on cream
  // bgScreen. They get a minimal back-and-close row at the top so back
  // navigation stays one tap away.
  Widget _wrapPlainStep(Widget content, {VoidCallback? onBack}) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepCloseBar(
            onBack: onBack,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Step 1 — harvest preview

  Widget _buildPreviewStep() {
    // Back from any preview state lands on reconcile so the user can fix
    // typos and let the preview recompute on next forward step.
    void onBack() => setState(() => _step = 0);
    if (_previewLoading) {
      return _wrapPlainStep(
        const Center(
          child: CircularProgressIndicator(color: CropkeepColors.greenPrimary),
        ),
        onBack: onBack,
      );
    }
    if (_previewError != null) {
      return _wrapPlainStep(
        _PreviewErrorState(message: _previewError!, onRetry: _loadPreview),
        onBack: onBack,
      );
    }
    final preview = _preview;
    if (preview == null) {
      return _wrapPlainStep(
        const Center(child: Text('No active cycle to close.')),
        onBack: onBack,
      );
    }
    // Success path: _HarvestPreviewBody embeds its own SafeArea + back +
    // close affordances inside the sand hero, so it bypasses _wrapPlainStep.
    return _HarvestPreviewBody(
      preview: preview,
      onBack: onBack,
      onContinue: () => setState(() {
        _step = _surplusSliderShown ? 2 : 3;
      }),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Step 2 — surplus split

  Widget _buildSurplusSplitStep() {
    final preview = _preview;
    if (preview == null || preview.surplus <= 0) {
      // Defensive — shouldn't be on this step if surplus is zero, but
      // skip forward if we are.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _step = 3));
      return const SizedBox.shrink();
    }
    final decimals = preview.baseCurrencyDecimals;
    final baseCode = preview.baseCurrencyCode;
    final saved = (preview.surplus * _savedFraction).round();
    final rolled = preview.surplus - saved;
    final coinBonus = math.min(50, saved ~/ 10);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SurplusSplitHero(
          surplus: preview.surplus,
          decimals: decimals,
          baseCode: baseCode,
          onBack: () => setState(() => _step = 1),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SplitTile(
                  icon: Icons.savings_rounded,
                  color: CropkeepColors.greenPrimary,
                  label: 'Save to barn',
                  amount: saved,
                  decimals: decimals,
                  baseCode: baseCode,
                  subtitle: coinBonus > 0 ? '+$coinBonus coins' : '',
                  controller: _savedController,
                  focusNode: _savedFocus,
                  onAmountChanged: (text) {
                    final parsed = _parseMinorInput(text, decimals);
                    if (parsed == null) return; // ignore unparseable input
                    final clamped = parsed.clamp(0, preview.surplus);
                    setState(() {
                      _savedFraction = clamped / preview.surplus;
                    });
                  },
                ),
                const SizedBox(height: 8),
                _SplitTile(
                  icon: Icons.replay_rounded,
                  color: CropkeepColors.goldPrimary,
                  label: 'Roll over',
                  amount: rolled,
                  decimals: decimals,
                  baseCode: baseCode,
                  subtitle: 'Lands in next cycle as Carryover income',
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _savedFraction,
                  onChanged: (v) {
                    setState(() => _savedFraction = v);
                    // Only push slider value into the field when it
                    // isn't focused — yanking text from under an actively
                    // typing user would feel hostile.
                    if (!_savedFocus.hasFocus) {
                      final newSaved = (preview.surplus * v).round();
                      _setSavedFieldText(newSaved, decimals);
                    }
                  },
                  min: 0.0,
                  max: 1.0,
                  activeColor: CropkeepColors.greenPrimary,
                  inactiveColor: CropkeepColors.borderCard,
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All to roll',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: CropkeepColors.textSecondary,
                      ),
                    ),
                    Text(
                      'All to barn',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: CropkeepColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _PrimaryButton(
            label: 'Continue',
            onPressed: () => setState(() => _step = 3),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // Step 3 — begin next cycle

  Widget _buildBeginNextStep() {
    final isFirst = widget.mode == CycleTransitionMode.firstCycle;
    if (isFirst) {
      // firstCycle has no planting-plan step (creation already charged
      // seeds), so the body needs no catalog stream.
      return _buildBeginNextLayout(
        isFirst: true,
        effectivePlan: const <_EffectivePlanRow>[],
      );
    }
    // closeAndStart — watch the crop catalog so the planting-plan card,
    // swap sheet, and commit guard all read consistent inventory state.
    // _computeEffectivePlan applies the user's staged swaps on top.
    return StreamBuilder<List<CropPickerEntry>>(
      stream: AppScope.of(context).market.watchCropPicker(),
      builder: (context, snap) {
        final catalog = snap.data ?? const <CropPickerEntry>[];
        final catalogById = <String, CropPickerEntry>{
          for (final e in catalog) e.crop.cropId: e,
        };
        final preview = _preview;
        final effectivePlan = preview == null
            ? const <_EffectivePlanRow>[]
            : _computeEffectivePlan(
                preview.plantingPlan,
                _pendingCropSwaps,
                _pendingFertilizers,
                catalogById,
              );
        return _buildBeginNextLayout(
          isFirst: false,
          effectivePlan: effectivePlan,
          catalogById: catalogById,
        );
      },
    );
  }

  Widget _buildBeginNextLayout({
    required bool isFirst,
    required List<_EffectivePlanRow> effectivePlan,
    Map<String, CropPickerEntry> catalogById = const {},
  }) {
    final monthName = _monthName(_nextStart.month);
    final startMonth = _monthAbbrev(_nextStart.month);
    final endMonth = _monthAbbrev(_nextEnd.month);
    final endLabel = '$endMonth ${_nextEnd.day}';
    final lengthDays = _nextEnd.difference(_nextStart).inDays + 1;
    // firstCycle has nowhere to go back to; closeAndStart's back jumps
    // over the split step if surplus ≤ 0 (we never actually showed it).
    final VoidCallback? onBack = isFirst
        ? null
        : () => setState(() {
              _step = _surplusSliderShown ? 2 : 1;
            });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NextCycleHero(
          onBack: onBack,
          title: isFirst
              ? 'Your $monthName cycle'
              : 'Begin tracking $monthName',
          startMonth: startMonth,
          startDay: _nextStart.day,
          endMonth: endMonth,
          endDay: _nextEnd.day,
          lengthDays: lengthDays,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Planting-plan card only shows for the closeAndStart
                // flow — firstCycle plots haven't passed through a
                // cycle-start seed deduction yet (creation already
                // charged them). The card lists each non-Unplanned plot
                // with its planned crop + inventory state; tapping a row
                // opens the swap sheet.
                if (!isFirst && effectivePlan.isNotEmpty) ...[
                  _PlantingPlanCard(
                    rows: effectivePlan,
                    onSwap: _openSwapSheetByPlotId,
                    onApplyFertilizer: _openFertilizerSheetByPlotId,
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  isFirst
                      ? 'Once you confirm, you can log transactions and '
                          'income against this cycle. The cycle ends on '
                          '$endLabel — close it from the Farm tab when '
                          'you\'re ready.'
                      : 'Once you confirm, the previous cycle is sealed '
                          'into your harvest history and the new cycle '
                          'goes live.',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CropkeepColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _submitError!,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      color: CropkeepColors.textRedDeep,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _PrimaryButton(
            label: _submitting ? 'Working…' : 'Begin tracking',
            onPressed: _submitting
                ? null
                : () => _commitWithSeedGuard(effectivePlan),
          ),
        ),
      ],
    );
  }

  // Looks up the PlotPlanEntry the planting-plan row corresponds to and
  // hands it to _openSwapSheet. Indirection keeps the card UI from
  // having to carry the raw preview entries — it only needs plotId.
  Future<void> _openSwapSheetByPlotId(int plotId) async {
    final preview = _preview;
    if (preview == null) return;
    final entry = preview.plantingPlan.firstWhere(
      (e) => e.plotId == plotId,
      orElse: () => const PlotPlanEntry(
        plotId: -1,
        plotName: '',
        plotColorId: null,
        cropTypeId: '',
        cropName: '',
        isConsumable: false,
        isStarter: false,
        seedsOwned: 0,
      ),
    );
    if (entry.plotId == -1) return;
    await _openSwapSheet(entry);
  }

  // Opens the swap-crop sheet for one plot in the planting plan. The
  // sheet returns the chosen cropId (or null if cancelled); we stage
  // the choice in _pendingCropSwaps without touching the database. The
  // actual write happens atomically inside closeAndStartNext at commit
  // time, so abandoning the cycle close discards staged swaps cleanly.
  Future<void> _openSwapSheet(PlotPlanEntry entry) async {
    final preview = _preview;
    if (preview == null) return;
    final newCropId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SwapCropSheet(
        entry: entry,
        plantingPlan: preview.plantingPlan,
        pendingSwaps: Map<int, String>.unmodifiable(_pendingCropSwaps),
      ),
    );
    if (newCropId == null) return;
    setState(() {
      if (newCropId == entry.cropTypeId) {
        // User picked the original crop — clear any staged swap.
        _pendingCropSwaps.remove(entry.plotId);
      } else {
        _pendingCropSwaps[entry.plotId] = newCropId;
      }
    });
  }

  // Opens the apply-fertilizer sheet in staged mode for the given plot.
  // Returns from the sheet are either a new pick (stage it) or an
  // explicit clear (unstage). Other plots' staged commitments are
  // passed so the sheet filters out packs already allocated and the
  // user can't double-spend a shed of one pack across two plots.
  Future<void> _openFertilizerSheetByPlotId(int plotId) async {
    final preview = _preview;
    if (preview == null) return;
    final plot = preview.plantingPlan.firstWhere(
      (e) => e.plotId == plotId,
      orElse: () => const PlotPlanEntry(
        plotId: -1,
        plotName: '',
        plotColorId: null,
        cropTypeId: '',
        cropName: '',
        isConsumable: false,
        isStarter: false,
        seedsOwned: 0,
      ),
    );
    if (plot.plotId == -1) return;
    // Commitments from OTHER plots — current plot's own staged pick
    // shouldn't shadow itself (it's surfaced separately by the sheet
    // as the "currently staged" band).
    final committed = <String, int>{};
    _pendingFertilizers.forEach((pid, itemId) {
      if (pid == plotId) return;
      committed.update(itemId, (v) => v + 1, ifAbsent: () => 1);
    });
    final staged = _pendingFertilizers[plotId];
    final result = await showApplyFertilizerSheetStaged(
      context,
      plotName: plot.plotName,
      currentlyStagedItemId: staged,
      committedElsewhere: committed,
    );
    if (result == null) return;
    setState(() {
      if (result.cleared) {
        _pendingFertilizers.remove(plotId);
      } else if (result.itemId != null) {
        _pendingFertilizers[plotId] = result.itemId!;
      }
    });
  }

  // Commit wrapper that surfaces the wheat-fallback warning when one or
  // more plots would still auto-revert at cycle start after all staged
  // swaps are applied. User can resolve in place (close sheet, swap
  // crops) or proceed and accept wheat for the affected plots.
  Future<void> _commitWithSeedGuard(
    List<_EffectivePlanRow> effectivePlan,
  ) async {
    if (widget.mode == CycleTransitionMode.firstCycle) {
      // firstCycle doesn't trigger cycle-start seed consumption — no
      // guard needed.
      await _commit();
      return;
    }
    final shortages =
        effectivePlan.where((e) => e.hasShortage).toList();
    if (shortages.isEmpty) {
      await _commit();
      return;
    }
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _WheatFallbackConfirmSheet(shortages: shortages),
    );
    if (proceed == true) {
      await _commit();
    }
  }

  Future<void> _commit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final scope = AppScope.of(context);
    try {
      int newCycleId;
      if (widget.mode == CycleTransitionMode.firstCycle) {
        newCycleId = await scope.cycles.startFirstCycle(
          startDate: _nextStart,
          endDate: _nextEnd,
        );
      } else {
        final preview = _preview;
        final int amountSaved;
        final int amountRolled;
        if (preview != null && preview.surplus > 0) {
          amountSaved = (preview.surplus * _savedFraction).round();
          amountRolled = preview.surplus - amountSaved;
        } else {
          amountSaved = 0;
          amountRolled = 0;
        }
        newCycleId = await scope.cycles.closeAndStartNext(
          amountSavedMinor: amountSaved,
          amountRolledMinor: amountRolled,
          nextStartDate: _nextStart,
          nextEndDate: _nextEnd,
          pendingCropSwaps: Map<int, String>.from(_pendingCropSwaps),
          pendingFertilizers:
              Map<int, String>.from(_pendingFertilizers),
        );
      }

      // Apply onboarding-deferred rates and/or fetch fresh FX once the
      // new cycle has an id to scope them to.
      await _applyInitialOrFreshRates(newCycleId);

      if (!mounted) return;
      Navigator.of(context).maybePop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = '$e';
        _submitting = false;
      });
    }
  }

  Future<void> _applyInitialOrFreshRates(int newCycleId) async {
    final scope = AppScope.of(context);
    final pending = await scope.appSettings.consumePendingInitialRates();
    final settings = await scope.appSettings.watch().first;
    if (settings == null) return;
    final baseCode = settings.baseCurrencyCode;
    final db = scope.database;
    final secondaries = await (db.select(db.currencies)
          ..where((t) => t.isActive.equals(true) & t.isBase.equals(false)))
        .get();
    final codes = [for (final c in secondaries) c.code];
    if (codes.isEmpty) return;
    if (pending.isNotEmpty) {
      for (final entry in pending.entries) {
        if (entry.value <= 0) continue;
        if (entry.key == baseCode) continue;
        await scope.exchangeRates.upsertRate(
          cycleId: newCycleId,
          fromCode: entry.key,
          toCode: baseCode,
          rate: entry.value,
        );
      }
      return;
    }
    // No pending → try fresh FX. Fall back silently to whatever the user
    // can enter later in the rates sheet.
    try {
      await scope.exchangeRates.snapshotFromApi(
        cycleId: newCycleId,
        baseCode: baseCode,
        secondaryCodes: codes,
      );
    } on FxRatesException {
      // Silent — the user can enter rates manually via the rates sheet
      // on the Farmer tab.
    }
  }
}

// ──────────────────────────────────────────────────────────────────────
// Ledger entry — unified shape that the reconcile step uses to render
// transactions and income entries in one list.

class _LedgerEntry {
  const _LedgerEntry({
    required this.id,
    required this.cycleId,
    required this.isIncome,
    required this.label,
    required this.amountMinor,
    required this.baseAmountMinor,
    required this.currencyCode,
    required this.note,
    required this.occurredAt,
  });

  final int id;
  final int cycleId;
  final bool isIncome;
  final String label;
  // Source-currency amount, kept around even though render uses
  // baseAmountMinor so totals never drift across mixed-currency cycles.
  final int amountMinor;
  // Base-currency amount — what the hero totals and per-row display use.
  final int baseAmountMinor;
  final String currencyCode;
  final String? note;
  final DateTime occurredAt;
}

// ──────────────────────────────────────────────────────────────────────
// Step 0 — reconcile body
//
// Owns the StreamBuilder stack (active cycle, base currency, transactions,
// income, plots, wells). Once data is in, hands off to _ReconcileContent
// which composes the hero + heads-up + section + CTA.

class _ReconcileBody extends StatelessWidget {
  const _ReconcileBody({required this.onContinue});

  final VoidCallback onContinue;

  Future<void> _editEntry(BuildContext context, _LedgerEntry entry) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditLedgerEntrySheet(
        entryId: entry.id,
        isExpense: !entry.isIncome,
      ),
    );
  }

  Future<void> _addEntry(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LogTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<CycleRow?>(
      stream: scope.cycles.watchActiveCycle(),
      builder: (context, cycleSnap) {
        final cycle = cycleSnap.data;
        if (cycle == null) {
          // No sand hero to host the close X yet, so use the same minimal
          // top bar that the plain steps use.
          return SafeArea(
            child: Column(
              children: [
                _StepCloseBar(
                  onClose: () => Navigator.of(context).maybePop(),
                ),
                const Expanded(
                  child: Center(child: Text('No active cycle.')),
                ),
              ],
            ),
          );
        }
        return StreamBuilder<AppSettingsRow?>(
          stream: scope.appSettings.watch(),
          builder: (context, settingsSnap) {
            final code = settingsSnap.data?.baseCurrencyCode;
            return StreamBuilder<CurrencyRow?>(
              stream: _watchBaseCurrency(scope.database, code),
              builder: (context, currencySnap) {
                final currency = currencySnap.data;
                final symbol = currency?.symbol ?? r'$';
                final decimals = currency?.decimalPlaces ?? 2;
                return StreamBuilder<List<TransactionRow>>(
                  stream: scope.transactions.watchByCycle(cycle.id),
                  builder: (context, txSnap) {
                    return StreamBuilder<List<IncomeEntryRow>>(
                      stream: scope.incomeEntries.watchByCycle(cycle.id),
                      builder: (context, incSnap) {
                        return StreamBuilder<List<PlotRow>>(
                          stream: scope.plots.watchActivePlots(),
                          builder: (context, plotsSnap) {
                            return StreamBuilder<List<WellRow>>(
                              stream: scope.wells.watchActiveWells(),
                              builder: (context, wellsSnap) {
                                return _ReconcileContent(
                                  cycle: cycle,
                                  transactions:
                                      txSnap.data ?? const <TransactionRow>[],
                                  incomes:
                                      incSnap.data ?? const <IncomeEntryRow>[],
                                  plots:
                                      plotsSnap.data ?? const <PlotRow>[],
                                  wells:
                                      wellsSnap.data ?? const <WellRow>[],
                                  symbol: symbol,
                                  decimals: decimals,
                                  onAdd: () => _addEntry(context),
                                  onEdit: (e) => _editEntry(context, e),
                                  onContinue: onContinue,
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
}

class _ReconcileContent extends StatelessWidget {
  const _ReconcileContent({
    required this.cycle,
    required this.transactions,
    required this.incomes,
    required this.plots,
    required this.wells,
    required this.symbol,
    required this.decimals,
    required this.onAdd,
    required this.onEdit,
    required this.onContinue,
  });

  final CycleRow cycle;
  final List<TransactionRow> transactions;
  final List<IncomeEntryRow> incomes;
  final List<PlotRow> plots;
  final List<WellRow> wells;
  final String symbol;
  final int decimals;
  final VoidCallback onAdd;
  final ValueChanged<_LedgerEntry> onEdit;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final plotById = {for (final p in plots) p.id: p};
    final wellById = {for (final w in wells) w.id: w};

    final entries = <_LedgerEntry>[
      for (final t in transactions)
        _LedgerEntry(
          id: t.id,
          cycleId: t.cycleId,
          isIncome: false,
          label: plotById[t.plotId]?.name ?? 'Unknown plot',
          amountMinor: t.amount,
          baseAmountMinor: t.baseAmount,
          currencyCode: t.currencyCode,
          note: t.note,
          occurredAt: DateTime.fromMillisecondsSinceEpoch(t.spentAt),
        ),
      for (final e in incomes)
        _LedgerEntry(
          id: e.id,
          cycleId: e.cycleId,
          isIncome: true,
          label: wellById[e.wellId]?.name ?? 'Unknown well',
          amountMinor: e.amount,
          baseAmountMinor: e.baseAmount,
          currencyCode: e.currencyCode,
          note: e.note,
          occurredAt: DateTime.fromMillisecondsSinceEpoch(e.receivedAt),
        ),
    ]..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

    final int incomeTotalBase = entries
        .where((e) => e.isIncome)
        .fold<int>(0, (s, e) => s + e.baseAmountMinor);
    final int spentTotalBase = entries
        .where((e) => !e.isIncome)
        .fold<int>(0, (s, e) => s + e.baseAmountMinor);

    final cycleStart = DateTime.fromMillisecondsSinceEpoch(cycle.startDate);
    final cycleStartWeekday = cycleStart.weekday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReconcileHero(
          cycle: cycle,
          entryCount: entries.length,
          incomeTotalBase: incomeTotalBase,
          spentTotalBase: spentTotalBase,
          symbol: symbol,
          decimals: decimals,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _HeadsUpCard(),
                const SizedBox(height: 14),
                _ReconcileSection(
                  entries: entries,
                  cycleStart: cycleStart,
                  cycleStartWeekday: cycleStartWeekday,
                  symbol: symbol,
                  decimals: decimals,
                  onEdit: onEdit,
                  onAdd: onAdd,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _PrimaryButton(
            label: 'Looks good, harvest',
            onPressed: onContinue,
          ),
        ),
      ],
    );
  }
}

// Sand band at the top of the reconcile step — IS the page header. No
// Material AppBar above; the close X lives in this band's top row,
// mirroring BreakdownEnvelopeHeader's back-arrow slot. Same chrome
// (bgHero, 24px bottom radius, shadowCard) so the page reads as a
// sibling of the breakdown screens.
class _ReconcileHero extends StatelessWidget {
  const _ReconcileHero({
    required this.cycle,
    required this.entryCount,
    required this.incomeTotalBase,
    required this.spentTotalBase,
    required this.symbol,
    required this.decimals,
  });

  final CycleRow cycle;
  final int entryCount;
  final int incomeTotalBase;
  final int spentTotalBase;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.fromMillisecondsSinceEpoch(cycle.startDate);
    final end = DateTime.fromMillisecondsSinceEpoch(cycle.endDate);
    final now = DateTime.now();
    final cycleLength = end.difference(start).inDays + 1;
    final rawDay = now.difference(start).inDays + 1;
    final cycleDay = rawDay.clamp(1, cycleLength);
    final daysLeft = (cycleLength - cycleDay).clamp(0, cycleLength);
    final monthLabel = _monthName(start.month).toUpperCase();

    return DecoratedBox(
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
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reconcile is the first step — no back affordance, just
              // the close X anchored to the right edge (conventional
              // wizard layout). Tinted to textSecondaryOnHero so it reads
              // as native to the sand band, not a foreign control.
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 26,
                      color: CropkeepColors.textSecondaryOnHero,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/ledger.svg',
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'CYCLE LEDGER · $monthLabel',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textGoldDeep,
                    letterSpacing: 0.8,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entryCount == 0
                  ? 'Nothing logged yet'
                  : '$entryCount entr${entryCount == 1 ? 'y' : 'ies'} this cycle',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1.1,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HeroAmountChip(
                    icon: Icons.arrow_upward_rounded,
                    label: 'income',
                    amount: incomeTotalBase,
                    symbol: symbol,
                    decimals: decimals,
                    accent: CropkeepColors.textGreenDeep,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroAmountChip(
                    icon: Icons.arrow_downward_rounded,
                    label: 'spent',
                    amount: spentTotalBase,
                    symbol: symbol,
                    decimals: decimals,
                    accent: CropkeepColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CropkeepColors.textSecondaryOnHero,
                  height: 1.3,
                ),
                children: [
                  const TextSpan(text: 'Day '),
                  TextSpan(
                    text: '$cycleDay',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                    ),
                  ),
                  TextSpan(text: ' of $cycleLength  ·  '),
                  if (daysLeft > 0) ...[
                    TextSpan(
                      text: '$daysLeft',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                      text: ' day${daysLeft == 1 ? '' : 's'} until harvest',
                    ),
                  ] else
                    const TextSpan(text: 'harvest is ready'),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _CycleProgressBar(fraction: cycleDay / cycleLength),
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

// Small white chip in the reconcile hero showing one of the two totals
// (income or spent). White card on sand band reads as a clean, scannable
// readout instead of a fact buried in body text.
class _HeroAmountChip extends StatelessWidget {
  const _HeroAmountChip({
    required this.icon,
    required this.label,
    required this.amount,
    required this.symbol,
    required this.decimals,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final int amount;
  final String symbol;
  final int decimals;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _formatMoney(amount, symbol: symbol, decimals: decimals),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CropkeepColors.textSecondary,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleProgressBar extends StatelessWidget {
  const _CycleProgressBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final clamped = fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 10,
        child: Stack(
          children: [
            Container(color: CropkeepColors.progressTrackOnHero),
            FractionallySizedBox(
              widthFactor: clamped,
              alignment: Alignment.centerLeft,
              child: Container(color: CropkeepColors.textGoldDeep),
            ),
          ],
        ),
      ),
    );
  }
}

// Small white card sitting between the hero and the entries list — gentle
// reminder that the cycle freezes after harvest. Sun glyph rather than a
// warning sign keeps the tone light.
class _HeadsUpCard extends StatelessWidget {
  const _HeadsUpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CropkeepColors.goldWash,
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              size: 20,
              color: CropkeepColors.textGoldDeep,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add anything you missed before harvest. Tap any row to fix '
              'typos — once you harvest, the cycle freezes.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Day-grouped ledger inside a SectionCard. Each day-of-cycle becomes a
// sub-section with a "Day N · Wed" eyebrow, and entries inside use the
// calendar-tile + amount row pattern borrowed from the plot breakdown.
class _ReconcileSection extends StatelessWidget {
  const _ReconcileSection({
    required this.entries,
    required this.cycleStart,
    required this.cycleStartWeekday,
    required this.symbol,
    required this.decimals,
    required this.onEdit,
    required this.onAdd,
  });

  final List<_LedgerEntry> entries;
  final DateTime cycleStart;
  final int cycleStartWeekday;
  final String symbol;
  final int decimals;
  final ValueChanged<_LedgerEntry> onEdit;
  final VoidCallback onAdd;

  int _dayOfCycle(_LedgerEntry e) {
    final occurDate =
        DateTime(e.occurredAt.year, e.occurredAt.month, e.occurredAt.day);
    final startDate =
        DateTime(cycleStart.year, cycleStart.month, cycleStart.day);
    final delta = occurDate.difference(startDate).inDays + 1;
    return delta < 1 ? 1 : delta;
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionHeader('By day'),
            const SizedBox(height: 12),
            const _ReconcileEmptyState(),
            const SizedBox(height: 14),
            _AddTransactionTile(onTap: onAdd),
          ],
        ),
      );
    }

    final Map<int, List<_LedgerEntry>> byDay = {};
    for (final e in entries) {
      byDay.putIfAbsent(_dayOfCycle(e), () => []).add(e);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader('By day'),
          for (int i = 0; i < days.length; i++) ...[
            _DayGroupHeader(
              day: days[i],
              cycleStartWeekday: cycleStartWeekday,
            ),
            for (final e in byDay[days[i]]!)
              _ReconcileEntryRow(
                entry: e,
                day: days[i],
                cycleStartWeekday: cycleStartWeekday,
                symbol: symbol,
                decimals: decimals,
                onTap: () => onEdit(e),
              ),
          ],
          const SizedBox(height: 14),
          _AddTransactionTile(onTap: onAdd),
        ],
      ),
    );
  }
}

class _DayGroupHeader extends StatelessWidget {
  const _DayGroupHeader({
    required this.day,
    required this.cycleStartWeekday,
  });

  final int day;
  final int cycleStartWeekday;

  static const List<String> _weekdayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  int _weekdayIndex(int d) => ((cycleStartWeekday - 1) + (d - 1)) % 7;

  @override
  Widget build(BuildContext context) {
    final wd = _weekdayLabels[_weekdayIndex(day)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
      child: Text(
        'DAY $day · ${wd.toUpperCase()}',
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

class _ReconcileEntryRow extends StatelessWidget {
  const _ReconcileEntryRow({
    required this.entry,
    required this.day,
    required this.cycleStartWeekday,
    required this.symbol,
    required this.decimals,
    required this.onTap,
  });

  final _LedgerEntry entry;
  final int day;
  final int cycleStartWeekday;
  final String symbol;
  final int decimals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = entry.isIncome;
    // U+2212 minus sign reads better than a hyphen on amounts; same width
    // as the plus, no italic kerning quirks.
    final sign = isIncome ? '+' : '−';
    final amountColor =
        isIncome ? CropkeepColors.textGreenDeep : CropkeepColors.textPrimary;
    final hasNote = entry.note != null && entry.note!.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CalendarTile(day: day, cycleStartWeekday: cycleStartWeekday),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.label,
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
                    if (hasNote) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: CropkeepColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${_formatMoney(entry.baseAmountMinor, symbol: symbol, decimals: decimals)}',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Inviting card-row at the bottom of the entries list. Green-hint wash so
// the tile reads as a friendly call to action (not a generic outlined
// button); chevron on the trailing edge mirrors the action-row pattern
// from PlotBreakdownScreen's overflow sheet.
class _AddTransactionTile extends StatelessWidget {
  const _AddTransactionTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: CropkeepColors.greenHint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: CropkeepColors.greenPrimary.withValues(alpha: 0.4),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CropkeepColors.greenPrimary,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Log one more transaction',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CropkeepColors.textGreenDeep,
                    height: 1.2,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: CropkeepColors.textGreenDeep,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReconcileEmptyState extends StatelessWidget {
  const _ReconcileEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CropkeepColors.greenHint,
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 28,
              color: CropkeepColors.greenPrimary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'The field\'s quiet this cycle.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CropkeepColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Nothing logged yet — that\'s okay.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CropkeepColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Step 1 — harvest preview body
//
// Wraps the preview compute result in a layout that mirrors reconcile:
// sand hero band → padded scrollable section cards → fixed CTA. Watches
// the base currency row for its symbol so amounts render with the user's
// chosen currency glyph instead of the raw ISO code.

class _HarvestPreviewBody extends StatelessWidget {
  const _HarvestPreviewBody({
    required this.preview,
    required this.onBack,
    required this.onContinue,
  });

  final CyclePreview preview;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<CurrencyRow?>(
      stream: _watchBaseCurrency(scope.database, preview.baseCurrencyCode),
      builder: (context, currencySnap) {
        final symbol = currencySnap.data?.symbol ?? r'$';
        return StreamBuilder<CycleRow?>(
          stream: scope.cycles.watchActiveCycle(),
          builder: (context, cycleSnap) {
            final cycle = cycleSnap.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HarvestHero(
                  preview: preview,
                  cycle: cycle,
                  symbol: symbol,
                  onBack: onBack,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _IncomeCard(preview: preview, symbol: symbol),
                        const SizedBox(height: 14),
                        _SpendingCard(preview: preview, symbol: symbol),
                        const SizedBox(height: 14),
                        _PerPlotCard(preview: preview, symbol: symbol),
                        const SizedBox(height: 14),
                        _CoinSummaryCard(preview: preview),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _PrimaryButton(
                    label: 'Continue',
                    onPressed: onContinue,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _PreviewErrorState extends StatelessWidget {
  const _PreviewErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CropkeepColors.redAlert.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 28,
                color: CropkeepColors.redAlert,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not compute harvest',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: CropkeepColors.greenPrimary,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

// Sand band at the top of the harvest preview. Mirrors _ReconcileHero's
// chrome (close X embedded in the top row, no AppBar above) but the
// content language shifts from reconciliation ("entries this cycle") to
// verdict ("Excellent harvest" + surplus). The tier badge + label is the
// emotional headline; the surplus number is the supporting data.
class _HarvestHero extends StatelessWidget {
  const _HarvestHero({
    required this.preview,
    required this.cycle,
    required this.symbol,
    required this.onBack,
  });

  final CyclePreview preview;
  final CycleRow? cycle;
  final String symbol;
  // Step 1 always has a previous step (reconcile), so onBack is required
  // rather than nullable. Tap → caller pops back to step 0.
  final VoidCallback onBack;

  (String, IconData, Color, Color) _tierStyle() {
    switch (preview.resultTier) {
      case CycleResultTier.excellent:
        return (
          'Excellent harvest',
          Icons.spa_rounded,
          CropkeepColors.greenPrimary,
          CropkeepColors.textGreenDeep,
        );
      case CycleResultTier.solidlyPositive:
        return (
          'Net positive',
          Icons.eco_rounded,
          CropkeepColors.greenPrimary,
          CropkeepColors.textGreenDeep,
        );
      case CycleResultTier.barelyPositive:
        return (
          'Just barely',
          Icons.local_florist_rounded,
          CropkeepColors.goldPrimary,
          CropkeepColors.textGoldDeep,
        );
      case CycleResultTier.negative:
        return (
          'Tough month',
          Icons.cloud_rounded,
          CropkeepColors.redAlert,
          CropkeepColors.textRedDeep,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, icon, badgeColor, deepText) = _tierStyle();
    final decimals = preview.baseCurrencyDecimals;
    final surplus = preview.surplus;
    final surplusSign = surplus > 0
        ? '+ '
        : surplus < 0
            ? '− '
            : '';
    final surplusAbs =
        _formatMoney(surplus.abs(), symbol: symbol, decimals: decimals);
    final descriptor = surplus < 0 ? 'deficit' : 'surplus';
    final surplusColor = surplus < 0
        ? CropkeepColors.textRedDeep
        : surplus > 0
            ? CropkeepColors.textGreenDeep
            : CropkeepColors.textPrimary;

    int? cycleLength;
    String monthLabel = 'CYCLE';
    if (cycle != null) {
      final start = DateTime.fromMillisecondsSinceEpoch(cycle!.startDate);
      final end = DateTime.fromMillisecondsSinceEpoch(cycle!.endDate);
      cycleLength = end.difference(start).inDays + 1;
      monthLabel = '${_monthName(start.month).toUpperCase()} CYCLE';
    }

    return DecoratedBox(
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
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back-left + close-right — the conventional wizard layout.
              // Both glyphs tinted to textSecondaryOnHero so they read as
              // native to the sand band, not foreign controls.
              Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/back.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        CropkeepColors.textSecondaryOnHero,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: onBack,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 26,
                      color: CropkeepColors.textSecondaryOnHero,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/cornucopia.svg',
                  width: 14,
                  height: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  'HARVEST · $monthLabel',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textGoldDeep,
                    letterSpacing: 0.8,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: badgeColor.withValues(alpha: 0.16),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.4),
                      width: 1.4,
                    ),
                  ),
                  child: Icon(icon, size: 20, color: badgeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: deepText,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$surplusSign$surplusAbs',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: surplusColor,
                        height: 1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    TextSpan(
                      text: '  $descriptor',
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
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CropkeepColors.textSecondaryOnHero,
                  height: 1.3,
                ),
                children: [
                  const TextSpan(text: 'Income '),
                  TextSpan(
                    text: _formatMoney(
                      preview.totalFoundationIncome +
                          preview.totalBonusIncome,
                      symbol: symbol,
                      decimals: decimals,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                    ),
                  ),
                  const TextSpan(text: '  ·  Spent '),
                  TextSpan(
                    text: _formatMoney(
                      preview.totalSpent,
                      symbol: symbol,
                      decimals: decimals,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                    ),
                  ),
                  if (cycleLength != null)
                    TextSpan(text: '  ·  $cycleLength days'),
                ],
              ),
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

// "Income" section card — two rows (foundation / bonus) with the same
// share-bar grammar as the breakdown screens. Foundation gets a water
// drop (the foundation-well metaphor), bonus gets the gold sparkle.
class _IncomeCard extends StatelessWidget {
  const _IncomeCard({required this.preview, required this.symbol});
  final CyclePreview preview;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final foundation = preview.totalFoundationIncome;
    final bonus = preview.totalBonusIncome;
    final total = foundation + bonus;
    final decimals = preview.baseCurrencyDecimals;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader('Income'),
          const SizedBox(height: 12),
          _BreakdownAmountRow(
            icon: Icons.water_drop_rounded,
            iconBg: CropkeepColors.greenHint,
            iconColor: CropkeepColors.textGreenDeep,
            label: 'Foundation income',
            amount: foundation,
            symbol: symbol,
            decimals: decimals,
            share: total > 0 ? foundation / total : 0,
            shareCaption: 'of income',
          ),
          const SizedBox(height: 14),
          _BreakdownAmountRow(
            icon: Icons.auto_awesome_rounded,
            iconBg: CropkeepColors.goldWash,
            iconColor: CropkeepColors.textGoldDeep,
            label: 'Bonus income',
            amount: bonus,
            symbol: symbol,
            decimals: decimals,
            share: total > 0 ? bonus / total : 0,
            shareCaption: 'of income',
          ),
        ],
      ),
    );
  }
}

// "Where it went" section card — planned vs. unplanned, same row template
// as the income card. Wild patch label echoes the breakdown screen's
// "WILD PATCH" eyebrow vocabulary.
class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.preview, required this.symbol});
  final CyclePreview preview;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final planned = preview.totalSpentPlanned;
    final unplanned = preview.totalSpentUnplanned;
    final total = planned + unplanned;
    final decimals = preview.baseCurrencyDecimals;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader('Where it went'),
          const SizedBox(height: 12),
          _BreakdownAmountRow(
            icon: Icons.spa_rounded,
            iconBg: CropkeepColors.greenHint,
            iconColor: CropkeepColors.textGreenDeep,
            label: 'Planned spending',
            amount: planned,
            symbol: symbol,
            decimals: decimals,
            share: total > 0 ? planned / total : 0,
            shareCaption: 'of spend',
          ),
          const SizedBox(height: 14),
          _BreakdownAmountRow(
            icon: Icons.local_florist_rounded,
            iconBg: CropkeepColors.goldWash,
            iconColor: CropkeepColors.textGoldDeep,
            label: 'Wild patch (unplanned)',
            amount: unplanned,
            symbol: symbol,
            decimals: decimals,
            share: total > 0 ? unplanned / total : 0,
            shareCaption: 'of spend',
          ),
        ],
      ),
    );
  }
}

// Single row used by both the Income and Where-it-went cards. Pastel icon
// tile (40px) + title + right-justified amount + share caption + gold
// share bar. Visual cousin of plot_breakdown_screen's _TransactionRow.
class _BreakdownAmountRow extends StatelessWidget {
  const _BreakdownAmountRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.amount,
    required this.symbol,
    required this.decimals,
    required this.share,
    required this.shareCaption,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final int amount;
  final String symbol;
  final int decimals;
  final double share;
  final String shareCaption;

  @override
  Widget build(BuildContext context) {
    final sharePct = (share * 100).clamp(0, 100).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBg,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
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
                      label,
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
                    _formatMoney(amount, symbol: symbol, decimals: decimals),
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
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_formatSharePct(sharePct)}% $shareCaption',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              _ShareBar(sharePct: sharePct),
            ],
          ),
        ),
      ],
    );
  }
}

// "By plot" section — the centerpiece. Each plot becomes a row with a
// 44px tinted leaf-icon chip (color tracks the final state), a state pill
// next to the name, a caption with budget context, and a gold share bar
// for its share of total cycle spend. Coin pill on the trailing edge
// when the plot earned harvest coins.
class _PerPlotCard extends StatelessWidget {
  const _PerPlotCard({required this.preview, required this.symbol});
  final CyclePreview preview;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final plots = preview.plotResults;
    final cycleTotal = preview.totalSpent;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader('By plot'),
          const SizedBox(height: 4),
          if (plots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No plots tracked this cycle.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CropkeepColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            for (final p in plots)
              _PlotResultRow(
                result: p,
                cycleTotalSpent: cycleTotal,
                symbol: symbol,
                decimals: preview.baseCurrencyDecimals,
              ),
        ],
      ),
    );
  }
}

class _PlotResultRow extends StatelessWidget {
  const _PlotResultRow({
    required this.result,
    required this.cycleTotalSpent,
    required this.symbol,
    required this.decimals,
  });

  final PlotResultPreview result;
  final int cycleTotalSpent;
  final String symbol;
  final int decimals;

  // (pill label, pill background, pill text color, icon accent)
  (String, Color, Color, Color) _stateStyle() {
    switch (result.finalState) {
      case PlotFinalState.harvested:
        return (
          'Harvested',
          CropkeepColors.greenLight,
          CropkeepColors.textGreenDeep,
          CropkeepColors.greenPrimary,
        );
      case PlotFinalState.mildStress:
        return (
          'Mild stress',
          CropkeepColors.goldWash,
          CropkeepColors.textGoldDeep,
          CropkeepColors.goldPrimary,
        );
      case PlotFinalState.withered:
        return (
          'Withered',
          CropkeepColors.redAlert.withValues(alpha: 0.12),
          CropkeepColors.textRedDeep,
          CropkeepColors.redAlert,
        );
      case PlotFinalState.dead:
        return (
          'Dead',
          CropkeepColors.redAlert.withValues(alpha: 0.18),
          CropkeepColors.textRedDeep,
          CropkeepColors.redAlert,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (stateLabel, pillBg, pillText, iconAccent) = _stateStyle();
    final share = cycleTotalSpent > 0
        ? result.totalSpentBase / cycleTotalSpent
        : 0.0;
    final sharePct = (share * 100).clamp(0, 100).toDouble();
    final hasBudget =
        !result.isUnplanned && (result.budgetAmountBase ?? 0) > 0;
    final spentStr =
        _formatMoney(result.totalSpentBase, symbol: symbol, decimals: decimals);
    final caption = result.isUnplanned
        ? '$spentStr spent · wild patch'
        : hasBudget
            ? '$spentStr of ${_formatMoney(result.budgetAmountBase!, symbol: symbol, decimals: decimals)}'
            : '$spentStr spent';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconAccent.withValues(alpha: 0.14),
              border: Border.all(
                color: iconAccent.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Icon(Icons.spa_rounded, size: 22, color: iconAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        result.plotName,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stateLabel.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: pillText,
                          letterSpacing: 0.6,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                _ShareBar(sharePct: sharePct),
              ],
            ),
          ),
          if (result.coinsEarned > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CropkeepColors.goldWash,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: CropkeepColors.goldPrimary.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/coin.svg',
                    width: 12,
                    height: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${result.coinsEarned}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textGoldDeep,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Coin summary card — itemized payouts with subtle dividers, then a
// gold-washed total pill at the bottom. The pill is what makes this read
// as currency the rest of the app speaks (matching the coin chips on
// market cards and the cropkeep header coin badge).
class _CoinSummaryCard extends StatelessWidget {
  const _CoinSummaryCard({required this.preview});
  final CyclePreview preview;

  @override
  Widget build(BuildContext context) {
    final lines = <(String, int)>[
      if (preview.perPlotCoins > 0) ('Per-plot harvest', preview.perPlotCoins),
      if (preview.unplannedHealthyCoins > 0)
        ('Unplanned bonus', preview.unplannedHealthyCoins),
      if (preview.overallBonusCoins > 0)
        ('Overall harvest', preview.overallBonusCoins),
      if (preview.comboBonusCoins > 0)
        ('Combo bonus', preview.comboBonusCoins),
    ];
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/coin.svg',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Coins from this harvest',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (lines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No coin payouts this cycle.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: CropkeepColors.textSecondary,
                ),
              ),
            )
          else
            for (int i = 0; i < lines.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lines[i].$1,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CropkeepColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '+${lines[i].$2}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textGoldDeep,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < lines.length - 1)
                const Divider(
                  height: 1,
                  color: CropkeepColors.borderDivider,
                ),
            ],
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: CropkeepColors.goldWash,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: CropkeepColors.goldPrimary.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Coins before the split',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textGoldDeep,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/coin.svg',
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${preview.baselineCoins}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textGoldDeep,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Shared primitives — section card, header, calendar tile, share bar.
// Duplicated from plot_breakdown_screen.dart following that file's
// established precedent (helpers stay local to the screen until a third
// caller actually needs them).

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

class _CalendarTile extends StatelessWidget {
  const _CalendarTile({
    required this.day,
    required this.cycleStartWeekday,
  });

  final int day;
  final int cycleStartWeekday;

  static const List<String> _weekdayLabels = [
    'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN',
  ];

  int _weekdayIndex(int d) => ((cycleStartWeekday - 1) + (d - 1)) % 7;

  @override
  Widget build(BuildContext context) {
    final int idx = _weekdayIndex(day);
    final bool isWeekend = idx >= 5;
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

// Minimal back-and-close top bar for steps that don't have a sand hero
// (surplus split + begin next). Back arrow on the left (omitted when no
// previous step exists), close X on the right — conventional multi-step
// wizard layout. The step's content carries its own headline; the bar
// exists for navigation only.
class _StepCloseBar extends StatelessWidget {
  const _StepCloseBar({this.onBack, required this.onClose});

  // Null on the first step (or firstCycle mode) where there's nowhere to
  // go back to. When null the leading slot collapses to keep close X
  // anchored to the right edge.
  final VoidCallback? onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          const SizedBox(width: 4),
          if (onBack != null)
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/back.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  CropkeepColors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
              onPressed: onBack,
            ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: 26,
              color: CropkeepColors.textPrimary,
            ),
            onPressed: onClose,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Step 2 widget — surplus-split tile. Unchanged from the prior version.

// Sand band at the top of the surplus-split step. Same chrome as the
// reconcile and harvest heroes (bgHero, 24px bottom radius, shadowCard).
// The surplus IS the page's headline number — the body below just hosts
// the editor (save/roll tiles + slider).
class _SurplusSplitHero extends StatelessWidget {
  const _SurplusSplitHero({
    required this.surplus,
    required this.decimals,
    required this.baseCode,
    required this.onBack,
  });

  final int surplus;
  final int decimals;
  final String baseCode;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/back.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        CropkeepColors.textSecondaryOnHero,
                        BlendMode.srcIn,
                      ),
                    ),
                    onPressed: onBack,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 26,
                      color: CropkeepColors.textSecondaryOnHero,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/treasure.svg',
                          width: 14,
                          height: 14,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'SURPLUS SPLIT',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: CropkeepColors.textGoldDeep,
                            letterSpacing: 0.8,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Split the surplus',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textPrimary,
                        height: 1.1,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '$baseCode ${_formatMinor(surplus, decimals)}',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: CropkeepColors.textGreenDeep,
                                height: 1,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const TextSpan(
                              text: '  to allocate',
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
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Saving grows the barn and earns coins  ·  '
                      'Rolling over funds next cycle',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CropkeepColors.textSecondaryOnHero,
                        height: 1.4,
                      ),
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

// Sand band at the top of the begin-next step. Date range is the
// headline number; the body below is just a one-paragraph explanation
// and the commit CTA. onBack is nullable — firstCycle mode has no
// previous step, so the leading slot collapses.
class _NextCycleHero extends StatelessWidget {
  const _NextCycleHero({
    this.onBack,
    required this.title,
    required this.startMonth,
    required this.startDay,
    required this.endMonth,
    required this.endDay,
    required this.lengthDays,
  });

  final VoidCallback? onBack;
  final String title;
  final String startMonth;
  final int startDay;
  final String endMonth;
  final int endDay;
  final int lengthDays;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      icon: SvgPicture.asset(
                        'assets/icons/back.svg',
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          CropkeepColors.textSecondaryOnHero,
                          BlendMode.srcIn,
                        ),
                      ),
                      onPressed: onBack,
                    ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 26,
                      color: CropkeepColors.textSecondaryOnHero,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          size: 14,
                          color: CropkeepColors.textGoldDeep,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'NEW CYCLE',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: CropkeepColors.textGoldDeep,
                            letterSpacing: 0.8,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textPrimary,
                        height: 1.1,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '$startMonth $startDay – $endMonth $endDay',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: CropkeepColors.textGreenDeep,
                          height: 1,
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$lengthDays day${lengthDays == 1 ? '' : 's'} of tracking',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CropkeepColors.textSecondaryOnHero,
                        height: 1.3,
                      ),
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

// Planting-plan section card shown on the begin-next step. Lists every
// active non-Unplanned plot with its planned crop + current seed stock,
// so the user sees premium-crop costs and shortages before the cycle
// commits. Tapping any row opens the swap sheet so the user can switch
// the plot to a crop they actually own.
class _PlantingPlanCard extends StatelessWidget {
  const _PlantingPlanCard({
    required this.rows,
    required this.onSwap,
    required this.onApplyFertilizer,
  });

  // Effective per-plot view: original or staged crop, inventory state
  // already resolved. The card just paints; the parent owns the math.
  final List<_EffectivePlanRow> rows;
  // Plot id picked when the user taps a row. Parent looks up the
  // PlotPlanEntry and opens the swap sheet.
  final ValueChanged<int> onSwap;
  // Plot id picked when the user taps the fertilizer pill on a row.
  // Parent opens the apply-fertilizer sheet in staged mode.
  final ValueChanged<int> onApplyFertilizer;

  @override
  Widget build(BuildContext context) {
    final shortageCount = rows.where((r) => r.hasShortage).length;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader('Planting plan'),
              ),
              if (shortageCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: CropkeepColors.goldWash,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: CropkeepColors.goldPrimary.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$shortageCount short',
                    style: const TextStyle(
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
          ),
          const SizedBox(height: 4),
          for (final row in rows)
            _PlotPlanRow(
              row: row,
              onTap: () => onSwap(row.plotId),
              onApplyFertilizer: () => onApplyFertilizer(row.plotId),
            ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: CropkeepColors.borderDivider),
          const SizedBox(height: 10),
          const Text(
            'Each plot uses 1 seed at cycle start. Tap a row to swap '
            'crops, or tap the boost pill to stage a fertilizer for the '
            'next cycle. Shortage rows auto-revert to wheat if not '
            'resolved. Seeds and fertilizer packs aren\'t deducted '
            'until you confirm.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: CropkeepColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// Single row inside the planting-plan card. Plot leaf icon (tinted by
// state — green for ok, gold for shortage), plot name + effective crop
// caption, trailing stock pill. A "Swap" sub-pill flags rows where the
// user has staged a change so they can see at a glance what's pending.
// Whole row is tappable so the user can also pre-swap a plot they have
// plenty of seeds for.
class _PlotPlanRow extends StatelessWidget {
  const _PlotPlanRow({
    required this.row,
    required this.onTap,
    required this.onApplyFertilizer,
  });

  final _EffectivePlanRow row;
  final VoidCallback onTap;
  // Independent tap target for the trailing boost pill. The pill
  // GestureDetector swallows the tap so it doesn't fall through to
  // the row's crop-swap target — two affordances, two destinations,
  // one row.
  final VoidCallback onApplyFertilizer;

  @override
  Widget build(BuildContext context) {
    final shortage = row.hasShortage;
    final Color iconAccent =
        shortage ? CropkeepColors.goldPrimary : CropkeepColors.greenPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: iconAccent.withValues(alpha: 0.14),
                      border: Border.all(
                        color: iconAccent.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      Icons.spa_rounded,
                      size: 18,
                      color: iconAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                row.plotName,
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
                            if (row.hasPendingSwap) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: CropkeepColors.greenHint,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'SWAPPED',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: CropkeepColors.textGreenDeep,
                                    letterSpacing: 0.5,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Planting ${row.cropName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  ),
                  const SizedBox(width: 8),
                  _StockPill(row: row),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: shortage
                        ? CropkeepColors.textGoldDeep
                        : CropkeepColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Indent the boost pill to the crop caption's optical
              // column so the two readings stack as one block of info
              // about the plot, not two unrelated rows.
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: _BoostPill(
                  spec: row.pendingFertilizerSpec,
                  onTap: onApplyFertilizer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Fertilizer affordance hanging off the bottom of each planting-plan
// row. Two visuals:
//  • Empty — dashed sand-border pill with "+ Boost", reads as an
//    optional call-to-action.
//  • Staged — green-tinted pill with the fertilizer icon, name, and a
//    "STAGED" chip mirroring the SWAPPED affordance on the row above.
// GestureDetector with HitTestBehavior.opaque consumes the tap so it
// doesn't fall through to the parent row's crop-swap InkWell.
class _BoostPill extends StatelessWidget {
  const _BoostPill({required this.spec, required this.onTap});

  final MarketItemSpec? spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final staged = spec != null;
    final Widget body;
    if (!staged) {
      body = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: CropkeepColors.borderCard,
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              size: 12,
              color: CropkeepColors.textSecondary,
            ),
            SizedBox(width: 4),
            Text(
              'Boost',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textSecondary,
                letterSpacing: 0.3,
                height: 1,
              ),
            ),
          ],
        ),
      );
    } else {
      body = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: CropkeepColors.greenHint,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: CropkeepColors.greenPrimary.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(spec!.iconAsset, width: 14, height: 14),
            const SizedBox(width: 6),
            Text(
              spec!.name,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textGreenDeep,
                height: 1,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: CropkeepColors.greenPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'STAGED',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textOnGreenBtn,
                  letterSpacing: 0.5,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: body,
    );
  }
}

// Inventory state pill on planting-plan rows. Three flavors:
//  • Starter (wheat/apple/potato) → "Free" in sand wash
//  • Consumable with seed available for this plot → "{N} in satchel"
//    in green wash, where N is the user's owned count of that crop
//  • Consumable in shortage → "Out · Swap" in gold wash (warning)
class _StockPill extends StatelessWidget {
  const _StockPill({required this.row});

  final _EffectivePlanRow row;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color fg;
    final String label;
    if (row.isStarter) {
      bg = CropkeepColors.bgHero;
      border = CropkeepColors.borderCard;
      fg = CropkeepColors.textSecondaryOnHero;
      label = 'Free';
    } else if (row.hasShortage) {
      bg = CropkeepColors.goldWash;
      border = CropkeepColors.goldPrimary.withValues(alpha: 0.5);
      fg = CropkeepColors.textGoldDeep;
      label = 'Out · Swap';
    } else {
      bg = CropkeepColors.greenHint;
      border = CropkeepColors.greenPrimary.withValues(alpha: 0.4);
      fg = CropkeepColors.textGreenDeep;
      label = '${row.seedsOwnedForCrop} in satchel';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.3,
          height: 1,
        ),
      ),
    );
  }
}

// Swap-crop bottom sheet. Stages a crop choice for one planting-plan
// row — does NOT write to the database. Pops with the chosen cropId
// (or null on cancel); the parent stores the choice in
// _pendingCropSwaps and applies the whole batch atomically at commit.
// Inventory checks factor in OTHER plots' pending swaps so the user
// can't allocate more strawberries than they own across the plan.
class _SwapCropSheet extends StatelessWidget {
  const _SwapCropSheet({
    required this.entry,
    required this.plantingPlan,
    required this.pendingSwaps,
  });

  final PlotPlanEntry entry;
  final List<PlotPlanEntry> plantingPlan;
  final Map<int, String> pendingSwaps;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    // Current effective crop for this plot — either a previously-staged
    // swap or the plot's original crop. The "CURRENT" badge in the
    // option list pins to whichever this resolves to.
    final currentEff = pendingSwaps[entry.plotId] ?? entry.cropTypeId;
    return Container(
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Swap crop · ${entry.plotName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pick a crop for next cycle. Seeds aren\'t deducted '
                      'until you confirm the cycle.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CropkeepColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                  height: 1, color: CropkeepColors.borderDivider),
              Flexible(
                child: StreamBuilder<List<CropPickerEntry>>(
                  stream: scope.market.watchCropPicker(),
                  builder: (context, snap) {
                    final entries = snap.data ?? const <CropPickerEntry>[];
                    final catalogById = <String, CropPickerEntry>{
                      for (final e in entries) e.crop.cropId: e,
                    };
                    final visible = entries
                        .where((e) {
                          if (e.crop.cropId == 'unplanned') return false;
                          if (e.crop.isStarter) return true;
                          // Current pick stays visible even if other
                          // pending swaps would otherwise have hidden
                          // it — picking it is the "revert" no-op.
                          if (e.crop.cropId == currentEff) return true;
                          if (!e.crop.isConsumable) return false;
                          final avail = _seedsAvailableForCrop(
                            cropId: e.crop.cropId,
                            swappingPlotId: entry.plotId,
                            plan: plantingPlan,
                            pendingSwaps: pendingSwaps,
                            catalogById: catalogById,
                          );
                          return avail >= 1;
                        })
                        .toList()
                      ..sort((a, b) {
                        // Starters first, then by displayOrder.
                        if (a.crop.isStarter != b.crop.isStarter) {
                          return a.crop.isStarter ? -1 : 1;
                        }
                        return a.crop.displayOrder.compareTo(
                          b.crop.displayOrder,
                        );
                      });
                    if (visible.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No crops available. Visit the Market to buy '
                            'seeds.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CropkeepColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final opt = visible[i];
                        final isCurrent =
                            opt.crop.cropId == currentEff;
                        final remaining = opt.crop.isConsumable
                            ? _seedsAvailableForCrop(
                                cropId: opt.crop.cropId,
                                swappingPlotId: entry.plotId,
                                plan: plantingPlan,
                                pendingSwaps: pendingSwaps,
                                catalogById: catalogById,
                              )
                            : null;
                        return _SwapCropOption(
                          option: opt,
                          isCurrent: isCurrent,
                          remaining: remaining,
                          onTap: () => Navigator.of(context)
                              .pop(opt.crop.cropId),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(
                  height: 1, color: CropkeepColors.borderDivider),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Text(
                  'Need a different seed? Visit the Market to buy more.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: CropkeepColors.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SwapCropOption extends StatelessWidget {
  const _SwapCropOption({
    required this.option,
    required this.isCurrent,
    required this.remaining,
    required this.onTap,
  });

  final CropPickerEntry option;
  final bool isCurrent;
  // Seeds available for THIS swap (owned − other plots' projected
  // demand). Null for starters (unlimited). The pill renders this
  // count so the user knows exactly how many seeds remain to allocate.
  final int? remaining;
  final VoidCallback onTap;

  String get _iconAsset {
    if (option.crop.isStarter) {
      return 'assets/icons/crops/${option.crop.cropId}.svg';
    }
    final dashed = option.crop.cropId.replaceAll('_', '-');
    return 'assets/icons/crops/icons8-$dashed.svg';
  }

  @override
  Widget build(BuildContext context) {
    final stockLabel = option.crop.isStarter
        ? 'Free'
        : '${remaining ?? 0} for swap';
    final Color stockBg = option.crop.isStarter
        ? CropkeepColors.bgHero
        : CropkeepColors.greenHint;
    final Color stockBorder = option.crop.isStarter
        ? CropkeepColors.borderCard
        : CropkeepColors.greenPrimary.withValues(alpha: 0.4);
    final Color stockFg = option.crop.isStarter
        ? CropkeepColors.textSecondaryOnHero
        : CropkeepColors.textGreenDeep;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isCurrent
              ? CropkeepColors.greenPrimary.withValues(alpha: 0.5)
              : CropkeepColors.borderCard,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: SvgPicture.asset(_iconAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            option.crop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: CropkeepColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CropkeepColors.greenHint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'CURRENT',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: CropkeepColors.textGreenDeep,
                                letterSpacing: 0.5,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: stockBg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: stockBorder, width: 1),
                ),
                child: Text(
                  stockLabel,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: stockFg,
                    letterSpacing: 0.3,
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

// Wheat-fallback confirmation. Appears when the user taps Begin tracking
// while one or more plots still have shortages. "Resolve" closes the
// sheet so the user can swap crops; "Plant wheat anyway" proceeds to
// commit, accepting the silent revert for the listed plots.
class _WheatFallbackConfirmSheet extends StatelessWidget {
  const _WheatFallbackConfirmSheet({required this.shortages});

  // Rows from the effective plan that would auto-revert at cycle start.
  // Carries the staged crop (not necessarily the original) so the
  // listing shows the user what they're about to lose to wheat.
  final List<_EffectivePlanRow> shortages;

  @override
  Widget build(BuildContext context) {
    final count = shortages.length;
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
            Text(
              count == 1
                  ? '1 plot will plant wheat'
                  : '$count plots will plant wheat',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'These plots want a crop you\'re out of. At cycle start '
              'they\'ll auto-revert to wheat — the free starter.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CropkeepColors.goldWash,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: CropkeepColors.goldPrimary.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < shortages.length; i++) ...[
                    if (i > 0) const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.spa_rounded,
                          size: 14,
                          color: CropkeepColors.textGoldDeep,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${shortages[i].plotName} · ${shortages[i].cropName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: CropkeepColors.textGoldDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
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
                      child: const Text('Resolve'),
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
                        backgroundColor: CropkeepColors.greenPrimary,
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
                      child: const Text('Plant wheat'),
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

// Surplus-split row. Trailing amount is read-only by default ("Roll
// over"). When a controller is supplied, it becomes an inline TextField
// so the user can type an exact figure ("Save to barn") — slider and
// field both write to the same _savedFraction in the parent state.
class _SplitTile extends StatelessWidget {
  const _SplitTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.amount,
    required this.decimals,
    required this.baseCode,
    required this.subtitle,
    this.controller,
    this.focusNode,
    this.onAmountChanged,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int amount;
  final int decimals;
  final String baseCode;
  final String subtitle;
  // When non-null the trailing slot renders as an editable field.
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onAmountChanged;

  bool get _editable => controller != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
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
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      color: CropkeepColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (_editable)
            _SplitAmountField(
              baseCode: baseCode,
              controller: controller!,
              focusNode: focusNode,
              decimals: decimals,
              accentColor: color,
              onChanged: onAmountChanged ?? (_) {},
            )
          else
            Text(
              '$baseCode ${_formatMinor(amount, decimals)}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

// Inline editable amount used inside the Save tile. White input field
// with the base currency code as a static prefix, right-aligned bold
// numerals so the layout matches the read-only Roll tile beside it.
// Tap → select-all so users can replace the value with one keystroke.
class _SplitAmountField extends StatelessWidget {
  const _SplitAmountField({
    required this.baseCode,
    required this.controller,
    required this.focusNode,
    required this.decimals,
    required this.accentColor,
    required this.onChanged,
  });

  final String baseCode;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int decimals;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
        textAlign: TextAlign.right,
        onChanged: onChanged,
        onTap: () {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
        },
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
        decoration: InputDecoration(
          prefixText: '$baseCode ',
          prefixStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: CropkeepColors.textSecondary,
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: CropkeepColors.borderCard,
              width: 1.2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: CropkeepColors.borderCard,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: accentColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: CropkeepColors.greenPrimary,
          disabledBackgroundColor:
              CropkeepColors.greenPrimary.withValues(alpha: 0.3),
          foregroundColor: CropkeepColors.textOnGreenBtn,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// Helpers.

// Per-plot view of the planting plan with all staged swaps applied and
// inventory allocated first-come-first-served by plot order. The card,
// the swap sheet, and the wheat-fallback guard all read from this so a
// single allocation decision drives the visible state, the available
// swap targets, and the commit-time warning.
class _EffectivePlanRow {
  const _EffectivePlanRow({
    required this.plotId,
    required this.plotName,
    required this.originalCropId,
    required this.cropId,
    required this.cropName,
    required this.isStarter,
    required this.isConsumable,
    required this.seedsOwnedForCrop,
    required this.hasShortage,
    required this.hasPendingSwap,
    required this.pendingFertilizerSpec,
  });

  final int plotId;
  final String plotName;
  // The crop the plot would plant if no swap was staged — used by the
  // sheet to decide whether picking this option means "revert to
  // original" or "stage a new swap".
  final String originalCropId;
  final String cropId;
  final String cropName;
  final bool isStarter;
  final bool isConsumable;
  final int seedsOwnedForCrop;
  // True when the plot would auto-revert to wheat at cycle start
  // because consumable seeds of `cropId` ran out before this plot's
  // turn in the first-come-first-served allocation.
  final bool hasShortage;
  // True when the effective crop differs from the original (i.e., the
  // user has staged a swap for this plot). Drives the "swapped"
  // affordance on the planting-plan row.
  final bool hasPendingSwap;
  // The catalog spec of the fertilizer staged for this plot in the
  // next cycle, or null when nothing is staged. The row uses this to
  // paint the boost pill; the commit reads from _pendingFertilizers
  // directly, so this field is purely a render hint.
  final MarketItemSpec? pendingFertilizerSpec;
}

// Walks the planting plan in order, applies staged swaps, and decides
// per-plot inventory state. Consumable seeds are allocated FIFO by
// plot order — the same order _consumeCycleStartSeeds will iterate at
// cycle close, so the UI's shortage decisions match the eventual
// outcome.
List<_EffectivePlanRow> _computeEffectivePlan(
  List<PlotPlanEntry> plan,
  Map<int, String> pendingSwaps,
  Map<int, String> pendingFertilizers,
  Map<String, CropPickerEntry> catalogById,
) {
  // Index fertilizer specs once so each row's lookup is O(1). Catalog
  // is static so the map is cheap to rebuild on every render.
  final fertilizerSpecById = <String, MarketItemSpec>{
    for (final s in MarketCatalog.fertilizers) s.itemId: s,
  };
  final consumed = <String, int>{};
  final result = <_EffectivePlanRow>[];
  for (final entry in plan) {
    final swapped = pendingSwaps[entry.plotId];
    final effCropId = swapped ?? entry.cropTypeId;
    final cat = catalogById[effCropId];
    final isStarter = cat?.crop.isStarter ?? false;
    final isConsumable = cat?.crop.isConsumable ?? false;
    final cropName = cat?.crop.name ?? effCropId;
    final owned = cat?.stock ?? 0;
    bool hasShortage = false;
    if (isConsumable) {
      final alreadyUsed = consumed[effCropId] ?? 0;
      if (alreadyUsed >= owned) {
        hasShortage = true;
      } else {
        consumed[effCropId] = alreadyUsed + 1;
      }
    }
    final pendingFertId = pendingFertilizers[entry.plotId];
    result.add(_EffectivePlanRow(
      plotId: entry.plotId,
      plotName: entry.plotName,
      originalCropId: entry.cropTypeId,
      cropId: effCropId,
      cropName: cropName,
      isStarter: isStarter,
      isConsumable: isConsumable,
      seedsOwnedForCrop: owned,
      hasShortage: hasShortage,
      hasPendingSwap: swapped != null,
      pendingFertilizerSpec:
          pendingFertId == null ? null : fertilizerSpecById[pendingFertId],
    ));
  }
  return result;
}

// Seeds of `cropId` available to plot `swappingPlotId`. The swapping
// plot's own current demand is intentionally excluded — picking the
// same crop you already have should not be blocked by a shortage you
// yourself caused, and switching crops frees up your old seed for
// others. Returns a large positive sentinel for starters since they
// don't draw from inventory.
int _seedsAvailableForCrop({
  required String cropId,
  required int swappingPlotId,
  required List<PlotPlanEntry> plan,
  required Map<int, String> pendingSwaps,
  required Map<String, CropPickerEntry> catalogById,
}) {
  final cat = catalogById[cropId];
  if (cat == null) return 0;
  if (cat.crop.isStarter) return 1 << 30;
  if (!cat.crop.isConsumable) return 1 << 30;
  final owned = cat.stock ?? 0;
  int otherDemand = 0;
  for (final entry in plan) {
    if (entry.plotId == swappingPlotId) continue;
    final effCropId = pendingSwaps[entry.plotId] ?? entry.cropTypeId;
    if (effCropId != cropId) continue;
    final effCat = catalogById[effCropId];
    if (effCat == null || !effCat.crop.isConsumable) continue;
    otherDemand++;
  }
  return owned - otherDemand;
}

Stream<CurrencyRow?> _watchBaseCurrency(AppDatabase db, String? code) {
  if (code == null) return Stream<CurrencyRow?>.value(null);
  return (db.select(db.currencies)..where((t) => t.code.equals(code)))
      .watchSingleOrNull();
}

// 33.4% → "33", 3.4% → "3.4", 0.0% → "0". Matches plot_breakdown's
// formatter so the share captions read identically across screens.
String _formatSharePct(double pct) {
  if (pct >= 10) return pct.toStringAsFixed(0);
  if (pct <= 0) return '0';
  return pct.toStringAsFixed(1);
}

// Minor-units (cents) → "$1,234.56". Mirror of the formatter used in
// plot_breakdown_screen.dart; kept local to avoid forming a cross-screen
// utility module until at least one more caller needs it.
String _formatMoney(int minorUnits, {required String symbol, int decimals = 2}) {
  final int absUnits = minorUnits.abs();
  int divisor = 1;
  for (int i = 0; i < decimals; i++) {
    divisor *= 10;
  }
  final int whole = absUnits ~/ divisor;
  final String wholeStr = _withCommas(whole);
  final String sign = minorUnits < 0 ? '-' : '';
  if (decimals == 0) return '$sign$symbol$wholeStr';
  final String frac = (absUnits % divisor).toString().padLeft(decimals, '0');
  return '$sign$symbol$wholeStr.$frac';
}

// Used by _SplitTile (step 2) which still prefixes the ISO code rather
// than the symbol; the split sheet stays unchanged in this redesign.
String _formatMinor(int minor, int decimals) {
  final int abs = minor.abs();
  int divisor = 1;
  for (int i = 0; i < decimals; i++) {
    divisor *= 10;
  }
  final int whole = abs ~/ divisor;
  final String wholeStr = _withCommas(whole);
  final String sign = minor < 0 ? '-' : '';
  if (decimals == 0) return '$sign$wholeStr';
  final frac = (abs % divisor).toString().padLeft(decimals, '0');
  return '$sign$wholeStr.$frac';
}

// Variant of _formatMinor without thousands separators — for the inline
// Save amount TextField on step 2. Commas would have to be stripped on
// parse anyway, and keyboard-driven editing reads cleaner without them.
String _formatMinorPlain(int minor, int decimals) {
  final int abs = minor.abs();
  int divisor = 1;
  for (int i = 0; i < decimals; i++) {
    divisor *= 10;
  }
  final int whole = abs ~/ divisor;
  final String sign = minor < 0 ? '-' : '';
  if (decimals == 0) return '$sign$whole';
  final frac = (abs % divisor).toString().padLeft(decimals, '0');
  return '$sign$whole.$frac';
}

// Parses user input ("1234.56" or "1,234.56" or "") into minor units.
// Returns null on unparseable input (lets the caller leave state alone
// instead of clobbering it with a 0). Empty string parses as 0 so users
// can clear the field cleanly.
int? _parseMinorInput(String input, int decimals) {
  final cleaned = input.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return 0;
  final value = double.tryParse(cleaned);
  if (value == null || value < 0) return null;
  int multiplier = 1;
  for (int i = 0; i < decimals; i++) {
    multiplier *= 10;
  }
  return (value * multiplier).round();
}

String _withCommas(int v) {
  final s = v.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _monthName(int month) {
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
