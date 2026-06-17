import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';

// ──────────────────────────────────────────────────────────────────────────
// FarmScreen — first visual pass.
//
// Two subpages live behind a segmented control + swipeable PageView:
//   • Crops — compact reservoir meter + plot grid (default)
//   • Wells — detailed reservoir, bonus harvest pool, foundation & bonus
//             wells, plus the system-managed Carryover well
//
// All data is hardcoded sample content so the aesthetic can be iterated on.
// Every tap (other than segment + swipe) surfaces a "coming soon" snackbar.
// Repositories, creation sheets, and live cycle math come in follow-up passes.

class FarmScreen extends StatefulWidget {
  const FarmScreen({super.key});

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  late final PageController _pageController;
  int _index = 0;

  // For the layout pass: pretend the bonus pool is above the nudge threshold
  // so the dot on the Wells segment renders. Real trigger lands with data
  // wiring.
  static const bool _bonusPoolNudge = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectSegment(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int i) {
    if (i != _index) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    // No SafeArea wrapper here — the parent (RootShell) renders the
    // CropkeepHeader directly above, which already consumes the top
    // status-bar inset via its own SafeArea. Wrapping FarmScreen in a
    // second SafeArea reads the same MediaQuery top inset (SafeArea
    // doesn't propagate consumption to siblings, only descendants) and
    // ends up double-padding the top by the notch height — a ~47px ghost
    // gap on notch iPhones between the header and the segment control.
    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: Column(
        children: [
          Padding(
            // 8px top so the segment couples to the header (header has
            // 8px internal bottom padding → ~16px reading gap, the
            // standard Material tabs-under-header pattern).
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _SubpageSegmentedControl(
              index: _index,
              bonusPoolNudge: _bonusPoolNudge,
              onSelected: _selectSegment,
            ),
          ),
          const SizedBox(height: 4),
          _PageIndicatorDots(index: _index, count: 2),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: const [
                _CropsSubpage(),
                _WellsSubpage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Segmented control — toggles between Crops and Wells. Pairs with PageView
// swipe so either gesture advances the other.

class _SubpageSegmentedControl extends StatelessWidget {
  const _SubpageSegmentedControl({
    required this.index,
    required this.bonusPoolNudge,
    required this.onSelected,
  });

  final int index;
  final bool bonusPoolNudge;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CropkeepColors.bgPageAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTab(
              label: 'Crops',
              isActive: index == 0,
              onTap: () => onSelected(0),
            ),
          ),
          Expanded(
            child: _SegmentTab(
              label: 'Wells',
              isActive: index == 1,
              // The dot only nudges while the user is on the OTHER tab — once
              // they're on Wells, no need to keep poking.
              showDot: bonusPoolNudge && index != 1,
              onTap: () => onSelected(1),
            ),
          ),
        ],
      ),
    );
  }
}

// Two quiet dots under the segment control. Their job is *not* navigation —
// taps go to the segment above. The dots advertise that the PageView swipe
// is a real gesture, which otherwise has no visual signal.
class _PageIndicatorDots extends StatelessWidget {
  const _PageIndicatorDots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: i == index
                  ? CropkeepColors.greenPrimary
                  : CropkeepColors.borderCard,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.showDot = false,
  });

  final String label;
  final bool isActive;
  final bool showDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? CropkeepColors.greenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive
                    ? CropkeepColors.textOnGreenBtn
                    : CropkeepColors.textNavInactive,
                height: 1,
              ),
            ),
            if (showDot) ...[
              const SizedBox(width: 6),
              // Bonus = gold in this system, so the nudge is gold not red —
              // it should read as "good news to claim" rather than danger.
              // 2px white halo lets the dot survive on both the green-active
              // segment and the cream-toned inactive segment.
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: CropkeepColors.goldPrimary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Crops subpage — compact reservoir meter + 2-column plot grid.

class _CropsSubpage extends StatefulWidget {
  const _CropsSubpage();

  @override
  State<_CropsSubpage> createState() => _CropsSubpageState();
}

class _CropsSubpageState extends State<_CropsSubpage> {
  _PlotFilter _filter = _PlotFilter.all;

  List<_SamplePlot> _filteredPlots() {
    switch (_filter) {
      case _PlotFilter.all:
        return _samplePlots;
      case _PlotFilter.spending:
        // "Spending" = discretionary plots, including the Unplanned wild
        // patch — they're all the buckets the user spends *into*.
        return _samplePlots
            .where((p) => p.kind == _PlotKind.discretionary)
            .toList(growable: false);
      case _PlotFilter.bills:
        return _samplePlots
            .where((p) => p.kind == _PlotKind.fixedObligation)
            .toList(growable: false);
    }
  }

  Map<_PlotFilter, int> _counts() {
    int spending = 0;
    int bills = 0;
    for (final p in _samplePlots) {
      if (p.kind == _PlotKind.fixedObligation) {
        bills++;
      } else {
        spending++;
      }
    }
    return {
      _PlotFilter.all: _samplePlots.length,
      _PlotFilter.spending: spending,
      _PlotFilter.bills: bills,
    };
  }

  @override
  Widget build(BuildContext context) {
    // "Remaining" is the daily glance — actual water still available to
    // spend. That means foundation income (the reservoir budgeting cap)
    // PLUS logged bonus income, since logged bonus is real money already
    // received. Plot creation uses the reservoir cap; this hero uses the
    // full picture so the user reads what they can actually spend.
    final int foundationTotal = _sampleFoundationTotal;
    final int bonusLogged = _sampleBonusWells
        .fold<int>(0, (sum, w) => sum + w.loggedThisCycle);
    final int totalIncome = foundationTotal + bonusLogged;
    final int totalSpent = _samplePlots
        .fold<int>(0, (sum, p) => sum + p.spent);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReservoirHeroBlock(
            total: totalIncome,
            totalSpent: totalSpent,
          ),
          const SizedBox(height: 20),
          _PlotFilterChips(
            active: _filter,
            counts: _counts(),
            onSelected: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 16),
          _PlotList(plots: _filteredPlots()),
        ],
      ),
    );
  }
}

