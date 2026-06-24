// Static metadata the database doesn't carry: tier per crop, set
// membership, set-bonus values, fertilizer/decoration/avatar/plot-color
// specs, and the icon asset mapping. The seed code in
// `app_settings_repository.dart` reads from here so the UI and the
// persisted catalog can't drift.
//
// Values are kept in sync with `md/shop.md`. When that doc changes,
// update this file and `_resyncConsumableCrops` in the same pass.

import '../../data/tables/owned_items.dart';

enum CropTier { common, uncommon, rare }

// Tier-level economics. Common to every crop in the tier — rendered
// once as a section header on the Crops page rather than repeated on
// every card.
class CropTierSpec {
  const CropTierSpec({
    required this.tier,
    required this.priceCoins,
    required this.seedPackSize,
    required this.yieldPerSeed,
    required this.packMax,
    required this.breakEvenLabel,
  });

  final CropTier tier;
  final int priceCoins;
  final int seedPackSize;
  final int yieldPerSeed;
  // Inventory ceiling per shop.md. Owned quantity will not exceed this
  // once we wire the cap into MarketRepository.purchase.
  final int packMax;
  // Human-readable break-even ("3 of 5", "~4.4 of 5"). Renders inside
  // the tier header so the user reasons about the bet up front.
  final String breakEvenLabel;
}

class CropSetSpec {
  const CropSetSpec({
    required this.id,
    required this.name,
    required this.bonusCoins,
    required this.cropIds,
  });

  final String id;
  final String name;
  final int bonusCoins;
  final List<String> cropIds;
}

class MarketCropSpec {
  const MarketCropSpec({
    required this.cropId,
    required this.name,
    required this.tier,
    required this.setId,
    required this.iconAsset,
    required this.displayOrder,
  });

  final String cropId;
  final String name;
  final CropTier tier;
  final String setId;
  final String iconAsset;
  final int displayOrder;
}

// Single source of truth for fertilizers / decorations / avatars.
// Effect text is rendered verbatim from `description`. Owned quantity
// for consumables is the stock; for one-time items it's 0 or 1.
class MarketItemSpec {
  const MarketItemSpec({
    required this.itemId,
    required this.itemType,
    required this.name,
    required this.priceCoins,
    required this.description,
    required this.iconAsset,
    this.payback,
  });

  final String itemId;
  final OwnedItemType itemType;
  final String name;
  final int priceCoins;
  // Renders verbatim under the name. Keep terse — graphics.md voice.
  final String description;
  final String iconAsset;
  // Decorations only — rough cycles-to-payback note from shop.md.
  final String? payback;
}

// Plot color tile — no icon, just a swatch hex.
class PlotColorSpec {
  const PlotColorSpec({
    required this.itemId,
    required this.name,
    required this.priceCoins,
    required this.swatchHex,
    this.description,
  });

  final String itemId;
  final String name;
  final int priceCoins;
  final int swatchHex;
  // Null for pure cosmetics; populated for the two effect colors.
  final String? description;
}

class MarketCatalog {
  const MarketCatalog._();

  // ──────── Crops ────────

  static const Map<CropTier, CropTierSpec> tierSpecs = <CropTier, CropTierSpec>{
    CropTier.common: CropTierSpec(
      tier: CropTier.common,
      priceCoins: 75,
      seedPackSize: 5,
      yieldPerSeed: 25,
      packMax: 125,
      breakEvenLabel: '3 of 5 to break even',
    ),
    CropTier.uncommon: CropTierSpec(
      tier: CropTier.uncommon,
      priceCoins: 175,
      seedPackSize: 5,
      yieldPerSeed: 40,
      packMax: 200,
      breakEvenLabel: '~4.4 of 5 to break even',
    ),
    CropTier.rare: CropTierSpec(
      tier: CropTier.rare,
      priceCoins: 300,
      seedPackSize: 5,
      yieldPerSeed: 75,
      packMax: 375,
      breakEvenLabel: '4 of 5 to break even',
    ),
  };

