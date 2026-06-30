# Shop catalog

Canonical reference for every Market item in CropKeep. Mirrors the economy spine the cycle-close reward calculator and the Market screen are built against. When catalog values change here, update [`lib/screens/market/market_catalog.dart`](../lib/screens/market/market_catalog.dart) and the `ensureSeeded` resync in [`lib/data/repositories/app_settings_repository.dart`](../lib/data/repositories/app_settings_repository.dart) in the same change.

**Art constraint:** every item's icon must exist in icons8's **Color** style. Verified by checking `https://img.icons8.com/color/96/{slug}.png` returns HTTP 200. SVG export from icons8's web UI, saved as `{slug}.svg` (no prefix). Existing `icons8-*.svg` files in [`assets/icons/`](../assets/icons/) should be renamed to drop the prefix as the catalog wires up.

---

## Per-cycle coin earnings

The cycle-close calculator emits one `CoinLedgerRow` per reason and a final delta on `AppSettings.coinsBalance`. Reasons defined in [`lib/data/tables/coin_ledger.dart`](../lib/data/tables/coin_ledger.dart).

| Reason | Formula | Typical value |
|---|---|---|
| `plotHarvestedHealthy` | `crop.baseCoinYield × stateMultiplier` — harvested=1.0, mildStress=0.5, withered=0.0, dead=0.0 | Starter=5, Common=25, Uncommon=40, Rare=75 |
| `unplannedHealthyShare` | flat: harvested=15, mildStress=5, else 0 | 15 |
| `cycleOverallPositive` | excellent=40, solidlyPositive=20, barelyPositive=10, negative=0 | 20 |
| `cycleComboBonus` | +15 if all budgeted plots ≥ mildStress; +25 if all harvested | 15–25 |
| ~~`cropSetBonus`~~ | **paused for v1** — see [`md/to-do.md`](to-do.md) §"Set bonuses paused for v1" | — |
| `surplusSaved` | `floor(coinsSavedToBarn / 10)`, capped at +50/cycle | 0–50 |
| `badgeUnlocked` | 25 per first-time badge | episodic |
| `levelUpBonus` | `50 × newLevel` | episodic |

**Anchor:** a typical good cycle (5 plots, all ≥ mildStress, Unplanned harvested, solidlyPositive tier) earns **100–200 coins**.

---

## 1. Crops

Consumable seed packs. Each plot consumes 1 seed per cycle it's active for, deducted at the moment of planting — mid-cycle creation (or crop reassignment) pays the seed up-front, then cycle start pays again for every subsequent cycle the plot persists. No refund on plot removal or crop reassignment. See [`md/database.md`](database.md) §"Two seed-consumption points" for the full rule.

Harvested healthy = full yield, mildStress = half yield, withered/dead = 0. Set bonuses are **paused for v1** — see [`md/to-do.md`](to-do.md) §"Set bonuses paused for v1". The `MarketCatalog.sets` catalog and the `setId` field on each crop stay dormant until the feature returns.

| Tier | Price | Pack | Yield/seed |
|---|---|---|---|
| Starter (Wheat / Apple / Potato — free) | 0 | ∞ | 5 |
| Common (Corn / Barley / Carrot / Lettuce) | 75c | 5 | 25 |
| Uncommon (Peach / Pear / Tomato / Eggplant / Bell pepper) | 175c | 5 | 40 |
| Rare (Strawberry / Raspberry / Blueberry / Mango / Orange / Pineapple) | 300c | 5 | 75 |

No inventory cap — players can hoard packs freely.

### Sets (paused for v1)

Set bonuses are paused for v1 — the catalog below is preserved as the
single source of truth for when the feature returns, but no coins are
awarded today. See [`md/to-do.md`](to-do.md) §"Set bonuses paused for
v1" for the rationale and what's needed to bring them back.