enum _PlotFilter { all, spending, bills }

// ──────────────────────────────────────────────────────────────────────────
// Wells subpage — detailed reservoir, bonus pool, foundation + bonus lists.

class _WellsSubpage extends StatelessWidget {
  const _WellsSubpage();

  @override
  Widget build(BuildContext context) {
    final int foundationTotal = _sampleFoundationTotal;
    final int bonusLogged = _sampleBonusWells
        .fold<int>(0, (s, w) => s + w.loggedThisCycle);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IncomeSummaryBlock(
            reservoirTotal: foundationTotal,
            bonusLogged: bonusLogged,
          ),
          const SizedBox(height: 20),
          _WellsSectionCard(
            title: 'Foundation wells',
            wells: _sampleFoundationWells,
            addLabel: 'Add foundation well',
            leadingAsset: 'assets/icons/well.svg',
          ),
          const SizedBox(height: 20),
          _WellsSectionCard(
            title: 'Bonus wells',
            wells: _sampleBonusWells,
            addLabel: 'Add bonus well',
            leadingAsset: 'assets/icons/water-bottle.svg',
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Income summary card — used on the Wells subpage. Mirrors the Crops hero
// pattern ("$X remaining" / "$X this cycle") so the two summary cards
// feel like one design system: hero amount + descriptor word inline, then
// a small subtitle line carrying the breakdown.
//
// "Total" stays textPrimary rather than the green Crops uses for
// "remaining"; remaining is an action signal (room left to spend), total
// is a stated fact. Color stays reserved for things the user can act on.
//
// Plot creation will still enforce sum(plot budgets) ≤ reservoir — this
// card answers "what came in this cycle?", it doesn't change the
// budgeting basis.

// Mirrors _ReservoirHeroBlock: shared _HeroCard chrome (sand wash, deeper
// shadow, generous padding) so both hero blocks read as the same kind of
// object across subpages. No tap target here — the summary states a fact;
// drilling into income happens via the individual well rows below.
class _IncomeSummaryBlock extends StatelessWidget {
  const _IncomeSummaryBlock({
    required this.reservoirTotal,
    required this.bonusLogged,
  });

  final int reservoirTotal;
  final int bonusLogged;

  @override
  Widget build(BuildContext context) {
    final int totalIncome = reservoirTotal + bonusLogged;
    return _HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: _formatMoney(totalIncome, r'$', 2),
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                      height: 1,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const TextSpan(
                    text: ' total',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: CropkeepColors.textSecondaryOnHero,
                      height: 1,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondaryOnHero,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: _formatMoney(reservoirTotal, r'$', 2),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                  ),
                ),
                const TextSpan(text: ' reservoir + '),
                TextSpan(
                  text: _formatMoney(bonusLogged, r'$', 2),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textGoldDeep,
                  ),
                ),
                const TextSpan(text: ' bonus'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Reservoir meter — bold single-number hero, simple progress bar, one
// quiet reservoir reference caption. The card is tappable; the breakdown
// (allocated vs unplanned vs overrun split) opens on tap so the daily
// glance stays clean.
//
// "Remaining" tracks actual reservoir drain — total foundation income
// minus everything that's been logged this cycle (plot transactions +
// Unplanned). Budgeted-but-unspent plot money still counts as remaining
// in the reservoir; the budget is just a soft fence for that money, not
// a commitment that's already withdrawn. This matches the water-level
// metaphor more honestly than the "free for allocation" reading.
//
// Design rationale:
//   • Hero is one number + one descriptor word ("$3,725 remaining"). The
//     descriptor flips to "over" with a red hero when spent > total.
//   • Bar reads as a standard progress bar: fill = spent / total. Green
//     while there's room; red when over (fills to 100%). No segments —
//     the allocated / unplanned split lives in the tap-to-open sheet.
//   • One caption: "of $4,800 reservoir" — present in both states so the
//     cap is always available without the user doing mental math.

// Lives inside _HeroCard so the page-defining number reads as a different
// kind of object from the white data cards below. Sand chrome + bigger
// padding/radius/shadow do the work; the trailing chevron preserves the
// tap-to-breakdown affordance.
class _ReservoirHeroBlock extends StatelessWidget {
  const _ReservoirHeroBlock({
    required this.total,
    required this.totalSpent,
  });

  final int total;
  // Sum of every non-deleted transaction this cycle, across all plots
  // including Unplanned. The water that has actually left the reservoir.
  final int totalSpent;

  @override
  Widget build(BuildContext context) {
    final int remaining = total - totalSpent;
    final bool isOver = remaining < 0;
    final int overrun = isOver ? -remaining : 0;

    return Semantics(
      button: true,
      label: 'View reservoir breakdown',
      child: _HeroCard(
        onTap: () => _comingSoon(
          context,
          'Reservoir breakdown is coming soon.',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _ReservoirHeroLine(
                    isOver: isOver,
                    remaining: remaining,
                    overrun: overrun,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: CropkeepColors.textSecondaryOnHero,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ReservoirProgressBar(
              total: total,
              spent: totalSpent,
              isOver: isOver,
              cycleDay: _cycleDayFake,
              cycleLength: _cycleLengthFake,
            ),
            const SizedBox(height: 12),
            _ReservoirReferenceCaption(total: total),
          ],
        ),
      ),
    );
  }
}

class _ReservoirHeroLine extends StatelessWidget {
  const _ReservoirHeroLine({
    required this.isOver,
    required this.remaining,
    required this.overrun,
  });

  final bool isOver;
  final int remaining;
  final int overrun;

  @override
  Widget build(BuildContext context) {
    final int heroAmount = isOver ? overrun : remaining;
    final String descriptor = isOver ? 'over' : 'remaining';
    // Deep siblings used here because the hero sits on bgHero (warm sand).
    // The bright primaries (textGreen / textRed) have cool undertones that
    // clash against the sand's yellow undertone; the deep variants land
    // like harvest-leaf / brick on linen — same semantic, in-key hue.
    final Color heroColor = isOver
        ? CropkeepColors.textRedDeep
        : CropkeepColors.textGreenDeep;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: _formatMoney(heroAmount, r'$', 2),
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: heroColor,
                height: 1,
                letterSpacing: -0.6,
              ),
            ),
            TextSpan(
              text: ' $descriptor',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textSecondaryOnHero,
                height: 1,
              ),
            ),
          ],
        ),
        maxLines: 1,
      ),
    );
  }
}

