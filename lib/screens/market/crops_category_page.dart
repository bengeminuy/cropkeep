import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/repositories/market_repository.dart';
import '../../data/tables/owned_items.dart';
import '../../theme/colors.dart';
import '../../widgets/cropkeep_toast.dart';
import '../../widgets/market/crop_market_card.dart';
import 'market_catalog.dart';

// Crops Market page. Grouped by tier — tier is the economic decision,
// set is just info. Each section header carries the tier badge plus a
// pack/yield/price triplet so cards stay scannable. Per shop.md, set
// completion is a Farm/Harvest concept, NOT a Market progression
// metric, so set bonus shows on the card only as context, never as a
// purchase gate.
//
// Tap-to-buy + toast — seed packs are cheap, stackable, and easy to
// recover from if you misclick. The PurchaseConfirmSheet is reserved
// for one-time irreversible items (decorations, avatars) where the
// confirm friction earns its keep.
class CropsCategoryPage extends StatelessWidget {
  const CropsCategoryPage({
    super.key,
    required this.coinBalance,
    required this.ownedQuantities,
    required this.affordableOnly,
  });

  final int coinBalance;
  final Map<String, int> ownedQuantities;
  final bool affordableOnly;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];
    bool anyVisible = false;
    for (final tier in CropTier.values) {
      final spec = MarketCatalog.tierSpecs[tier]!;
      final consumables = MarketCatalog.consumablesForTier(tier);
      final visible = affordableOnly
          ? consumables.where((c) => coinBalance >= spec.priceCoins).toList()
          : consumables;
      if (visible.isEmpty) continue;
      anyVisible = true;

      children.add(_TierHeader(spec: spec));
      for (final cropSpec in visible) {
        final int stock = ownedQuantities[cropSpec.cropId] ?? 0;
        final bool canAfford = coinBalance >= spec.priceCoins;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CropMarketCard(
            name: cropSpec.name,
            iconAsset: cropSpec.iconAsset,
            tier: cropSpec.tier,
            stock: stock,
            priceCoins: spec.priceCoins,
            packSize: spec.seedPackSize,
            canAfford: canAfford,
            coinShort: canAfford ? 0 : (spec.priceCoins - coinBalance),
            onBuy: canAfford ? () => _purchase(context, cropSpec) : null,
          ),
        ));
      }
      children.add(const SizedBox(height: 22));
    }
    if (children.isNotEmpty) children.removeLast();

    if (!anyVisible) {
      return const _EmptyState();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
      children: children,
    );
  }

  Future<void> _purchase(
    BuildContext context,
    MarketCropSpec spec,
  ) async {
    final tier = MarketCatalog.tierSpecs[spec.tier]!;
    final market = AppScope.of(context).market;
    try {
      await market.purchase(
        itemId: spec.cropId,
        itemType: OwnedItemType.crop,
        priceCoins: tier.priceCoins,
        quantityDelta: tier.seedPackSize,
        description: 'Bought ${spec.name} seed pack',
      );
      if (!context.mounted) return;
      CropkeepToast.success(
        context,
        iconAsset: spec.iconAsset,
        title: '+${tier.seedPackSize} ${spec.name} seeds',
        flavor: 'Tucked into the seed pouch',
      );
    } on InsufficientCoinsException catch (e) {
      if (!context.mounted) return;
      CropkeepToast.error(
        context,
        icon: Icons.savings_outlined,
        title: 'Need more coins',
        flavor: '${e.need - e.have} short for this purchase',
      );
    }
  }
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({required this.spec});

  final CropTierSpec spec;

  String get _tierLabel {
    switch (spec.tier) {
      case CropTier.common:
        return 'Common';
      case CropTier.uncommon:
        return 'Uncommon';
      case CropTier.rare:
        return 'Rare';
    }
  }

  Color get _tierColor {
    switch (spec.tier) {
      case CropTier.common:
        return CropkeepColors.tierCommon;
      case CropTier.uncommon:
        return CropkeepColors.greenPrimary;
      case CropTier.rare:
        return CropkeepColors.bluePremium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tier badge — color-coded chip with the tier label so the
          // section is identifiable by glyph even if the spec line
          // gets clipped on small screens.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _tierColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _tierLabel.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _SpecToken(
                  icon: Icons.shopping_bag_outlined,
                  text: '×${spec.seedPackSize} pack',
                ),
                _SpecToken(
                  icon: Icons.show_chart_rounded,
                  text: '+${spec.yieldPerSeed}/seed',
                ),
                _SpecToken(
                  icon: Icons.savings_outlined,
                  text: '${spec.priceCoins}c',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecToken extends StatelessWidget {
  const _SpecToken({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: CropkeepColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: CropkeepColors.textPrimary,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.eco_outlined,
              size: 40,
              color: CropkeepColors.textSecondary,
            ),
            const SizedBox(height: 10),
            const Text(
              'Nothing in reach yet',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Turn off the Affordable filter to browse, or keep '
              'harvesting to unlock the next tier.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
