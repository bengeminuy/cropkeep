import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/tables/owned_items.dart';
import '../../theme/colors.dart';
import '../../widgets/market/market_hint_banner.dart';
import 'market_catalog.dart';

// Read-only "what do I own?" view for the Market tab. Reuses the same
// chip rail as the buy pages so swiping left from Crops lands here —
// the videogame "open the bag" gesture. Every purchase already writes
// to `owned_items` via MarketRepository.purchase(); this page just
// renders that table in slot-grid form, grouped by item type.
//
// Equipping cosmetics (avatars, future skins) lives on the Farmer tab
// per spec, and seeds are plantable only at plot creation. So the
// Satchel never exposes Use / Equip actions — it points the user at
// the right destination instead. That keeps the screen honest as a
// reference surface and avoids two ways of doing the same thing.
class SatchelPage extends StatelessWidget {
  const SatchelPage({
    super.key,
    required this.ownedQuantities,
    required this.onShopForType,
  });

  final Map<String, int> ownedQuantities;
  // Tapped from a band's "Shop ›" link — the parent screen swaps the
  // active chip to that category's buy page.
  final ValueChanged<OwnedItemType> onShopForType;

  @override
  Widget build(BuildContext context) {
    final bands = _buildBands();
    final totalKinds = ownedQuantities.values.where((q) => q > 0).length;

    if (totalKinds == 0) {
      return _EmptySatchel(onShop: () => onShopForType(OwnedItemType.crop));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
      children: [
        MarketHintBanner(
          icon: Icons.backpack_outlined,
          text: 'Your satchel — $totalKinds '
              '${totalKinds == 1 ? 'kind' : 'kinds'} collected so far. '
              'Plant seeds when you create a plot, equip avatars from the '
              'Farmer tab.',
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < bands.length; i++) ...[
          _Band(
            band: bands[i],
            onShop: () => onShopForType(bands[i].itemType),
          ),
          if (i != bands.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  List<_BandData> _buildBands() {
    return [
      _BandData(
        itemType: OwnedItemType.crop,
        label: 'Seeds',
        icon: Icons.eco_outlined,
        slots: _cropSlots(),
        tint: CropkeepColors.greenHint,
      ),
      _BandData(
        itemType: OwnedItemType.fertilizer,
        label: 'Fertilizers',
        icon: Icons.water_drop_outlined,
        slots: _fertilizerSlots(),
        tint: CropkeepColors.greenHint,
      ),
      _BandData(
        itemType: OwnedItemType.decoration,
        label: 'Decorations',
        icon: Icons.auto_awesome_outlined,
        slots: _decorationSlots(),
        tint: CropkeepColors.bgGoldWash,
      ),
      _BandData(
        itemType: OwnedItemType.avatar,
        label: 'Avatars',
        icon: Icons.face_outlined,
        slots: _avatarSlots(),
        tint: CropkeepColors.bgPageAlt,
      ),
    ];
  }

  List<_SlotData> _cropSlots() {
    final out = <_SlotData>[];
    for (final spec in MarketCatalog.consumables) {
      final q = ownedQuantities[spec.cropId] ?? 0;
      if (q <= 0) continue;
      final tierSpec = MarketCatalog.tierSpecs[spec.tier]!;
      out.add(_SlotData(
        itemId: spec.cropId,
        name: spec.name,
        iconAsset: spec.iconAsset,
        qty: q,
        kind: _SlotKind.consumable,
        tint: _tierTint(spec.tier),
        accent: _tierAccent(spec.tier),
        subtitle: _tierLabel(spec.tier),
        description:
            '${tierSpec.seedPackSize} seeds per pack · each seed pays '
            '${tierSpec.yieldPerSeed}c at harvest if the plot ends healthy.',
        useHint:
            'Plant from the Farm tab when you create a new plot.',
      ));
    }
    return out;
  }

  List<_SlotData> _fertilizerSlots() {
    final out = <_SlotData>[];
    for (final spec in MarketCatalog.fertilizers) {
      final q = ownedQuantities[spec.itemId] ?? 0;
      if (q <= 0) continue;
      out.add(_SlotData(
        itemId: spec.itemId,
        name: spec.name,
        iconAsset: spec.iconAsset,
        qty: q,
        kind: _SlotKind.consumable,
        tint: CropkeepColors.greenHint,
        accent: CropkeepColors.greenPrimary,
        subtitle: 'Fertilizer',
        description: spec.description,
        useHint:
            'Tap a plot on the Farm tab → ⋮ → Apply fertilizer. One '
            'pack per plot, per cycle.',
      ));
    }
    return out;
  }

  List<_SlotData> _decorationSlots() {
    final out = <_SlotData>[];
    for (final spec in MarketCatalog.decorations) {
      final q = ownedQuantities[spec.itemId] ?? 0;
      if (q <= 0) continue;
      out.add(_SlotData(
        itemId: spec.itemId,
        name: spec.name,
        iconAsset: spec.iconAsset,
        qty: q,
        kind: _SlotKind.placed,
        tint: CropkeepColors.bgGoldWash,
        accent: CropkeepColors.borderGoldPill,
        subtitle: 'Decoration · always active',
        description: spec.description,
        useHint: 'No setup needed — the effect is already running.',
      ));
    }
    return out;
  }

  List<_SlotData> _avatarSlots() {
    final out = <_SlotData>[];
    for (final spec in MarketCatalog.avatars) {
      final q = ownedQuantities[spec.itemId] ?? 0;
      if (q <= 0) continue;
      out.add(_SlotData(
        itemId: spec.itemId,
        name: spec.name,
        iconAsset: spec.iconAsset,
        qty: q,
        kind: _SlotKind.owned,
        tint: CropkeepColors.bgPageAlt,
        accent: CropkeepColors.bluePremium,
        subtitle: 'Avatar',
        description: spec.description,
        useHint: 'Equip from the Farmer tab.',
      ));
    }
    return out;
  }
}

enum _SlotKind { consumable, placed, owned }

class _BandData {
  const _BandData({
    required this.itemType,
    required this.label,
    required this.icon,
    required this.slots,
    required this.tint,
  });
  final OwnedItemType itemType;
  final String label;
  final IconData icon;
  final List<_SlotData> slots;
  final Color tint;
}

class _SlotData {
  const _SlotData({
    required this.itemId,
    required this.name,
    required this.iconAsset,
    required this.qty,
    required this.kind,
    required this.tint,
    required this.accent,
    required this.subtitle,
    required this.description,
    required this.useHint,
  });
  final String itemId;
  final String name;
  final String iconAsset;
  final int qty;
  final _SlotKind kind;
  final Color tint;
  final Color accent;
  final String subtitle;
  final String description;
  final String useHint;
}

// ─────────────────────────────────────────────────────────────────────
// Band — one section per item type. White card, label + count + shop
// link header, then the 4-column slot grid. Even an empty band renders
// its outline so the satchel always "feels" like a bag with pockets,
// not just a list that happens to be empty.

class _Band extends StatelessWidget {
  const _Band({required this.band, required this.onShop});
  final _BandData band;
  final VoidCallback onShop;

  static const _columns = 4;
  // Minimum visible slot count so empty bands still show the bag
  // outline. One full row keeps the "pockets to fill" feel.
  static const _minSlots = 4;

  @override
  Widget build(BuildContext context) {
    final filled = band.slots.length;
    final padded = filled < _minSlots
        ? _minSlots
        : ((filled + _columns - 1) ~/ _columns) * _columns;
    final empties = padded - filled;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CropkeepColors.borderCard, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: band.tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(band.icon,
                    size: 16, color: CropkeepColors.textPrimary),
              ),
              const SizedBox(width: 10),
              Text(
                band.label,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              _CountChip(count: filled),
              const Spacer(),
              _ShopLink(onTap: onShop),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: _columns,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final slot in band.slots)
                _FilledSlot(
                  slot: slot,
                  onTap: () => _openDetail(context, slot),
                ),
              for (int i = 0; i < empties; i++) const _EmptySlot(),
            ],
          ),
          if (filled == 0) ...[
            const SizedBox(height: 10),
            Text(
              'No ${band.label.toLowerCase()} yet — tap Shop to browse.',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textSecondary,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, _SlotData slot) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SatchelDetailSheet(slot: slot),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final empty = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:
            empty ? CropkeepColors.borderDivider : CropkeepColors.greenHint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: empty
              ? CropkeepColors.textSecondary
              : CropkeepColors.textGreenDeep,
          height: 1,
        ),
      ),
    );
  }
}