class _ReservoirProgressBar extends StatelessWidget {
  const _ReservoirProgressBar({
    required this.total,
    required this.spent,
    required this.isOver,
    required this.cycleDay,
    required this.cycleLength,
  });

  final int total;
  final int spent;
  final bool isOver;
  // Day-position within the harvest cycle. The vertical tick at this
  // fraction turns the bar from a "spent vs total" gauge into a "spent vs
  // total vs time" gauge — which is the actual question a daily glance is
  // asking. Distance between fill and tick = pace margin.
  final int cycleDay;
  final int cycleLength;

  static const double _height = 14;

  @override
  Widget build(BuildContext context) {
    final double fraction = total <= 0
        ? 0.0
        : (spent / total).clamp(0.0, 1.0);
    final double tickFraction = cycleLength <= 0
        ? 0.0
        : (cycleDay / cycleLength).clamp(0.0, 1.0);
    // Sand-shadow groove sits under both green-deep (under) and red-deep
    // (over) fills. Single track tone keeps the bar reading as a carved
    // recess in the hero card rather than two competing surfaces.
    const Color trackColor = CropkeepColors.progressTrackOnHero;
    final Color fillColor = isOver
        ? CropkeepColors.textRedDeep
        : CropkeepColors.textGreenDeep;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: _height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double tickX = constraints.maxWidth * tickFraction;
            return Stack(
              children: [
                Container(color: trackColor),
                FractionallySizedBox(
                  widthFactor: fraction,
                  alignment: Alignment.centerLeft,
                  child: Container(color: fillColor),
                ),
                Positioned(
                  left: tickX,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1.5,
                    color: CropkeepColors.textSecondaryOnHero
                        .withValues(alpha: 0.60),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Plain caption — the total-this-cycle reference is always available, but
// small enough to stay supportive rather than headline. Uses "this cycle"
// rather than "reservoir" because the total includes logged bonus, which
// isn't part of the reservoir budgeting cap.
class _ReservoirReferenceCaption extends StatelessWidget {
  const _ReservoirReferenceCaption({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CropkeepColors.textSecondaryOnHero,
          height: 1.3,
        ),
        children: [
          const TextSpan(text: 'of '),
          TextSpan(
            text: _formatMoney(total, r'$', 2),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textPrimary,
            ),
          ),
          const TextSpan(text: ' this cycle'),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Plot filter chips — three pills above the list. Active chip = filled
// green pill (echoes the Crops/Wells segmented control). Inactive = white
// pill with the standard borderCard outline. Counts are inline so the
// user can see what each filter contains before tapping.

class _PlotFilterChips extends StatelessWidget {
  const _PlotFilterChips({
    required this.active,
    required this.counts,
    required this.onSelected,
  });

  final _PlotFilter active;
  final Map<_PlotFilter, int> counts;
  final ValueChanged<_PlotFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterChip(
          label: 'All',
          count: counts[_PlotFilter.all] ?? 0,
          isActive: active == _PlotFilter.all,
          onTap: () => onSelected(_PlotFilter.all),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Spending',
          count: counts[_PlotFilter.spending] ?? 0,
          isActive: active == _PlotFilter.spending,
          onTap: () => onSelected(_PlotFilter.spending),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Bills',
          count: counts[_PlotFilter.bills] ?? 0,
          isActive: active == _PlotFilter.bills,
          onTap: () => onSelected(_PlotFilter.bills),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? CropkeepColors.greenPrimary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive
                ? CropkeepColors.greenPrimary
                : CropkeepColors.borderCard,
            width: 1.5,
          ),
        ),
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? CropkeepColors.textOnGreenBtn
                  : CropkeepColors.textPrimary,
              height: 1,
            ),
            children: [
              TextSpan(text: label),
              TextSpan(
                text: '  $count',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? CropkeepColors.textOnGreenBtn.withValues(alpha: 0.85)
                      : CropkeepColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Plot list — vertical stack of plot row cards, then an "Add plot" footer.
// Each row gives a plot enough horizontal room to show:
//   • crop icon
//   • plot name + a small headline amount on the right ("$X left/over",
//     "$X paid", or "$X spent" for the wild Unplanned patch)
//   • a per-plot progress bar (spent ÷ budget for budgeted plots; income
//     share against the 20% danger threshold for Unplanned)
//   • a one-line status: pace + spent / budget context for discretionary,
//     state + due day for fixed obligation, "X% of income · wild patch"
//     for Unplanned
// State coloring follows the colors.md plot palette. The withering accent
// flips from a top strip (old tile) to a left strip (more natural for
// row layouts).

class _PlotList extends StatelessWidget {
  const _PlotList({required this.plots});

  final List<_SamplePlot> plots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < plots.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _PlotRow(
            plot: plots[i],
            onTap: () => _comingSoon(
              context,
              '${plots[i].name} — details coming soon.',
            ),
          ),
        ],
        const SizedBox(height: 12),
        _AddPlotRow(
          onTap: () => _comingSoon(context, 'Plot creation is coming soon.'),
        ),
      ],
    );
  }
}

// Static demo values while data wiring is still pending. Pulled to top-level
// so the reservoir progress bar can sync its time-tick against the same
// "fake day" the plot rows use for pace math — otherwise the two would
// drift and reading the screen as a single moment in time would fall apart.
const int _cycleLengthFake = 30;
const int _cycleDayFake = _cycleLengthFake - _daysLeftFake;
const int _daysLeftFake = 14;

class _PlotRow extends StatelessWidget {
  const _PlotRow({required this.plot, required this.onTap});

  final _SamplePlot plot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visuals = _PlotVisuals.forState(
      plot.state,
      isUnplanned: plot.isUnplanned,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: visuals.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: visuals.borderColor,
            width: visuals.borderWidth,
          ),
          boxShadow: const [
            BoxShadow(
              color: CropkeepColors.shadowCard,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: SvgPicture.asset(
                plot.iconAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: _content(visuals)),
          ],
        ),
      ),
    );
  }

  Widget _content(_PlotVisuals visuals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                plot.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _headlineAmount(),
          ],
        ),
        const SizedBox(height: 8),
        _PlotProgressBar(plot: plot),
        const SizedBox(height: 6),
        _statusLine(visuals.statusColor),
      ],
    );
  }

  Widget _headlineAmount() {
    if (plot.isUnplanned) {
      return _amount(
        amount: plot.spent,
        descriptor: 'spent',
        amountColor: CropkeepColors.textPrimary,
      );
    }
    if (plot.kind == _PlotKind.fixedObligation) {
      return _amount(
        amount: plot.budget ?? 0,
        descriptor: _fixedObligationDescriptor(),
        amountColor: CropkeepColors.textPrimary,
      );
    }
    final remaining = (plot.budget ?? 0) - plot.spent;
    final bool isOver = remaining < 0;
    return _amount(
      amount: remaining.abs(),
      descriptor: isOver ? 'over' : 'left',
      amountColor:
          isOver ? CropkeepColors.textRed : CropkeepColors.textPrimary,
    );
  }

  Widget _amount({
    required int amount,
    required String descriptor,
    required Color amountColor,
  }) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: CropkeepColors.textSecondary,
          height: 1.1,
        ),
        children: [
          TextSpan(
            text: _formatMoney(amount, r'$', 2),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: amountColor,
            ),
          ),
          TextSpan(text: ' $descriptor'),
        ],
      ),
    );
  }

  String _fixedObligationDescriptor() {
    switch (plot.state) {
      case _PlotVisualState.ready:
        return 'paid';
      case _PlotVisualState.almostFull:
        return 'due';
      case _PlotVisualState.seedling:
        return 'awaiting';
      case _PlotVisualState.withering:
        return 'short';
      case _PlotVisualState.growing:
        return 'partial';
    }
  }

  Widget _statusLine(Color statusColor) {
    final String text;
    if (plot.isUnplanned) {
      text =
          '${plot.incomeSharePct!.toStringAsFixed(1)}% of income · wild patch';
    } else if (plot.kind == _PlotKind.fixedObligation) {
      text = plot.statusLabel ?? 'Awaiting';
    } else {
      // Discretionary plots show pace as long as there's budget left to
      // spend — it's the actionable daily target. Once spent ≥ budget the
      // pace is meaningless (zero or negative remaining ÷ days), so fall
      // back to the qualitative state.
      final int budget = plot.budget ?? 0;
      final int remaining = budget - plot.spent;
      if (remaining > 0) {
        final pace = remaining ~/ _daysLeftFake;
        text = '≈${_formatMoney(pace, r'$', 2)}/day to stay on track';
      } else {
        text = 'Withering';
      }
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: statusColor,
        height: 1.2,
      ),
    );
  }
}

