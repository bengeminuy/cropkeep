import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/colors.dart';

// Coin balance card + "Affordable only" toggle. Sits between the
// category chips and the page body. The header pill is the global
// wallet; this is Market-local reinforcement so the user can keep
// their eyes on the cards.
class MarketResourceStrip extends StatelessWidget {
  const MarketResourceStrip({
    super.key,
    required this.coinBalance,
    required this.affordableOnly,
    required this.onAffordableToggled,
  });

  final int coinBalance;
  final bool affordableOnly;
  final ValueChanged<bool> onAffordableToggled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CropkeepColors.borderCard, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'COIN BALANCE',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: CropkeepColors.textSecondary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SvgPicture.asset(
                      'assets/icons/coin.svg',
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatCoins(coinBalance),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textGold,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _AffordableToggle(
            value: affordableOnly,
            onChanged: onAffordableToggled,
          ),
        ],
      ),
    );
  }
}

class _AffordableToggle extends StatelessWidget {
  const _AffordableToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? CropkeepColors.greenLight : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value
                ? CropkeepColors.greenPrimary
                : CropkeepColors.borderGoldPill,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_rounded : Icons.tune_rounded,
              size: 14,
              color: value
                  ? CropkeepColors.textGreenDeep
                  : CropkeepColors.textGoldDeep,
            ),
            const SizedBox(width: 4),
            Text(
              'Affordable',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: value
                    ? CropkeepColors.textGreenDeep
                    : CropkeepColors.textGoldDeep,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCoins(int coins) {
  final s = coins.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
  }
  return buf.toString();
}