class _ShopLink extends StatelessWidget {
  const _ShopLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Shop',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textGreenDeep,
              height: 1,
            ),
          ),
          SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded,
              size: 16, color: CropkeepColors.textGreenDeep),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Slot tiles. The whole inventory feel rides on these — a square cell
// with the icon centered, plus a corner badge that says what kind of
// "owned" this is (stack count, active passive, or one-time owned).

class _FilledSlot extends StatelessWidget {
  const _FilledSlot({required this.slot, required this.onTap});
  final _SlotData slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: slot.tint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: slot.accent.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: SvgPicture.asset(
                slot.iconAsset,
                width: 38,
                height: 38,
              ),
            ),
            if (slot.kind == _SlotKind.consumable)
              Positioned(
                top: 4,
                right: 4,
                child: _QtyBadge(qty: slot.qty),
              ),
            if (slot.kind == _SlotKind.placed)
              const Positioned(top: 4, right: 4, child: _ActiveDot()),
          ],
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: CropkeepColors.bgPageAlt.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CropkeepColors.borderDivider,
          width: 1,
        ),
      ),
    );
  }
}

class _QtyBadge extends StatelessWidget {
  const _QtyBadge({required this.qty});
  final int qty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: CropkeepColors.greenPrimary, width: 1),
      ),
      child: Text(
        '×$qty',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textGreenDeep,
          height: 1,
        ),
      ),
    );
  }
}