class _PlotProgressBar extends StatelessWidget {
  const _PlotProgressBar({required this.plot});

  final _SamplePlot plot;

  static const double _height = 8;
  // Unplanned has no budget, so its bar measures income share against the
  // 20% "dead" threshold from the README — 0% leaves the bar empty, ≥20%
  // fills it completely. The fill color still follows the visual state.
  static const double _unplannedDangerCap = 20.0;

  @override
  Widget build(BuildContext context) {
    final double fraction;
    if (plot.isUnplanned) {
      fraction = ((plot.incomeSharePct ?? 0) / _unplannedDangerCap)
          .clamp(0.0, 1.0);
    } else {
      final int budget = plot.budget ?? 0;
      fraction = budget <= 0
          ? 0.0
          : (plot.spent / budget).clamp(0.0, 1.0);
    }

    final Color fill;
    final Color track;
    switch (plot.state) {
      case _PlotVisualState.withering:
        fill = CropkeepColors.redAlert;
        track = CropkeepColors.redAlert.withValues(alpha: 0.18);
        break;
      case _PlotVisualState.almostFull:
        fill = CropkeepColors.goldPrimary;
        track = CropkeepColors.bgGoldWash;
        break;
      case _PlotVisualState.seedling:
      case _PlotVisualState.growing:
      case _PlotVisualState.ready:
        fill = CropkeepColors.greenPrimary;
        track = CropkeepColors.greenHint;
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: _height,
        child: Stack(
          children: [
            Container(color: track),
            FractionallySizedBox(
              widthFactor: fraction,
              alignment: Alignment.centerLeft,
              child: Container(color: fill),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PlotVisualState { seedling, growing, almostFull, ready, withering }

enum _PlotKind { discretionary, fixedObligation }

class _PlotVisuals {
  const _PlotVisuals({
    required this.bg,
    required this.borderColor,
    required this.borderWidth,
    required this.statusColor,
  });

  final Color bg;
  final Color borderColor;
  // 1.5 on state-coded states (ready / almostFull / withering) so the
  // colored border itself carries part of the signal; 1.0 elsewhere so
  // neutral rows feel like quiet containers rather than outlined boxes.
  final double borderWidth;
  final Color statusColor;

  static _PlotVisuals forState(
    _PlotVisualState state, {
    required bool isUnplanned,
  }) {
    if (isUnplanned) {
      // Wild patch — soft tan ground, neutral border, muted status text.
      // Wash sits between bgPlot (#D4C8A8) and the cream page so the row
      // doesn't shout against neighboring white plots.
      return const _PlotVisuals(
        bg: Color(0xFFE0D7BD),
        borderColor: CropkeepColors.borderPlot,
        borderWidth: 1.0,
        statusColor: CropkeepColors.textSecondary,
      );
    }
    switch (state) {
      case _PlotVisualState.seedling:
        return const _PlotVisuals(
          bg: Color(0xFFE0D7BD),
          borderColor: CropkeepColors.borderPlot,
          borderWidth: 1.0,
          statusColor: CropkeepColors.textSecondary,
        );
      case _PlotVisualState.growing:
        return const _PlotVisuals(
          bg: Colors.white,
          borderColor: CropkeepColors.borderCard,
          borderWidth: 1.0,
          statusColor: CropkeepColors.textSecondary,
        );
      case _PlotVisualState.almostFull:
        // Wash halved from #FFFBE8 toward cream so the row reads as a "tint",
        // not a state alert. Deep gold keeps the status text AA on the wash.
        return const _PlotVisuals(
          bg: Color(0xFFFFFCF1),
          borderColor: CropkeepColors.goldPrimary,
          borderWidth: 1.5,
          statusColor: CropkeepColors.textGoldDeep,
        );
      case _PlotVisualState.ready:
        // Wash halved from bgPlotReady (#D6F0C2) toward cream. Deep green
        // keeps the status text AA on the wash.
        return const _PlotVisuals(
          bg: Color(0xFFE4F4D2),
          borderColor: CropkeepColors.borderPlotReady,
          borderWidth: 1.5,
          statusColor: CropkeepColors.textGreenDeep,
        );
      case _PlotVisualState.withering:
        // Match almost-full's pattern: tinted wash bg + full colored border
        // + matching status color. Wash halved from #FDECEC so a list of
        // plots with one withering row doesn't read as alarm-flooded.
        return const _PlotVisuals(
          bg: Color(0xFFFCF4F4),
          borderColor: CropkeepColors.borderPlotWarn,
          borderWidth: 1.5,
          statusColor: CropkeepColors.textRedDeep,
        );
    }
  }
}

// "Add plot" sits in the same list as data rows but should not read as one.
// A dashed border signals "secondary action / placeholder" — universal UX
// convention — so the eye treats it as optional rather than another item to
// scan. Painted via _DashedRoundedBorderPainter (below) so the dash spacing
// is consistent with the row's 16px radius.
class _AddPlotRow extends StatelessWidget {
  const _AddPlotRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        // foregroundPainter (not painter) so the dashes paint OVER the
        // Container's fill — `painter` draws before the child, which the
        // Container then completely covers.
        child: CustomPaint(
          foregroundPainter: const _DashedRoundedBorderPainter(
            color: CropkeepColors.borderPlot,
            strokeWidth: 1.5,
            radius: 16,
            dashLength: 6,
            gapLength: 4,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: CropkeepColors.bgScreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: CropkeepColors.textNavInactive,
                ),
                SizedBox(width: 8),
                Text(
                  'Add plot',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textNavInactive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Paints a dashed rounded-rectangle outline. PathMetrics walks the rounded
// path so dashes hug the curve correctly instead of skipping at the corners.
class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.gapLength,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth / 2,
            strokeWidth / 2,
            size.width - strokeWidth,
            size.height - strokeWidth,
          ),
          Radius.circular(radius),
        ),
      );

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRoundedBorderPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

// ──────────────────────────────────────────────────────────────────────────
// Foundation / bonus wells — vertical list with divider rows + Add footer.

class _WellsSectionCard extends StatelessWidget {
  const _WellsSectionCard({
    required this.title,
    required this.wells,
    required this.addLabel,
    required this.leadingAsset,
  });

  final String title;
  final List<_SampleWell> wells;
  final String addLabel;
  // 18px glyph from the existing illustrative icon set — anchors the
  // section header in the same visual language as the row icons and gives
  // wayfinding a quiet, brand-consistent touch.
  final String leadingAsset;

  @override
  Widget build(BuildContext context) {
    final int sectionTotal = wells.fold<int>(
      0,
      (sum, w) => sum + w.loggedThisCycle,
    );
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _SectionHeader(title, leadingAsset: leadingAsset),
              ),
              // Per-section total — replaces the count badge so each section
              // header carries the answer to "how much is in here this
              // cycle?" without making the summary hero re-do the math.
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    height: 1,
                  ),
                  children: [
                    TextSpan(
                      text: _formatMoney(sectionTotal, r'$', 2),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: CropkeepColors.textPrimary,
                      ),
                    ),
                    const TextSpan(text: ' this cycle'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (int i = 0; i < wells.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: CropkeepColors.borderDivider,
              ),
            _WellRow(well: wells[i]),
          ],
          const Divider(
            height: 1,
            thickness: 1,
            color: CropkeepColors.borderDivider,
          ),
          _AddWellRow(label: addLabel),
        ],
      ),
    );
  }
}

class _WellRow extends StatelessWidget {
  const _WellRow({required this.well});

