# Cropkeep — Open Design Questions

Things that have been deferred from the main design docs. Park them here so they're not forgotten when the rest of the model evolves.

## Market — follow-ups now that the catalog is wired

The Market v1 is in place against [`md/shop.md`](shop.md). The catalog,
purchase flow, and four category pages (Crops / Fertilizers /
Decorations / Skins → Avatar + Plot color sub-tabs) all work end to
end. Open items:

### Equipping flows (Market acquires, other screens equip)

- **Cosmetic-already-owned tap** — when a user taps an Owned item in
  the Market, currently nothing happens. Should open a small "Already
  owned — equip from X" sheet that deep-links to the relevant tab.
- **Deep-link from the avatar picker's locked tile to Market > Skins.**
  The picker currently dismisses with an info toast pointing the user
  there manually because RootShell's tab switcher and MarketScreen's
  chip index aren't exposed below the root. Wire a root-scope router
  callback (or InheritedWidget) so the picker can land the user on the
  Skins chip in one tap. The Market-side "Cosmetic-already-owned tap"
  above can reuse the same plumbing.

### Set bonuses paused for v1

Set bonuses are removed from the live economy for v1. The original
design (each themed trio pays 30–120c at cycle close when every crop
in the set is planted across plots and all of them end `harvested`)
remains valid, but pacing a satisfying in-cycle preview around it
turned out to be a deeper design problem than we wanted to ship —
parking it lets the rest of the harvest economy keep moving.

**What was removed (behavior, not schema):**

- The set-bonus accumulator + Beekeeper +25% boost in
  [`CycleRepository._buildPreview`](../lib/data/repositories/cycle_repository.dart).
- `CyclePreview.cropSetBonusCoins` field and all consumers
  (`baselineCoins`, the `totalCoins` sum, the per-plot total written
  to `cycle_summaries`).
- The `coin_ledger` write with `reason = 'crop_set_bonus'`.
- The "Crop set bonus" line on
  [`cycle_transition_screen.dart`](../lib/screens/cycle/cycle_transition_screen.dart).
- Beekeeper's avatar passive — now cosmetic-only. Description in
  [`market_catalog.dart`](../lib/screens/market/market_catalog.dart)
  and the picker's `_passiveLineFor` updated. Price stays at 600c;
  the passive slot is open for re-design when the feature returns.