  // Sets are kept for reference only — set progress is a Farm/harvest
  // concept (set completion fires when all crops in a set are PLANTED
  // and harvest healthy). The Market only surfaces the set name and
  // bonus value beside each crop so the player can plan ahead.
  static const List<CropSetSpec> sets = <CropSetSpec>[
    CropSetSpec(
      id: 'grain_trio',
      name: 'Grain trio',
      bonusCoins: 30,
      cropIds: ['wheat', 'corn', 'barley'],
    ),
    CropSetSpec(
      id: 'the_orchard',
      name: 'The Orchard',
      bonusCoins: 40,
      cropIds: ['apple', 'peach', 'pear'],
    ),
    CropSetSpec(
      id: 'veggie_patch',
      name: 'Veggie patch',
      bonusCoins: 60,
      cropIds: ['potato', 'carrot', 'lettuce'],
    ),
    CropSetSpec(
      id: 'berry_medley',
      name: 'Berry medley',
      bonusCoins: 60,
      cropIds: ['strawberry', 'raspberry', 'blueberry'],
    ),
    CropSetSpec(
      id: 'nightshade',
      name: 'Nightshade',
      bonusCoins: 60,
      cropIds: ['tomato', 'eggplant', 'bell_pepper'],
    ),
    CropSetSpec(
      id: 'tropical_trio',
      name: 'Tropical trio',
      bonusCoins: 120,
      cropIds: ['mango', 'orange', 'pineapple'],
    ),
  ];

  // 15 consumable crops. Starters (wheat / apple / potato) are seeded
  // by completeOnboarding and live alongside these in crops_catalog.
  //
  // Set assignment from `shop.md` §1 table:
  //   Common (75c/5/25):    Corn, Barley, Carrot, Lettuce
  //   Uncommon (175c/5/40): Peach, Pear, Tomato, Eggplant, Bell pepper
  //   Rare (300c/5/75):     Strawberry, Raspberry, Blueberry, Mango, Orange, Pineapple
  static const List<MarketCropSpec> consumables = <MarketCropSpec>[
    // Common
    MarketCropSpec(
      cropId: 'corn',
      name: 'Corn',
      tier: CropTier.common,
      setId: 'grain_trio',
      iconAsset: 'assets/icons/crops/icons8-corn.svg',
      displayOrder: 11,
    ),
    MarketCropSpec(
      cropId: 'barley',
      name: 'Barley',
      tier: CropTier.common,
      setId: 'grain_trio',
      iconAsset: 'assets/icons/crops/icons8-barley.svg',
      displayOrder: 12,
    ),
    MarketCropSpec(
      cropId: 'carrot',
      name: 'Carrot',
      tier: CropTier.common,
      setId: 'veggie_patch',
      iconAsset: 'assets/icons/crops/icons8-carrot.svg',
      displayOrder: 31,
    ),
    MarketCropSpec(
      cropId: 'lettuce',
      name: 'Lettuce',
      tier: CropTier.common,
      setId: 'veggie_patch',
      iconAsset: 'assets/icons/crops/icons8-lettuce.svg',
      displayOrder: 32,
    ),
    // Uncommon
    MarketCropSpec(
      cropId: 'peach',
      name: 'Peach',
      tier: CropTier.uncommon,
      setId: 'the_orchard',
      iconAsset: 'assets/icons/crops/icons8-peach.svg',
      displayOrder: 21,
    ),
    MarketCropSpec(
      cropId: 'pear',
      name: 'Pear',
      tier: CropTier.uncommon,
      setId: 'the_orchard',
      iconAsset: 'assets/icons/crops/icons8-pear.svg',
      displayOrder: 22,
    ),
    MarketCropSpec(
      cropId: 'tomato',
      name: 'Tomato',
      tier: CropTier.uncommon,
      setId: 'nightshade',
      iconAsset: 'assets/icons/crops/icons8-tomato.svg',
      displayOrder: 51,
    ),
    MarketCropSpec(
      cropId: 'eggplant',
      name: 'Eggplant',
      tier: CropTier.uncommon,
      setId: 'nightshade',
      iconAsset: 'assets/icons/crops/icons8-eggplant.svg',
      displayOrder: 52,
    ),
    MarketCropSpec(
      cropId: 'bell_pepper',
      name: 'Bell pepper',
      tier: CropTier.uncommon,
      setId: 'nightshade',
      iconAsset: 'assets/icons/crops/icons8-bell-pepper.svg',
      displayOrder: 53,
    ),
    // Rare
    MarketCropSpec(
      cropId: 'strawberry',
      name: 'Strawberry',
      tier: CropTier.rare,
      setId: 'berry_medley',
      iconAsset: 'assets/icons/crops/icons8-strawberry.svg',
      displayOrder: 41,
    ),
    MarketCropSpec(
      cropId: 'raspberry',
      name: 'Raspberry',
      tier: CropTier.rare,
      setId: 'berry_medley',
      iconAsset: 'assets/icons/crops/icons8-raspberry.svg',
      displayOrder: 42,
    ),
    MarketCropSpec(
      cropId: 'blueberry',
      name: 'Blueberry',
      tier: CropTier.rare,
      setId: 'berry_medley',
      iconAsset: 'assets/icons/crops/icons8-blueberry.svg',
      displayOrder: 43,
    ),
    MarketCropSpec(
      cropId: 'mango',
      name: 'Mango',
      tier: CropTier.rare,
      setId: 'tropical_trio',
      iconAsset: 'assets/icons/crops/icons8-mango.svg',
      displayOrder: 61,
    ),
    MarketCropSpec(
      cropId: 'orange',
      name: 'Orange',
      tier: CropTier.rare,
      setId: 'tropical_trio',
      iconAsset: 'assets/icons/crops/icons8-orange.svg',
      displayOrder: 62,
    ),
    MarketCropSpec(
      cropId: 'pineapple',
      name: 'Pineapple',
      tier: CropTier.rare,
      setId: 'tropical_trio',
      iconAsset: 'assets/icons/crops/icons8-pineapple.svg',
      displayOrder: 63,
    ),
  ];

