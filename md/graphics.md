# Cropkeep — Graphic Style Guide

## Visual identity in one sentence

Cropkeep looks like a sheet of warm, collectible stickers scattered across a softly painted farm world — every icon feels like something you'd want to peel off and keep, every background feels like a page from a children's picture book.

---

## Core design philosophy

Cropkeep uses no custom animation libraries. All delight comes from:

- **The quality and warmth of static illustrations**
- **Typography that feels crafted, not default**
- **Intentional spacing and layout**
- **Color and subtle texture doing the emotional heavy lifting**

Flutter's built-in transitions handle all state changes. No Rive, no Lottie, no external animation packages.

---

## Two illustration styles, used together

Cropkeep uses two styles that each serve a different purpose and scale. They share the same warm pastel palette so they never feel mismatched.

| Style | Used for | Key quality |
|---|---|---|
| **Sticker illustration** | Crop icons, well icons, reward assets, decorations | Physical, collectible, warm — like a die-cut sticker |
| **Kawaii flat icon** | Navigation icons, status badges, UI chrome | Simple, round, immediately readable at small sizes |

---

## Style A: Sticker illustration

### What it looks like

Imagine a beautifully illustrated die-cut sticker of a strawberry. It has:
- A thick, clean, slightly rounded outline in a dark warm color (not black — dark brown or dark version of the object's color)
- Soft, matte gouache-like fill colors — pastel but not washed out
- Very simple shading: one lighter area (highlight), one slightly darker area (shadow), no gradients
- A tiny white drop shadow behind the entire outline, as if the sticker is slightly lifted off the surface
- Rounded, slightly chubby proportions — everything is a little rounder and softer than real life

### Defining characteristics

- **Outline:** Thick, clean, uniform weight. Dark warm brown or dark version of the object's dominant color. Rounded line caps and joins — no sharp points anywhere.
- **Fill:** Flat matte color with at most two shading steps (base, highlight, shadow). Gouache-like — opaque, slightly chalky, not shiny.
- **Palette:** Warm pastels. 3 colors per object maximum. No neons, no cold colors, no gradients.
- **Shadow:** A small, slightly blurred white offset shadow behind the outline — gives the sticker its lifted, physical feeling. Not a grey drop shadow.
- **Proportions:** Slightly chubby and rounded. Objects are a little wider, a little rounder than realistic.
- **Background:** Always transparent PNG.

### What to avoid

- Gradients of any kind
- Glossy or shiny surfaces
- More than 3 colors per icon
- Perfect photorealistic proportions
- Grey or cool-toned shadows
- Thin outlines or hairline details
- Scratchy, rough, or hand-drawn-looking lines
- Clay 3D or any three-dimensional render

### Base AI prompt

```
[OBJECT], sticker illustration style, thick clean rounded outline, 
soft matte gouache colors, warm pastel palette, [COLOR NOTE], 
simple flat shading with one highlight and one shadow area, 
slightly chubby rounded proportions, small white drop shadow 
behind outline, transparent background, cute cozy style, 
no gradients, no gloss, isolated object
```

**Negative prompt:**
```
photorealistic, 3D render, clay, glossy, metallic, gradient, 
neon, cool grey, dark background, thin outline, scratchy, 
hand-drawn rough texture, anime sharp style, text, watermark,
harsh shadows, complex shading
```

---

## Style B: Kawaii flat icon

### What it looks like

Small, round, simple icons that feel friendly and immediately readable. Like the emoji set from a cozy chat app — everything has a face or a simple expression of warmth, colors are clean and warm, shapes are reduced to their simplest readable form.

### Defining characteristics

- **Shape:** Reduced to the simplest possible silhouette. A sun is a circle with stubby rays. A cloud is three overlapping circles. No complex geometry.
- **Outline:** Slightly thinner than sticker style but still present — same dark warm color approach.
- **Fill:** Completely flat — single color per region, no shading at all.
- **Size:** Designed to be read clearly at 24×24px display size.
- **Expression:** Where possible, objects have a subtle friendly quality — rounded corners, slightly uneven proportions that feel organic rather than geometric.
- **Background:** Always transparent PNG.

### Base AI prompt

```
[OBJECT], kawaii flat icon, simple rounded shapes, 
clean thick outline, warm pastel colors, [COLOR NOTE], 
completely flat fill no shading, minimal detail, 
friendly and cute, transparent background, 
simple silhouette, no gradients, no shadows
```

---

## Asset categories

### Crop icons — Sticker illustration style

The most important assets in the app. Each crop represents a budget category. Four state variants required per crop.

| Crop | Category | Dominant color | Accent color |
|---|---|---|---|
| Wheat sheaf | General | Warm golden yellow `#E8B84B` | Brown twine `#8B5E3C` |
| Strawberry | Food & dining | Coral red `#E8524A` | Leaf green `#5AAA3A` |
| Sugarcane | Transport | Fresh green `#6ABF5E` | Pale joint cream `#E8DFB8` |
| Coffee branch | Subscriptions | Cherry red `#C8453A` | Leaf green `#3A7A30` |
| Corn | Shopping | Golden yellow `#F0C040` | Husk green `#7AAA50` |
| Sunflower | Entertainment | Petal yellow `#F0C830` | Center brown `#8B5E3C` |
| Tomato | Health & fitness | Tomato red `#E8503A` | Stem green `#5AAA3A` |
| Herb bundle | Daily expenses | Mixed greens `#6AAA50` | Twine brown `#8B5E3C` |
| Oak sapling | Rent / Fixed | Leaf green `#5AAA3A` | Pot terracotta `#C8703A` |
| Blueberries | Savings | Blue-purple `#7A70C8` | Leaf green `#5AAA3A` |

#### Four state variants per crop

| State | Visual instruction | Prompt suffix |
|---|---|---|
| Seedling | Tiny sprout just emerged, 30% of full size, single stem and two small leaves | `seedling sprout version, very small, single stem two tiny leaves` |
| Growing | Full illustration, normal healthy state | (base prompt, no suffix) |
| Withering | Same object, drooping posture, colors slightly desaturated and warmer/browner | `wilting and drooping, slightly desaturated warm colors, sad droopy posture` |
| Harvested | Same object, clean healthy state, small sparkle stars around it | `glowing healthy, small sparkle star accents around it, celebratory` |

**Workflow:** Generate the Growing state first. Use it as the reference for the other three with image-to-image: *"Same sticker illustration style and object. Show it as [seedling / wilting / harvested with sparkles]."*

---

### Income well icons — Sticker illustration style

Each well is a small illustrated container or structure representing an income stream.

| Well type | Object | Dominant color | Accent |
|---|---|---|---|
| Salary | Stone well with wooden beam and rope bucket | Stone grey-tan `#C8B898` | Wood brown `#8B5E3C` |
| Freelance | Open treasure chest with coin spill | Wood brown `#8B5E3C` | Gold `#E8C040` |
| Rental | Small house with coin slot on roof | Terracotta `#C8703A` | Roof red `#C84040` |
| Investment | Round pot with coins and small sprout | Clay brown `#B87850` | Gold `#E8C040` |
| Side business | Market stall with striped awning | Cream `#F5F0E8` | Stripe red `#C84040` |
| Default | Simple wooden barrel | Honey wood `#C89050` | Copper hoop `#B87040` |

---

### Currency & reward assets — Sticker illustration style

Appear during harvests, in the Market, and as reward moments. Same sticker style. Slightly more emphasis on the highlight area to convey value and shine — still matte, just with a slightly more prominent highlight spot.

| Asset | Object description | Color note |
|---|---|---|
| Coin | Round coin, small leaf embossed on face | Warm gold `#E8C040`, dark gold outline |
| Gem | Faceted oval gem, simplified facets | Soft cyan `#70C8E0`, white highlight dot |
| Star | Five-point star, rounded tips | Warm yellow `#F0C830` |
| Harvest basket | Round woven basket overflowing with crop tops | Brown wicker `#C89050`, colorful crop tops |
| Trophy | Simple cup trophy on a small base | Gold cup `#E8C040`, green base `#5AAA3A` |
| XP badge | Circular badge with small sprout in center | Green `#5AAA3A`, gold rim `#E8C040` |
| Coin stack | Stack of 4 coins slightly offset | Warm gold `#E8C040` |

---

### Navigation icons — Kawaii flat icon style

Four icons for the bottom navigation bar. Must work at 24px display size. Active state: `#5BAF3A`. Inactive state: `#888888`.

| Tab | Icon object | Simplified form |
|---|---|---|
| Farm | Small barn or house with a leaf | Square building, triangle roof, single leaf accent |
| Ledger | Open book or scroll | Rectangle with horizontal lines, rounded corners |
| Market | Small market stall or shop bag | Simple bag shape with handles, or stall with awning |
| Farmer | Round person silhouette with hat | Circle head, small farmer hat on top |

Generate in the active green color. Flutter renders the inactive grey state via color filtering — only one color version needed per icon.

---

### Farm decoration assets — Sticker illustration style

Purchasable in the Market. Same sticker style as crop icons. Can have slightly more detail since they display larger on the farm screen.

Initial set:
- Scarecrow (straw hat, button eyes, crossed stick arms)
- Wooden fence section (three rails, two posts)
- Flower pot cluster (three terracotta pots, different small flowers)
- Beehive (classic domed straw skep, one small bee beside it)
- Signpost (single post, one wooden arrow — text applied by app)
- Watering can (classic rounded can, long spout)
- Small barn (red walls, white X on door, grey roof)
- Windmill (white sails, brown square base)

---

## Typography

Two typefaces only. Never the system default.

### Heading typeface — Nunito (SemiBold / Bold)

**Why Nunito for headings:** Its extremely rounded letterforms match the roundness of the sticker illustration style directly. When a Nunito heading sits next to a sticker illustration icon, they feel like they came from the same design world. Warm, friendly, slightly playful without being childish. Free on Google Fonts.

**Use for:**
- Screen titles
- Plot tile category names
- Harvest screen headline
- Section headers
- Farmer name on profile
- Market item names

**Weights:** SemiBold (600) and ExtraBold (800) only.

### Body / number typeface — Nunito (Regular / Medium)

Nunito serves as both the heading and body face — the weight variation is enough to create clear hierarchy without introducing a second typeface. This also means perfect roundness consistency throughout the entire app.

**Use for:**
- All numbers (budget amounts, pace, coins)
- Transaction log entries
- Labels and metadata
- Button text
- Status labels ("Growing", "Ready!", "Withering")
- Notes and captions

**Weights:** Regular (400) and Medium (500).

### Type scale

| Role | Weight | Size | Color |
|---|---|---|---|
| Screen title | ExtraBold 800 | 24sp | `#1A1A1A` |
| Section header | SemiBold 600 | 16sp | `#1A1A1A` |
| Plot tile name | SemiBold 600 | 14sp | `#1A1A1A` |
| Primary number | ExtraBold 800 | 22sp | `#1A1A1A` |
| Secondary number | SemiBold 600 | 15sp | `#1A1A1A` |
| Pace / metadata | Regular 400 | 12sp | `#888888` |
| Status label | SemiBold 600 | 11sp | state color |
| Button text | SemiBold 600 | 14sp | see buttons |
| Body / notes | Regular 400 | 13sp | `#1A1A1A` |
| Caption | Regular 400 | 11sp | `#888888` |

---

## Surface & texture

### Background

Base color `#F5F0E8` (warm parchment) with a very subtle paper grain texture PNG overlaid at **8% opacity**. Applied as a `DecorationImage` with `ImageRepeat.repeat` in Flutter. Makes flat surfaces feel slightly physical — like the app is printed on warm paper.

The grain tile: 256×256px, neutral warm grain, no color, subtle and fine.

### Cards / plot tiles

- Background: `#FFFFFF`
- Border: 1.5px solid `#C8BA90`
- Border radius: 12px
- No box shadow — the warm border does the lifting

### Empty / locked plot tiles

- Background: `#F5F0E8` (recedes into the page background)
- Border: 1.5px dashed `#C8BA90`
- Shows a small lock kawaii flat icon centered

### Currency pills (header)

- Coins: background `#FEF3D0`, border 1.5px `#F0A020`, text and icon `#F0A020`
- Gems: background `#E8F4FF`, border 1.5px `#5AACDC`, text and icon `#5AACDC`
- Border radius: 20px (fully rounded pill)

---

## Flutter animations — built-in only

| Moment | Flutter technique | Duration | Curve |
|---|---|---|---|
| Transaction logged → tile bounce | `ScaleTransition` 1.0 → 1.06 → 1.0 | 280ms | `easeOutBack` |
| Crop state PNG swap | `AnimatedSwitcher` + `FadeTransition` | 400ms | `easeInOut` |
| Tile border / color change | `AnimatedContainer` | 300ms | `easeInOut` |
| FAB → bottom sheet | `showModalBottomSheet` default | Default | Default |
| Screen navigation | `MaterialPageRoute` default | Default | Default |
| Status label color change | `AnimatedDefaultTextStyle` | 300ms | `easeInOut` |
| Market purchase | `ScaleTransition` 1.0 → 0.94 → 1.0 | 200ms | `easeOutCubic` |
| Tab switch | `IndexedStack` — no animation | Instant | — |

---

## Asset export specs

Export all AI-generated assets at 3× intended display size. PNG with transparent background.

| Asset type | Display size | Export size |
|---|---|---|
| Crop icon — plot tile | 72×72px | 216×216px |
| Crop icon — detail view | 120×120px | 360×360px |
| Well icon | 56×56px | 168×168px |
| Reward / coin asset | 36×36px | 108×108px |
| Navigation icon | 24×24px | 72×72px |
| Market item | 88×88px | 264×264px |
| Farm decoration | 96×96px | 288×288px |
| Background scenes | full screen | 1290×2796px |
| Paper grain texture tile | 256×256px | 256×256px |

---

## Consistency checklist

Before approving any generated asset:

- [ ] Thick clean outline present — warm dark color, not black, not grey
- [ ] Fill is flat matte — no gradients, no gloss, no 3D shading
- [ ] Maximum 3 colors used in the entire illustration
- [ ] White drop shadow behind outline (sticker style assets only)
- [ ] Proportions are slightly chubby / rounded — not realistic
- [ ] Background is fully transparent
- [ ] No text, labels, or watermarks on the asset
- [ ] Reads clearly at 50% of intended display size
- [ ] Colors are warm — no cool greys, no cold whites, no neons
- [ ] Feels cozy and friendly — show it to someone and their first reaction should be warmth

---

## AI generation reference search terms

When searching for style references or fine-tuning prompts:

- "sticker illustration cute food"
- "kawaii flat icon set"
- "cute sticker pack fruit illustration"
- "cozy game asset sticker style"
- "Picrew sticker aesthetic"
- "LINE sticker illustration style"
- "cute gouache sticker illustration"
- "kawaii vegetable sticker transparent"