class _ActiveDot extends StatelessWidget {
  const _ActiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: CropkeepColors.greenPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// First-run empty state. Single big satchel glyph + CTA back to the
// Crops chip (the most common first purchase).

class _EmptySatchel extends StatelessWidget {
  const _EmptySatchel({required this.onShop});
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: CropkeepColors.bgHero,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.backpack_outlined,
                size: 56,
                color: CropkeepColors.textSecondaryOnHero,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your satchel is empty',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buy seeds, fertilizers, decorations and avatars from the '
              'Market — anything you own will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onShop,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: CropkeepColors.greenPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 16, color: CropkeepColors.textOnGreenBtn),
                    SizedBox(width: 8),
                    Text(
                      'Shop for seeds',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textOnGreenBtn,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Detail sheet. Mirrors PurchaseConfirmSheet's silhouette so the two
// modals read as the same product. No primary action — the satchel
// only points the user at the right place to use the item.

class _SatchelDetailSheet extends StatelessWidget {
  const _SatchelDetailSheet({required this.slot});
  final _SlotData slot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: CropkeepColors.borderDivider,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: slot.tint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: slot.accent.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child:
                    SvgPicture.asset(slot.iconAsset, width: 50, height: 50),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.name,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: CropkeepColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.subtitle,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CropkeepColors.textSecondary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _OwnedBadge(slot: slot),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            slot.description,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CropkeepColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CropkeepColors.bgHero,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: CropkeepColors.textSecondaryOnHero,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    slot.useHint,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CropkeepColors.textSecondaryOnHero,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: CropkeepColors.bgPageAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnedBadge extends StatelessWidget {
  const _OwnedBadge({required this.slot});
  final _SlotData slot;

  @override
  Widget build(BuildContext context) {
    switch (slot.kind) {
      case _SlotKind.consumable:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CropkeepColors.greenHint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 12,
                color: CropkeepColors.textGreenDeep,
              ),
              const SizedBox(width: 5),
              Text(
                'You have ×${slot.qty}',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textGreenDeep,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      case _SlotKind.placed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CropkeepColors.bgGoldWash,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CropkeepColors.borderGoldPill, width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 12,
                color: CropkeepColors.textGoldDeep,
              ),
              SizedBox(width: 5),
              Text(
                'Active on your farm',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textGoldDeep,
                  height: 1,
                ),
              ),
            ],
          ),
        );
      case _SlotKind.owned:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: CropkeepColors.bgPageAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: CropkeepColors.bluePremium, width: 1),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_rounded,
                size: 12,
                color: CropkeepColors.bluePremium,
              ),
              SizedBox(width: 5),
              Text(
                'Owned',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.bluePremium,
                  height: 1,
                ),
              ),
            ],
          ),
        );
    }
  }
}

Color _tierTint(CropTier tier) {
  switch (tier) {
    case CropTier.common:
      return CropkeepColors.bgHero;
    case CropTier.uncommon:
      return CropkeepColors.greenHint;
    case CropTier.rare:
      return CropkeepColors.bgPageAlt;
  }
}

Color _tierAccent(CropTier tier) {
  switch (tier) {
    case CropTier.common:
      return CropkeepColors.tierCommon;
    case CropTier.uncommon:
      return CropkeepColors.greenPrimary;
    case CropTier.rare:
      return CropkeepColors.bluePremium;
  }
}

String _tierLabel(CropTier tier) {
  switch (tier) {
    case CropTier.common:
      return 'Common seed pack';
    case CropTier.uncommon:
      return 'Uncommon seed pack';
    case CropTier.rare:
      return 'Rare seed pack';
  }
}
