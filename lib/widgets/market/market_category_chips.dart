import 'package:flutter/material.dart';

import '../../theme/colors.dart';

// Five horizontal scrollable chips above the PageView. Same visual
// idiom as Farm's `_SubpageSegmentedControl` (`bgPageAlt` track,
// greenPrimary active pill), but scrollable to fit five labels at any
// width without crushing them.
class MarketCategoryChips extends StatelessWidget {
  const MarketCategoryChips({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CropkeepColors.bgPageAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _ChipTab(
                label: labels[i],
                isActive: i == activeIndex,
                onTap: () => onSelected(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChipTab extends StatelessWidget {
  const _ChipTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? CropkeepColors.greenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive
                ? CropkeepColors.textOnGreenBtn
                : CropkeepColors.textNavInactive,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// Page indicator dots matching the five-cell PageView. Copied from
// Farm's `_PageIndicatorDots` so Market doesn't import private types.
class MarketPageDots extends StatelessWidget {
  const MarketPageDots({
    super.key,
    required this.index,
    required this.count,
  });

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: i == index
                  ? CropkeepColors.greenPrimary
                  : CropkeepColors.borderCard,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}
