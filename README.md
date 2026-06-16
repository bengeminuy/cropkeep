# Cropkeep

A cozy gamified personal finance app for Android and iOS, built with Flutter. Cropkeep reframes budgeting as tending a farm — income streams are wells, budget categories are crop plots, and every transaction waters a crop. Visually inspired by Hay Day: warm, tactile, and cheerful.

The core belief: **people spend more consciously when awareness is a habit, not a chore.** Logging a transaction should feel like watering a crop — small, satisfying, and meaningful.

## Status

Skeleton stage. The four-tab navigation shell and color token system are in place; screens are placeholders.

## Tech

- Flutter (Android + iOS)
- Org id: `com.cropkeep`
- Light-only theme, system default font

## The farm as a financial model

The farm is a direct mapping of how personal finance actually works:

- **Wells** — income streams. Multiple wells, multiple currencies, different schedules. All water flows into one reservoir.
- **Reservoir** — total available budget for the cycle, in base currency. The sum of all confirmed income this period.
- **Crop plots** — budget categories. Each plot is carved out of the reservoir.
- **Transactions** — watering the crops. Spend money → a crop grows. Income arrives → a well fills.

Total plots cannot exceed the reservoir; the app blocks over-allocation before it happens.

### Income: wells and the reservoir

- Each well has a name, expected amount, currency, and schedule (monthly fixed date or irregular).
- Wells in foreign currencies are converted using a per-cycle exchange rate the user sets (auto-fetch planned).
- **Confirmed** income fills the reservoir immediately; **pending** income is shown separately and does not count against the available budget.
- At the start of each cycle, a lightweight income-review screen asks the user to confirm or update each well.

### Budgets: crop plots

- Each category becomes a crop plot. The plot tile shows: total remaining, daily pace (remaining ÷ days left), and a crop state.
- **Budget frequency** maps to crop growth cycle: monthly → slow crops (wheat, sugarcane), weekly → medium (tomatoes, corn), daily → fast (strawberries, herbs).
- Budgets can be denominated in any configured currency, not just the base.

### Rolling pace, not hard limits

After every transaction, `remaining budget ÷ remaining days` recalculates the daily pace. The crop state reacts to the trajectory, never to a single transaction in isolation:

| State | Condition |
|---|---|
| Seedling | Just created, no spending |
| Growing | Pace ≤ 1.0× original reference |
| Mild stress | Pace 1.0–1.5× original |
| Withering | Pace > 1.5× original |
| Dead | Budget exhausted before period ends |
| Harvested | Period ended within budget |

## Multi-currency

- **Base currency** set once at onboarding. All reservoir and summary totals are in base.
- **Secondary currencies** added in Settings; available as denominations for wells, plots, or individual transactions.
- Each cycle locks an exchange rate per currency pair. Transactions always show original and converted amounts.

## Reward economy

**Coins are earned by:** same-day logging, healthy/harvested crops at period end, logging streaks, combo harvests across multiple categories, wells fully filled on time.

**Coins are spent on:** extra plot slots, new crop visuals, well skins, farm decorations.

## Weather

A daily weather condition adds variety without obligation — sunny (normal), rainy (+50% coin bonus on logging), harvest moon (end-of-day bonus if all plots healthy), storm warning (per-category challenge). Weather never punishes.

## Navigation

Bottom nav with four tabs and a persistent `＋` FAB above the bar. The FAB is the single most important UX decision — log expense or income from anywhere in under 10 seconds via a bottom sheet with an Expense/Income toggle.

| Tab | Role | Visit frequency |
|---|---|---|
| **Farm** | Default home — weather, soil meter, crop plot grid | Every open |
| **Ledger** | Plain, ungamified transaction history (expenses / income / all) | Weekly or less |
| **Market** | Coin shop — plot slots, crop types, skins, decorations | ~Monthly |
| **Farmer** | Profile, income wells, harvest history, badges, settings | Occasional |

## Onboarding (one-time, ~5 min)

1. Name your farm — farmer name and avatar
2. Set your base currency
3. Add income wells (at least one)
4. Set exchange rates (only if secondary currencies were added)
5. Plant your first crops (at least one budget category, with sensible defaults suggested)

Skippable after step 1; wells and plots can be added later from the Farmer tab.

## Harvest cycle transitions

At the start of each cycle, a Harvest Transition screen runs as a small ritual: last season's summary → income review → budget review → plant. Crops reset to seedlings, wells reset to empty.

## What Cropkeep is not

- Not a bank sync app. Manual logging is the point — the act is the habit.
- Not a punishment machine. Overspending wilts; it doesn't scold.
- Not a daily check-in app. Quiet days don't need the app.
- Not complex. Onboarding takes five minutes. Daily use takes five seconds.

## Project structure

```
lib/
  main.dart            # CropkeepApp + RootShell (bottom nav)
  screens/             # one file per top-level tab
    farm_screen.dart
    ledger_screen.dart
    market_screen.dart
    farmer_screen.dart
  widgets/             # shared widgets (empty)
  models/              # domain models (empty)
  theme/
    colors.dart        # CropkeepColors — all design tokens
```

## Design system

See [colors.md](colors.md) for the full color token spec and the rules governing each one (greens = healthy, gold = currency, red = warning, blue = premium). Every token in that doc has a matching `static const Color` on `CropkeepColors` in [lib/theme/colors.dart](lib/theme/colors.dart) — always reference colors by semantic name, never by hex.

## Running

```
flutter pub get
flutter run
```

Requires an Android emulator or iOS simulator running. Default tab is **Farm**.
