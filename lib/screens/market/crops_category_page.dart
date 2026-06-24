import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../widgets/market/crop_market_card.dart';
import 'market_catalog.dart';
import 'purchase_confirm_sheet.dart';

// Crops Market page. Grouped by tier (Common / Uncommon / Rare) — tier
// is the economic decision, set is just info. Each section header
// carries the tier's price / pack / yield / break-even so cards stay
// scannable. Per shop.md, set completion is a Farm/Harvest concept,
// NOT a Market progression metric.
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
    for (final tier in CropTier.values) {
      final spec = MarketCatalog.tierSpecs[tier]!;
      final consumables = MarketCatalog.consumablesForTier(tier);
      final visible = affordableOnly
          ? consumables.where((c) => coinBalance >= spec.priceCoins).toList()
          : consumables;
      if (visible.isEmpty && affordableOnly) continue;

      children.add(_TierHeader(spec: spec));
      for (final cropSpec in visible) {
        final setSpec = MarketCatalog.setById(cropSpec.setId);
        final int stock = ownedQuantities[cropSpec.cropId] ?? 0;
        final bool canAfford = coinBalance >= spec.priceCoins;
        children.add(Padding(
          padding: const EdgeInsets.only(top: 10),
          child: CropMarketCard(
            name: cropSpec.name,
            iconAsset: cropSpec.iconAsset,
            setName: setSpec.name,
            setBonusCoins: setSpec.bonusCoins,
            stock: stock,
            packMax: spec.packMax,
            priceCoins: spec.priceCoins,
            canAfford: canAfford,
            coinShort: canAfford ? 0 : (spec.priceCoins - coinBalance),
            onBuy: canAfford && stock < spec.packMax
                ? () => _openConfirmSheet(
                      context,
                      spec: cropSpec,
                      currentStock: stock,
                    )
                : null,
          ),
        ));
      }
      children.add(const SizedBox(height: 24));
    }
    if (children.isNotEmpty) children.removeLast();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: children,
    );
  }

  Future<void> _openConfirmSheet(
    BuildContext context, {
    required MarketCropSpec spec,
    required int currentStock,
  }) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PurchaseConfirmSheet(
        spec: spec,
        balanceBefore: coinBalance,
        currentStock: currentStock,
      ),
    );
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
      padding: const EdgeInsets.only(top: 4, bottom: 2, left: 2, right: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _tierColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _tierLabel.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: _tierColor,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${spec.priceCoins}c · pack ${spec.seedPackSize} · '
            '${spec.yieldPerSeed} yield per seed',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: CropkeepColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${spec.breakEvenLabel} · max stock ${spec.packMax}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: CropkeepColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
