import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/colors.dart';

// Compact tile for a single plot-color swatch. Square tile, swatch
// disc on top, name + price (or Owned chip) below. Smaller than the
// fertilizer/decoration cards because the swatch is the whole story.
class PlotColorTile extends StatelessWidget {
  const PlotColorTile({
    super.key,
    required this.name,
    required this.swatchColor,
    required this.priceCoins,
    required this.canAfford,
    required this.coinShort,
    required this.isOwned,
    this.description,
    this.onBuy,
  });

  final String name;
  final Color swatchColor;
  final int priceCoins;
  final bool canAfford;
  final int coinShort;
  final bool isOwned;
  final String? description;
  final VoidCallback? onBuy;

  bool get _isFree => priceCoins == 0;

  @override
  Widget build(BuildContext context) {
    final bool muted = !canAfford && !isOwned && !_isFree;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: (canAfford && !isOwned && !_isFree) ? onBuy : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CropkeepColors.borderCard, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Opacity(
                opacity: muted ? 0.6 : 1.0,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: swatchColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CropkeepColors.borderCard,
                      width: 1.2,
                    ),
                  ),
                  child: isOwned
                      ? const Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1.1,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 2),
              Text(
                description!,
                maxLines: 2,
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
            const SizedBox(height: 8),
            _Footer(
              priceCoins: priceCoins,
              isFree: _isFree,
              isOwned: isOwned,
              canAfford: canAfford,
              coinShort: coinShort,
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.priceCoins,
    required this.isFree,
    required this.isOwned,
    required this.canAfford,
    required this.coinShort,
  });

  final int priceCoins;
  final bool isFree;
  final bool isOwned;
  final bool canAfford;
  final int coinShort;

  @override
  Widget build(BuildContext context) {
    if (isOwned || isFree) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 13,
            color: CropkeepColors.textGreenDeep,
          ),
          const SizedBox(width: 4),
          Text(
            isFree && !isOwned ? 'Free' : 'Owned',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textGreenDeep,
              height: 1,
            ),
          ),
        ],
      );
    }
    if (!canAfford) {
      return Text(
        'Need $coinShort more',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: CropkeepColors.textSecondaryOnHero,
          height: 1,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('assets/icons/coin.svg', width: 13, height: 13),
        const SizedBox(width: 4),
        Text(
          '$priceCoins',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: CropkeepColors.textGoldDeep,
            height: 1,
          ),
        ),
      ],
    );
  }
}
