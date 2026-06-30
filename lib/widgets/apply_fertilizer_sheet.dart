import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../data/database.dart';
import '../data/repositories/fertilizer_repository.dart';
import '../screens/market/market_catalog.dart';
import '../theme/colors.dart';
import 'cropkeep_toast.dart';

// Bottom sheet used to pick and apply a fertilizer to one plot.
//
// Two modes, same chrome:
//  • LIVE  — invoked from the plot breakdown ⋮ menu mid-cycle. Reads
//    the current application from the DB, writes through on tap. Fires
//    toasts. Pops with `true` when anything changed.
//  • STAGED — invoked from the cycle-reset Step 3 planting plan. Does
//    not touch the DB. Pops with an `ApplyFertilizerStaging` value so
//    the caller can hold the choice in memory until the cycle commits.
//
// Both modes pre-filter to `quantity > 0`; staged mode further excludes
// packs already committed to OTHER plots in the same staging session
// so the user can't allocate more packs than they own across the plan.
//
// One-fertilizer-per-plot-per-cycle is enforced at the DB layer; the
// sheet surfaces the existing pick (if any) at the top with a Remove
// affordance and a no-refund confirm.

class ApplyFertilizerStaging {
  const ApplyFertilizerStaging.apply(String this.itemId) : cleared = false;
  const ApplyFertilizerStaging.clear()
      : itemId = null,
        cleared = true;

  final String? itemId;
  final bool cleared;
}

// Live-mode helper. Returns `true` when an apply/remove/swap occurred.
Future<bool> showApplyFertilizerSheetLive(
  BuildContext context, {
  required int plotId,
  required int cycleId,
  required String plotName,
  required int cycleDay,
  required int cycleLength,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ApplyFertilizerSheet.live(
      plotId: plotId,
      cycleId: cycleId,
      plotName: plotName,
      cycleDay: cycleDay,
      cycleLength: cycleLength,
    ),
  );
  return result ?? false;
}

// Staged-mode helper. Returns `null` on cancel; an `ApplyFertilizerStaging`
// otherwise (apply with `itemId` or clear).
Future<ApplyFertilizerStaging?> showApplyFertilizerSheetStaged(
  BuildContext context, {
  required String plotName,
  required String? currentlyStagedItemId,
  required Map<String, int> committedElsewhere,
}) {
  return showModalBottomSheet<ApplyFertilizerStaging>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ApplyFertilizerSheet.staged(
      plotName: plotName,
      currentlyStagedItemId: currentlyStagedItemId,
      committedElsewhere: committedElsewhere,
    ),
  );
}

enum _Mode { live, staged }

class _ApplyFertilizerSheet extends StatelessWidget {
  const _ApplyFertilizerSheet.live({
    required int this.plotId,
    required int this.cycleId,
    required this.plotName,
    required int this.cycleDay,
    required int this.cycleLength,
  })  : mode = _Mode.live,
        currentlyStagedItemId = null,
        committedElsewhere = const <String, int>{};

  const _ApplyFertilizerSheet.staged({
    required this.plotName,
    required this.currentlyStagedItemId,
    required this.committedElsewhere,
  })  : mode = _Mode.staged,
        plotId = null,
        cycleId = null,
        cycleDay = null,
        cycleLength = null;

  final _Mode mode;
  final String plotName;
  // LIVE-only context — null in staged mode.
  final int? plotId;
  final int? cycleId;
  final int? cycleDay;
  final int? cycleLength;
  // STAGED-only context — null/empty in live mode.
  final String? currentlyStagedItemId;
  final Map<String, int> committedElsewhere;

  @override
  Widget build(BuildContext context) {
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
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                child: _Header(
                  plotName: plotName,
                  subtitle: _subtitle(),
                ),
              ),
              const Divider(height: 1, color: CropkeepColors.borderDivider),
              Flexible(
                child: _Body(
                  mode: mode,
                  plotId: plotId,
                  cycleId: cycleId,
                  plotName: plotName,
                  currentlyStagedItemId: currentlyStagedItemId,
                  committedElsewhere: committedElsewhere,
                ),
              ),
              const Divider(height: 1, color: CropkeepColors.borderDivider),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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

