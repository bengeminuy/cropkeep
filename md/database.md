# Cropkeep — Database Schema Design (v2)

## Storage approach

Cropkeep is a local-first app — all user data lives on-device in a SQLite database. No server, no sync (for now). The schema favors simplicity and clarity over normalization purity.

Recommended Flutter package: **drift** (formerly moor) — a reactive, typed SQLite wrapper.

### Money representation

All monetary columns (`amount`, `base_amount`, `plot_amount`, `expected_amount`, `surplus`, `total_saved`, etc.) are stored as **`INTEGER` minor units** in the column's currency. The unit is implicit from context: a transaction's `amount` is in its `currency_code`'s minor units, `base_amount` is in the user's base currency's minor units, and so on. The `currencies` table carries a `decimal_places` column that the app uses to format for display and to drive conversions.

Examples:
- NT$3,050.00 with `currencies.decimal_places = 2` → stored as `305000`
- ¥3,000 with `decimal_places = 0` → stored as `3000`
- BD 5.250 with `decimal_places = 3` → stored as `5250`

This avoids floating-point rounding accumulating across many transactions and currency conversions — addition, subtraction, and equality on monetary values are all exact integer math. The only non-integer columns on the money side are **ratios** (exchange rates and the Unplanned plot's income share at close), which remain `REAL` since they're not amounts.

Conversion at log time: when a transaction or income arrives in a non-base currency, the app computes `base_amount` by multiplying the source minor units by the cycle's exchange rate and rescaling by the decimal-places delta between the source and the base, then rounding to the nearest integer base minor unit. The rounded result is what gets stored. Per-row rounding error is at most 0.5 base minor units; summing many rows keeps total error well bounded.

---

## Entity overview

17 tables grouped into five conceptual zones:

**Configuration** — app-level settings the user defines once
- `app_settings` (singleton)
- `currencies`

**Cycles** — the harvest cycle is the unit of time everything else hangs off
- `cycles`
- `cycle_summaries`
- `exchange_rates`

**Income** — wells, income arrivals, the bonus pool, and the savings barn
- `wells`
- `income_entries`
- `bonus_allocations`
- `savings_barn`

**Expenses** — plots, the transactions that water them, and the frozen per-plot harvest record
- `plots`
- `transactions`
- `plot_cycle_results`
- `plot_fertilizer_applications`

**Game** — the reward, market, and progression layer
- `coin_ledger`
- `badges_earned`
- `crops_catalog`
- `owned_items`

---

## Configuration zone

### `app_settings`

Singleton table for global user preferences.

```sql
CREATE TABLE app_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    farmer_name TEXT NOT NULL,
    avatar_id TEXT NOT NULL,
    base_currency_code TEXT NOT NULL,
    onboarding_completed INTEGER NOT NULL DEFAULT 0,
    farmer_level INTEGER NOT NULL DEFAULT 1,
    farmer_xp INTEGER NOT NULL DEFAULT 0,
    coins_balance INTEGER NOT NULL DEFAULT 0,
    notifications_enabled INTEGER NOT NULL DEFAULT 1,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (base_currency_code) REFERENCES currencies(code)
);
```

### `currencies`

```sql
CREATE TABLE currencies (
    code TEXT PRIMARY KEY,
    symbol TEXT NOT NULL,
    name TEXT NOT NULL,
    decimal_places INTEGER NOT NULL CHECK (decimal_places >= 0 AND decimal_places <= 4),
    is_base INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    display_order INTEGER NOT NULL DEFAULT 0
);
```

Only one currency has `is_base = 1`. `is_active` allows soft-disabling without losing historical data. `decimal_places` is the count of fractional digits — 2 for USD/NTD/EUR, 0 for JPY/KRW, 3 for BHD/KWD. It's the only piece of metadata needed to interpret integer minor units back into the displayed amount.

---

## Cycles zone

### `cycles`

```sql
CREATE TABLE cycles (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    start_date INTEGER NOT NULL,
    end_date INTEGER NOT NULL,
    state TEXT NOT NULL CHECK (state IN ('active', 'completed', 'archived')),
    label TEXT,
    created_at INTEGER NOT NULL,
    completed_at INTEGER
);

CREATE INDEX idx_cycles_state ON cycles(state);
CREATE INDEX idx_cycles_dates ON cycles(start_date, end_date);
```

Only one cycle can be `active` at a time.

### `cycle_summaries`

Captures the end-of-cycle financial outcome. Written once when a cycle transitions from `active` to `completed`. Powers the harvest history view and the overall harvest reward logic.

```sql
CREATE TABLE cycle_summaries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cycle_id INTEGER NOT NULL UNIQUE,
    total_foundation_income INTEGER NOT NULL,  -- base currency minor units, computed per the foundation income rule (logged sum if any, else expected)
    total_bonus_income INTEGER NOT NULL,       -- base currency minor units, sum of non-deleted bonus income_entries this cycle
    total_spent_planned INTEGER NOT NULL,      -- base minor units, sum of transactions on regular plots
    total_spent_unplanned INTEGER NOT NULL,    -- base minor units, sum of transactions on Unplanned plot
    total_spent INTEGER NOT NULL,              -- base minor units, convenience sum
    surplus INTEGER NOT NULL,                  -- base minor units, total_income − total_spent (can be negative)
    result_tier TEXT NOT NULL CHECK (result_tier IN (
        'excellent',      -- spent < 70% of foundation
        'solidly_positive', -- spent 70-90% of foundation
        'barely_positive', -- spent 90-100% of foundation
        'negative'        -- spent > foundation
    )),
    overall_bonus_coins INTEGER NOT NULL DEFAULT 0,
    per_plot_coins INTEGER NOT NULL DEFAULT 0,
    surplus_saved_coins INTEGER NOT NULL DEFAULT 0,
    total_coins_earned INTEGER NOT NULL DEFAULT 0,
    amount_saved INTEGER NOT NULL DEFAULT 0,         -- base minor units
    amount_rolled_to_next INTEGER NOT NULL DEFAULT 0, -- base minor units
    completed_at INTEGER NOT NULL,
    FOREIGN KEY (cycle_id) REFERENCES cycles(id) ON DELETE CASCADE,
    CHECK (
        (surplus <= 0 AND amount_saved = 0 AND amount_rolled_to_next = 0)
     OR (surplus > 0  AND amount_saved >= 0 AND amount_rolled_to_next >= 0
                      AND amount_saved + amount_rolled_to_next = surplus)
    )
);

CREATE INDEX idx_cycle_summary_tier ON cycle_summaries(result_tier);
```

**Why a separate table from `cycles`?** A cycle exists from the moment it starts (active state) but its summary only exists once it's completed. Splitting them keeps the active cycle row clean and makes the harvest history query a simple join.

`cycle_summaries` holds only cycle-level scalars — totals, tier, coin counts, user decisions. Per-plot frozen state lives in `plot_cycle_results` (in the Expenses zone). Together they give the Harvest History view everything it needs: the outer-ring tier from `cycle_summaries.result_tier`, the inner-cell per-plot health from `plot_cycle_results`.

### `exchange_rates`

```sql
CREATE TABLE exchange_rates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cycle_id INTEGER NOT NULL,
    from_currency_code TEXT NOT NULL,
    to_currency_code TEXT NOT NULL,
    rate REAL NOT NULL,
    set_at INTEGER NOT NULL,
    FOREIGN KEY (cycle_id) REFERENCES cycles(id) ON DELETE CASCADE,
    FOREIGN KEY (from_currency_code) REFERENCES currencies(code),
    FOREIGN KEY (to_currency_code) REFERENCES currencies(code),
    UNIQUE (cycle_id, from_currency_code, to_currency_code)
);

CREATE INDEX idx_rates_cycle ON exchange_rates(cycle_id);
```

---

## Income zone

### `wells`

Both foundation and bonus wells in one table.

```sql
CREATE TABLE wells (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    well_type TEXT NOT NULL CHECK (well_type IN ('foundation', 'bonus')),
    is_carryover INTEGER NOT NULL DEFAULT 0,
    currency_code TEXT NOT NULL,
    expected_amount INTEGER,              -- in the well's currency_code minor units
    estimate_min INTEGER,                 -- in the well's currency_code minor units
    estimate_max INTEGER,                 -- in the well's currency_code minor units
    well_icon_id TEXT NOT NULL DEFAULT 'default',
    is_active INTEGER NOT NULL DEFAULT 1,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (currency_code) REFERENCES currencies(code),
    CHECK (is_carryover = 0 OR well_type = 'bonus'),
    CHECK (well_type <> 'foundation' OR expected_amount IS NOT NULL)
);

CREATE INDEX idx_wells_type ON wells(well_type);
CREATE INDEX idx_wells_active ON wells(is_active);
CREATE UNIQUE INDEX idx_wells_carryover ON wells(is_carryover) WHERE is_carryover = 1;
```

**Design notes:**
- Exactly one well has `is_carryover = 1` — the system-managed **Carryover** well, seeded at onboarding alongside the Unplanned plot. It receives the previous cycle's rolled-over surplus as an auto-logged income entry at the start of each new cycle.
- The Carryover well is always of type `bonus` (enforced by CHECK) and cannot be archived or deleted by the user (enforce in application code).
- Foundation wells must have a non-null `expected_amount` (CHECK enforced). Bonus wells may have `expected_amount` null and instead carry optional `estimate_min` / `estimate_max` for the user's own reference.

**Foundation income computation rule.** For each foundation well in a given cycle, the well's contribution to that cycle's income is:

- `SUM(income_entries.base_amount)` over non-deleted entries for this well in this cycle, **if at least one such entry exists**
- otherwise, `expected_amount` converted to base currency

This is the single rule used both for the live projected overall result during the cycle and for the closing `cycle_summaries.total_foundation_income`. The model is "default trust, override on log" — the user doesn't have to log fixed income for it to count, but if they do log (a short paycheck, a one-off bonus on the salary well, a missed arrival), the logged sum becomes truth and overrides the expected amount for that cycle.

Biweekly / semi-monthly salaries: the user logs each arrival as a separate income entry; the sum becomes the well's contribution. While only partial arrivals have been logged, the projection temporarily underestimates — the Foundation Income Review at cycle close is the safety net for any missed logs.

### `income_entries`

Every actual income arrival. Supports edit and soft-delete.

```sql
CREATE TABLE income_entries (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    well_id INTEGER NOT NULL,
    cycle_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,              -- in currency_code minor units
    currency_code TEXT NOT NULL,
    base_amount INTEGER NOT NULL,         -- in base currency minor units
    exchange_rate REAL NOT NULL,
    received_at INTEGER NOT NULL,
    note TEXT,
    is_system_generated INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    edited_at INTEGER,
    deleted_at INTEGER,
    FOREIGN KEY (well_id) REFERENCES wells(id),
    FOREIGN KEY (cycle_id) REFERENCES cycles(id),
    FOREIGN KEY (currency_code) REFERENCES currencies(code)
);

CREATE INDEX idx_income_cycle ON income_entries(cycle_id);
CREATE INDEX idx_income_well ON income_entries(well_id);
CREATE INDEX idx_income_received ON income_entries(received_at);
CREATE INDEX idx_income_deleted ON income_entries(deleted_at);
```

All read queries filter `WHERE deleted_at IS NULL` for active entries. The "Recently removed" view in the Ledger filters by `deleted_at IS NOT NULL AND deleted_at > (now - 30 days)`.

A background job hard-deletes rows where `deleted_at < (now - 30 days)`.

**Locked entries.** Rows with `is_system_generated = 1` cannot be edited or soft-deleted (enforce in application code). The only producer of system-generated entries is the cycle-close flow, which logs the rollover amount as an income entry on the Carryover well. The amount is derived from the user's surplus-split decision and is fixed at that moment — there is no edit path.

### `bonus_allocations`

Records of bonus pool funds moved to a specific plot during the cycle. This is the only in-cycle action available on the bonus pool — every other surplus disposition is decided at cycle close.

```sql
CREATE TABLE bonus_allocations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cycle_id INTEGER NOT NULL,
    target_plot_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,        -- in base currency minor units
    allocated_at INTEGER NOT NULL,
    FOREIGN KEY (cycle_id) REFERENCES cycles(id),
    FOREIGN KEY (target_plot_id) REFERENCES plots(id)
);

CREATE INDEX idx_bonus_alloc_cycle ON bonus_allocations(cycle_id);
```

There is no per-transaction interaction between the bonus pool and emergencies, and no in-cycle "save to barn" or "convert to coins" action. Anything left in the bonus pool at cycle close folds into the surplus reconciliation:

`surplus = total_foundation_income + total_logged_bonus_income − total_spent (including emergencies and Unplanned)`

If positive, the user splits the surplus between **Save** (adds to barn + earns coins) and **Roll over** (becomes an income entry on the Carryover well for the next cycle).

Current bonus pool balance = `SUM(income_entries.base_amount for bonus wells in current cycle, where deleted_at IS NULL) − SUM(bonus_allocations.amount in current cycle)`.

### `savings_barn`

A simple accumulator. The barn is a single tracked balance that grows when positive cycles save into it.

```sql
CREATE TABLE savings_barn (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    total_saved INTEGER NOT NULL DEFAULT 0, -- in base currency minor units
    barn_skin_id TEXT NOT NULL DEFAULT 'default',
    last_updated_at INTEGER NOT NULL
);
```

Singleton. The barn balance is incremented at cycle close by `cycle_summaries.amount_saved` when the user chooses to Save part of the surplus. The matching coin reward is recorded as a `surplus_saved` entry in `coin_ledger` — the user gains both the cumulative barn balance *and* spendable coins from the same action.

The barn lives on the **Farmer tab** in the UI (not the Farm/Wells subpage) — it's a long-horizon stat, not something the user checks daily. Withdrawals are intentionally not supported in v1; the barn is psychologically a one-way deposit. A future feature could add a "withdraw" flow that goes through a confirmation step.

---

## Expenses zone

### `plots`

```sql
CREATE TABLE plots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    kind TEXT NOT NULL DEFAULT 'discretionary' CHECK (kind IN ('discretionary', 'fixed_obligation')),
    budget_amount INTEGER,          -- in currency_code minor units; NULL only for the Unplanned plot
    currency_code TEXT NOT NULL,
    crop_type_id TEXT NOT NULL,
    plot_color_id TEXT,
    due_day INTEGER CHECK (due_day IS NULL OR (due_day BETWEEN 1 AND 31)),
    is_unplanned INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (currency_code) REFERENCES currencies(code),
    FOREIGN KEY (crop_type_id) REFERENCES crops_catalog(crop_id),
    CHECK (is_unplanned = 0 OR kind = 'discretionary'),
    CHECK (kind = 'discretionary' OR due_day IS NOT NULL)
);

CREATE INDEX idx_plots_active ON plots(is_active);
CREATE INDEX idx_plots_kind ON plots(kind);
CREATE UNIQUE INDEX idx_plots_unplanned ON plots(is_unplanned) WHERE is_unplanned = 1;
```

**Design notes:**
- Exactly one plot has `is_unplanned = 1`, enforced by the unique partial index
- The Unplanned plot's `budget_amount` is NULL — it has no pre-allocated budget; its in-cycle pressure comes from the free-reservoir calculation, and its harvest-history `final_state` is judged against the user's total income for the cycle (see `plot_cycle_results` below)
- The Unplanned plot cannot be archived (enforce in application code) and is always `discretionary` kind (CHECK enforced)
- Regular plots always have `budget_amount` set
- **Plot kinds:** `discretionary` (default — food, transport, fun money; uses rolling pace) and `fixed_obligation` (rent, loans, subscriptions, fixed bills; pace is irrelevant, scored on logged-vs-expected). Fixed obligation plots require `due_day` (1–31, the expected day of the month payment is due — drives the "Due" indicator on the tile). Discretionary plots may leave `due_day` NULL.

### `transactions`

Adds `is_emergency` flag and edit/soft-delete columns.

```sql
CREATE TABLE transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    plot_id INTEGER NOT NULL,
    cycle_id INTEGER NOT NULL,
    amount INTEGER NOT NULL,              -- in currency_code minor units
    currency_code TEXT NOT NULL,
    base_amount INTEGER NOT NULL,         -- in base currency minor units
    plot_amount INTEGER NOT NULL,         -- in the plot's denomination currency minor units
    exchange_rate REAL NOT NULL,
    spent_at INTEGER NOT NULL,
    note TEXT,
    is_emergency INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    edited_at INTEGER,
    deleted_at INTEGER,
    FOREIGN KEY (plot_id) REFERENCES plots(id),
    FOREIGN KEY (cycle_id) REFERENCES cycles(id),
    FOREIGN KEY (currency_code) REFERENCES currencies(code)
);

CREATE INDEX idx_txn_plot ON transactions(plot_id);
CREATE INDEX idx_txn_cycle ON transactions(cycle_id);
CREATE INDEX idx_txn_spent ON transactions(spent_at);
CREATE INDEX idx_txn_plot_cycle ON transactions(plot_id, cycle_id);
CREATE INDEX idx_txn_deleted ON transactions(deleted_at);
CREATE INDEX idx_txn_emergency ON transactions(is_emergency) WHERE is_emergency = 1;
```

All read queries filter `WHERE deleted_at IS NULL` for active entries.

Emergency transactions are tagged so they can show a small badge in the Ledger and be excluded from the "should this become a recurring category?" suggestion system. The flag has no effect on cycle reconciliation — an emergency expense is still just spending against the Unplanned plot.

**Every plot is monthly.** There is no sub-period bucketing within a cycle — the cycle *is* the period for every plot. The pace formula is just `remaining_budget ÷ days_left_in_cycle`; the health-state mapping is computed against the whole cycle's spend.

Transactions don't carry any "logged on time vs late" flag. The daily-logging habit is driven by the intrinsic feedback loop (watching crops grow, live pace updates) plus the meaningful cycle-end rewards — not by a per-log micro-incentive that would punish legitimate no-spend days or catch-up logging.

### `plot_cycle_results`

One row per (plot, cycle) pair, written once at cycle close and never updated. This is the frozen per-plot record that powers the Harvest History inner cells on the Farmer tab.

```sql
CREATE TABLE plot_cycle_results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cycle_id INTEGER NOT NULL,
    plot_id INTEGER NOT NULL,
    plot_name_snapshot TEXT NOT NULL,
    kind_snapshot TEXT NOT NULL DEFAULT 'discretionary' CHECK (kind_snapshot IN ('discretionary', 'fixed_obligation')),
    crop_type_id_snapshot TEXT NOT NULL,
    plot_color_id_snapshot TEXT,
    is_unplanned INTEGER NOT NULL DEFAULT 0,
    budget_amount_snapshot INTEGER,             -- in base currency minor units, NULL for the Unplanned plot
    currency_code_snapshot TEXT NOT NULL,       -- the plot's denomination at close
    total_spent INTEGER NOT NULL,               -- in base currency minor units
    income_share_at_close REAL,                 -- non-null only for the Unplanned plot: total_spent / total_income (a ratio, stays REAL)
    final_state TEXT NOT NULL CHECK (final_state IN (
        'harvested', 'mild_stress', 'withered', 'dead'
    )),
    completed_at INTEGER NOT NULL,
    FOREIGN KEY (cycle_id) REFERENCES cycles(id) ON DELETE CASCADE,
    FOREIGN KEY (plot_id) REFERENCES plots(id),
    FOREIGN KEY (currency_code_snapshot) REFERENCES currencies(code),
    UNIQUE (cycle_id, plot_id)
);

CREATE INDEX idx_pcr_cycle ON plot_cycle_results(cycle_id);
CREATE INDEX idx_pcr_plot ON plot_cycle_results(plot_id);
CREATE INDEX idx_pcr_final_state ON plot_cycle_results(final_state);
```

**Why snapshot columns?** The user can rename a plot, change its color, edit its budget, or archive it after a cycle closes. The Harvest History must keep showing what was true at the moment of close — otherwise renaming "Food" to "Groceries" today would silently rewrite last year's history. Frozen snapshots are the simplest way to make the history view truthful and self-contained.

**Final state mapping at close** — branches by `kind_snapshot`:

*Discretionary regular plots* — judged against their `budget_amount`:

| Spend / budget | `final_state` |
|---|---|
| ≤ 100% (period ended within budget) | `harvested` |
| 100 – 110% (slightly over) | `mild_stress` |
| 110 – 150% | `withered` |
| > 150% (or budget exhausted before period end) | `dead` |

*Fixed obligation plots* — judged on **logged vs. expected** payment. Pace is irrelevant; what matters is whether the obligation was met. Only what was actually logged counts toward the cycle's `total_spent` (an unpaid loan didn't cost real money), but the per-plot `final_state` reflects whether the user actually met the obligation.

