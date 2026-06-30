import 'package:flutter/material.dart';

import '../../theme/colors.dart';

// One shared hint banner used by Fertilizers / Decorations / Skins to
// surface a short page-level note (stacking rule, equip reminder, etc).
// Previously each page rolled its own private widget with drifting
// colors and padding — this collapses them into a single neutral idiom
// so the three pages feel like the same product.
class MarketHintBanner extends StatelessWidget {
  const MarketHintBanner({
    super.key,
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CropkeepColors.bgHero,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: CropkeepColors.textSecondaryOnHero),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textSecondaryOnHero,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