  String _subtitle() {
    switch (mode) {
      case _Mode.live:
        return 'Day $cycleDay of $cycleLength · one pack per plot, per cycle.';
      case _Mode.staged:
        return 'Stages with the next cycle — packs aren\'t consumed until '
            'you tap Begin tracking.';
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.plotName, required this.subtitle});

  final String plotName;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Apply fertilizer · $plotName',
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
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CropkeepColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// Body — composes the live-mode StreamBuilder over the current
// application + the owned-items stream, or the staged-mode static
// current-pick + owned-items stream.
class _Body extends StatelessWidget {
  const _Body({
    required this.mode,
    required this.plotId,
    required this.cycleId,
    required this.plotName,
    required this.currentlyStagedItemId,
    required this.committedElsewhere,
  });

  final _Mode mode;
  final int? plotId;
  final int? cycleId;
  final String plotName;
  final String? currentlyStagedItemId;
  final Map<String, int> committedElsewhere;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final ownedStream = scope.market.watchOwned();
    if (mode == _Mode.live) {
      return StreamBuilder<PlotFertilizerApplicationRow?>(
        stream: scope.fertilizers
            .watchByPlotAndCycle(cycleId: cycleId!, plotId: plotId!),
        builder: (context, appliedSnap) {
          return StreamBuilder<List<OwnedItemRow>>(
            stream: ownedStream,
            builder: (context, ownedSnap) {
              return _renderBody(
                context: context,
                owned: ownedSnap.data ?? const <OwnedItemRow>[],
                currentItemId: appliedSnap.data?.fertilizerItemId,
              );
            },
          );
        },
      );
    }
    return StreamBuilder<List<OwnedItemRow>>(
      stream: ownedStream,
      builder: (context, ownedSnap) {
        return _renderBody(
          context: context,
          owned: ownedSnap.data ?? const <OwnedItemRow>[],
          currentItemId: currentlyStagedItemId,
        );
      },
    );
  }