| Logged amount / expected | `final_state` |
|---|---|
| 95 – 105% (paid within tolerance) | `harvested` |
| 75 – 95% or 105 – 125% (soft ceiling — small under/overpay) | `mild_stress` |
| 50 – 75% or 125 – 150% | `withered` |
| < 50% or > 150%, or zero logged | `dead` |

The asymmetric soft-ceiling treatment is intentional: small overpayments (bills that wobble) shouldn't punish the user, but underpaying a fixed obligation is a real problem and surfaces sooner than a discretionary overspend.

*The Unplanned plot* — always `kind = 'discretionary'`, but judged against the user's total income for the cycle (`total_foundation_income + total_bonus_income`) rather than a `budget_amount`. The ratio is recorded in `income_share_at_close`:

| Unplanned spend / total income | `final_state` |
|---|---|
| < 5% | `harvested` |
| 5 – 10% | `mild_stress` |
| 10 – 20% | `withered` |
| > 20% | `dead` |

The thresholds are placeholders, easy to tune. The Unplanned plot has no `budget_amount` to judge against, so its health scales with income — Cropkeep's reading of *"did Unplanned eat into your overall financial health this cycle?"*

### `plot_fertilizer_applications`

Records when a fertilizer was applied to a plot during a cycle. Cycle close reads this table per plot to compute fertilizer-boosted coin yields. One fertilizer per plot per cycle — enforced by the UNIQUE constraint.

