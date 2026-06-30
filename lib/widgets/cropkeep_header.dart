import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';
import 'avatar_picker_sheet.dart';

class CropkeepHeader extends StatelessWidget {
  const CropkeepHeader({
    super.key,
    required this.avatarId,
    required this.farmerName,
    required this.coins,
    required this.showCyclePill,
  });

  final String avatarId;
  final String farmerName;
  final int coins;

  /// Whether to show the day-of-month pill. The pill is purely a
  /// calendar position ("Day 15 / 31" = "March 15 of March") and only
  /// makes sense when a cycle is being tracked. Pass false to hide it
  /// in the no-active-cycle state.
  final bool showCyclePill;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Container(
      color: CropkeepColors.bgScreen,
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: Row(
            children: [
              Expanded(
                child: _AvatarGreetingBlock(
                  avatarId: avatarId,
                  farmerName: farmerName,
                ),
              ),
              const SizedBox(width: 8),
              if (showCyclePill) ...[
                _CyclePill(day: now.day, totalDays: daysInMonth),
                const SizedBox(width: 8),
              ],
              _CoinsPill(coins: coins),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarGreetingBlock extends StatelessWidget {
  const _AvatarGreetingBlock({
    required this.avatarId,
    required this.farmerName,
  });

  final String avatarId;
  final String farmerName;

  static const double _avatarSize = 44;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _avatarSize,
          height: _avatarSize,
          decoration: const BoxDecoration(
            color: CropkeepColors.greenHint,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            AvatarPickerSheet.assetFor(avatarId),
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 10),
        // Flexible — long farmer names ellipsize instead of pushing
        // the cycle/coin pills off-screen on narrow devices.
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome back,',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CropkeepColors.textSecondary,
                  height: 1,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                farmerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CyclePill extends StatelessWidget {
  const _CyclePill({required this.day, required this.totalDays});

  final int day;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CropkeepColors.greenHint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CropkeepColors.greenPrimary, width: 1),
      ),
      child: Text(
        'Day $day / $totalDays',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: CropkeepColors.textGreen,
        ),
      ),
    );
  }
}

class _CoinsPill extends StatelessWidget {
  const _CoinsPill({required this.coins});

  final int coins;

  String get _formatted {
    final String s = coins.toString();
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
      out.write(s[i]);
    }
    return out.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CropkeepColors.goldWash,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CropkeepColors.borderGoldPill, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset('assets/icons/coin.svg', width: 16, height: 16),
          const SizedBox(width: 6),
          Text(
            _formatted,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textOnGoldPill,
            ),
          ),
        ],
      ),
    );
  }
}
