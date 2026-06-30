import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';

// Read-only "tap to expand" view of a ledger row. The collapsed row
// shows just amount + name + meta; this sheet surfaces the data that
// doesn't fit there — most importantly the exchange rate that produced
// the stored base amount, plus the full note and edit timestamp.
//
// Edit and Remove are reached through a ⋮ overflow in the top-right of
// this sheet, opening a Cropkeep-styled action sheet. This mirrors the
// plot-breakdown pattern (see `_PlotOverflowMenu` /
// `_PlotActionSheet`) so the user reads "do something to this thing"
// the same way across the app. The captions on each action row carry
// the discouragement / consequence message — "saved edits stay in
// history," "moves to Recently removed for 30 days" — so the user gets
// the rule up front without the affordance being spatially hidden.
//
// Long-press is intentionally NOT wired on the underlying row anymore.
// A swipe-and-mash gesture is a poor entry point for a destructive
// action; routing through tap → ⋮ → Remove forces a moment of
// deliberate intent.
class LedgerEntryDetailSheet extends StatelessWidget {
  const LedgerEntryDetailSheet({
    super.key,
    required this.isExpense,
    required this.isEmergency,
    required this.sourceName,
    required this.baseAmountMinor,
    required this.baseCode,
    required this.baseSymbol,
    required this.baseDecimals,
    required this.originalAmountMinor,
    required this.originalCurrencyCode,
    required this.originalDecimals,
    required this.exchangeRate,
    required this.whenLogged,
    required this.note,
    required this.editedAt,
    required this.isLocked,
    this.onEdit,
    this.onRemove,
  });

  final bool isExpense;
  final bool isEmergency;
  final String? sourceName;
  final int baseAmountMinor;
  final String baseCode;
  final String baseSymbol;
  final int baseDecimals;
  final int originalAmountMinor;
  // Null when the entry was logged in the base currency.
  final String? originalCurrencyCode;
  final int originalDecimals;
  final double exchangeRate;
  final DateTime whenLogged;
  final String? note;
  final DateTime? editedAt;
  final bool isLocked;
  // Action callbacks routed through the ⋮ overflow. When both are null
  // (e.g., locked entries) the overflow itself is hidden — the sheet
  // stays honest about what can actually be done.
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  bool get _isForeign => originalCurrencyCode != null;
  bool get _hasActions => onEdit != null || onRemove != null;

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
            // Top zone — handle centered for drag-to-dismiss affordance,
            // ⋮ aligned to the right when any action is available. The
            // zone is sized to fit IconButton's full hit target (≈40)
            // so the hover/splash circle isn't clipped, and Clip.none
            // is set as a safety net against any future overflow.
            SizedBox(
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: CropkeepColors.borderDivider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (_hasActions)
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'More',
                        onPressed: () => _openActions(context),
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 22,
                          color: CropkeepColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            _Hero(
              isExpense: isExpense,
              isEmergency: isEmergency,
              isLocked: isLocked,
              baseAmount: _formatMoney(
                baseAmountMinor,
                baseSymbol,
                baseDecimals,
              ),
            ),
            const SizedBox(height: 18),
            _DetailCard(
              children: [
                _DetailRow(
                  label: isExpense ? 'Plot' : 'Well',
                  value: sourceName ?? '—',
                ),
                if (_isForeign) ...[
                  _DetailRow(
                    label: 'Original amount',
                    value:
                        '$originalCurrencyCode '
                        '${_formatAmountOnly(originalAmountMinor, originalDecimals)}',
                  ),
                  _DetailRow(
                    label: 'Rate used',
                    value:
                        '1 $baseCode = '
                        '${_formatPerBase(_safePerBase(exchangeRate))} '
                        '$originalCurrencyCode',
                  ),
                ],
                _DetailRow(
                  label: 'Logged',
                  value: _formatWhen(whenLogged),
                ),
                if (editedAt != null)
                  _DetailRow(
                    label: 'Edited',
                    value: _formatWhen(editedAt!),
                  ),
                if (note != null && note!.trim().isNotEmpty)
                  _DetailRow(
                    label: 'Note',
                    value: note!.trim(),
                    isLast: true,
                  )
                else
                  const _DetailRowSpacer(),
              ],
            ),
            const SizedBox(height: 16),
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
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openActions(BuildContext context) async {
    final action = await showModalBottomSheet<_LedgerEntryAction>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LedgerEntryActionSheet(
        isExpense: isExpense,
        canEdit: onEdit != null,
        canRemove: onRemove != null,
      ),
    );
    if (action == null || !context.mounted) return;
    // Pop the detail sheet before dispatching so the next surface (the
    // edit sheet or the soft-delete snackbar) lands on a clean stack.
    Navigator.of(context).pop();
    switch (action) {
      case _LedgerEntryAction.edit:
        onEdit?.call();
      case _LedgerEntryAction.remove:
        onRemove?.call();
    }
  }
}

enum _LedgerEntryAction { edit, remove }

