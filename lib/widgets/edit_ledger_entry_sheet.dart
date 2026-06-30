import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/database.dart';
import '../theme/colors.dart';
import 'cropkeep_toast.dart';

// Focused edit form for a single ledger entry. The form deliberately
// scopes itself to the three fields a typo-fix needs (amount, date,
// note) and shows currency + source as read-only context. Changing
// currency would require re-rating against the cycle's rate sheet and
// is treated as "wrong entry, delete + re-log" instead. Changing the
// source plot/well has cycle-reconciliation cascades and is out of
// scope here too.
//
// Amount edits are scaled proportionally against the originally stored
// base and (for expenses) plot amounts, which preserves the rate that
// was correct at log time. This matches the philosophy "edits fix
// typos, they don't re-do the math."
class EditLedgerEntrySheet extends StatefulWidget {
  const EditLedgerEntrySheet({
    super.key,
    required this.entryId,
    required this.isExpense,
  });

  final int entryId;
  final bool isExpense;

  @override
  State<EditLedgerEntrySheet> createState() => _EditLedgerEntrySheetState();
}

class _EditLedgerEntrySheetState extends State<EditLedgerEntrySheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();

  Future<_EditSheetData>? _bootstrap;
  _EditSheetData? _data;

  DateTime? _date;
  bool _submitting = false;
  bool _attemptedSubmit = false;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onChange);
    _noteController.addListener(_onChange);
  }

  @override
  void dispose() {
    _amountController.removeListener(_onChange);
    _noteController.removeListener(_onChange);
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<_EditSheetData> _load() {
    final db = AppScope.of(context).database;
    return _loadEditSheetData(
      db: db,
      entryId: widget.entryId,
      isExpense: widget.isExpense,
    );
  }

  void _hydrate(_EditSheetData data) {
    if (_initialised) return;
    _initialised = true;
    _data = data;
    _date = data.whenLogged;
    _amountController.text = _formatAmountForInput(
      data.originalAmountMinor,
      data.originalDecimals,
    );
    _noteController.text = data.note ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _amountFocus.requestFocus();
    });
  }

  Future<void> _pickDate() async {
    final data = _data;
    if (data == null) return;
    final today = _todayStart();
    final cycleEnd = _dayStart(data.cycleEnd);
    final upperBound = cycleEnd.isBefore(today) ? cycleEnd : today;
    final initial = (_date ?? data.whenLogged).isAfter(upperBound)
        ? upperBound
        : (_date ?? data.whenLogged);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _dayStart(data.cycleStart),
      lastDate: upperBound,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;
    setState(() {
      _date = DateTime(picked.year, picked.month, picked.day);
    });
  }

  int? _parsedAmountMinor() {
    final data = _data;
    if (data == null) return null;
    return _parseAmountToMinor(
      _amountController.text.trim(),
      data.originalDecimals,
    );
  }

  bool _isValid() {
    final amount = _parsedAmountMinor();
    if (amount == null || amount <= 0) return false;
    return true;
  }

  bool _hasChanges() {
    final data = _data;
    if (data == null) return false;
    final amountMinor = _parsedAmountMinor();
    if (amountMinor != null && amountMinor != data.originalAmountMinor) {
      return true;
    }
    final note = _noteController.text.trim();
    final originalNote = (data.note ?? '').trim();
    if (note != originalNote) return true;
    if (_date != null && !_sameDay(_date!, data.whenLogged)) return true;
    return false;
  }

  Future<void> _submit() async {
    setState(() => _attemptedSubmit = true);
    final data = _data;
    if (data == null) return;
    if (!_isValid()) return;
    if (!_hasChanges()) {
      Navigator.of(context).maybePop();
      return;
    }

    final amountMinor = _parsedAmountMinor()!;
    // Preserve the original effective rate by scaling proportionally
    // against the stored base/plot amounts. Avoids needing live rate
    // lookups and keeps cycle-close math internally consistent.
    final scaledBase = _scaleProportionally(
      newAmountMinor: amountMinor,
      oldAmountMinor: data.originalAmountMinor,
      oldDerivedMinor: data.baseAmountMinor,
    );
    final scaledPlot = data.plotAmountMinor == null
        ? null
        : _scaleProportionally(
            newAmountMinor: amountMinor,
            oldAmountMinor: data.originalAmountMinor,
            oldDerivedMinor: data.plotAmountMinor!,
          );
    // Compose the new timestamp on the picked date, keeping the
    // original wall-clock time so same-day sort order is preserved
    // when only the note or amount was tweaked.
    final originalWhen = data.whenLogged;
    final newDate = _date ?? originalWhen;
    final stamp = _sameDay(newDate, originalWhen)
        ? originalWhen
        : DateTime(
            newDate.year,
            newDate.month,
            newDate.day,
            originalWhen.hour,
            originalWhen.minute,
            originalWhen.second,
          );
    final rawNote = _noteController.text.trim();
    final note = rawNote.isEmpty ? '' : rawNote;

    setState(() => _submitting = true);
    final scope = AppScope.of(context);
    try {
      if (widget.isExpense) {
        await scope.transactions.editExpense(
          id: widget.entryId,
          amountMinor: amountMinor,
          baseAmountMinor: scaledBase,
          plotAmountMinor: scaledPlot,
          note: note,
          spentAt: stamp,
        );
      } else {
        await scope.incomeEntries.editIncome(
          id: widget.entryId,
          amountMinor: amountMinor,
          baseAmountMinor: scaledBase,
          note: note,
          receivedAt: stamp,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      CropkeepToast.success(
        context,
        title: 'Entry updated',
        duration: const Duration(seconds: 2),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _bootstrap ??= _load();
    final media = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: FutureBuilder<_EditSheetData>(
        future: _bootstrap,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const _LoadingPlaceholder();
          }
          if (snap.hasError || snap.data == null) {
            return const _LoadFailedPlaceholder();
          }
          _hydrate(snap.data!);
          return _buildForm(snap.data!);
        },
      ),
    );
  }

  Widget _buildForm(_EditSheetData data) {
    final amountError = _attemptedSubmit && !_isValid();
    final canSubmit = _isValid() && _hasChanges() && !_submitting;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetHandle(),
            _Header(
              isExpense: widget.isExpense,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Advisory(),
                    const SizedBox(height: 16),
                    _ContextStrip(
                      isExpense: widget.isExpense,
                      isEmergency: data.isEmergency,
                      sourceName: data.sourceName,
                      currencyCode: data.originalCurrencyCode,
                    ),
                    const SizedBox(height: 22),
                    _AmountHero(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      symbol: data.originalSymbol,
                      decimals: data.originalDecimals,
                      hasError: amountError,
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: _DateChip(
                        date: _date ?? data.whenLogged,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel('note'),
                    const SizedBox(height: 10),
                    _NoteField(controller: _noteController),
                    if (data.editedAt != null) ...[
                      const SizedBox(height: 18),
                      _PreviouslyEditedNote(editedAt: data.editedAt!),
                    ],
                  ],
                ),
              ),
            ),
            _Footer(
              canSubmit: canSubmit,
              submitting: _submitting,
              onCancel: () => Navigator.of(context).maybePop(),
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Data loader.

class _EditSheetData {
  const _EditSheetData({
    required this.originalAmountMinor,
    required this.originalCurrencyCode,
    required this.originalSymbol,
    required this.originalDecimals,
    required this.baseAmountMinor,
    required this.plotAmountMinor,
    required this.whenLogged,
    required this.note,
    required this.editedAt,
    required this.sourceName,
    required this.isEmergency,
    required this.cycleStart,
    required this.cycleEnd,
  });

  final int originalAmountMinor;
  final String originalCurrencyCode;
  final String originalSymbol;
  final int originalDecimals;
  final int baseAmountMinor;
  // Null for income (no plot). Present for expense regardless of plot
  // currency — log time always populates it.
  final int? plotAmountMinor;
  final DateTime whenLogged;
  final String? note;
  final DateTime? editedAt;
  final String? sourceName;
  final bool isEmergency;
  final DateTime cycleStart;
  final DateTime cycleEnd;
}

Future<_EditSheetData> _loadEditSheetData({
  required AppDatabase db,
  required int entryId,
  required bool isExpense,
}) async {
  if (isExpense) {
    final row = await (db.select(db.transactions)
          ..where((t) => t.id.equals(entryId)))
        .getSingle();
    final currency = await (db.select(db.currencies)
          ..where((c) => c.code.equals(row.currencyCode)))
        .getSingle();
    final cycle = await (db.select(db.cycles)
          ..where((c) => c.id.equals(row.cycleId)))
        .getSingle();
    final plot = await (db.select(db.plots)
          ..where((p) => p.id.equals(row.plotId)))
        .getSingleOrNull();
    return _EditSheetData(
      originalAmountMinor: row.amount,
      originalCurrencyCode: row.currencyCode,
      originalSymbol: currency.symbol,
      originalDecimals: currency.decimalPlaces,
      baseAmountMinor: row.baseAmount,
      plotAmountMinor: row.plotAmount,
      whenLogged: DateTime.fromMillisecondsSinceEpoch(row.spentAt),
      note: row.note,
      editedAt: row.editedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row.editedAt!),
      sourceName: plot?.name,
      isEmergency: row.isEmergency,
      cycleStart: DateTime.fromMillisecondsSinceEpoch(cycle.startDate),
      cycleEnd: DateTime.fromMillisecondsSinceEpoch(cycle.endDate),
    );
  }
  final row = await (db.select(db.incomeEntries)
        ..where((t) => t.id.equals(entryId)))
      .getSingle();
  final currency = await (db.select(db.currencies)
        ..where((c) => c.code.equals(row.currencyCode)))
      .getSingle();
  final cycle = await (db.select(db.cycles)
        ..where((c) => c.id.equals(row.cycleId)))
      .getSingle();
  final well = await (db.select(db.wells)
        ..where((w) => w.id.equals(row.wellId)))
      .getSingleOrNull();
  return _EditSheetData(
    originalAmountMinor: row.amount,
    originalCurrencyCode: row.currencyCode,
    originalSymbol: currency.symbol,
    originalDecimals: currency.decimalPlaces,
    baseAmountMinor: row.baseAmount,
    plotAmountMinor: null,
    whenLogged: DateTime.fromMillisecondsSinceEpoch(row.receivedAt),
    note: row.note,
    editedAt: row.editedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.editedAt!),
    sourceName: well?.name,
    isEmergency: false,
    cycleStart: DateTime.fromMillisecondsSinceEpoch(cycle.startDate),
    cycleEnd: DateTime.fromMillisecondsSinceEpoch(cycle.endDate),
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Leaf widgets.

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

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

class _Header extends StatelessWidget {
  const _Header({required this.isExpense, required this.onClose});

  final bool isExpense;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: SizedBox(
        height: 44,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                isExpense ? 'Edit expense' : 'Edit income',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                ),
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

// Advisory banner — sets the expectation that this is a traceable
// rewrite, not a silent one. Tone is informational, not warning: we
// don't want to scare users away from a legitimate typo fix.
class _Advisory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CropkeepColors.bgGoldWash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CropkeepColors.borderGoldPill.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: CropkeepColors.textGoldDeep,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Edit only if the original entry was wrong. Saving marks '
              'this as edited and keeps a history breadcrumb.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textGoldDeep,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Read-only context — type · source · currency. Communicates what's
// locked: you can't switch plots or currency from here; if those are
// wrong, the right move is to remove and re-log.
class _ContextStrip extends StatelessWidget {
  const _ContextStrip({
    required this.isExpense,
    required this.isEmergency,
    required this.sourceName,
    required this.currencyCode,
  });

  final bool isExpense;
  final bool isEmergency;
  final String? sourceName;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final typeLabel = isEmergency
        ? 'Emergency expense'
        : (isExpense ? 'Expense' : 'Income');
    final source = sourceName ?? '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            typeLabel.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textNavInactive,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${isExpense ? 'Plot' : 'Well'}: $source',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CropkeepColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: CropkeepColors.bgPageAlt,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currencyCode,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textNavInactive,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountHero extends StatelessWidget {
  const _AmountHero({
    required this.controller,
    required this.focusNode,
    required this.symbol,
    required this.decimals,
    required this.hasError,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String symbol;
  final int decimals;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final hint = decimals == 0 ? '0' : '0.00';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => focusNode.requestFocus(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                symbol,
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
                      decimal: decimals > 0,
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
            Container(width: 80, height: 1.5, color: CropkeepColors.redAlert),
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
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CropkeepColors.borderCard, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: CropkeepColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              _formatDateChip(date),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textPrimary,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: CropkeepColors.borderDivider,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textSecondary,
              letterSpacing: 0.6,
              height: 1,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: CropkeepColors.borderDivider,
          ),
        ),
      ],
    );
  }
}

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
          hintText: 'Add a note',
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

class _PreviouslyEditedNote extends StatelessWidget {
  const _PreviouslyEditedNote({required this.editedAt});

  final DateTime editedAt;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.history_rounded,
          size: 13,
          color: CropkeepColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Text(
          'Last edited ${_formatWhen(editedAt)}',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: CropkeepColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.canSubmit,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

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
                : const Text(
                    'Save changes',
                    style: TextStyle(
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

class _LoadFailedPlaceholder extends StatelessWidget {
  const _LoadFailedPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 28,
              color: CropkeepColors.textSecondary,
            ),
            const SizedBox(height: 8),
            const Text(
              "Couldn't load this entry.",
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Close'),
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

DateTime _dayStart(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

int? _parseAmountToMinor(String raw, int decimalPlaces) {
  final value = double.tryParse(raw);
  if (value == null || value < 0) return null;
  final num scale = math.pow(10, decimalPlaces);
  return (value * scale).round();
}

// Pre-fill the amount input with the stored minor value as a decimal
// the user can edit. Mirrors how the log sheet hints its empty state.
String _formatAmountForInput(int minor, int decimals) {
  if (decimals == 0) return minor.toString();
  final scale = math.pow(10, decimals).toInt();
  final whole = minor ~/ scale;
  final frac = (minor % scale).toString().padLeft(decimals, '0');
  return '$whole.$frac';
}

// Scale a derived minor amount (base or plot) by the ratio of new to
// old original-currency amount. Guards against a zero divisor — the
// only way the original is zero is if the row was already broken,
// which we leave alone rather than fabricate a value.
int _scaleProportionally({
  required int newAmountMinor,
  required int oldAmountMinor,
  required int oldDerivedMinor,
}) {
  if (oldAmountMinor == 0) return oldDerivedMinor;
  return (oldDerivedMinor * newAmountMinor / oldAmountMinor).round();
}

String _formatDateChip(DateTime date) {
  final today = _todayStart();
  final delta = today.difference(_dayStart(date)).inDays;
  if (delta == 0) return 'Today';
  if (delta == 1) return 'Yesterday';
  return '${_monthShort(date.month)} ${date.day}';
}

String _formatWhen(DateTime when) {
  final today = DateTime.now();
  final isSameDay = when.year == today.year &&
      when.month == today.month &&
      when.day == today.day;
  final time = '${_pad(when.hour)}:${_pad(when.minute)}';
  if (isSameDay) return 'today · $time';
  final yesterday = today.subtract(const Duration(days: 1));
  final isYesterday = when.year == yesterday.year &&
      when.month == yesterday.month &&
      when.day == yesterday.day;
  if (isYesterday) return 'yesterday · $time';
  return '${_monthShort(when.month)} ${when.day}, ${when.year} · $time';
}

String _pad(int v) => v.toString().padLeft(2, '0');

String _monthShort(int m) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[math.max(0, math.min(11, m - 1))];
}
