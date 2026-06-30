import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../data/database.dart';
import '../data/tables/owned_items.dart';
import '../screens/market/market_catalog.dart';
import '../theme/colors.dart';
import 'cropkeep_toast.dart';

// Catalog-driven avatar picker. Every entry in `MarketCatalog.avatars`
// renders as a tile; `owned_items` decides which are equippable vs.
// locked. The equipped avatar is stored as `app_settings.avatar_id` —
// `CycleRepository._buildPreview` reads that field at close time to
// apply each passive (Beekeeper +25% set bonus, Forest Elf +5% plot
// yield, Arcane Wizard +10% yield + combo override). A single column
// covers "owned freebie" and "equipped slot" because the avatar slot
// is single-equip; the obsolete `equipped_avatar_id` schema item in
// to-do.md has been removed.
class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({super.key, required this.currentAvatarId});

  final String currentAvatarId;

  // Single source of truth for avatar asset paths. Header, FarmerScreen
  // profile, onboarding hero, and this picker all route through here so
  // a catalog change reaches every surface in one edit. Unknown ids fall
  // back to the default farmer SVG — covers legacy installs whose
  // `avatar_id` was `farmer-fl` before `ensureSeeded` migrates them.
  static String assetFor(String id) {
    for (final spec in MarketCatalog.avatars) {
      if (spec.itemId == id) return spec.iconAsset;
    }
    return 'assets/icons/farmer.svg';
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: StreamBuilder<List<OwnedItemRow>>(
          stream: scope.market.watchOwned(),
          builder: (context, snap) {
            final ownedAvatars = <String>{
              for (final row in snap.data ?? const <OwnedItemRow>[])
                if (row.itemType == OwnedItemType.avatar && row.quantity > 0)
                  row.itemId,
            };
            // The default farmer is the freebie. `completeOnboarding`
            // doesn't insert an `owned_items` row for it (avatars aren't
            // seeded that way), so we fold it in here rather than gate
            // it on the database.
            ownedAvatars.add('farmer');
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CropkeepColors.borderDivider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Choose your avatar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Passive bonuses apply at this cycle's harvest.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CropkeepColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: MarketCatalog.avatars.length,
                    itemBuilder: (context, i) {
                      final spec = MarketCatalog.avatars[i];
                      final isOwned = ownedAvatars.contains(spec.itemId);
                      final isEquipped = spec.itemId == currentAvatarId;
                      return _AvatarTile(
                        spec: spec,
                        isOwned: isOwned,
                        isEquipped: isEquipped,
                        onTap: () =>
                            _onTileTap(context, spec, isOwned, isEquipped),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onTileTap(
    BuildContext context,
    MarketItemSpec spec,
    bool isOwned,
    bool isEquipped,
  ) async {
    if (isEquipped) return;
    if (!isOwned) {
      // Toast first, pop second: the toast registers with the root
      // ScaffoldMessenger (above the modal route) so it survives the
      // sheet teardown. We don't deep-link straight to Market > Skins
      // because the root tab switcher isn't exposed to widgets below
      // it — wiring that up was deferred per the design recommendation.
      CropkeepToast.info(
        context,
        title: 'Locked',
        flavor: 'Unlock ${spec.name} from the Market under Skins.',
      );
      Navigator.of(context).pop();
      return;
    }
    final repo = AppScope.of(context).appSettings;
    await repo.updateAvatar(spec.itemId);
    if (!context.mounted) return;
    CropkeepToast.success(
      context,
      title: 'Equipped ${spec.name}',
      flavor: _passiveLineFor(spec),
      iconAsset: spec.iconAsset,
    );
    Navigator.of(context).pop();
  }
}

// One-line passive copy, short enough to render under the avatar name
// in the tile and as the equip-confirmation toast flavor. Trimmed from
// `MarketItemSpec.description`, which is sometimes two sentences and
// frames the effect for shopping rather than equipping.
String _passiveLineFor(MarketItemSpec spec) {
  switch (spec.itemId) {
    case 'forest_elf':
      return '+5% yield on every plot';
    case 'arcane_wizard':
      return '+10% yield; mildly stressed counts as healthy';
    default:
      // Beekeeper sits here too while its passive slot is open — set
      // bonuses (the +25% boost) are paused for v1. See md/to-do.md.
      return 'Cosmetic — no gameplay effect';
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.spec,
    required this.isOwned,
    required this.isEquipped,
    required this.onTap,
  });

  final MarketItemSpec spec;
  final bool isOwned;
  final bool isEquipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isEquipped
        ? CropkeepColors.greenPrimary
        : CropkeepColors.borderCard;
    final double borderWidth = isEquipped ? 2 : 1.5;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isOwned ? 1.0 : 0.45,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: CropkeepColors.greenHint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      spec.iconAsset,
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (!isOwned)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: _LockBadge(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              spec.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isOwned
                    ? CropkeepColors.textPrimary
                    : CropkeepColors.textSecondary,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                _passiveLineFor(spec),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: CropkeepColors.textSecondary,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 6),
            _StatePill(
              isEquipped: isEquipped,
              isOwned: isOwned,
              priceCoins: spec.priceCoins,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({
    required this.isEquipped,
    required this.isOwned,
    required this.priceCoins,
  });

  final bool isEquipped;
  final bool isOwned;
  final int priceCoins;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color bg;
    final Color fg;
    final Color border;
    if (isEquipped) {
      label = 'Equipped';
      bg = CropkeepColors.greenHint;
      fg = CropkeepColors.textGreen;
      border = CropkeepColors.greenLight;
    } else if (isOwned) {
      label = 'Equip';
      bg = Colors.white;
      fg = CropkeepColors.textPrimary;
      border = CropkeepColors.borderCard;
    } else {
      label = '${priceCoins}c';
      bg = CropkeepColors.bgGoldWash;
      fg = CropkeepColors.textGold;
      border = CropkeepColors.goldPrimary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: fg,
          height: 1,
        ),
      ),
    );
  }
}

class _LockBadge extends StatelessWidget {
  const _LockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.lock_outline,
        size: 14,
        color: CropkeepColors.textSecondary,
      ),
    );
  }
}