  Widget _renderBody({
    required BuildContext context,
    required List<OwnedItemRow> owned,
    required String? currentItemId,
  }) {
    // Index owned quantities by item id, for both filter and detail.
    final ownedByItem = <String, int>{
      for (final o in owned) o.itemId: o.quantity,
    };
    // Spec lookup for the current pick (always shown even if quantity
    // is zero — the pack is already burned).
    MarketItemSpec? currentSpec;
    if (currentItemId != null) {
      for (final s in MarketCatalog.fertilizers) {
        if (s.itemId == currentItemId) {
          currentSpec = s;
          break;
        }
      }
    }
    // Available list: every catalog fertilizer the user owns ≥1 of,
    // minus the current pick (it's shown in the band above), minus
    // staging commitments elsewhere.
    final available = <_AvailableEntry>[];
    for (final spec in MarketCatalog.fertilizers) {
      if (spec.itemId == currentItemId) continue;
      final qty = ownedByItem[spec.itemId] ?? 0;
      final committed = committedElsewhere[spec.itemId] ?? 0;
      final usable = qty - committed;
      if (usable < 1) continue;
      available.add(_AvailableEntry(spec: spec, usable: usable));
    }
    available.sort((a, b) => a.spec.priceCoins.compareTo(b.spec.priceCoins));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      shrinkWrap: true,
      children: [
        if (currentSpec != null) ...[
          _CurrentlyAppliedBand(
            spec: currentSpec,
            mode: mode,
            onRemove: () => _remove(context),
          ),
          const SizedBox(height: 14),
        ],
        _RuleEyebrow(
          label: currentSpec == null ? 'From your shed' : 'Swap for',
        ),
        const SizedBox(height: 8),
        if (available.isEmpty)
          _EmptyShedCard(
            isSwap: currentSpec != null,
          )
        else
          for (int i = 0; i < available.length; i++) ...[
            _FertilizerCard(
              entry: available[i],
              onTap: () => _pick(context, available[i].spec),
            ),
            if (i != available.length - 1) const SizedBox(height: 8),
          ],
      ],
    );
  }

  Future<void> _pick(BuildContext context, MarketItemSpec spec) async {
    // Swap warning: if a different fertilizer is already applied/staged,
    // confirm the no-refund forfeit before going through.
    final currentItemId = await _currentPickItemId(context);
    if (currentItemId != null && currentItemId != spec.itemId) {
      if (!context.mounted) return;
      final proceed = await _showForfeitConfirm(context);
      if (proceed != true) return;
    }

    if (!context.mounted) return;
    switch (mode) {
      case _Mode.live:
        await _applyLive(context, spec);
      case _Mode.staged:
        Navigator.of(context).pop(ApplyFertilizerStaging.apply(spec.itemId));
    }
  }

  // Re-read the current pick at decision time so a fast tap on top of a
  // stale stream snapshot can't sneak past the forfeit confirm. Cheap —
  // it's a single-row select.
  Future<String?> _currentPickItemId(BuildContext context) async {
    if (mode == _Mode.staged) return currentlyStagedItemId;
    final scope = AppScope.of(context);
    final row = await scope.fertilizers
        .watchByPlotAndCycle(cycleId: cycleId!, plotId: plotId!)
        .first;
    return row?.fertilizerItemId;
  }

  Future<void> _applyLive(BuildContext context, MarketItemSpec spec) async {
    final scope = AppScope.of(context);
    try {
      await scope.fertilizers.applyToPlot(
        cycleId: cycleId!,
        plotId: plotId!,
        fertilizerItemId: spec.itemId,
      );
    } on OutOfFertilizerStockException {
      if (!context.mounted) return;
      CropkeepToast.error(
        context,
        title: 'Out of ${spec.name} packs',
        flavor: 'Your shed is empty.',
      );
      return;
    } catch (e) {
      if (!context.mounted) return;
      CropkeepToast.error(
        context,
        title: 'Could not apply ${spec.name}',
        flavor: '$e',
      );
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).pop(true);
    CropkeepToast.success(
      context,
      title: '${spec.name} applied to $plotName',
      flavor: _flavorFor(spec.itemId),
      iconAsset: spec.iconAsset,
    );
  }

  Future<void> _remove(BuildContext context) async {
    final proceed = await _showRemoveConfirm(context);
    if (proceed != true) return;
    if (!context.mounted) return;
    switch (mode) {
      case _Mode.live:
        final scope = AppScope.of(context);
        try {
          await scope.fertilizers.removeFromPlot(
            cycleId: cycleId!,
            plotId: plotId!,
          );
        } catch (e) {
          if (!context.mounted) return;
          CropkeepToast.error(
            context,
            title: 'Could not remove fertilizer',
            flavor: '$e',
          );
          return;
        }
        if (!context.mounted) return;
        Navigator.of(context).pop(true);
        CropkeepToast.info(
          context,
          title: 'Pack forfeited',
          flavor: 'Shed slot freed — no refund.',
        );
      case _Mode.staged:
        Navigator.of(context).pop(const ApplyFertilizerStaging.clear());
    }
  }
}

// Per-spec flavor text on the success toast. Keeps the tone in the
// graphics.md voice without bloating MarketItemSpec with a UI field.
String _flavorFor(String itemId) {
  switch (itemId) {
    case 'fertilizer_mix':
      return 'Roots reach a little deeper.';
    case 'compost_heap':
      return 'Rich and earthy.';
    case 'liquid_boost':
      return 'Drank it right up.';
    case 'pumpkin_bloom':
      return 'The vines are humming.';
    case 'storm_umbrella':
      return 'Set against the weather.';
    case 'buzzing_beehive':
      return 'Pollinators on patrol.';
    case 'faerie_reviver':
      return 'A second wind on standby.';
    case 'mystic_potion':
      return 'High risk, high yield.';
    default:
      return 'In the soil.';
  }
}

class _AvailableEntry {
  const _AvailableEntry({required this.spec, required this.usable});
  final MarketItemSpec spec;
  // Owned − committed-elsewhere. Always ≥1 by construction.
  final int usable;
}

