import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/repositories/market_repository.dart';
import '../../theme/colors.dart';
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
    final visible = affordableOnly
        ? MarketCatalog.fertilizers
            .where((f) => coinBalance >= f.priceCoins)
            .toList()
        : MarketCatalog.fertilizers;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        const _StackingHeader(),
        const SizedBox(height: 14),
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
            kind: MarketItemKind.consumable,
            stockOrOwned: ownedQuantities[spec.itemId] ?? 0,
            onBuy: coinBalance >= spec.priceCoins
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
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${spec.name} added',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } on InsufficientCoinsException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Not enough coins.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
            ),
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class _StackingHeader extends StatelessWidget {
  const _StackingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: CropkeepColors.bgGoldWash,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CropkeepColors.borderGoldPill, width: 1),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: CropkeepColors.textGoldDeep,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Per-plot +% yield boosts stack additively up to +50%. '
              'Mystic Potion and Buzzing Beehive sit outside the cap.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textGoldDeep,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