```sql
CREATE TABLE plot_fertilizer_applications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cycle_id INTEGER NOT NULL,
    plot_id INTEGER NOT NULL,
    fertilizer_item_id TEXT NOT NULL,       -- references the hardcoded fertilizer catalog (TBD as a table)
    applied_at INTEGER NOT NULL,
    FOREIGN KEY (cycle_id) REFERENCES cycles(id),
    FOREIGN KEY (plot_id) REFERENCES plots(id),
    UNIQUE (cycle_id, plot_id)
);

CREATE INDEX idx_pfa_cycle_plot ON plot_fertilizer_applications(cycle_id, plot_id);
```

The fertilizer catalog itself (names, yield multipliers, prices) is hardcoded in app code for v1. If the catalog grows or needs DB-side queries, it can be promoted to a `fertilizers_catalog` table later — see [to-do.md](to-do.md).

Applying a fertilizer also decrements the corresponding `owned_items.quantity` for that fertilizer.

---

## Game zone

### `coin_ledger`

Adds reasons for new reward sources.

```sql
CREATE TABLE coin_ledger (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cycle_id INTEGER,
    amount INTEGER NOT NULL,        -- positive for earned, negative for spent
    reason TEXT NOT NULL CHECK (reason IN (
        'plot_harvested_healthy',
        'unplanned_healthy_share',        -- Unplanned ended cycle below the 'harvested' threshold (< 5% of total income)
        'cycle_overall_positive',         -- the big overall harvest bonus
        'cycle_combo_bonus',
        'crop_set_bonus',                 -- themed-set bonus when every crop in a set is on a harvested plot
        'surplus_saved',                  -- coin reward for the cycle-close Save action
        'badge_unlocked',
        'level_up_bonus',                 -- coin reward when farmer_level increments (level × 25 coins)
        'market_purchase',
        'manual_adjustment'
    )),
    related_id INTEGER,
    related_type TEXT,
    description TEXT,
    occurred_at INTEGER NOT NULL,
    FOREIGN KEY (cycle_id) REFERENCES cycles(id)
);

CREATE INDEX idx_coin_cycle ON coin_ledger(cycle_id);
CREATE INDEX idx_coin_occurred ON coin_ledger(occurred_at);
CREATE INDEX idx_coin_reason ON coin_ledger(reason);
```