// Eyebrow rule mirroring log_transaction_sheet's `_RuleEyebrow` — short
// label flanked by hair-thin dividers so the section break reads as
// "this list" rather than "this card."
class _RuleEyebrow extends StatelessWidget {
  const _RuleEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Divider(
              height: 1, color: CropkeepColors.borderDivider, thickness: 1),
        ),
        const SizedBox(width: 10),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: CropkeepColors.textSecondary,
            letterSpacing: 0.8,
            height: 1,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(
              height: 1, color: CropkeepColors.borderDivider, thickness: 1),
        ),
      ],
    );
  }
}

// White card showing the current pick. The label "Currently boosting" in
// live mode vs "Currently staged" in staged mode is the only mode signal
// — chrome stays identical so the same surface reads as the same kind
// of thing regardless of which surface invoked it.
class _CurrentlyAppliedBand extends StatelessWidget {
  const _CurrentlyAppliedBand({
    required this.spec,
    required this.mode,
    required this.onRemove,
  });

  final MarketItemSpec spec;
  final _Mode mode;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final label = mode == _Mode.live ? 'Currently boosting' : 'Currently staged';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: CropkeepColors.greenPrimary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _IconTile(asset: spec.iconAsset),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CropkeepColors.greenHint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textGreenDeep,
                      letterSpacing: 0.5,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  spec.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
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
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              foregroundColor: CropkeepColors.textRedDeep,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// Available fertilizer card. Tap-anywhere target. Mystic Potion gets a
// gold pill border + risk sublabel; Buzzing Beehive gets a stress-proof
// sublabel so its state-guarantee component reads loud next to the %.
class _FertilizerCard extends StatelessWidget {
  const _FertilizerCard({required this.entry, required this.onTap});

  final _AvailableEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spec = entry.spec;
    final bool isPotion = spec.itemId == 'mystic_potion';
    final bool isBeehive = spec.itemId == 'buzzing_beehive';
    final String? sublabel = isPotion
        ? 'High risk · pays 0 if anything goes wrong'
        : isBeehive
            ? 'Keeps the plot stress-proof'
            : null;
    final Color borderColor = isPotion
        ? CropkeepColors.borderGoldPill
        : CropkeepColors.borderCard;
    final double borderWidth = isPotion ? 1.5 : 1;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: borderWidth),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _IconTile(asset: spec.iconAsset),
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
                        fontSize: 14,
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
                    if (sublabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        sublabel,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isPotion
                              ? CropkeepColors.textGoldDeep
                              : CropkeepColors.textGreenDeep,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _QtyPill(qty: entry.usable),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: CropkeepColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.asset});
  final String asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: CropkeepColors.greenHint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: CropkeepColors.greenPrimary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(asset, width: 30, height: 30),
    );
  }
}

class _QtyPill extends StatelessWidget {
  const _QtyPill({required this.qty});
  final int qty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CropkeepColors.greenPrimary, width: 1),
      ),
      child: Text(
        '×$qty',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textGreenDeep,
          height: 1,
        ),
      ),
    );
  }
}

class _EmptyShedCard extends StatelessWidget {
  const _EmptyShedCard({required this.isSwap});
  final bool isSwap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: CropkeepColors.bgGoldWash,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: CropkeepColors.borderGoldPill.withValues(alpha: 0.5),
            width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.water_drop_outlined,
            size: 22,
            color: CropkeepColors.textGoldDeep,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSwap
                      ? 'No other fertilizers in your shed'
                      : 'Your shed is empty',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Visit the Market → Fertilizers to stock up.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CropkeepColors.textGoldDeep,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Confirm before swapping a fertilizer mid-cycle (live) or restaging
// over a previous pick (staged). Same shape as the remove confirm so
// they read as one family of "small forfeits" sheets.
Future<bool?> _showForfeitConfirm(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ConfirmSheet(
      title: 'Swap fertilizer?',
      body: 'The previous pack is forfeited — no refund. The new pack '
          'consumes from your shed when you confirm.',
      confirmLabel: 'Swap',
    ),
  );
}

Future<bool?> _showRemoveConfirm(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ConfirmSheet(
      title: 'Remove fertilizer?',
      body: 'The pack is forfeited — no refund. The plot reverts to its '
          'unboosted yield for this cycle.',
      confirmLabel: 'Remove',
    ),
  );
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.body,
    required this.confirmLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;

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
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
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
                      child: Text(confirmLabel),
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
