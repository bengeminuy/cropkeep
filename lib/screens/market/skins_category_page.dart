import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/tables/owned_items.dart';
import '../../theme/colors.dart';
import '../../widgets/market/market_item_card.dart';
import '../../widgets/market/plot_color_tile.dart';
import 'market_catalog.dart';

// Skins Market page. Two sub-categories per shop.md §4:
//   • Avatar — gallery list of farmer faces
//   • Plot color — swatch grid (5 cosmetic + 2 effect-bearing)
//
// Acquisition only — equipping lives elsewhere (Farmer tab for avatar,
// plot edit screen for plot color).
class SkinsCategoryPage extends StatefulWidget {
  const SkinsCategoryPage({
    super.key,
    required this.coinBalance,
    required this.ownedQuantities,
    required this.affordableOnly,
  });

  final int coinBalance;
  final Map<String, int> ownedQuantities;
  final bool affordableOnly;

  @override
  State<SkinsCategoryPage> createState() => _SkinsCategoryPageState();
}

class _SkinsCategoryPageState extends State<SkinsCategoryPage> {
  int _subIndex = 0; // 0 = Avatar, 1 = Plot color

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SubSegment(
          index: _subIndex,
          onSelected: (i) => setState(() => _subIndex = i),
        ),
        const SizedBox(height: 12),
        const _EquipReminder(),
        const SizedBox(height: 12),
        Expanded(
          child: _subIndex == 0
              ? _AvatarsList(
                  coinBalance: widget.coinBalance,
                  ownedQuantities: widget.ownedQuantities,
                  affordableOnly: widget.affordableOnly,
                )
              : _PlotColorsGrid(
                  coinBalance: widget.coinBalance,
                  ownedQuantities: widget.ownedQuantities,
                  affordableOnly: widget.affordableOnly,
                ),
        ),
      ],
    );
  }
}

class _SubSegment extends StatelessWidget {
  const _SubSegment({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CropkeepColors.bgPageAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SubTab(
              label: 'Avatar',
              isActive: index == 0,
              onTap: () => onSelected(0),
            ),
          ),
          Expanded(
            child: _SubTab(
              label: 'Plot color',
              isActive: index == 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubTab extends StatelessWidget {
  const _SubTab({
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
        height: 36,
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

class _EquipReminder extends StatelessWidget {
  const _EquipReminder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CropkeepColors.bgHero,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: CropkeepColors.textSecondaryOnHero,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Purchase here. Equip avatars from the Farmer tab and plot '
              'colors when creating or editing a plot.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textSecondaryOnHero,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────

class _AvatarsList extends StatelessWidget {
  const _AvatarsList({
    required this.coinBalance,
    required this.ownedQuantities,
    required this.affordableOnly,
  });

  final int coinBalance;
  final Map<String, int> ownedQuantities;
  final bool affordableOnly;

  @override
  Widget build(BuildContext context) {
    final visible = affordableOnly
        ? MarketCatalog.avatars
            .where((a) =>
                a.priceCoins == 0 || coinBalance >= a.priceCoins)
            .toList()
        : MarketCatalog.avatars;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        for (final spec in visible) ...[
          MarketItemCard(
            name: spec.name,
            iconAsset: spec.iconAsset,
            description: spec.description,
            priceCoins: spec.priceCoins,
            canAfford: coinBalance >= spec.priceCoins,
            coinShort: coinBalance >= spec.priceCoins
                ? 0
                : spec.priceCoins - coinBalance,
            kind: MarketItemKind.oneTime,
            stockOrOwned: ownedQuantities[spec.itemId] ?? 0,
            onBuy: (coinBalance >= spec.priceCoins ||
                        spec.priceCoins == 0) &&
                    (ownedQuantities[spec.itemId] ?? 0) == 0
                ? () => _purchase(context, spec)
                : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _purchase(BuildContext context, MarketItemSpec spec) async {
    final market = AppScope.of(context).market;
    try {
      await market.purchase(
        itemId: spec.itemId,
        itemType: spec.itemType,
        priceCoins: spec.priceCoins,
        quantityDelta: 1,
        description: 'Bought ${spec.name}',
        oneTime: true,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${spec.name} unlocked',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } on InsufficientCoinsException {
      _toast(context, 'Not enough coins.');
    } on AlreadyOwnedException {
      _toast(context, '${spec.name} already owned.');
    }
  }

  void _toast(BuildContext context, String text) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────

class _PlotColorsGrid extends StatelessWidget {
  const _PlotColorsGrid({
    required this.coinBalance,
    required this.ownedQuantities,
    required this.affordableOnly,
  });

  final int coinBalance;
  final Map<String, int> ownedQuantities;
  final bool affordableOnly;

  @override
  Widget build(BuildContext context) {
    final visible = affordableOnly
        ? MarketCatalog.plotColors
            .where((c) =>
                c.priceCoins == 0 || coinBalance >= c.priceCoins)
            .toList()
        : MarketCatalog.plotColors;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: visible.length,
      itemBuilder: (context, i) {
        final spec = visible[i];
        final bool owned = (ownedQuantities[spec.itemId] ?? 0) > 0;
        final bool canAfford = coinBalance >= spec.priceCoins;
        return PlotColorTile(
          name: spec.name,
          swatchColor: Color(spec.swatchHex),
          priceCoins: spec.priceCoins,
          canAfford: canAfford,
          coinShort: canAfford ? 0 : spec.priceCoins - coinBalance,
          isOwned: owned,
          description: spec.description,
          onBuy: () => _purchase(context, spec),
        );
      },
    );
  }

  Future<void> _purchase(BuildContext context, PlotColorSpec spec) async {
    final market = AppScope.of(context).market;
    try {
      await market.purchase(
        itemId: spec.itemId,
        itemType: OwnedItemType.plotColor,
        priceCoins: spec.priceCoins,
        quantityDelta: 1,
        description: 'Unlocked ${spec.name}',
        oneTime: true,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${spec.name} unlocked',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } on InsufficientCoinsException {
      _toast(context, 'Not enough coins.');
    } on AlreadyOwnedException {
      _toast(context, '${spec.name} already owned.');
    }
  }

  void _toast(BuildContext context, String text) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