| Set | Bonus (when re-enabled) | Crops |
|---|---|---|
| Grain trio | 30c | Wheat, Corn, Barley |
| The Orchard | 40c | Apple, Peach, Pear |
| Veggie patch | 60c | Potato, Carrot, Lettuce |
| Berry medley | 60c | Strawberry, Raspberry, Blueberry |
| Nightshade | 60c | Tomato, Eggplant, Bell pepper |
| Tropical trio | 120c | Mango, Orange, Pineapple |

Crop icons already exist under [`assets/icons/crops/`](../assets/icons/crops/).

---

## 2. Fertilizers

Consumables, applied mid-cycle. One per plot per cycle (enforced by `unique(cycleId, plotId)` in `plot_fertilizer_applications`).

| Item | Price | Effect | Icon |
|---|---|---|---|
| Fertilizer Mix | 20c | +15% coin yield on harvest | `fertilizer` |
| Compost Heap | 30c | +25% coin yield on harvest | `compost-heap` |
| Liquid Boost | 45c | +35% coin yield on harvest | `liquid-fertilizer` |
| Pumpkin Bloom | 60c | +50% coin yield on harvest | `pumpkin` |
| Storm Umbrella | 80c | mildStress treated as harvested for that plot's coin yield | `umbrella` |
| Buzzing Beehive | 90c | +25% coin yield AND plot is stress-proof (any final state pays as if harvested healthy) | `beehive` |
| Faerie Reviver | 120c | Withered → mildStress (recovers 50% yield) | `fairy` |
| Mystic Potion | 200c | +100% yield, but plot must finish harvested or yields 0 | `mana` |

---

## 3. Decorations

Permanent global passives. Buy once, always active. Unlimited ownership — all stack subject to the per-plot cap in §5.

| Item | Price | Permanent global effect | Payback | Icon |
|---|---|---|---|---|
| Mushroom Gnome | 200c | +5c per cycle if overall positive | ~40 cycles (flavor buy) | `mushroom` |
| Iron Pitchfork | 350c | Withered plots no longer break the combo bonus | situational | `pitchfork` |
| Stone Fountain | 500c | +1c per healthy harvest (per plot, per cycle) | ~20 cycles, 5-plot player | `fountain` |
| Wishing Windmill | 700c | Unplanned bonus pays 25c (was 15) when harvested | ~70 cycles, status | `windmill` |
| Potted Heirloom | 900c | All fertilizer prices −20% | ~10 cycles for fertilizer-heavy players | `potted-plant` |
| Eternal Sun | 1500c | +10% to all `plotHarvestedHealthy`, permanent | ~50 cycles, prestige | `sun` |
| Crystal Aquifer | 1800c | Carryover well lifts next cycle's `cycleOverallPositive` by one tier if rollover ≥10% of income | ~60 cycles for big savers | `crystal` |

A top-tier "barn interest" decoration was considered (Treasure Vault,
2000c, +1c per 100c stored) but dropped — the barn is denominated in
the user's base currency, so any payout formula tied to the barn
balance would scale wildly across currencies (USD vs JPY vs PHP). The
2000c prestige slot is open for a currency-agnostic replacement.

---

## 4. Skins

Equipped-only passives. One equipped per slot. Free defaults always exist; cheap items are pure cosmetic; premium items carry passives while equipped.

### Avatar (`OwnedItemType.avatar`) — equipped on `app_settings.equipped_avatar_id`

| Item | Price | Effect | Icon |
|---|---|---|---|
| Default Farmer | 0 | cosmetic | `farmer-male` |
| Pirate Sailor | 150c | cosmetic | `pirate` |
| Beekeeper | 600c | Cosmetic for v1 — passive slot open while set bonuses are paused (was `cropSetBonus` payouts +25%) | `beekeeper` |
| Forest Elf | 1200c | +5% yield to all plots | `legolas` |
| Arcane Wizard | 2500c | +10% yield, mildStress counted as harvested for combo bonus | `gandalf` |

Plot colors are NOT a Market item. They're an organizational tool —
players pick from the full palette in [`lib/theme/plot_swatches.dart`](../lib/theme/plot_swatches.dart)
freely on plot create/edit. No coin gate; no Market entry.

