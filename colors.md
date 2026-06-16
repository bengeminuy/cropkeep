# Cropkeep — Color Design System

Cropkeep is a cozy gamified personal finance app built around a farming metaphor. The visual style is directly inspired by Hay Day: warm, tactile, and cheerful — but clean enough to feel like a modern mobile app. This document defines every color token used in the app and when to use each one.

---

## Design philosophy

- **Light-first.** Surfaces are white or near-white. Cozy comes from warm accent colors and rounded shapes, not dark backgrounds.
- **Restrained palette.** Two or three colors do all the work. Never decorate — every color encodes meaning.
- **Game rules for color.** Green = healthy/on-track. Gold = reward/currency. Red = warning/overspent. Blue = premium. Nothing breaks these rules.

---

## Color tokens

### Backgrounds

| Token | Hex | Usage |
|---|---|---|
| `bg-screen` | `#FAF6EE` | Default page background, list screens, card surfaces |
| `bg-nav` | `#E5D2A8` | Floating-island bottom navigation bar — soft linen tan, light enough that the full-color sticker icons stay clear against it while remaining distinct from the cream screen |
| `bg-plot` | `#D4C8A8` | Plot tile base — the "soil" color for unready/neutral crop cards |
| `bg-plot-ready` | `#D6F0C2` | Plot tile background when a crop is ready to harvest |
| `bg-page-alt` | `#E8EEF4` | Alternative page background for secondary/modal screens |
| `bg-gold-wash` | `#FEF3D0` | Currency pill fill, timer banner, reward notification backgrounds |

---

### Greens (growth & health)

The green family is the app's primary brand color. Use it to signal that something is healthy, on track, or completed.

| Token | Hex | Usage |
|---|---|---|
| `green-primary` | `#5BAF3A` | Active nav icon, "Ready!" status label, avatar ring, CTA buttons, plot progress bars when healthy |
| `green-light` | `#D6F0C2` | Ready plot card background tint |
| `green-hint` | `#E8F5E0` | Quantity badge backgrounds, subtle success tints |

**Rules:**
- `green-primary` is the only green used on interactive elements (buttons, active states).
- `green-light` and `green-hint` are backgrounds only — never use them for text or icons.
- Never use green to mean anything other than "healthy / on track / complete."

---

### Gold (currency & rewards)

Gold is exclusively for anything the player earns, spends, or is rewarded with. It should feel special — don't dilute it by using it decoratively.

| Token | Hex | Usage |
|---|---|---|
| `gold-primary` | `#F0A020` | Coin icon, coin count text, event badge background, XP gain indicators |
| `gold-wash` | `#FEF3D0` | Coin pill border-fill, reward banner backgrounds, timer countdown background |

**Rules:**
- Gold only appears in the context of currency, rewards, or time-limited events.
- Never use gold for general UI decoration or non-reward states.

---

### Alerts & status

| Token | Hex | Usage |
|---|---|---|
| `red-alert` | `#E53030` | Notification badge dots, plot card top-border when overspent/withering, critical warnings |
| `blue-premium` | `#5AACDC` | Premium/diamond currency icon and pill, locked content indicators |

**Rules:**
- `red-alert` is strictly for "something needs attention." Never use it neutrally.
- `blue-premium` is only for the secondary (diamond/gem) currency and locked/premium features.

---

### Typography

| Token | Hex | Usage |
|---|---|---|
| `text-primary` | `#1A1A1A` | Headings, item names, all primary readable text |
| `text-secondary` | `#888888` | Subtitles, metadata, helper labels (e.g. "Traveling Merchant", "Planted on") |
| `text-green` | `#5BAF3A` | "Ready!" labels, quantity highlights (x3, x6), on-track status text |
| `text-gold` | `#F0A020` | Coin amounts, timer countdowns, reward values |
| `text-red` | `#E53030` | Overspent amounts, warning counts, critical status text |
| `text-on-green-btn` | `#FFFFFF` | White text on `green-primary` buttons |
| `text-on-gold-pill` | `#7A5000` | Dark warm brown on gold pill backgrounds — never black |

---

### Borders & dividers