  // ──────── Fertilizers (consumables, 1 use per pack) ────────
  // Single use per purchase — apply to one plot for one cycle. The
  // `quantity` column on owned_items stores remaining applications.
  static const List<MarketItemSpec> fertilizers = <MarketItemSpec>[
    MarketItemSpec(
      itemId: 'fertilizer_mix',
      itemType: OwnedItemType.fertilizer,
      name: 'Fertilizer Mix',
      priceCoins: 20,
      description: '+15% coin yield on harvest',
      iconAsset: 'assets/icons/fertilizers/fertilizer.svg',
    ),
    MarketItemSpec(
      itemId: 'compost_heap',
      itemType: OwnedItemType.fertilizer,
      name: 'Compost Heap',
      priceCoins: 30,
      description: '+25% coin yield on harvest',
      iconAsset: 'assets/icons/fertilizers/compost-heap.svg',
    ),
    MarketItemSpec(
      itemId: 'liquid_boost',
      itemType: OwnedItemType.fertilizer,
      name: 'Liquid Boost',
      priceCoins: 45,
      description: '+35% coin yield on harvest',
      iconAsset: 'assets/icons/fertilizers/liquid-fertilizer.svg',
    ),
    MarketItemSpec(
      itemId: 'pumpkin_bloom',
      itemType: OwnedItemType.fertilizer,
      name: 'Pumpkin Bloom',
      priceCoins: 60,
      description: '+50% coin yield on harvest',
      iconAsset: 'assets/icons/fertilizers/pumpkin.svg',
    ),
    MarketItemSpec(
      itemId: 'storm_umbrella',
      itemType: OwnedItemType.fertilizer,
      name: 'Storm Umbrella',
      priceCoins: 80,
      description: 'Mild stress treated as harvested for that plot',
      iconAsset: 'assets/icons/fertilizers/umbrella.svg',
    ),
    MarketItemSpec(
      itemId: 'buzzing_beehive',
      itemType: OwnedItemType.fertilizer,
      name: 'Buzzing Beehive',
      priceCoins: 90,
      description: 'All plots get +10% yield this cycle',
      iconAsset: 'assets/icons/fertilizers/beehive.svg',
    ),
    MarketItemSpec(
      itemId: 'faerie_reviver',
      itemType: OwnedItemType.fertilizer,
      name: 'Faerie Reviver',
      priceCoins: 120,
      description: 'Withered → mild stress (recovers 50% yield)',
      iconAsset: 'assets/icons/fertilizers/fairy.svg',
    ),
    MarketItemSpec(
      itemId: 'mystic_potion',
      itemType: OwnedItemType.fertilizer,
      name: 'Mystic Potion',
      priceCoins: 200,
      description: '+100% yield, but yields 0 if not harvested',
      iconAsset: 'assets/icons/fertilizers/mana.svg',
    ),
  ];

