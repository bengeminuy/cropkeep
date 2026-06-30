import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/colors.dart';

// Slim hero bar above the category chips. The global header already
// shows the wallet — this is in-context reinforcement plus the
// "affordable only" filter on a single row, instead of the previous
// full-bleed COIN BALANCE card that doubled the top chrome.
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CropkeepColors.bgHero,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _WalletPill(coinBalance: coinBalance),
          const Spacer(),
          _AffordableToggle(
            value: affordableOnly,
            onChanged: onAffordableToggled,
          ),
        ],
      ),
    );
  }
}

class _WalletPill extends StatelessWidget {
  const _WalletPill({required this.coinBalance});

  final int coinBalance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: CropkeepColors.bgGoldWash,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CropkeepColors.borderGoldPill, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/icons/coin.svg', width: 18, height: 18),
          const SizedBox(width: 6),
          Text(
            _formatCoins(coinBalance),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textGoldDeep,
              height: 1,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'in wallet',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CropkeepColors.textGoldDeep,
              height: 1,
            ),
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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: value ? CropkeepColors.greenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value
                ? CropkeepColors.greenPrimary
                : CropkeepColors.textSecondaryOnHero.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_rounded : Icons.filter_alt_outlined,
              size: 14,
              color: value
                  ? CropkeepColors.textOnGreenBtn
                  : CropkeepColors.textSecondaryOnHero,
            ),
            const SizedBox(width: 4),
            Text(
              'Affordable',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: value
                    ? CropkeepColors.textOnGreenBtn
                    : CropkeepColors.textSecondaryOnHero,
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