The `cycle_overall_positive` reason is the big one — issued during cycle close when `cycle_summaries.result_tier` is anything other than `negative`. The `crop_set_bonus` reason is issued once per qualifying set per cycle: for each hardcoded set, if every required crop is assigned to at least one plot with `plot_cycle_results.final_state = 'harvested'`, a row is written with `amount = set.bonus_coins`.

### `badges_earned`

```sql
CREATE TABLE badges_earned (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    badge_id TEXT NOT NULL UNIQUE,
    earned_at INTEGER NOT NULL,
    cycle_id INTEGER,
    FOREIGN KEY (cycle_id) REFERENCES cycles(id)
);
```

The catalog of all possible badges is hardcoded in the app. Initial badge candidates:
- `first_excellent_cycle` — first cycle with `result_tier = 'excellent'`
- `three_positive_in_a_row` — three consecutive cycles ending positive
- `barn_milestone_10k` — savings barn reaches NT$10,000 (or equivalent)
- `weathered_the_storm` — closed a cycle net positive overall despite at least one emergency-tagged expense
- `unplanned_master` — Unplanned plot ended `harvested` (< 5% of total income) for 3 consecutive cycles

### XP earning rules and level curve

`app_settings.farmer_xp` and `app_settings.farmer_level` are the long-term progression counters. XP is earn-only — there is no XP-spend mechanic. It rewards consistent engagement with the habit, not micro-actions.

