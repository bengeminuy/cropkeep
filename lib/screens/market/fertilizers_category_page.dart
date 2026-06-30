import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/repositories/market_repository.dart';
import '../../widgets/cropkeep_toast.dart';
import '../../widgets/market/market_hint_banner.dart';
import '../../widgets/market/market_item_card.dart';
import 'market_catalog.dart';

// Fertilizers Market page. Consumable single-use applications, sorted
// by price ascending. Per shop.md §5 the +% effects stack with other
// per-plot modifiers up to a hard +50% cap — surfaced as a top
// reminder so the player doesn't over-stock items that won't apply.
class FertilizersCategoryPage extends StatelessWidget {
  const FertilizersCategoryPage({
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
    // Potted Heirloom (900c decoration) shaves 20% off every
    // fertilizer's effective price. The discount is computed inline
    // here so the affordability filter, the card UI, and the buy
    // handler all read the same number.
    final bool discounted =
        (ownedQuantities['potted_heirloom'] ?? 0) >= 1;
    int priceFor(MarketItemSpec spec) =>
        discounted ? (spec.priceCoins * 80) ~/ 100 : spec.priceCoins;

    final visible = affordableOnly
        ? MarketCatalog.fertilizers
            .where((f) => coinBalance >= priceFor(f))
            .toList()
        : MarketCatalog.fertilizers;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
      children: [
        const MarketHintBanner(
          icon: Icons.info_outline_rounded,
          text: 'Per-plot +% yield boosts stack additively up to +50%. '
              'Mystic Potion and Buzzing Beehive sit outside the cap.',
        ),
        if (discounted) ...[
          const SizedBox(height: 8),
          const MarketHintBanner(
            icon: Icons.local_offer_outlined,
            text: 'Potted Heirloom is active — fertilizers are 20% off.',
          ),
        ],
        const SizedBox(height: 12),
        for (final spec in visible) ...[
          MarketItemCard(
            name: spec.name,
            iconAsset: spec.iconAsset,
            description: spec.description,
            priceCoins: priceFor(spec),
            canAfford: coinBalance >= priceFor(spec),
            coinShort: coinBalance >= priceFor(spec)
                ? 0
                : priceFor(spec) - coinBalance,
            kind: MarketItemKind.consumable,
            stockOrOwned: ownedQuantities[spec.itemId] ?? 0,
            onBuy: coinBalance >= priceFor(spec)
                ? () => _purchase(context, spec, priceFor(spec))
                : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _purchase(
    BuildContext context,
    MarketItemSpec spec,
    int effectivePrice,
  ) async {
    final market = AppScope.of(context).market;
    try {
      await market.purchase(
        itemId: spec.itemId,
        itemType: spec.itemType,
        priceCoins: effectivePrice,
        quantityDelta: 1,
        description: 'Bought ${spec.name}',
      );
      if (!context.mounted) return;
      CropkeepToast.success(
        context,
        iconAsset: spec.iconAsset,
        title: spec.name,
        flavor: 'Stacked in the shed',
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