| Token | Hex | Usage |
|---|---|---|
| `border-card` | `#E0D8CC` | Default card border — subtle warm grey |
| `border-plot` | `#C8BA90` | Plot tile dashed border (neutral/growing state) |
| `border-plot-ready` | `#5BAF3A` | Plot tile border when ready to harvest |
| `border-plot-warn` | `#E53030` | Plot tile top-border when overspent/withering |
| `border-gold-pill` | `#F0A020` | Coin currency pill border |
| `border-blue-pill` | `#5AACDC` | Diamond currency pill border |
| `border-divider` | `#EEEBE4` | Horizontal list dividers, section separators |

---

## State mapping for plot tiles

Plot tiles are the core UI unit of Cropkeep. Each tile's color state communicates budget health at a glance.

| Budget state | Background | Border | Status label color |
|---|---|---|---|
| Seedling (just started) | `#D4C8A8` | `#C8BA90` dashed | `#888888` |
| Growing (under 75%) | `#FFFFFF` | `#E0D8CC` | `#888888` |
| Almost full (75–95%) | `#FFFBE8` | `#F0A020` | `#F0A020` |
| Ready / harvested (month complete) | `#D6F0C2` | `#5BAF3A` | `#5BAF3A` |
| Withering / overspent | `#FFFFFF` | `#E53030` top-only | `#E53030` |

---

## Navigation bar

The bottom nav is a **floating island**: a rounded card with a 10px gutter on each side and 14px from the bottom, sitting on a strip of `bg-screen` (`#FAF6EE`). The island itself uses `bg-nav` (`#E4DFD2`) with a 0.5px `border-nav` (`#C8C0A0`) border and a 22px corner radius.

Tabs use these nav-specific tokens:

| Token | Hex | Usage |
|---|---|---|
| `bg-pill-active` | `#FAF6EE` | Active tab pill — matches `bg-screen` so the active state looks carved out of the island, mirroring the FAB halo |
| `border-nav` | `#A88458` | 1.5px warm-brown border around the floating island |
| `shadow-nav` | `#604015` @ 20% | Soft warm drop shadow under the island (24px blur, 8px Y-offset) |
| `text-nav-inactive` | `#6B5530` | Inactive tab label — dark warm brown for legibility on the linen island |
| `icon-nav-inactive` | `#A89070` | Reserved for tinted nav icons (currently unused — SVGs render full-color) |

The active tab sits inside a `bg-pill-active` pill (16px radius, no border) with its label in `green-primary` (`#5BAF3A`) at Nunito 10sp/700 and its icon scaled up from 20×20 to 24×24. Inactive labels use `text-nav-inactive` at Nunito 10sp/600. SVG icons are full-color assets and are never tinted in either state.

A central FAB (54×54) sits in the row between Ledger and Market, lifted 32px above the island. It uses a white (`#FFFFFF`) fill with a 4px `green-primary` outline — the white interior gives the green watering-can icon enough contrast to read clearly.

**Note:** This supersedes the earlier rule that nav had no pill or highlight behind the active item — the floating-island design re-introduces a pill.

---

## Currency pills (header)

Two pill badges always appear in the header:

**Coins pill:** background `#FEF3D0`, border `1.5px solid #F0A020`, icon and text in `#F0A020`.

**Gems/diamonds pill:** background `#E8F4FF`, border `1.5px solid #5AACDC`, icon and text in `#5AACDC`.

---

## What NOT to do

- Do not use dark backgrounds. The app is light-first.
- Do not use green for anything that isn't healthy/on-track/complete.
- Do not use gold decoratively — it must always mean "earned" or "currency."
- Do not introduce new colors without mapping them to a meaning in this system.
- Do not use more than one accent color per UI component.
- Do not use red for anything other than warnings and overspent states.
- Do not use pure `#000000` black for text — always `#1A1A1A`.

---

## Reference apps

The palette is derived from two reference apps:

1. **Hay Day** (Supercell) — primary inspiration for the cozy farm aesthetic. Warm tan plot tiles, linen nav bar, single confident green, gold currency pills.
2. **Plant & Grow** (first reference image) — secondary inspiration for the dark forest green + lime-yellow dashboard variant, if a dark mode is ever introduced.

For now, Cropkeep ships light mode only using the Hay Day–derived tokens above.