**Earning sources — per cycle (awarded at cycle close):**

| Source | XP |
|---|---|
| Cycle completed (closed the month with the app) | 10 |
| Net positive cycle (any positive tier) | 30 |
| Excellent cycle (top tier, < 70% spent) — stacks with net positive | +50 |
| Each healthy plot at harvest (counted from `plot_cycle_results.final_state = 'harvested'`) | 5 |
| Saving any surplus (whether minimal or large) | 20 |
| Unplanned ended `harvested` (< 5% of total income) | 15 |

**Earning sources — milestones (one-shot, fired when condition is first met):**

| Source | XP |
|---|---|
| Each badge unlocked | 25–100 (per-badge value defined in the hardcoded badge catalog) |
| Barn balance reaches NT$1,000 (or equivalent) | 50 |
| Barn balance reaches NT$10,000 | 200 |
| Barn balance reaches NT$100,000 | 500 |
| Barn balance reaches NT$1,000,000 | 2000 |
| First time a brand-new plot harvests healthy | 10 |

**Level-up formula:**

```
xp_required_for_next_level(current_level) = 100 + (current_level × 50)
```

| Level | XP to next | Cumulative |
|---|---|---|
| 1 → 2 | 100 | 100 |
| 2 → 3 | 150 | 250 |
| 5 → 6 | 300 | 1,000 |
| 10 → 11 | 600 | ~3,300 |
| 20 → 21 | 1,100 | ~12,000 |
| 50 → 51 | 2,600 | ~67,000 |

