import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';

class CropkeepNavBar extends StatelessWidget {
  const CropkeepNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onFabTapped,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onFabTapped;

  static const double _islandHeight = 64;
  // Bumped from 64 to 68 to fit the brown outline ring around the cradle
  // without shrinking the inner FAB.
  static const double _fabSize = 68;
  static const double _fabLift = 22;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CropkeepColors.bgScreen,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 0),
          child: SizedBox(
            height: _islandHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: _NavIsland(
                    currentIndex: currentIndex,
                    onTabSelected: onTabSelected,
                    fabSlotWidth: _fabSize,
                  ),
                ),
                Positioned(
                  top: -_fabLift,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _FabCradle(
                      size: _fabSize,
                      onTap: onFabTapped,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIsland extends StatelessWidget {
  const _NavIsland({
    required this.currentIndex,
    required this.onTabSelected,
    required this.fabSlotWidth,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final double fabSlotWidth;

  // Left edge of the active tab's slot inside the Row's coordinate space.
  // Slots 2/3 (Market/Farmer) sit past the FAB spacer.
  double _activeSlotLeft(double tabSlot) {
    switch (currentIndex) {
      case 0:
        return 0;
      case 1:
        return tabSlot;
      case 2:
        return 2 * tabSlot + fabSlotWidth;
      case 3:
        return 3 * tabSlot + fabSlotWidth;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CropkeepColors.bgNav,
        // Softened from 24 — rounder edge reads as more pillowy than crisp.
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: CropkeepColors.borderNav,
          width: 1.5,
        ),
        boxShadow: const [
          // Wider blur + smaller drop softens the lift without losing it.
          BoxShadow(
            color: CropkeepColors.shadowNav,
            blurRadius: 28,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double tabSlot =
                (constraints.maxWidth - fabSlotWidth) / 4;
            final double slotLeft = _activeSlotLeft(tabSlot);
            const double indicatorMargin = 4;

            return Stack(
              fit: StackFit.expand,
              children: [
                // The sliding pill. Sits *behind* the Row, so it ducks under
                // the FAB cradle (which lives in the outer Stack on top) when
                // crossing the center.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  left: slotLeft + indicatorMargin,
                  top: 0,
                  bottom: 0,
                  width: tabSlot - 2 * indicatorMargin,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: CropkeepColors.greenHint,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _NavItem(
                        icon: 'assets/icons/farm.svg',
                        label: 'Farm',
                        isActive: currentIndex == 0,
                        onTap: () => onTabSelected(0),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: 'assets/icons/ledger.svg',
                        label: 'Ledger',
                        isActive: currentIndex == 1,
                        onTap: () => onTabSelected(1),
                      ),
                    ),
                    SizedBox(width: fabSlotWidth),
                    Expanded(
                      child: _NavItem(
                        icon: 'assets/icons/market.svg',
                        label: 'Market',
                        isActive: currentIndex == 2,
                        onTap: () => onTabSelected(2),
                      ),
                    ),
                    Expanded(
                      child: _NavItem(
                        icon: 'assets/icons/farmer.svg',
                        label: 'Farmer',
                        isActive: currentIndex == 3,
                        onTap: () => onTabSelected(3),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  // Warm brown (textNavInactive #6B5530) at ~12% / ~6% alpha. Reads as a
  // gentle "press darkening" in palette — the green accent is reserved for
  // the active state, not for transient tap feedback.
  static const Color _splash = Color(0x1F6B5530);
  static const Color _highlight = Color(0x0F6B5530);

  @override
  Widget build(BuildContext context) {
    // Matches the sliding indicator's radius so the ripple shape echoes it.
    final BorderRadius radius = BorderRadius.circular(20);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: _splash,
        highlightColor: _highlight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dimming inactive icons creates active/inactive hierarchy
              // without tinting — preserves the full-color sticker style.
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                opacity: isActive ? 1.0 : 0.55,
                child: SvgPicture.asset(icon, width: 22, height: 22),
              ),
              const SizedBox(height: 4),
              // Label stays brown in both states — green-on-greenHint had
              // weak value contrast (~2.3:1, fails WCAG AA). The sliding
              // pill, icon opacity, and bolder weight carry the active state.
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  color: CropkeepColors.textNavInactive,
                ).copyWith(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FabCradle extends StatelessWidget {
  const _FabCradle({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  // Warm brown drop shadow under the FAB button — softened blur + tighter drop.
  static const BoxShadow _fabShadow = BoxShadow(
    color: Color(0x33806240),
    blurRadius: 14,
    offset: Offset(0, 2),
  );

  // White ripple at ~25% / ~12% alpha — visible on the solid green FAB body.
  static const Color _splash = Color(0x40FFFFFF);
  static const Color _highlight = Color(0x1FFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      // Brown outline continues the island's border around the cradle, so the
      // FAB looks nested into the island instead of cutting through it.
      // Inside the outline, the bg-screen ring is the visible halo.
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(
            color: CropkeepColors.borderNav,
            width: 1.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [_fabShadow],
          ),
          // Filled green body = primary CTA. Halo + shadow provide
          // definition, so no border is needed.
          child: Material(
            color: CropkeepColors.greenPrimary,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              splashColor: _splash,
              highlightColor: _highlight,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/water.svg',
                  width: 26,
                  height: 26,
                  colorFilter: const ColorFilter.mode(
                    CropkeepColors.textOnGreenBtn,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
