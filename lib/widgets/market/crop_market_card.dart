import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/colors.dart';

// Crop card under a tier section. Tier-level economics (price/yield/
// break-even) live in the tier header, so the card body is small:
// name, set membership (info, NOT progress), stock vs. pack max,
// price + Buy CTA. When `canAfford == false` the icon fades to 60%
// and the right pill turns sand with "Need N more".
class CropMarketCard extends StatelessWidget {
  const CropMarketCard({
    super.key,
    required this.name,
    required this.iconAsset,
    required this.setName,
    required this.setBonusCoins,
    required this.stock,
    required this.packMax,
    required this.priceCoins,
    required this.canAfford,
    required this.coinShort,
    this.onBuy,
    this.previewOnly = false,
    this.previewNewStock,
  });

  final String name;
  final String iconAsset;
  // Set membership is info, not progress. Set completion happens on
  // the Farm/Harvest screens.
  final String setName;
  final int setBonusCoins;
  final int stock;
  final int packMax;
  final int priceCoins;
  final bool canAfford;
  final int coinShort;
  final VoidCallback? onBuy;
  // Drop the CTA + bottom divider when shown inside the confirm sheet.
  final bool previewOnly;
  // When previewOnly is true, show "stock N → N+5" instead of just N.
  final int? previewNewStock;

  @override
  Widget build(BuildContext context) {
    final String stockLabel = previewOnly && previewNewStock != null
        ? 'stock $stock → $previewNewStock / $packMax'
        : 'stock $stock / $packMax';
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
            opacity: canAfford ? 1.0 : 0.6,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: CropkeepColors.greenHint,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(iconAsset, width: 52, height: 52),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$setName · ${setBonusCoins}c set bonus',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stockLabel,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CropkeepColors.textGreenDeep,
                    height: 1.2,
                  ),
                ),
                if (previewOnly) ...[
                  const SizedBox(height: 8),
                  _PriceLabel(priceCoins: priceCoins),
                ] else ...[
                  const SizedBox(height: 10),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: CropkeepColors.borderDivider,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _PriceLabel(priceCoins: priceCoins),
                      const Spacer(),
                      _BuyPill(
                        canAfford: canAfford,
                        coinShort: coinShort,
                        onTap: onBuy,
                        atCap: stock >= packMax,
                      ),
                    ],
                  ),
                ],
              ],
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

class _BuyPill extends StatelessWidget {
  const _BuyPill({
    required this.canAfford,
    required this.coinShort,
    required this.onTap,
    required this.atCap,
  });

  final bool canAfford;
  final int coinShort;
  final VoidCallback? onTap;
  final bool atCap;

  @override
  Widget build(BuildContext context) {
    if (atCap) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: CropkeepColors.bgPlot,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'At pack max',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: CropkeepColors.textSecondaryOnHero,
            height: 1,
          ),
        ),
      );
    }
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: CropkeepColors.bgHero,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Need $coinShort more',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: CropkeepColors.textSecondaryOnHero,
          height: 1,
        ),
      ),
    );
  }
}
