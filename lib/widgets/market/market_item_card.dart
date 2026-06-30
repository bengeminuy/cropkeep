import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/colors.dart';

// Generic row card used by Fertilizers, Decorations, and Avatars.
// Differs from CropMarketCard in two ways:
//   • Effect text replaces tier / stock economics
//   • Three terminal states: Buy (affordable, not owned), "Need N more"
//     plain text, Owned chip (one-time items)
//
// Consumables (fertilizers) always surface a stock chip in the top-right
// of the name row — neutral-grey when zero, green when held — so the
// player can see "I have none of these" at a glance instead of having
// to remember. Matches the chip idiom on CropMarketCard.
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
    this.onBuy,
    this.previewOnly = false,
  });

  final String name;
  final String iconAsset;
  final String description;
  final int priceCoins;
  final bool canAfford;
  final int coinShort;
  final MarketItemKind kind;
  // For consumables: current stock count (rendered as a stock badge).
  // For one-time items: 0 if not owned, ≥1 if owned.
  final int stockOrOwned;
  final VoidCallback? onBuy;
  // Used by the one-time-item PurchaseConfirmSheet: drop the Buy/Need
  // terminal so the card reads as a preview of what you're about to
  // own, not another action surface inside the modal.
  final bool previewOnly;

  bool get _isOwned =>
      kind == MarketItemKind.oneTime && stockOrOwned > 0;
  bool get _isConsumable => kind == MarketItemKind.consumable;

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: CropkeepColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (_isConsumable) ...[
                      const SizedBox(width: 8),
                      _StockChip(stock: stockOrOwned),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textPrimary,
                    height: 1.35,
                  ),
                ),
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
                    if (!previewOnly)
                      _Terminal(
                        kind: kind,
                        isOwned: _isOwned,
                        canAfford: canAfford,
                        coinShort: coinShort,
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

// Mirror of CropMarketCard._StockChip so consumable cards across the
// Market read as the same idiom. Neutral grey at zero, green at ≥1.
class _StockChip extends StatelessWidget {
  const _StockChip({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final bool empty = stock == 0;
    final Color bg = empty
        ? CropkeepColors.borderDivider
        : CropkeepColors.greenHint;
    final Color fg = empty
        ? CropkeepColors.textSecondary
        : CropkeepColors.textGreenDeep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(
            '$stock',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: fg,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

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

class _Terminal extends StatelessWidget {
  const _Terminal({
    required this.kind,
    required this.isOwned,
    required this.canAfford,
    required this.coinShort,
    required this.onBuy,
  });

  final MarketItemKind kind;
  final bool isOwned;
  final bool canAfford;
  final int coinShort;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
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

    if (!canAfford) {
      // Plain text — no rectangular bg, doesn't read as a button.
      return Text(
        'Need $coinShort more',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: CropkeepColors.textSecondary,
          height: 1,
        ),
      );
    }

    return GestureDetector(
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
    );
  }
}