No level cap.

**Level-up procedure** (when XP is awarded):

1. Increment `farmer_xp` by the awarded amount.
2. Loop while `farmer_xp >= xp_required_for_next_level(farmer_level)`:
   - Subtract the threshold from `farmer_xp`.
   - Increment `farmer_level` by 1.
   - Insert a `coin_ledger` row with `reason = 'level_up_bonus'`, `amount = farmer_level × 25`.
   - Increment `app_settings.coins_balance` by the same amount.
   - Surface the level-up moment in the UI (one celebration per level reached, even if multiple in one award).

Multiple level-ups in a single XP award are possible (rare but worth handling — e.g., unlocking a milestone badge and crossing a barn threshold simultaneously). Each level-up fires its own coin bonus.

**Titles** (cosmetic, hardcoded by level threshold):

| Level | Title |
|---|---|
| 1–4 | Sprout |
| 5–9 | Sapling |
| 10–19 | Tender |
| 20–49 | Steward |
| 50+ | Elder |

Shown next to the level number on the Farmer tab. Users can hide titles if they prefer.

### `crops_catalog`

The set of crops a user can assign to plots. Some are starter (unlocked at onboarding for free); others are paid via Market coins. Lives in the database (not hardcoded in app code) because the starter-vs-paid distinction needs querying and per-crop yield values may evolve.

```sql
CREATE TABLE crops_catalog (
    crop_id TEXT PRIMARY KEY,                                  -- e.g. 'wheat', 'strawberry', 'corn'
    name TEXT NOT NULL,
    base_coin_yield INTEGER NOT NULL,                          -- coins at harvest for a healthy plot using this crop
    is_starter INTEGER NOT NULL DEFAULT 0,
    is_consumable INTEGER NOT NULL DEFAULT 0,                  -- 0 = permanent unlock; 1 = consumed at cycle start
    seed_pack_size INTEGER,                                    -- seeds delivered per purchase; NULL for permanents
    price_coins INTEGER,                                       -- per-pack price for consumables; per-unlock price for paid permanents; NULL if starter
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    CHECK (is_starter = 1 OR price_coins IS NOT NULL),
    CHECK (
        (is_consumable = 0 AND seed_pack_size IS NULL)
     OR (is_consumable = 1 AND seed_pack_size >= 1)
    )
);

CREATE INDEX idx_crops_catalog_starter ON crops_catalog(is_starter);
CREATE INDEX idx_crops_catalog_consumable ON crops_catalog(is_consumable);
```

Every plot is monthly, so crops don't encode a growth cadence — they differ by visual style, `base_coin_yield`, and whether they're permanent or consumable. Seeded with 3 starter (permanent) crops at onboarding — **wheat, apple, potato** — plus the initial catalog of 15 consumable seed-pack crops. Onboarding also inserts an `owned_items` row for each starter so the user can immediately assign them.

