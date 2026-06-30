import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../screens/market/market_catalog.dart';
import '../../theme/colors.dart';

// Crop card under a tier section.
//
// The card is honest about how little it has to say: identity (icon +
// name), state (your current stock), cost (price), action (Buy / Need).
// Earlier passes tried to fill a four-element vertical stack which left
// either a hollow middle or asymmetric spacing once set info was
// pulled out. This pass gives the right column two parallel lanes
// instead:
//   • Top lane  — Name           …  Stock chip
//   • Bottom    — Price          …  Buy CTA / "Need N more"
// Each lane pairs "what" on the left with "how much / do it" on the
// right, and the two rows mirror each other so the eye reads the card
// as two parallel beats rather than a thin scroll of disconnected
// fields. No divider is needed — the row rhythm carries the
// separation, and the icon tile sits vertically centered as the visual
// anchor.
//
// The icon tile is tinted by tier (warm sand / green / cool blue) with
// a faint tier-colored border, so each card visually echoes its
// section header even when the header has scrolled off the top.
class CropMarketCard extends StatelessWidget {
  const CropMarketCard({
    super.key,
    required this.name,
    required this.iconAsset,
    required this.tier,
    required this.stock,
    required this.priceCoins,
    required this.packSize,
    required this.canAfford,
    required this.coinShort,
    this.onBuy,
  });

  final String name;
  final String iconAsset;
  final CropTier tier;
  final int stock;
  final int priceCoins;
  // Seeds per purchase. Renders on the Buy CTA ("Buy ×5") so the card
  // is self-contained without leaning on the tier header to disambiguate.
  final int packSize;
  final bool canAfford;
  final int coinShort;
  final VoidCallback? onBuy;

  Color get _iconTint {
    switch (tier) {
      case CropTier.common:
        return CropkeepColors.bgHero;
      case CropTier.uncommon:
        return CropkeepColors.greenHint;
      case CropTier.rare:
        return CropkeepColors.bgPageAlt;
    }
  }

  Color get _iconBorder {
    switch (tier) {
      case CropTier.common:
        return CropkeepColors.tierCommon;
      case CropTier.uncommon:
        return CropkeepColors.greenPrimary;
      case CropTier.rare:
        return CropkeepColors.bluePremium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CropkeepColors.borderCard, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _IconTile(
            iconAsset: iconAsset,
            tint: _iconTint,
            borderColor: _iconBorder,
            faded: !canAfford,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Identity lane.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: CropkeepColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StockChip(stock: stock),
                  ],
                ),
                const SizedBox(height: 10),
                // Commerce lane.
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _PriceLabel(priceCoins: priceCoins),
                    const Spacer(),
                    _BuyTerminal(
                      canAfford: canAfford,
                      coinShort: coinShort,
                      packSize: packSize,
                      onTap: onBuy,
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

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.iconAsset,
    required this.tint,
    required this.borderColor,
    required this.faded,
  });

  final String iconAsset;
  final Color tint;
  final Color borderColor;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.55 : 1.0,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(iconAsset, width: 46, height: 46),
      ),
    );
  }
}

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
  const _PriceLabel({required this.priceCoins});

  final int priceCoins;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/icons/coin.svg', width: 17, height: 17),
        const SizedBox(width: 5),
        Text(
          '$priceCoins',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: CropkeepColors.textGoldDeep,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _BuyTerminal extends StatelessWidget {
  const _BuyTerminal({
    required this.canAfford,
    required this.coinShort,
    required this.packSize,
    required this.onTap,
  });

  final bool canAfford;
  final int coinShort;
  final int packSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (canAfford) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: CropkeepColors.greenPrimary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Buy ×$packSize',
            style: const TextStyle(
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
    // Plain text — no rectangular bg, so it doesn't read as a button.
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
}