  // ──────── Decorations (one-time, permanent global passive) ────────
  static const List<MarketItemSpec> decorations = <MarketItemSpec>[
    MarketItemSpec(
      itemId: 'mushroom_gnome',
      itemType: OwnedItemType.decoration,
      name: 'Mushroom Gnome',
      priceCoins: 200,
      description: '+5 coins per cycle if overall positive',
      iconAsset: 'assets/icons/decorations/mushroom.svg',
      payback: '~40 cycles · flavor buy',
    ),
    MarketItemSpec(
      itemId: 'iron_pitchfork',
      itemType: OwnedItemType.decoration,
      name: 'Iron Pitchfork',
      priceCoins: 350,
      description: 'Withered plots no longer break the combo bonus',
      iconAsset: 'assets/icons/decorations/pitchfork.svg',
      payback: 'situational',
    ),
    MarketItemSpec(
      itemId: 'stone_fountain',
      itemType: OwnedItemType.decoration,
      name: 'Stone Fountain',
      priceCoins: 500,
      description: '+1 coin per healthy harvest, per plot, per cycle',
      iconAsset: 'assets/icons/decorations/fountain.svg',
      payback: '~20 cycles for a 5-plot player',
    ),
    MarketItemSpec(
      itemId: 'wishing_windmill',
      itemType: OwnedItemType.decoration,
      name: 'Wishing Windmill',
      priceCoins: 700,
      description: 'Unplanned bonus pays 25c when harvested (was 15)',
      iconAsset: 'assets/icons/decorations/windmill.svg',
      payback: '~70 cycles · status',
    ),
    MarketItemSpec(
      itemId: 'potted_heirloom',
      itemType: OwnedItemType.decoration,
      name: 'Potted Heirloom',
      priceCoins: 900,
      description: 'All fertilizer prices −20%',
      iconAsset: 'assets/icons/decorations/potted-plant.svg',
      payback: '~10 cycles if you fertilize heavily',
    ),
    MarketItemSpec(
      itemId: 'eternal_sun',
      itemType: OwnedItemType.decoration,
      name: 'Eternal Sun',
      priceCoins: 1500,
      description: '+10% to all healthy harvest coin yields, permanent',
      iconAsset: 'assets/icons/decorations/sun.svg',
      payback: '~50 cycles · prestige',
    ),
    MarketItemSpec(
      itemId: 'crystal_aquifer',
      itemType: OwnedItemType.decoration,
      name: 'Crystal Aquifer',
      priceCoins: 1800,
      description:
          'Carryover well lifts next cycle\'s overall result one tier '
          'if rollover ≥10% of income',
      iconAsset: 'assets/icons/decorations/crystal.svg',
      payback: '~60 cycles for big savers',
    ),
    MarketItemSpec(
      itemId: 'treasure_vault',
      itemType: OwnedItemType.decoration,
      name: 'Treasure Vault',
      priceCoins: 2000,
      description:
          'Barn balance earns +1c per 100c stored each cycle, cap +20',
      iconAsset: 'assets/icons/decorations/safe.svg',
      payback: 'scales with barn size · top-tier prestige',
    ),
  ];