**Permanent vs consumable.** Permanent crops (`is_consumable = 0`) are owned-or-not-owned; `owned_items.quantity` stays at 1. Consumable crops (`is_consumable = 1`) ship in seed packs of `seed_pack_size`; buying a pack increments the matching `owned_items.quantity` by that count. At each cycle start the app iterates every active plot whose assigned crop is consumable and decrements that crop's `owned_items.quantity` by 1. If `quantity` would go below 0, the plot's `crop_type_id` is auto-set to `'wheat'` for the new cycle and the user is notified ("Out of strawberry seeds — planting wheat on Food this cycle"). No silent failure; the user always sees what happened.

**Crop sets.** Six themed sets are hardcoded in app code (like badges and farmer titles), not stored as a table — they're a fixed catalog with no user authoring. Each set names a list of required `crop_id`s and a `bonus_coins` amount. Evaluated at cycle close after `plot_cycle_results` are written: for each set, if every required crop is present on at least one plot whose `final_state = 'harvested'` this cycle, insert a `coin_ledger` row with `reason = 'crop_set_bonus'`, `related_type = 'crop_set'`, `related_id` referencing the set's positional index in the hardcoded list (or stored as a `related_set_id` text on a sibling column if added later).

### `owned_items`

Generic inventory — one row per distinct catalog entry the user owns. Covers crops, fertilizers, decorations, and any other Market category.

```sql
CREATE TABLE owned_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_id TEXT NOT NULL UNIQUE,                              -- references hardcoded or DB-side catalog
    item_type TEXT NOT NULL CHECK (item_type IN (
        'crop', 'fertilizer', 'decoration',
        'plot_color', 'well_skin', 'barn_skin',
        'avatar'
    )),
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity >= 0),
    acquired_at INTEGER NOT NULL
);

CREATE INDEX idx_owned_items_type ON owned_items(item_type);
```

Item-type semantics:
- **`crop`, `plot_color`, `well_skin`, `barn_skin`, `avatar`** — one-time unlocks. `quantity` is always 1; presence in the table means owned.
- **`fertilizer`** — consumable. `quantity` is the stock count; decremented by 1 each time a fertilizer is applied (recorded in `plot_fertilizer_applications`). When it hits 0 the row stays (re-purchase increments it).
- **`decoration`** — one-time unlock. Every owned decoration is always active and contributes its passive bonus (no placement state). The decoration effect catalog is hardcoded in app code for v1 — see [to-do.md](to-do.md).

The `coin_ledger.market_purchase` reason still records every Market spend. For inventory traceability, set `related_id = owned_items.id` and `related_type = 'owned_items'`.

**No sell-backs.** Items, once bought, stay owned forever (the row is never deleted). For fertilizers the stock can reach 0 but the row persists. This keeps the economy predictable and matches the user's intent.

---

## Derived data — what's NOT stored

