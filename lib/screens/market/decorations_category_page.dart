import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/repositories/market_repository.dart';
import '../../theme/colors.dart';
import '../../widgets/market/market_item_card.dart';
import 'market_catalog.dart';

// Decorations Market page. One-time, permanent global passives. Payback
// estimate shown per card so the player distinguishes flavor buys from
// real upgrades.
class DecorationsCategoryPage extends StatelessWidget {
  const DecorationsCategoryPage({
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
        ? MarketCatalog.decorations
            .where((d) => coinBalance >= d.priceCoins)
            .toList()
        : MarketCatalog.decorations;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        const _PassivesHeader(),
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
            kind: MarketItemKind.oneTime,
            stockOrOwned: ownedQuantities[spec.itemId] ?? 0,
            payback: spec.payback,
            onBuy: coinBalance >= spec.priceCoins &&
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
            '${spec.name} added to your farm',
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
      _toast(context, 'Not enough coins.');
    } on AlreadyOwnedException {
      if (!context.mounted) return;
      _toast(context, '${spec.name} already owned.');
    }
  }

  void _toast(BuildContext context, String text) {
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

class _PassivesHeader extends StatelessWidget {
  const _PassivesHeader();

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
            Icons.auto_awesome_outlined,
            size: 16,
            color: CropkeepColors.textGoldDeep,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Permanent global passives. Buy once, always active — no '
              'placement needed.',
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