**What stays dormant (don't touch until build_runner regen works):**

- `MarketCatalog.sets` list and the `setId` field on each consumable
  crop spec — pure metadata, no consumer today, the single source of
  truth when the feature returns.
- `CoinReason.cropSetBonus` enum value and the `'crop_set_bonus'`
  entry in the `coin_ledger` CHECK constraint
  ([`lib/data/tables/coin_ledger.dart`](../lib/data/tables/coin_ledger.dart)).
  Dropping the CHECK string changes the generated CREATE TABLE SQL,
  which requires a `.g.dart` regen, and build_runner 2.15.0 is broken
  on Dart 3.10 (same blocker as the dormant progression columns).

**When set bonuses come back, the open design questions are:**

1. *In-cycle preview UI.* A horizontal "Set progress" strip on the
   Farm > Crops subpage (between `_ReservoirHeroBlock` and
   `_PlotFilterChips`) was the v1 sketch — six cards, each with three
   mini crop icons rendered by projected state (full color =
   projecting `harvested`, amber outline = `mild_stress`, red outline
   = `withered`/`dead`, hollow = not planted), a status line picking
   the highest-leverage action ("Plant 1 more: Corn", "1 plot at
   risk: Food", "Locked in"), sorted leftmost by
   closest-to-completion-that's-still-salvageable. Use the
   `_SamplePlot` list the Crops subpage already computes; don't
   recompute. Buzzing Beehive (fertilizer) treats any final state as
   harvested-equivalent for the set check, so the projection has to
   special-case it.
2. *Beekeeper passive redesign.* "+25% cropSetBonus" was clean
   numerically but invisible until harvest close. Candidates worth
   exploring: a guaranteed flat coin per set planted (visible from the
   moment the strip surfaces), or a different cycle-level boost that
   doesn't depend on sets at all.
3. *Harvest-close surface.* A separate, smaller follow-up showing
   final set outcomes on the cycle transition screen so the player
   sees exactly which sets paid out.

### Cycle-close calculator

Modifier hooks for fertilizers, decorations, and avatar passives are
wired through [`CycleRepository._buildPreview`](../lib/data/repositories/cycle_repository.dart)
and the per-plot helper `_plotHarvestCoinsWithModifiers`. The §5
+50% stacking cap is applied per-plot; Mystic Potion bypasses it;
Stone Fountain / Mushroom Gnome / Wishing Windmill are flat sources
outside the cap; Crystal Aquifer lifts the tier for
`cycleOverallPositive` only; Iron Pitchfork and Arcane Wizard adjust
the combo check; Potted Heirloom discounts fertilizer prices in the
Market view. (Beekeeper's +25% `cropSetBonus` boost was removed
alongside set bonuses — see "Set bonuses paused for v1".)

Remaining items here:

- New ledger reasons would let the UI surface decoration-specific
  bonuses separately (e.g. "Mushroom Gnome bonus" as its own ledger
  row). Currently they fold into `cycleOverallPositive` /
  `unplannedHealthyShare` / `plotHarvestedHealthy` because adding
  enum values + CHECK entries requires a `.g.dart` regen and
  build_runner 2.15.0 is broken on Dart 3.10.
- A per-plot modifier summary view (so the player can see "+45% of
  the +50% cap is in use here") is not yet built. Cap math runs in
  the reward calculator silently.
- Plot-color passives are intentionally absent — plot colors are an
  organizational tool with no economy effect per [`md/shop.md`](shop.md) §4.
- The 2000c prestige decoration slot is open — Treasure Vault was
  dropped from [`md/shop.md`](shop.md) §3 because a barn-balance
  interest mechanic scales wildly across base currencies. Replacement
  needs a currency-agnostic effect.

### Schema additions for equipping

- `app_settings.equipped_avatar_id` — intentionally not adding this.
  The existing `app_settings.avatar_id` column is the equipped slot;
  `CycleRepository._buildPreview` reads it directly to apply each
  avatar's passive at cycle close. Single-equip means one column is
  enough; a separate equipped id would be redundant *and* trigger the
  build_runner 2.15.0 / Dart 3.10 regression for no gain.
- `app_settings.equipped_barn_skin_id` — removed from shop.md's Skins
  list, so this can wait until barn skins reappear (if ever).
- `wells.equipped_skin_id` — same story; well skins were dropped from
  the latest shop.md.

### Asset hygiene per shop.md art constraint

- Rename existing `icons8-*.svg` crop files to drop the `icons8-`
  prefix. Update all references in
  [`lib/screens/market/market_catalog.dart`](../lib/screens/market/market_catalog.dart)
  in the same pass.
- Default Farmer avatar currently reuses
  [`assets/icons/farmer.svg`](../assets/icons/farmer.svg). Add a
  dedicated `assets/icons/avatars/farmer-male.svg` if the existing
  asset doesn't match the icons8 Color style.
- Resolve icons8 attribution for the 15 prefixed crop icons.

### Pricing rebalance

- Numbers in [`md/shop.md`](shop.md) (Common 75c, Uncommon 175c, Rare
  300c) are first-pass placeholders. Tune after playtest using the
  cycle-close ledger.

### Set bonus copy

- The Crops page doesn't show set bonus values (was on the v1 design,
  removed when set progress moved out). Decide whether to surface
  set-bonus values inline (e.g. on hover/tap of the set name) or only
  on the Farm tab.

### Decoration ordering / sorting

- Decorations list is currently ordered by price ascending (cheap to
  prestige). Consider grouping by effect type (flat coin sources /
  state transforms / global multipliers / etc.) once the list grows.

## Plot kinds — investment follow-ups

The `investment` kind is defined in [`md/database.md`](database.md)
(plots / plot_cycle_results CHECK enums, plot kinds design notes,
final-state mapping, derived data). Schema, health-state branch,
new-plot UI, and breakdown copy are all in place. Remaining work:

### UI affordances

- Plot tiles should be visually distinct for investment (currently
  field crops vs orchard for discretionary vs fixed). Candidate
  motif: vines, beanstalks, or a "growth" plant that visibly fills
  upward. Asset choice deferred until the kind ships.

### Reward / coin notes

- Consider whether an investment-only crop set (e.g. "Compound
  growth" — a 3-crop set rewarding three healthy investment plots in
  one cycle) makes sense once the kind has a few cycles of playtest.

## Progression (XP, levels, badges) — removed from v1, schema kept dormant

The XP / level / badge progression layer described in
[`md/database.md`](database.md) §"XP earning rules and level curve" is
not in v1. The Farmer-tab progress ring, the header's level pill, the
`_BadgesSection`, the per-cycle XP awards in
`CycleRepository.closeAndStartNext`, and the `awardXp` / `XpCurve`
helpers have all been removed. Levels stay at 1 / 0 XP — nothing
reads or writes those columns now.

What was intentionally left in place because the build_runner 2.15.0 /
Dart 3.10 regression blocks Drift schema regen:

- `app_settings.farmer_xp` and `app_settings.farmer_level` columns
  (still defined in
  [`lib/data/tables/app_settings.dart`](../lib/data/tables/app_settings.dart)).
- The `badges_earned` table (listed in
  [`lib/data/database.dart`](../lib/data/database.dart) and dumped by
  the data export service). Empty in practice — nothing inserts.
- `CoinReason.badgeUnlocked` and `CoinReason.levelUpBonus` enum
  values, plus the matching `'badge_unlocked'` / `'level_up_bonus'`
  entries in the `coin_ledger` CHECK constraint
  ([`lib/data/tables/coin_ledger.dart`](../lib/data/tables/coin_ledger.dart)).
  Touching the CHECK string changes the generated CREATE TABLE SQL,
  which needs a `.g.dart` regen.

When build_runner is fixed (or when progression actually ships), drop
the table, the enum values, the CHECK entries, and the dormant
columns in one pass and regen.
