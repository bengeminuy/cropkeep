# Cropkeep — Open Design Questions

Things that have been deferred from the main design docs. Park them here so they're not forgotten when the rest of the model evolves.

## Market content

### Crop catalog and economy

The structural decisions are made (see [README.md](../README.md) reward economy section):

- **3 permanent starters** (wheat, apple, potato) seeded at onboarding.
- **15 consumable seed-pack crops** across common / uncommon / rare tiers, each in one of six themed sets (Grain trio, The Orchard, Veggie patch, Berry medley, Nightshade, Tropical trio).
- Yield modulation at cycle close: harvested 100% / mild_stress 50% / withered 25% / dead 0%.
- Crops are coin-only at any farmer level.

Still open:

- **Rebalance pack pricing and yields after playtest.** Current placeholders: starter yield 10; common pack 100 coins / 5 seeds at 25 yield; uncommon 175 / 5 at 40; rare 200 / 3 at 75. Set bonuses 30 / 40 / 60 / 60 / 60 / 120. Tune once real coin-earning data exists.
- **Resolve icons8 attribution** for the 15 `icons8-*.svg` crop icons before the Market UI ships.

### Fertilizer catalog
- Decide the initial fertilizer set. Each needs a name, a `yield_multiplier` (e.g., 1.25 for +25%), a price, and a description.
- Decide whether fertilizers stack across cycles (use one this cycle, next cycle you have to buy again) — current schema assumes yes (consumable).
- Decide whether to promote fertilizers to a DB-side `fertilizers_catalog` table or keep hardcoded for v1.

### Decoration catalog and effects
- Decide what kinds of passive bonuses decorations confer. Candidates:
  - Flat coin bonus added to overall harvest bonus
  - Multiplier on `surplus_saved` coin reward
  - Bonus to a specific crop type or category (e.g., +10% yield to all plots using a given crop)
- Decide the initial decoration set, with effect types, effect values, prices, and descriptions.
- Decide whether to promote decorations to a DB-side `decorations_catalog` table or keep hardcoded for v1.

### Pricing tiers
- Coin price tiers for crops, fertilizers, decorations, skins, avatars.
- Balance against the expected coin income per cycle (per-plot rewards + overall harvest bonus + surplus_saved) so a typical positive month buys roughly one mid-tier item.

