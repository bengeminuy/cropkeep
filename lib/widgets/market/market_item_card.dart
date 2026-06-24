import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/colors.dart';

// Generic row card used by Fertilizers, Decorations, and Avatars.
// Differs from CropMarketCard in three ways:
//   • Effect text replaces tier / stock economics
//   • Optional payback line (Decorations only)
//   • Three terminal states: Buy (affordable, not owned), "Need N more",
//     Owned (one-time items) / Stock N (consumables).
class MarketItemCard extends StatelessWidget {
  const MarketItemCard({
    super.key,
    required this.name,
    required this.iconAsset,
    required this.description,
    required this.priceCoins,
    required this.canAfford,
    required this.coinShort,
    required this.kind,
    required this.stockOrOwned,
    this.payback,
    this.onBuy,
  });

  final String name;
  final String iconAsset;
  final String description;
  final int priceCoins;
  final bool canAfford;
  final int coinShort;
  final MarketItemKind kind;
  // For consumables: current stock count (rendered as "Stock N").
  // For one-time items: 0 if not owned, ≥1 if owned.
  final int stockOrOwned;
  final String? payback;
  final VoidCallback? onBuy;

  bool get _isOwned =>
      kind == MarketItemKind.oneTime && stockOrOwned > 0;

  @override
  Widget build(BuildContext context) {
    final bool muted = !canAfford && !_isOwned;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CropkeepColors.borderCard, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Opacity(
            opacity: muted ? 0.6 : 1.0,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: CropkeepColors.greenHint,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(iconAsset, width: 44, height: 44),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                if (payback != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Payback · ${payback!}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: CropkeepColors.textGoldDeep,
                      height: 1.2,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: CropkeepColors.borderDivider,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PriceLabel(priceCoins: priceCoins, free: priceCoins == 0),
                    const Spacer(),
                    _StateChip(
                      kind: kind,
                      isOwned: _isOwned,
                      canAfford: canAfford,
                      coinShort: coinShort,
                      stock: stockOrOwned,
                      onBuy: onBuy,
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

enum MarketItemKind { consumable, oneTime }

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({required this.priceCoins, required this.free});

  final int priceCoins;
  final bool free;

  @override
  Widget build(BuildContext context) {
    if (free) {
      return const Text(
        'Free',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textSecondary,
          height: 1,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/icons/coin.svg', width: 16, height: 16),
        const SizedBox(width: 5),
        Text(
          '$priceCoins',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: CropkeepColors.textGoldDeep,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.kind,
    required this.isOwned,
    required this.canAfford,
    required this.coinShort,
    required this.stock,
    required this.onBuy,
  });

  final MarketItemKind kind;
  final bool isOwned;
  final bool canAfford;
  final int coinShort;
  final int stock;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    // One-time items that are already owned
    if (kind == MarketItemKind.oneTime && isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: CropkeepColors.greenLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: CropkeepColors.greenPrimary, width: 1.2),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              size: 14,
              color: CropkeepColors.textGreenDeep,
            ),
            SizedBox(width: 4),
            Text(
              'Owned',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textGreenDeep,
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    // Consumables — show the stock count alongside the Buy CTA
    final Widget stockChip = kind == MarketItemKind.consumable
        ? Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              'stock $stock',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textGreenDeep,
                height: 1,
              ),
            ),
          )
        : const SizedBox.shrink();

    if (!canAfford) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          stockChip,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CropkeepColors.bgHero,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Need $coinShort',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textSecondaryOnHero,
                height: 1,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        stockChip,
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBuy,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: CropkeepColors.greenPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Buy',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textOnGreenBtn,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
