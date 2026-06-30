import 'package:flutter/material.dart';

import '../../widgets/market/market_hint_banner.dart';
import '../../widgets/market/market_item_card.dart';
import 'market_catalog.dart';
import 'purchase_confirm_sheet.dart';

// Decorations Market page. One-time, permanent global passives.
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
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
      children: [
        const MarketHintBanner(
          icon: Icons.auto_awesome_outlined,
          text: 'Permanent global passives. Buy once, always active — no '
              'placement needed.',
        ),
        const SizedBox(height: 12),
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
            onBuy: coinBalance >= spec.priceCoins &&
                    (ownedQuantities[spec.itemId] ?? 0) == 0
                ? () => _openConfirmSheet(context, spec)
                : null,
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Future<void> _openConfirmSheet(
    BuildContext context,
    MarketItemSpec spec,
  ) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PurchaseConfirmSheet(
        spec: spec,
        balanceBefore: coinBalance,
      ),
    );
  }
}