| Derived value | Computed from |
|---|---|
| Current reservoir total | sum of all active foundation wells' `expected_amount` (converted to base) — note: reservoir is the *budget basis* and always uses expected, even if a well's actual logged sum diverges |
| Total allocated | sum of all active regular plots' `budget_amount` (converted to base) — Unplanned excluded |
| Free reservoir | reservoir total − total allocated − sum of Unplanned spending so far this cycle |
| Foundation income for the cycle | per foundation well: `SUM(non-deleted income_entries)` if any exist, else `expected_amount`; then sum across wells (converted to base). Drives both projected overall result and `cycle_summaries.total_foundation_income` |
| Bonus harvest pool balance | sum(bonus income entries this cycle, not deleted) − sum(bonus_allocations this cycle) |
| Plot remaining budget | plot's `budget_amount` − sum of non-deleted transactions on the plot in the current cycle |
| Plot daily pace (discretionary plots only) | remaining budget ÷ days left in cycle |
| Plot health state (discretionary) | function of pace ratio (computed each read) |
| Plot health state (fixed obligation) | function of `SUM(non-deleted transactions this cycle) / budget_amount` plus the `due_day` indicator (Awaiting → Due once `today > due_day` and nothing logged). Pace is NOT used. |
| Unplanned share of income | sum of transactions on Unplanned plot in current cycle ÷ projected total income for the cycle (foundation per the rule + logged bonus) |
| Projected overall result | foundation income for the cycle (per rule above) + logged bonus this cycle − total spent so far (refreshes on every transaction, lets the user see live whether they're tracking positive) |
| Crop available for assignment | exists in `crops_catalog` AND there is a matching row in `owned_items` (item_type = 'crop', item_id = crop_id). For consumables the `owned_items.quantity` must additionally be ≥ 1 at cycle start (otherwise the plot auto-reverts to wheat). |
| Crop set bonus eligibility (per set, per cycle) | for each hardcoded set, every required `crop_id` must appear on at least one row in this cycle's `plot_cycle_results` with `final_state = 'harvested'`. If yes, the set's `bonus_coins` is awarded. |
| XP to next level | `100 + (farmer_level × 50) − farmer_xp` |
| Farmer title | hardcoded mapping from `farmer_level`: 1–4 Sprout, 5–9 Sapling, 10–19 Tender, 20–49 Steward, 50+ Elder |

The **projected overall result** is particularly important — it's what shows in the soil meter as the cycle progresses, giving the user a live preview of whether they're heading for a positive harvest.

---

## Query patterns to optimize for

**1. Render the Farm screen (Crops subpage)**
- Fetch all active plots (`is_active = 1`)
- For each plot, fetch the cycle's non-deleted transactions
- Compute remaining, pace, health state
- Covered by `idx_txn_plot_cycle`

**2. Render the Farm screen (Wells subpage)**
- Fetch active wells grouped by type (the Carryover well sits among bonus wells, visually distinct)
- For each foundation well, check current cycle income_entries
- Sum bonus income entries (including any auto-logged Carryover entry) minus bonus_allocations for pool balance
- The savings barn is *not* rendered here — it lives on the Farmer tab

**3. Render the Ledger**
- Fetch transactions and income_entries for the requested filter
- Always filter `deleted_at IS NULL` unless "Recently removed" is active
- Covered by `idx_txn_spent`, `idx_income_received`, and `idx_txn_deleted`

**4. Cycle close — reconcile, compute summary, snapshot plots, rollover**
- **Reconciliation step (before any math):** prompt the user to add any forgotten transactions. Backdated entries are inserted as normal `transactions` rows scoped to the closing `cycle_id`. Same for missed income — late `income_entries` go in here. No special flag distinguishes catch-up entries from in-cycle ones; the cycle's totals just include them.
- Aggregate transactions and income_entries for the closing cycle
- Compute totals, surplus, result_tier
- For each active plot, compute total_spent and final_state, then insert a `plot_cycle_results` row with frozen snapshot columns. Unplanned uses the % of total income mapping; regular plots use the % of budget mapping. Also records `income_share_at_close` for Unplanned.
- If surplus > 0, user picks the save / rollover split via a single slider
- Write `cycle_summaries` row (including `amount_saved` and `amount_rolled_to_next`)
- Award coins to coin_ledger (per-plot rewards, overall harvest bonus, `unplanned_healthy_share` if applicable, `surplus_saved` if applicable)
- Increment `savings_barn.total_saved` by `amount_saved`
- Create new active cycle and reset plot period state
- If `amount_rolled_to_next > 0`, insert a system-generated income_entry (`is_system_generated = 1`) on the Carryover well, scoped to the new cycle_id
- Existing income entries are not migrated or archived — they remain bound to the cycle in which they arrived; only newly logged entries (including the rollover) get the new `cycle_id`

**5. Render Harvest History (Farmer tab)**
- Fetch `cycle_summaries` rows (newest first) for the outer-ring tier and headline totals
- For each cycle, fetch `plot_cycle_results` for the inner cells (per-plot health, name, color)
- Snapshot columns mean no joins back to `plots` are needed to render — the history is self-contained even if plots get renamed or archived later
- Covered by `idx_pcr_cycle`

---

## Migration strategy

Drift handles schema migrations declaratively. For v2 vs v1:

Additive changes (safe `ALTER TABLE`):
- New columns on existing tables: `edited_at`, `deleted_at`, `is_emergency` on transactions; same edit/delete columns on income_entries; `is_unplanned`, `soft_ceiling` on plots; `kind` and `due_day` on plots; `kind_snapshot` on `plot_cycle_results`
- New tables: `cycle_summaries`, `savings_barn`
- New reasons in `coin_ledger` CHECK constraint (requires migration — CHECK constraints can't be altered, need table recreation)
- New allocation_type in `bonus_allocations` CHECK constraint (same caveat)
- New CHECK constraints on `plots` (kind enum, due_day range, kind/Unplanned mutual exclusion) and on `plot_cycle_results.kind_snapshot` — both require table recreation under SQLite's rules

For the CHECK constraint changes, drift can handle table recreation as part of its migration system. Manually this is `CREATE TABLE new`, `INSERT SELECT`, `DROP TABLE old`, `RENAME`.

---

## What to build first (data layer milestones)

Incremental order:

1. `app_settings` + `currencies` + `crops_catalog` — onboarding cannot proceed without these (the catalog is seeded with starter + initial paid crops)
2. `cycles` — needed before anything financial
3. `wells` (foundation only) + `income_entries` — set the reservoir
4. `plots` (including the seeded Unplanned plot) + `transactions` — core spending loop
5. `wells` (bonus type, including the seeded Carryover well) + `bonus_allocations` — once foundation flow works
6. `cycle_summaries` + `plot_cycle_results` + `savings_barn` — once cycles can close (Save action, rollover, and the per-plot frozen record all depend on the close ritual)
7. `exchange_rates` — once secondary currencies are needed
8. `coin_ledger` + `badges_earned` — game layer
9. `owned_items` + `plot_fertilizer_applications` — Market and inventory last; the app is fully functional without them, they're just the spending side of the coin economy

The app is financially functional after step 4 — game and savings layers can be deferred.
