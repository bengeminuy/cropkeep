# Cropkeep

A cozy gamified personal finance app for Android and iOS, built with Flutter. Cropkeep reframes budgeting as tending a farm — income streams are wells, budget categories are crop plots, and every transaction waters a crop. Visually inspired by Hay Day: warm, tactile, and cheerful.

The core belief: **people spend more consciously when awareness is a habit, not a chore.** Logging a transaction should feel like watering a crop — small, satisfying, and meaningful.

## Status

Skeleton stage. The four-tab navigation shell and color token system are in place; screens are placeholders.

## Tech

- Flutter (Android + iOS)
- Org id: `com.cropkeep`
- Light-only theme, system default font

## Core principles

1. **Anything you see daily on the Farm is also managed from the Farm.** Wells, plots, and all daily financial objects are created, edited, and removed in place — never buried in a settings menu.
2. **Budget against what you can count on.** Fixed income is the foundation of every budget. Variable income is treated as bonus — never baked into the budget, always a reward to allocate consciously.
3. **The overall outcome matters more than any single plot.** Per-plot discipline is rewarded, but the biggest reward is reserved for ending the cycle positive overall — actually earning more than you spent.

## The farm as a financial model

- **Foundation wells** — reliable income streams that arrive every cycle (salary, rental, pension). These build the reservoir.
- **Bonus wells** — variable income streams (freelance, side hustle, gifts). These fill a separate bonus harvest pool — *never* the reservoir.
- **The Carryover well** — a special always-present bonus well. Auto-receives any portion of the previous cycle's surplus the user chose to roll over. Cannot be deleted; its incoming amount is fixed at the moment of the previous cycle's close decision.
- **Reservoir** — the cycle's total foundation income, in base currency. The basis for all plot allocation.
- **Bonus harvest pool** — accumulated bonus income (including the Carryover well's seeded amount), waiting to be consciously allocated.
- **Crop plots** — budget categories, each carved out of the reservoir.
- **The Unplanned plot** — a special always-present plot for uncategorized spending. No pre-allocated budget; its end-of-cycle health is judged against total income (the more you spend here as a share of what you earned, the worse it harvests). Cannot be deleted.
- **The savings barn** — cumulative long-term savings, decided at each cycle close. Lives on the Farmer tab; grows over time.
- **Transactions** — watering the crops or filling the wells.

Total plots cannot exceed the reservoir (foundation only). Variable income is never assumed.

### Foundation wells

Reliable, recurring income the user can count on: salary, rental, pension, regular allowance.

- Each foundation well has a name, a fixed expected amount per cycle, and a currency. There's no expected arrival date — the user logs whenever it suits them, or not at all.
- The expected amount is **assumed received** at its full value for budgeting (reservoir allocation). The user does *not* have to log arrival for the income to count.
- Logging arrival is optional — but **if the user does log, the logged amount becomes truth for that cycle's harvest reconciliation**, overriding the expected amount. The rule is: per foundation well per cycle, the cycle's contribution = sum of logged arrivals if any exist, otherwise expected. This is the escape hatch for when fixed income turns out to be unreliable — log a short paycheck or a missed arrival and the harvest math respects what actually happened.
- Reservoir allocation continues to use `expected_amount` regardless, since the reservoir is what the user *budgeted against* at cycle start. The override only affects the actual-income side of the harvest result.
- The **Foundation income review** in the harvest transition surfaces every foundation well with its expected and logged totals — last chance to log a forgotten arrival or adjust before the cycle closes.
- **Principle:** fixed income shouldn't be a chore to record. No timing pressure, no late penalties. The default is trust; the override is intentional.

### Bonus wells

Variable, unpredictable income: freelance gigs, side projects, gifts, irregular work.

- Each bonus well has a name, a currency, and optionally a rough estimate range (e.g. *$500–1000 USD*) — for the user's own reference only.
- Bonus wells do **not** contribute to the reservoir and do **not** affect plot allocation.
- **Bonus income must be logged on arrival to count anywhere.** Un-logged bonus is invisible to the app: it doesn't fill the bonus harvest pool, doesn't contribute to the harvest reconciliation, and doesn't earn any coin rewards. This is the natural pressure that keeps variable income recorded — the opposite default from foundation wells.
- When the user logs bonus income, it flows into the **bonus harvest pool** — a separate accumulator visible on the Wells subpage.

### The bonus harvest pool

A dedicated pool accumulating all bonus income for the current cycle, including any rollover from the previous cycle's Carryover well. During the cycle, the user has one action:

- **Add to a plot** — increase a specific crop's budget this cycle (e.g. freelance income → food plot for a grocery splurge)

Everything else — saving, rolling over, the long-term decisions — happens at cycle close as part of the surplus split, not as a mid-cycle scramble. Anything left in the pool at cycle close folds into the surplus reconciliation.

### The reservoir math

```
RESERVOIR (foundation only)
Total:       NT$70,800   ← sum of all foundation wells
Allocated:   NT$48,000   ← total plot budgets
Free:        NT$22,800

BONUS HARVEST POOL
Accumulated: NT$8,400    ← variable income received this cycle
```

Clean and simple. No confidence tiers, no "budget against expected" toggle. The structure itself enforces healthy budgeting.

### Budgets: crop plots

- Each category becomes a crop plot. The plot tile shows: total remaining, daily pace (remaining ÷ days left in cycle), and a crop state.
- **Every plot is monthly.** A cycle is one month long; that's the period every plot is judged against. No weekly or daily plot frequencies — most people think monthly, and the simpler model avoids forcing a sub-period decision at plot creation.
- Crops still vary in visual style and per-harvest coin yield (different crop types unlock in the Market) — they no longer differ in growth speed.
- Budgets can be denominated in any configured currency, not just the base.

### Plot kinds: discretionary vs. fixed obligation

Plots come in two kinds, chosen at creation. Both carve their `budget_amount` out of the reservoir; they differ in how the budget is spent and how the plot is scored.

- **Discretionary** (default — food, transport, fun money) — you spend gradually across the cycle. Uses the rolling pace model below: a budget you whittle down, paced day by day.
- **Fixed obligation** (rent, loans, subscriptions, fixed bills) — a known amount paid in one or a few transactions. Pace is irrelevant: paying NT$15k rent on the 5th isn't "exhausting the budget too early" — it's exactly what was supposed to happen.

Fixed obligation plots have their own state machine:

| State | Condition |
|---|---|
| Awaiting | Cycle started, no payment logged |
| Due | Past expected due day, still unpaid (gentle yellow nudge) |
| Paid | Logged amount within tolerance of the expected budget |
| Underpaid | Logged amount short of expected (cash didn't actually leave) |
| Overpaid | Logged amount above expected (soft ceiling — mild visual nudge, not wilting) |

At cycle close, only what was **actually logged** counts toward total spent (the reservoir math is honest — if you didn't pay your rent, the cash didn't leave your account). But the plot's individual harvest reflects whether the obligation was met:

| Logged amount / expected | `final_state` |
|---|---|
| 95 – 105% | `harvested` |
| 75 – 95% or 105 – 125% | `mild_stress` |
| 50 – 75% or 125 – 150% | `withered` |
| < 50% or > 150%, or zero logged | `dead` |

The asymmetry (over- and underpay both soft-ceilinged in the mild-stress band) is intentional: underpaying a loan is a real problem and surfaces sooner, but small overpayments — common when bills wobble — don't punish the user. Anything wildly off ends `dead`, because the budget was clearly wrong or the obligation went unmet.

### The Unplanned plot

Every farm has one mandatory **Unplanned** plot, seeded during onboarding and impossible to delete. It catches uncategorized spending — emergencies, one-offs, small purchases that don't justify their own category. Visually distinct: a wild patch of mixed wildflowers rather than a tended crop.

- **No pre-allocated budget.** Spending counts against the reservoir as real money leaving the account; the more the user spends on Unplanned, the less free reservoir they see.
- **End-of-cycle health scales with total income** (foundation + logged bonus). The harvest history cell for Unplanned reflects how much of the cycle's earnings it consumed:

| Unplanned spend / total income | Harvest state |
|---|---|
| < 5% | Harvested (healthy) |
| 5 – 10% | Mild stress |
| 10 – 20% | Withering |
| > 20% | Dead |

- The user can see the running ratio in-cycle on the Unplanned tile. If recurring categories start landing here, the app eventually suggests carving one out — but never demands it.
- **Principle:** budgeting should enforce discipline. If the user wants room for "fun" or one-off splurges, those deserve their own plot, allocated up front. The Unplanned plot is for the genuinely unforeseeable — and the harvest math measures whether that genuinely-unforeseeable bucket stayed proportional to what was earned.

### Emergency expenses

The FAB has an **Emergency** toggle in expense mode. When on:

- The transaction is logged to the Unplanned plot and tagged `is_emergency`.
- It's excluded from the "should this become a real category?" suggestion system (so a one-off ER bill or broken laptop doesn't pollute recurring-spend candidates).
- It shows a small badge in the Ledger.

That's it — there's no per-transaction interaction with the bonus pool. An emergency is just a transaction. Whether it broke the month is something the books tell you at cycle end via the **overall harvest result** (total spent vs. total foundation income) — that's the single reconciliation point, not log time.

### Quick-add plots while logging

The FAB's plot selector includes a **+ New plot** option. Tapping it opens a streamlined inline plot creation (name, crop type, budget) and uses the new plot for this transaction immediately. For the moment the user realizes mid-log that this purchase deserves its own category.

### Rolling pace, not hard limits (discretionary plots only)

For **discretionary** plots, every transaction recalculates `remaining budget ÷ days left in cycle`. The crop state reacts to the trajectory, never to a single transaction in isolation:

| State | Condition |
|---|---|
| Seedling | Just created, no spending |
| Growing | Pace ≤ 1.0× original reference |
| Mild stress | Pace 1.0–1.5× original |
| Withering | Pace > 1.5× original |
| Dead | Budget exhausted before cycle ends |
| Harvested | Cycle ended within budget |

Fixed obligation plots ignore pace entirely — their state machine is described in the Plot kinds section above.

## Editing and soft-deleting transactions

The Ledger is supposed to be the honest record of what happened, so transactions can be corrected but never silently erased.

- **Edit** — tap a transaction in the Ledger or in a plot's detail view to open an edit sheet (same fields as the FAB: amount, currency, plot, note). The `id` stays the same; an `edited_at` timestamp is added.
- **Soft delete** — long-press a transaction → "Remove this transaction." The row gets a `deleted_at` timestamp, is hidden from the Ledger, and excluded from all calculations, but stays in the database.
- **Recently removed** — a Ledger filter shows soft-deleted entries from the last 30 days with a restore option. After 30 days a background job hard-deletes them.

The same edit / soft-delete pattern applies to income entries — with one exception. **System-generated income entries** (the Carryover well's opening amount each cycle) are locked: no edit, no delete. They're a derived consequence of the previous cycle's surplus split and fixed at that moment.

**Why not free deletion?** Two reasons: (1) it would let users game the system retroactively — making a withering plot healthy again by erasing the transactions that caused it; (2) the Ledger only works as a trustworthy record if history can't be silently rewritten. The 30-day soft delete is the compromise — recoverable for genuine mistakes, not a tool for erasing financial reality.

## Multi-currency

- **Base currency** set once at onboarding. All reservoir and summary totals are in base.
- **Secondary currencies** enabled in Settings; available as denominations for wells, plots, and individual transactions.
- **Exchange rates** are cycle-level (one rate per currency pair, applied to every well/plot/transaction in that currency). They're set and reviewed during the **harvest cycle transition** at the start of each new cycle, then locked for the duration. Transactions always show both original and converted amounts.

## Reward economy

Rewards are layered so per-plot discipline is encouraged but the overall outcome is what gets the biggest celebration.

### Per-plot rewards (small, frequent)

- Ending a budget period with a healthy or harvested crop
- The Unplanned plot ending the cycle below 5% of total income

### Overall harvest bonus (large, monthly)

The biggest reward is reserved for ending the cycle **net positive overall** — total spent (across all plots, Unplanned included) ≤ **total income**, where total income = foundation (auto-counted) + bonus actually recorded this cycle. Tiered by spend as a percentage of total income:

| Tier | Spent (of total income) | Reward |
|---|---|---|
| Just barely positive | 90–100% | Modest bonus |
| Solidly positive | 70–90% | Good bonus |
| Excellent month | < 70% | Large bonus + special badge |

This split is intentional: plots are sized against the **foundation only** (you don't budget around income you can't count on), but the harvest reconciles against **foundation + recorded bonus** (a freelance check that actually arrived is real money that covered your spending). A user can have plots withering and still end the month net positive — and that deserves recognition. The app cares about the holistic outcome, not just per-category discipline.

### Crop set bonuses (at cycle close)

Six themed crop sets (Grain trio, The Orchard, Veggie patch, Berry medley, Nightshade, Tropical trio) award a coin bonus when every crop in the set is assigned to a plot that ended the cycle **harvested** (healthy). A single stressed, withered, or dead plot in the set means no bonus that cycle. Sets vary in difficulty and reward: the easiest set is built entirely from starters plus low-tier consumables; the hardest requires three rare consumables. Sets are the long-term collection goal that keeps the catalog meaningful years in.

### Surplus saved at cycle close

Choosing to Save part of the cycle's surplus (rather than rolling all of it into next month's spendable budget) earns additional coins. The barn grows by the saved amount; the coin reward is on top. The game economy structurally rewards long-term saving over deferred spending.

### Coins are spent on

Three primary Market categories:

- **Crops** — three starters (wheat, apple, potato) are unlocked at onboarding for free as **permanent** crops, flat yield, no recurring cost. Every other crop is a **consumable seed pack**: buy a pack of N seeds with coins; at the start of each cycle, every plot assigned that crop consumes one seed. Consumable yields are higher than starters but vary by tier — and because the seed costs against the yield, a withered or dead plot loses money on the seed. If a plot's assigned crop runs out of stock, the plot auto-reverts to wheat at cycle start with a notification. Crops also unlock **set bonuses** at cycle close (see below).
- **Fertilizers** — consumables. Apply one to a plot any time during a cycle (one per plot per cycle) and it boosts that plot's coin yield at harvest. Stock is tracked in inventory.
- **Decorations** — one-time purchases. Every owned decoration is always active and contributes a passive farm-wide bonus (no placement step). Effect details and pricing TBD.

Plus skins (plot color, well, barn) and avatar unlocks. Plots themselves are not gated by the Market — they're the core budgeting primitive and the user can create as many as they need from the start. Crops are coin-only at any farmer level; **farmer-level gates apply only to the truly cosmetic Market items** — decorations, skins, and avatars. Purchases are final; there is no sell-back.

## Farmer XP and levels

Alongside coins (the spendable Market currency), the farmer accumulates **XP** — a long-term progression counter that's earned, never spent. Coins drive consumption; XP marks the timeline of how long you've been tending a healthy farm.

XP is awarded at cycle close and at key milestones — not for individual transactions or daily activity. The earning pace is deliberate: a solid net-positive year takes the user to around level 5; five years of consistent positive months gets to roughly level 15. Visible progression early, meaningful achievement at higher levels, no plateau.

**XP sources:**

- **Per cycle (at close):** 10 for completing the cycle, +30 for net positive, +50 more for excellent (top tier), 5 per healthy plot, 20 for saving any surplus, 15 for Unplanned ending below 5% of income.
- **Milestones (one-shot):** 25–100 per badge unlocked (scaled by badge significance), 50/200/500/2000 when the savings barn hits NT$1k/10k/100k/1M, 10 the first time a brand-new plot harvests healthy.

**Level-up formula:** `100 + (current_level × 50)` XP to advance.

| Level milestone | Cumulative XP | Roughly when |
|---|---|---|
| Level 5 | ~1,000 | One year of solid positive cycles |
| Level 10 | ~3,300 | Around 2.5 years |
| Level 20 | ~12,000 | Around 5 years |
| Level 50 | ~67,000 | A long-term partner |

**On level up:**

1. A small coin bonus (level × 25 coins) drops, so the level-up moment is tangible.
2. A short title sits next to the level number on the Farmer tab — *Sprout* (1–4), *Sapling* (5–9), *Tender* (10–19), *Steward* (20–49), *Elder* (50+). Titles can be hidden if the user prefers just the number.
3. Some cosmetic Market items may unlock at higher levels — long-term users get visible flair short-term users haven't earned yet.

The pacing reflects Cropkeep's overall philosophy: this is a tool you use for years, not a daily-streak grinder. Even a tough negative month still earns the cycle-completion 10 XP — showing up matters, even when the math didn't work out.

## Surplus, the savings barn, and the Carryover well

At cycle close, surplus = `total income − total spent` (where total income = foundation income + logged bonus income). If positive, the user splits it between two destinations using one slider — pick how much to Save, and the remainder rolls over (or vice versa):

- **Save** — the amount is added to the **savings barn** *and* the user earns a coin reward. The barn is a cumulative tally of long-term saved value; coins are spendable in-game currency. One action, two effects.
- **Roll over** — the amount is logged as an income entry on the **Carryover well** at the start of the next cycle, where it shows up as already-received bonus on the Wells subpage. From there it behaves like any other bonus income — usable to top up plots mid-cycle, or it folds into next cycle's surplus reconciliation if untouched. The auto-logged entry is **locked** (no edit, no delete) — it's derived from the previous cycle's decision and fixed.

If the cycle ended at or below zero surplus, the split screen doesn't show. The harvest transition surfaces a gentle notification instead — *"You spent slightly more than you brought in this month"* or *"You broke even — close call"* — and moves on.

The savings barn lives on the **Farmer tab** — it's a long-horizon stat, not a daily-visit thing. Cropkeep doesn't move real money; the barn is purely a tracker, and the user's choice to Save is the psychological commitment. Its skin can be upgraded with coins from the Market.

## Navigation

Bottom nav with four tabs and a persistent `＋` FAB above the bar. The FAB is the single most important UX decision — log anything financial from anywhere in under 10 seconds.

**FAB bottom sheet:**

- **Expense mode** — amount → currency → plot selector (with a **+ New plot** option for inline plot creation) → note → confirm. An **Emergency** toggle routes the transaction to the Unplanned plot with the `is_emergency` tag.
- **Income mode** — amount → currency → well selector (foundation or bonus) → note → confirm.

| Tab | Role | Visit frequency |
|---|---|---|
| **Farm** | Default home, two subpages (swipe/segmented control): **Crops** (default) for daily spending awareness, **Wells** for income and the bonus harvest pool. All wells and plots are managed here. | Every open |
| **Ledger** | Plain, ungamified transaction history (expenses / income / all), with edit / soft-delete and a "Recently removed" filter | Weekly or less |
| **Market** | Coin shop — crop types, fertilizers, farm decorations, skins, avatars | ~Monthly |
| **Farmer** | Profile, savings barn, harvest history, badges, app-level settings (base currency, secondary currencies, notifications, reset, data export) | Occasional |

### Farm subpages

- **Crops** — compact reservoir meter (foundation total / allocated / free), grid of crop plot tiles with the Unplanned plot visually distinct (wildflowers). Tap a tile for detail; long-press to edit or remove (Unplanned cannot be removed). "Add plot" tile at the end.
- **Wells** — detailed reservoir meter, prominent bonus harvest pool tile (with a single in-cycle action: **Add to a plot**). Two grids below: foundation wells (name, expected amount, logged-this-cycle total) and bonus wells (name, optional estimate, accumulated this cycle). The **Carryover well** sits among the bonus wells, visually distinct — it's system-managed, its opening income entry is auto-logged from the previous cycle's rollover, and that entry is locked from edits. Tap a well to log income; long-press to edit or remove (Carryover cannot be removed). Each grid ends with an "Add foundation well" / "Add bonus well" tile.

A small dot appears on the Farm tab when the bonus pool sits unallocated above a threshold — a soft nudge to swipe to Wells, never a forced visit.

### Ledger details

- Toggle: All / Expenses / Income
- Search and filter (category/well, currency, date range)
- Special filter: **Recently removed** — last 30 days of soft-deleted entries, with one-tap restore
- Emergency-tagged transactions show a small badge
- No gamification — intentionally calm and plain

### Farmer tab

- Avatar + farmer name + level + title (Sprout / Sapling / Tender / Steward / Elder, optional) + XP progress bar. Tap the avatar to swap between `farmer` and `farmer-fl` (or any unlocked Market avatar).
- **Savings barn** — cumulative long-term saved value, with a per-cycle contribution breakdown. Its skin can be upgraded with coins.
- **Harvest History** — a scrollable timeline of past cycles using two layers: outer ring = overall result tier (excellent / solidly positive / barely positive / negative), inner cells = per-plot health summary
- **Badges** — milestones collected over time
- **Settings** — base currency, secondary currencies, notification preferences, reset (wipes data and restarts onboarding — base currency is locked after onboarding, so changing it requires a full reset), data export, app version

**Key principle:** anything *about the farm itself* — wells, plots, the bonus pool — lives on the Farm tab. The Farmer tab holds the farmer (profile, savings barn, harvest history, badges) and app-level admin. Exchange rates are not in Settings; they belong to the harvest cycle transition.

## Onboarding (one-time, ~5 min)

1. Name your farm — farmer name and avatar. The avatar defaults to the male farmer (`farmer`); female users can switch to `farmer-fl`. Either choice is free; additional avatars unlock later via the Market.
2. Set your base currency
3. Enable any secondary currencies (skip if not needed)
4. Add foundation wells (at least one — your reliable income)
5. Add bonus wells (optional — variable income; can be added later)
6. Set exchange rates (only if step 3 added secondary currencies)
7. Plant your first regular crops (at least one budget category)

The Unplanned plot and the Carryover well are created automatically — both with no configuration needed. Skippable after step 1; everything else can be completed later directly on the Farm tab.

## Harvest cycle transitions

At the end of each cycle, a Harvest Transition runs as a small ritual:

1. **Catch-up step (before any math runs)** — *"Anything you forgot to log this cycle?"* The user can quickly add backdated transactions and missed income arrivals. These count toward this cycle's totals as normal entries. This is the deliberate humane buffer: one explicit reconciliation moment at the end of the month, no shame attached.
2. **Last season's plot summary** — per-plot harvest results, individual coin rewards
3. **Overall harvest result** — total income vs. total spent, surplus amount, tier classification, overall bonus coins, any badges unlocked
4. **Surplus split** — if surplus > 0, one slider: how much to **Save** (barn balance grows, coin reward awarded) vs. **Roll over** to next cycle's Carryover well. Pick one side, the other is inferred. If surplus ≤ 0, a gentle notification appears instead (no split, no penalty).
5. **Foundation income review** — confirm or update each foundation well's expected amount
6. **Exchange rate review** — only if secondary currencies exist
7. **Budget review** — confirm or adjust each plot's budget (defaults to same as last)
8. **Plant** — new cycle begins: crops reset to seedlings, foundation wells to expected, bonus pool emptied except for the Carryover well, which opens with the rolled-over amount auto-logged as a locked income entry

## What Cropkeep is not

- Not a bank sync app. Manual logging is the point — the act is the habit.
- Not a punishment machine. Overspending wilts; it doesn't scold.
- Not a daily check-in app. Quiet days don't need the app.
- Not a tool that asks you to plan around variable income. Bonus income is always a gift, never a forecast.
- Not a rewriter of history. Past transactions can be edited and soft-deleted, but never silently erased.
- Not complex. Onboarding takes five minutes. Daily use takes five seconds.

## The experience, in one paragraph

You set up your farm in five minutes — your salary as a foundation well, maybe a freelance gig as a bonus well, the Unplanned plot already waiting for whatever doesn't fit a category, and five or six regular plots for your spending categories. From that day on, every time money moves you log it. Five seconds. Your crops grow or stress based on your spending pace, plotted against the income you can count on. Freelance work lands in your bonus harvest pool — a gift you can use to top up a plot mid-cycle, or just leave to accumulate. Unexpected expenses go to Unplanned or get tagged emergency. The Farm has two views: Crops for daily awareness, Wells for managing where money comes from. At each cycle's end, healthy crops harvest into per-plot rewards — but the real celebration is the overall harvest: did you earn more than you spent? If yes, one slider decides how much to save into the barn (which grows your savings tally and earns coins) versus how much to roll over to next month's Carryover well. Over months, your farm grows, your savings barn fills (over on the Farmer tab, quiet and patient), your farmer levels up — and somewhere along the way you realize you've been positive overall for three cycles running, not because you were disciplined in some effortful way, but because you were tending something you cared about.

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
