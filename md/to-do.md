# Cropkeep — Open Design Questions

Things that have been deferred from the main design docs. Park them here so they're not forgotten when the rest of the model evolves.

## Market — follow-ups now that the catalog is wired

The Market v1 is in place against [`md/shop.md`](shop.md). The catalog,
purchase flow, and four category pages (Crops / Fertilizers /
Decorations / Skins → Avatar + Plot color sub-tabs) all work end to
end. Open items:

### Equipping flows (Market acquires, other screens equip)

- **Avatar** — Farmer tab's avatar picker (`avatar_picker_sheet.dart`)
  reads `MarketCatalog.avatars`. Today it only swaps between `farmer` /
  `farmer-fl`; needs to surface every avatar with quantity ≥ 1 in
  `owned_items` and write the selection to
  `app_settings.equipped_avatar_id` (column doesn't exist yet — schema
  migration needed).
- **Plot color** — plot create / edit screen in
  [`lib/screens/farm/`](../lib/screens/farm/) needs a color picker that
  reads owned plot colors. Persist to `plots.plot_color_id` (column
  exists). Obsidian black's +15% yield and Volcanic red's
  withered→mildStress effects need to plug into the cycle-close
  calculator.
- **Cosmetic-already-owned tap** — when a user taps an Owned item in
  the Market, currently nothing happens. Should open a small "Already
  owned — equip from X" sheet that deep-links to the relevant tab.

### Set-progress lives on the Farm

- **Set progress UI** belongs on the Farm tab (or the harvest
  summary) — *not* the Market. Set completion fires when all crops in
  a set are PLANTED across plots and all harvest healthy in the same
  cycle. Surface this on the Farm's Crops subpage as a small "Set
  progress" strip or on the harvest close screen.
- The `MarketCatalog.sets` list is the single source of truth — read
  it from the Farm-side UI rather than duplicating.

### Cycle-close calculator

- Implement the reward calculator described in
  [`md/shop.md`](shop.md) §"Per-cycle coin earnings". One
  `CoinLedgerRow` per reason. Hooks needed for every fertilizer
  effect, decoration effect, avatar passive, and plot-color effect
  per [`md/shop.md`](shop.md) §5 stacking rules.
- Tracking the `+50%` per-plot stacking cap requires a per-plot
  modifier summary view — not built yet.

### Schema additions for equipping

- `app_settings.equipped_avatar_id` — currently the column is just
  `avatar_id` (interpreted as both owned & equipped on day 1, since
  there's only the freebie). Rename or add an explicit equipped column.
- `app_settings.equipped_barn_skin_id` — removed from shop.md's Skins
  list, so this can wait until barn skins reappear (if ever).
- `wells.equipped_skin_id` — same story; well skins were dropped from
  the latest shop.md.
- `plots.plot_color_id` — already exists per `plots.dart`. Verify the
  Market's `plot_*` itemIds match what the plot screen expects.

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

### Pack cap UX

- Per-tier pack max from shop.md is wired into
  `MarketRepository.purchase`, but the Market doesn't proactively warn
  the user as stock approaches the cap. Consider a soft warning at
  ≥80% capacity.

### Decoration ordering / sorting

- Decorations list is currently ordered by price ascending (cheap to
  prestige). Consider grouping by effect type (flat coin sources /
  state transforms / global multipliers / etc.) once the list grows.
