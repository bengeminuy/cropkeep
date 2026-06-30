import 'package:flutter/material.dart';

import '../../theme/colors.dart';

// Horizontal scrollable chip row. Each chip carries a glyph + label so
// the row reads as an icon rail even at narrow widths. Active chip
// turns greenPrimary on the bgPageAlt track. The previous separate
// `MarketPageDots` row was dropped — the active chip already conveys
// which page the PageView is on.
class MarketCategoryChips extends StatelessWidget {
  const MarketCategoryChips({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onSelected,
  });

  final List<MarketCategoryChipItem> items;
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
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _ChipTab(
                item: items[i],
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

class MarketCategoryChipItem {
  const MarketCategoryChipItem({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _ChipTab extends StatelessWidget {
  const _ChipTab({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final MarketCategoryChipItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color fg = isActive
        ? CropkeepColors.textOnGreenBtn
        : CropkeepColors.textNavInactive;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? CropkeepColors.greenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 15, color: fg),
            const SizedBox(width: 6),
            Text(
              item.label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: fg,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