  final _SampleWell well;

  @override
  Widget build(BuildContext context) {
    final Color iconBg = well.isBonus
        ? CropkeepColors.bgGoldWash
        : CropkeepColors.greenHint;
    final String trailingCaption =
        well.isCarryover ? 'Rolled over' : 'This cycle';

    return InkWell(
      onTap: () => _comingSoon(
        context,
        well.isCarryover
            ? 'The Carryover well is system-managed.'
            : (well.isBonus
                ? 'Log bonus income — coming soon.'
                : 'Log foundation income — coming soon.'),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: SvgPicture.asset(
                    well.iconAsset,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ),
                if (well.isCarryover)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: CropkeepColors.goldPrimary,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: SvgPicture.asset(
                        'assets/icons/carryover.svg',
                        width: 11,
                        height: 11,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    well.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CropkeepColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  if (well.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      well.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: CropkeepColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailingCaption,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    letterSpacing: 0.4,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatMoney(well.loggedThisCycle, r'$', 2),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: CropkeepColors.textPrimary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Lives inside a bordered card alongside data rows, so a dashed border (as
// used on _AddPlotRow) would over-decorate. Instead the `+` sits inside a
// small cream pill so the row reads as a chip-style CTA rather than another
// list entry.
class _AddWellRow extends StatelessWidget {
  const _AddWellRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _comingSoon(context, '$label — coming soon.'),
      borderRadius: BorderRadius.circular(8),
      // Asymmetric padding (20 top / 4 bottom) so the content sits visually
      // centered between the divider above and the card edge below: the
      // section card adds 16px below this row, so 4 + 16 = 20 matches the
      // 20px top. Symmetric 12/12 looked top-biased because the card's
      // bottom padding wasn't being accounted for.
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: CropkeepColors.bgScreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: CropkeepColors.textNavInactive,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textNavInactive,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Sample data — hardcoded so the screen is visually populated while the data
// layer catches up. All amounts are in base-currency minor units (cents).

class _SamplePlot {
  const _SamplePlot({
    required this.name,
    required this.iconAsset,
    required this.budget,
    required this.spent,
    required this.state,
    required this.kind,
    this.statusLabel,
    this.dueDay,
    this.isUnplanned = false,
    this.incomeSharePct,
  });

  final String name;
  final String iconAsset;
  final int? budget;
  final int spent;
  final _PlotVisualState state;
  final _PlotKind kind;
  final String? statusLabel;
  final int? dueDay;
  final bool isUnplanned;
  final double? incomeSharePct;
}

class _SampleWell {
  const _SampleWell({
    required this.name,
    required this.iconAsset,
    required this.subtitle,
    required this.loggedThisCycle,
    required this.isBonus,
    this.isCarryover = false,
  });

  final String name;
  final String iconAsset;
  final String? subtitle;
  final int loggedThisCycle;
  final bool isBonus;
  final bool isCarryover;
}

// Foundation total: Salary 4,000.00 + Rental 800.00 = 4,800.00.
const int _sampleFoundationTotal = 480000;

// Display order on the Crops grid: Unplanned first, then state-sorted
// discretionary (withering → almost-full → growing), then fixed-obligation.
// This makes the most-concerning plots surface near the top.
const List<_SamplePlot> _samplePlots = [
  _SamplePlot(
    name: 'Unplanned',
    // TODO: swap to a dedicated wildflower sticker once that asset lands —
    // see md/graphics.md. Cornucopia stands in as a warm, neutral placeholder.
    iconAsset: 'assets/icons/cornucopia.svg',
    budget: null,
    spent: 4500,
    state: _PlotVisualState.growing,
    kind: _PlotKind.discretionary,
    isUnplanned: true,
    incomeSharePct: 3.2,
  ),
  _SamplePlot(
    name: 'Fun money',
    iconAsset: 'assets/icons/crops/icons8-blueberry.svg',
    budget: 15000,
    spent: 15800,
    state: _PlotVisualState.withering,
    kind: _PlotKind.discretionary,
  ),
  _SamplePlot(
    name: 'Transport',
    iconAsset: 'assets/icons/crops/icons8-corn.svg',
    budget: 30000,
    spent: 26000,
    state: _PlotVisualState.almostFull,
    kind: _PlotKind.discretionary,
  ),
  _SamplePlot(
    name: 'Food',
    iconAsset: 'assets/icons/crops/icons8-strawberry.svg',
    budget: 60000,
    spent: 32000,
    state: _PlotVisualState.growing,
    kind: _PlotKind.discretionary,
  ),
  _SamplePlot(
    name: 'Rent',
    iconAsset: 'assets/icons/crops/apple.svg',
    budget: 150000,
    spent: 150000,
    state: _PlotVisualState.ready,
    kind: _PlotKind.fixedObligation,
    statusLabel: 'Paid · day 5',
    dueDay: 5,
  ),
  _SamplePlot(
    name: 'Subscriptions',
    iconAsset: 'assets/icons/crops/wheat.svg',
    budget: 8000,
    spent: 0,
    state: _PlotVisualState.seedling,
    kind: _PlotKind.fixedObligation,
    statusLabel: 'Awaiting · day 15',
    dueDay: 15,
  ),
];

const List<_SampleWell> _sampleFoundationWells = [
  _SampleWell(
    name: 'Salary',
    iconAsset: 'assets/icons/well.svg',
    subtitle: 'Expected \$4,000.00 / cycle',
    loggedThisCycle: 360000,
    isBonus: false,
  ),
  _SampleWell(
    name: 'Rental',
    iconAsset: 'assets/icons/well.svg',
    subtitle: 'Expected \$800.00 / cycle',
    loggedThisCycle: 0,
    isBonus: false,
  ),
];

const List<_SampleWell> _sampleBonusWells = [
  _SampleWell(
    name: 'Carryover',
    iconAsset: 'assets/icons/water-bottle.svg',
    subtitle: 'From last cycle\'s rollover',
    loggedThisCycle: 12000,
    isBonus: true,
    isCarryover: true,
  ),
  _SampleWell(
    name: 'Freelance',
    iconAsset: 'assets/icons/water-bottle.svg',
    subtitle: 'Estimate ~\$500 – \$1,500',
    loggedThisCycle: 70000,
    isBonus: true,
  ),
];

// ──────────────────────────────────────────────────────────────────────────
// Shared primitives — mirror of farmer_screen.dart conventions. Once both
// screens settle, lift these into lib/widgets/.

// Hero chrome — distinct from _SectionCard on purpose. The hero blocks (the
// page-defining number you read first) need to feel like a different kind
// of object than the white data cards underneath, otherwise they read as
// peers and the hierarchy flattens. Differential signals:
//   • warm sand wash (bgHero) instead of white
//   • 18px radius vs data 16px — slightly softer corner
//   • 20px padding vs data 16px — more breathing room
//   • stronger ambient lift (12px blur, 3px y) so the card sits "above"
//     the data layer rather than next to it
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  static const RoundedRectangleBorder _shape = RoundedRectangleBorder(
    side: BorderSide(color: CropkeepColors.borderCard, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(18)),
  );
  static const EdgeInsets _padding = EdgeInsets.all(20);
  static const List<BoxShadow> _shadow = [
    BoxShadow(
      color: CropkeepColors.shadowCard,
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final Widget inner = Padding(padding: _padding, child: child);
    final Widget card = onTap == null
        ? Material(
            color: CropkeepColors.bgHero,
            shape: _shape,
            child: inner,
          )
        : Material(
            color: CropkeepColors.bgHero,
            shape: _shape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(onTap: onTap, child: inner),
          );
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        boxShadow: _shadow,
      ),
      child: card,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  // Single source of truth for the card frame. Putting the border on the
  // Material via `shape` keeps the rounded edge crisp — a Container+border
  // + child Material previously painted the inner Material over the inside
  // of the border, swallowing it at the corners.
  static const RoundedRectangleBorder _shape = RoundedRectangleBorder(
    side: BorderSide(color: CropkeepColors.borderCard, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  static const EdgeInsets _padding = EdgeInsets.all(16);
  // Ambient lift — paints under the Material's rounded bounds so the card
  // separates from the cream page without a heavy outline.
  static const List<BoxShadow> _shadow = [
    BoxShadow(
      color: CropkeepColors.shadowCard,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: _shadow,
      ),
      child: Material(
        color: Colors.white,
        shape: _shape,
        child: Padding(padding: _padding, child: child),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.leadingAsset});

  final String title;
  // Optional 18px SVG glyph that prefixes the title. Pulls from Cropkeep's
  // illustrative icon set so section headers feel like part of the same
  // visual language as the row icons — quieter than a Material icon would.
  final String? leadingAsset;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      title,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: CropkeepColors.textPrimary,
        letterSpacing: -0.1,
      ),
    );
    if (leadingAsset == null) return label;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: SvgPicture.asset(leadingAsset!, fit: BoxFit.contain),
        ),
        const SizedBox(width: 8),
        label,
      ],
    );
  }
}

void _comingSoon(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
        ),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

String _formatMoney(int minorUnits, String symbol, int decimals) {
  final int absUnits = minorUnits.abs();
  int divisor = 1;
  for (int i = 0; i < decimals; i++) {
    divisor *= 10;
  }
  final int whole = absUnits ~/ divisor;
  final String wholeStr = _withThousandsSeparator(whole);
  final String sign = minorUnits < 0 ? '-' : '';
  if (decimals == 0) return '$sign$symbol$wholeStr';
  final String frac =
      (absUnits % divisor).toString().padLeft(decimals, '0');
  return '$sign$symbol$wholeStr.$frac';
}

String _withThousandsSeparator(int value) {
  final String s = value.toString();
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) out.write(',');
    out.write(s[i]);
  }
  return out.toString();
}
