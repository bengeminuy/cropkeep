import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/tables/owned_items.dart';
import '../../theme/colors.dart';
import '../../widgets/cropkeep_toast.dart';
import '../../widgets/market/market_item_card.dart';
import 'market_catalog.dart';

// Confirmation sheet shown when the user taps Buy on a one-time item
// (decoration or avatar). These purchases are irreversible — there's
// no sell-back — so the confirm friction is worth it. Cheap repeatable
// purchases (fertilizers, crop seed packs) stay tap-to-buy; only the
// "I can't undo this" buys get the modal.
class PurchaseConfirmSheet extends StatefulWidget {
  const PurchaseConfirmSheet({
    super.key,
    required this.spec,
    required this.balanceBefore,
  });

  final MarketItemSpec spec;
  final int balanceBefore;

  @override
  State<PurchaseConfirmSheet> createState() => _PurchaseConfirmSheetState();
}

class _PurchaseConfirmSheetState extends State<PurchaseConfirmSheet> {
  bool _submitting = false;

  Future<void> _confirm() async {
    final MarketRepository market = AppScope.of(context).market;
    setState(() => _submitting = true);
    try {
      await market.purchase(
        itemId: widget.spec.itemId,
        itemType: widget.spec.itemType,
        priceCoins: widget.spec.priceCoins,
        quantityDelta: 1,
        description: 'Bought ${widget.spec.name}',
        oneTime: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      CropkeepToast.success(
        context,
        iconAsset: widget.spec.iconAsset,
        title: widget.spec.name,
        flavor: _successFlavor(widget.spec.itemType),
      );
    } on InsufficientCoinsException catch (e) {
      if (!mounted) return;
      CropkeepToast.error(
        context,
        icon: Icons.savings_outlined,
        title: 'Need more coins',
        flavor: '${e.need - e.have} short for this purchase',
      );
      setState(() => _submitting = false);
    } on AlreadyOwnedException {
      // Race: the catalog button gated on "not owned" but the row was
      // bought from another surface between paint and tap. Bail out
      // cleanly so the player isn't stuck staring at a stale modal.
      if (!mounted) return;
      Navigator.of(context).pop(false);
      CropkeepToast.error(
        context,
        icon: Icons.check_circle_outline_rounded,
        title: 'Already yours',
        flavor: '${widget.spec.name} is already on the farm',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final spec = widget.spec;
    final int balanceAfter = widget.balanceBefore - spec.priceCoins;
    return Container(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 8,
            bottom: 16 + media.viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: CropkeepColors.borderCard,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 2),
                child: Text(
                  'Confirm purchase',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                    height: 1,
                  ),
                ),
              ),
              MarketItemCard(
                name: spec.name,
                iconAsset: spec.iconAsset,
                description: spec.description,
                priceCoins: spec.priceCoins,
                canAfford: true,
                coinShort: 0,
                kind: MarketItemKind.oneTime,
                stockOrOwned: 0,
                previewOnly: true,
              ),
              const SizedBox(height: 12),
              const _OneTimeHint(),
              const SizedBox(height: 12),
              _BalanceLine(
                before: widget.balanceBefore,
                after: balanceAfter,
              ),
              const SizedBox(height: 18),
              _BuyButton(
                submitting: _submitting,
                onTap: _confirm,
                priceCoins: spec.priceCoins,
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CropkeepColors.textSecondary,
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

String _successFlavor(OwnedItemType type) {
  switch (type) {
    case OwnedItemType.decoration:
      return 'Placed on the farm';
    case OwnedItemType.avatar:
      return 'Stitched up — try it on from the Farmer tab';
    case _:
      return 'Added to your satchel';
  }
}

class _OneTimeHint extends StatelessWidget {
  const _OneTimeHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CropkeepColors.bgPageAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: CropkeepColors.textSecondary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "One-time purchase. No resale — it's yours for good.",
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine({required this.before, required this.after});

  final int before;
  final int after;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CropkeepColors.bgGoldWash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CropkeepColors.borderGoldPill, width: 1),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/icons/coin.svg', width: 18, height: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Balance after',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textGoldDeep,
              ),
            ),
          ),
          Text(
            '$before',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CropkeepColors.textGoldDeep,
              height: 1,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: CropkeepColors.textGoldDeep,
            ),
          ),
          Text(
            '$after',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textGoldDeep,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.submitting,
    required this.onTap,
    required this.priceCoins,
  });

  final bool submitting;
  final VoidCallback onTap;
  final int priceCoins;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: submitting ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: submitting
              ? CropkeepColors.greenPrimary.withValues(alpha: 0.6)
              : CropkeepColors.greenPrimary,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    CropkeepColors.textOnGreenBtn,
                  ),
                ),
              )
            : priceCoins == 0
                ? const Text(
                    'Equip for free',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textOnGreenBtn,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Buy for ',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: CropkeepColors.textOnGreenBtn,
                        ),
                      ),
                      SvgPicture.asset('assets/icons/coin.svg',
                          width: 17, height: 17),
                      const SizedBox(width: 4),
                      Text(
                        '$priceCoins',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: CropkeepColors.textOnGreenBtn,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