  // ──────── Avatars (one-time, cosmetic + some passives) ────────
  // Default Farmer reuses the existing root `farmer.svg` since the
  // dedicated avatars/farmer-male.svg hasn't been imported yet.
  static const List<MarketItemSpec> avatars = <MarketItemSpec>[
    MarketItemSpec(
      itemId: 'farmer',
      itemType: OwnedItemType.avatar,
      name: 'Default Farmer',
      priceCoins: 0,
      description: 'Cosmetic',
      iconAsset: 'assets/icons/farmer.svg',
    ),
    MarketItemSpec(
      itemId: 'pirate',
      itemType: OwnedItemType.avatar,
      name: 'Pirate Sailor',
      priceCoins: 150,
      description: 'Cosmetic',
      iconAsset: 'assets/icons/avatars/pirate.svg',
    ),
    MarketItemSpec(
      itemId: 'beekeeper',
      itemType: OwnedItemType.avatar,
      name: 'Beekeeper',
      priceCoins: 600,
      description: 'Set bonus payouts +25% while equipped',
      iconAsset: 'assets/icons/avatars/beekeeper.svg',
    ),
    MarketItemSpec(
      itemId: 'forest_elf',
      itemType: OwnedItemType.avatar,
      name: 'Forest Elf',
      priceCoins: 1200,
      description: '+5% yield to all plots while equipped',
      iconAsset: 'assets/icons/avatars/legolas.svg',
    ),
    MarketItemSpec(
      itemId: 'arcane_wizard',
      itemType: OwnedItemType.avatar,
      name: 'Arcane Wizard',
      priceCoins: 2500,
      description:
          '+10% yield, mild stress counts as harvested for combo bonus',
      iconAsset: 'assets/icons/avatars/gandalf.svg',
    ),
  ];

  // ──────── Plot colors (one-time, per-plot swatch) ────────
  static const List<PlotColorSpec> plotColors = <PlotColorSpec>[
    PlotColorSpec(
      itemId: 'plot_soil',
      name: 'Soil brown',
      priceCoins: 0,
      swatchHex: 0xFF8B5E3C,
    ),
    PlotColorSpec(
      itemId: 'plot_loam',
      name: 'Loam',
      priceCoins: 50,
      swatchHex: 0xFFD2B48C,
    ),
    PlotColorSpec(
      itemId: 'plot_clay',
      name: 'Clay',
      priceCoins: 50,
      swatchHex: 0xFFB87333,
    ),
    PlotColorSpec(
      itemId: 'plot_ash',
      name: 'Ash',
      priceCoins: 50,
      swatchHex: 0xFFB2BEB5,
    ),
    PlotColorSpec(
      itemId: 'plot_moss',
      name: 'Moss',
      priceCoins: 50,
      swatchHex: 0xFF6E8B3D,
    ),
    PlotColorSpec(
      itemId: 'plot_snow',
      name: 'Snow',
      priceCoins: 50,
      swatchHex: 0xFFE8EEF4,
    ),
    PlotColorSpec(
      itemId: 'plot_obsidian',
      name: 'Obsidian black',
      priceCoins: 500,
      swatchHex: 0xFF1A1A1A,
      description: 'Chosen plot gets +15% yield (re-assignable)',
    ),
    PlotColorSpec(
      itemId: 'plot_volcanic',
      name: 'Volcanic red',
      priceCoins: 1500,
      swatchHex: 0xFFC84040,
      description: 'Chosen plot: withered treated as mild stress',
    ),
  ];

  // ──────── Helpers ────────

  static CropSetSpec setById(String id) =>
      sets.firstWhere((s) => s.id == id);

  static MarketCropSpec? consumableById(String cropId) {
    for (final spec in consumables) {
      if (spec.cropId == cropId) return spec;
    }
    return null;
  }

  static List<MarketCropSpec> consumablesForTier(CropTier tier) =>
      consumables.where((c) => c.tier == tier).toList(growable: false);
}