---

## 5. Stacking and caps

Per-plot yield modifiers stack **additively** with a hard **+50% per-plot cap**.

**Counts toward the cap:** Fertilizer Mix (+15%), Compost Heap (+25%), Liquid Boost (+35%), Pumpkin Bloom (+50%), Buzzing Beehive (+25%), Eternal Sun (+10%), Forest Elf (+5%), Arcane Wizard (+10%).

**Special cases:**
- **Mystic Potion (+100%)** bypasses the cap but yields 0 on any non-harvested state.
- **Flat coin sources** live outside the cap: Stone Fountain's +1c/harvest, Mushroom Gnome's +5c, Wishing Windmill's +10c on Unplanned.
- **State-transform sources** also outside the cap: Storm Umbrella (mildStress→harvested), Faerie Reviver (withered→mildStress), Buzzing Beehive (any final state→harvested-equivalent payout).
- **Cycle-level bonuses** are never per-plot and never capped: combo bonus, tier bonus, surplus saved, Iron Pitchfork's combo-protect, Crystal Aquifer's tier lift, Arcane Wizard's combo override. (Set bonus and Beekeeper's +25% boost are paused for v1.)

---

## 6. Trajectory sanity check (first 5 cycles)

Solidly-positive new player. Confirms first purchase happens cycle 1, no dead cycles. Set-bonus column intentionally absent — paused for v1.

| Cycle | Earnings | Spend | End balance |
|---|---|---|---|
| 0 | start | — | 5 |
| 1 | 4 starter harvested (20) + Unplanned (15) + tier (20) + combo (15) = **70** | Corn (75c) | 0 |
| 2 | 3 starter (15) + Corn (25) + Unplanned (15) + tier (20) + combo (15) = **90** | — | 90 |
| 3 | 90 | Carrot (75c) | 105 |
| 4 | 2 starter (10) + Corn + Carrot (50) + Unplanned (15) + tier (20) + combo (15) = **110**; +5 surplus | Barley (75c) | 145 |
| 5 | 1 starter (5) + Corn + Carrot + Barley (75) + Unplanned (15) + tier (20) + combo (15) = **130**; +5 surplus | — | 280 |

**Long-game milestones:** Fertilizer Mix reachable cycle 1, Mushroom Gnome ~cycle 15, first functional skin (Beekeeper 600c) ~cycle 30, Eternal Sun / Arcane Wizard 50+ cycles.

---

## Asset checklist

Each item below is an icons8 Color-style icon, verified at `https://img.icons8.com/color/96/{slug}.png`. Download the SVG export and save to the listed path. Filenames drop the `icons8-` prefix — existing crop/fertilizer files that still carry it should be renamed in the same pass.

### Fertilizers — `assets/icons/fertilizers/`
- [x] `fertilizer.svg` (already present)
- [x] `compost-heap.svg` (already present)
- [x] `liquid-fertilizer.svg` (already present)
- [ ] `pumpkin.svg`
- [ ] `umbrella.svg`
- [ ] `beehive.svg`
- [ ] `fairy.svg`
- [ ] `mana.svg`

### Decorations — `assets/icons/decorations/`
- [x] `mushroom.svg` (already present)
- [x] `pitchfork.svg` (already present)
- [x] `fountain.svg` (already present)
- [x] `windmill.svg` (already present)
- [x] `potted-plant.svg` (already present)
- [x] `sun.svg` (already present)
- [ ] `crystal.svg` (Crystal Aquifer)

### Avatars — `assets/icons/avatars/`
- [ ] `farmer-male.svg` (or reuse existing [`assets/icons/farmer.svg`](../assets/icons/farmer.svg))
- [x] `pirate.svg` (already present)
- [x] `beekeeper.svg` (already present)
- [x] `legolas.svg` (already present, used for Forest Elf)
- [x] `gandalf.svg` (already present, used for Arcane Wizard)

Plot colors are background swatches — no icon downloads needed.
