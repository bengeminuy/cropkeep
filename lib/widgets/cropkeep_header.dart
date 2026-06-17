import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';

class CropkeepHeader extends StatelessWidget {
  const CropkeepHeader({
    super.key,
    required this.avatarId,
    required this.level,
    required this.xpProgress,
    required this.coins,
  });

  final String avatarId;
  final int level;

  /// 0.0–1.0 — fraction of XP earned toward the next level.
  final double xpProgress;
  final int coins;

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
              _AvatarLevelBlock(
                avatarId: avatarId,
                level: level,
                xpProgress: xpProgress,
              ),
              const Spacer(),
              _CyclePill(day: now.day, totalDays: daysInMonth),
              const SizedBox(width: 8),
              _CoinsPill(coins: coins),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarLevelBlock extends StatelessWidget {
  const _AvatarLevelBlock({
    required this.avatarId,
    required this.level,
    required this.xpProgress,
  });

  final String avatarId;
  final int level;
  final double xpProgress;

  static const double _ringSize = 54;
  static const double _avatarSize = 44;

  static String _assetFor(String id) {
    switch (id) {
      case 'farmer-fl':
        return 'assets/icons/farmer-fl.svg';
      case 'farmer':
      default:
        return 'assets/icons/farmer.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _ringSize,
          height: _ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: _ringSize,
                height: _ringSize,
                child: CircularProgressIndicator(
                  value: xpProgress.clamp(0.0, 1.0),
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: CropkeepColors.greenHint,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    CropkeepColors.greenPrimary,
                  ),
                ),
              ),
              Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: const BoxDecoration(
                  color: CropkeepColors.greenHint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.asset(
                  _assetFor(avatarId),
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Level',
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
              '$level',
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
