import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/tables/owned_items.dart';
import '../../theme/colors.dart';
import '../../widgets/market/crop_market_card.dart';
import 'market_catalog.dart';

// Confirmation sheet shown when the user taps Buy on a consumable
// crop card. Mirrors `LogTransactionSheet`'s envelope so the modal
// chrome is consistent.
class PurchaseConfirmSheet extends StatefulWidget {
  const PurchaseConfirmSheet({
    super.key,
    required this.spec,
    required this.balanceBefore,
    required this.currentStock,
  });

  final MarketCropSpec spec;
  final int balanceBefore;
  final int currentStock;

  @override
  State<PurchaseConfirmSheet> createState() => _PurchaseConfirmSheetState();
}

class _PurchaseConfirmSheetState extends State<PurchaseConfirmSheet> {
  bool _submitting = false;

  Future<void> _confirm() async {
    final MarketRepository market = AppScope.of(context).market;
    final tier = MarketCatalog.tierSpecs[widget.spec.tier]!;
    setState(() => _submitting = true);
    try {
      await market.purchase(
        itemId: widget.spec.cropId,
        itemType: OwnedItemType.crop,
        priceCoins: tier.priceCoins,
        quantityDelta: tier.seedPackSize,
        description: 'Bought ${widget.spec.name} seed pack',
        inventoryCap: tier.packMax,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.spec.name} seed pack added',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } on InsufficientCoinsException {
      if (!mounted) return;
      _showSnack('Not enough coins.');
      setState(() => _submitting = false);
    } on PackCapException {
      if (!mounted) return;
      _showSnack('Stock is already at the pack max.');
      setState(() => _submitting = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final spec = widget.spec;
    final tier = MarketCatalog.tierSpecs[spec.tier]!;
    final setSpec = MarketCatalog.setById(spec.setId);
    final int balanceAfter = widget.balanceBefore - tier.priceCoins;
    final int newStock = widget.currentStock + tier.seedPackSize;
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
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: CropkeepColors.borderCard,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Confirm purchase',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: CropkeepColors.textSecondary,
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CropMarketCard(
                name: spec.name,
                iconAsset: spec.iconAsset,
                setName: setSpec.name,
                setBonusCoins: setSpec.bonusCoins,
                stock: widget.currentStock,
                packMax: tier.packMax,
                priceCoins: tier.priceCoins,
                canAfford: true,
                coinShort: 0,
                previewOnly: true,
                previewNewStock: newStock,
              ),
              const SizedBox(height: 14),
              _BalancePreview(
                before: widget.balanceBefore,
                after: balanceAfter,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
                  _BuyButton(
                    submitting: _submitting,
                    onTap: _confirm,
                    priceCoins: tier.priceCoins,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalancePreview extends StatelessWidget {
  const _BalancePreview({required this.before, required this.after});

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
            '$before → $after',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
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
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: submitting
              ? CropkeepColors.greenPrimary.withValues(alpha: 0.6)
              : CropkeepColors.greenPrimary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: submitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    CropkeepColors.textOnGreenBtn,
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Buy for ',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textOnGreenBtn,
                    ),
                  ),
                  SvgPicture.asset('assets/icons/coin.svg',
                      width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$priceCoins',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
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