// Cropkeep-styled action sheet mirroring `_PlotActionSheet`. Same
// rounded-card grammar, same icon-tinted-square + label + caption
// pattern. Captions carry the consequence so the user reads the rule
// before they reach for the row.
class _LedgerEntryActionSheet extends StatelessWidget {
  const _LedgerEntryActionSheet({
    required this.isExpense,
    required this.canEdit,
    required this.canRemove,
  });

  final bool isExpense;
  final bool canEdit;
  final bool canRemove;

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
            if (canEdit) ...[
              _ActionRow(
                icon: Icons.edit_outlined,
                label: 'Edit values',
                caption: 'Change amount, date, or note. Saved edits stay '
                    'in history.',
                destructive: false,
                onTap: () =>
                    Navigator.of(context).pop(_LedgerEntryAction.edit),
              ),
              if (canRemove) const SizedBox(height: 10),
            ],
            if (canRemove)
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                label: isExpense
                    ? 'Remove this transaction'
                    : 'Remove this income entry',
                caption: 'Moves to Recently removed for 30 days. Restore '
                    'from the ⋮ on the Ledger header.',
                destructive: true,
                onTap: () =>
                    Navigator.of(context).pop(_LedgerEntryAction.remove),
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

// White card row — same grammar as `_ActionRow` on the plot breakdown
// screen. Naked leading icon (no tinted-square chiclet) keeps the row
// light enough to scale to 3+ actions without becoming a wall of
// colored badges. Destructive variant tints both icon and label red —
// the color carries the signal, the chrome stays calm. A trailing
// chevron marks navigable rows ("tap leads to another surface") and is
// omitted on destructive rows so they read as terminal intent rather
// than "go somewhere."
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.caption,
    required this.destructive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final bool destructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = destructive
        ? CropkeepColors.textRedDeep
        : CropkeepColors.textPrimary;
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
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 22),
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
                        color: accent,
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
              if (!destructive) ...[
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

class _Hero extends StatelessWidget {
  const _Hero({
    required this.isExpense,
    required this.isEmergency,
    required this.isLocked,
    required this.baseAmount,
  });

  final bool isExpense;
  final bool isEmergency;
  final bool isLocked;
  final String baseAmount;

  @override
  Widget build(BuildContext context) {
    final color = isExpense
        ? CropkeepColors.textPrimary
        : CropkeepColors.textGreenDeep;
    final label = isLocked
        ? 'System-generated income'
        : isEmergency
            ? 'Emergency expense'
            : (isExpense ? 'Expense' : 'Income');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: CropkeepColors.textNavInactive,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${isExpense ? '−' : '+'}$baseAmount',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CropkeepColors.borderCard, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: CropkeepColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            thickness: 1,
            color: CropkeepColors.borderDivider,
          ),
      ],
    );
  }
}

// Trailing zero-height placeholder so the last divider drawn by the
// previous row doesn't visually clip the card's rounded corner. Cheaper
// than threading `isLast` flags through every conditional row above.
class _DetailRowSpacer extends StatelessWidget {
  const _DetailRowSpacer();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

double _safePerBase(double rateToBase) {
  if (rateToBase <= 0) return 0;
  return 1.0 / rateToBase;
}

String _formatPerBase(double perBase) {
  if (perBase >= 100) return perBase.toStringAsFixed(2);
  if (perBase >= 1) return perBase.toStringAsFixed(3);
  return perBase.toStringAsFixed(5);
}

String _formatMoney(int minor, String symbol, int decimals) {
  final int divisor = _pow10(decimals);
  final int whole = (minor.abs()) ~/ divisor;
  final String wholeStr = _withThousands(whole.toString());
  if (decimals == 0) return '$symbol$wholeStr';
  final String frac =
      (minor.abs() % divisor).toString().padLeft(decimals, '0');
  return '$symbol$wholeStr.$frac';
}

String _formatAmountOnly(int minor, int decimals) {
  final int divisor = _pow10(decimals);
  final int whole = minor.abs() ~/ divisor;
  final String wholeStr = _withThousands(whole.toString());
  if (decimals == 0) return wholeStr;
  final String frac = (minor.abs() % divisor).toString().padLeft(decimals, '0');
  return '$wholeStr.$frac';
}

int _pow10(int n) {
  int r = 1;
  for (int i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

String _withThousands(String digits) {
  if (digits.length <= 3) return digits;
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}

String _formatWhen(DateTime when) {
  final today = DateTime.now();
  final isSameDay = when.year == today.year &&
      when.month == today.month &&
      when.day == today.day;
  final time = '${_pad(when.hour)}:${_pad(when.minute)}';
  if (isSameDay) return 'Today · $time';
  final yesterday = today.subtract(const Duration(days: 1));
  final isYesterday = when.year == yesterday.year &&
      when.month == yesterday.month &&
      when.day == yesterday.day;
  if (isYesterday) return 'Yesterday · $time';
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
