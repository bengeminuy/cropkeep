import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:share_plus/share_plus.dart';

import '../app_scope.dart';
import '../data/currency_catalog.dart';
import '../data/database.dart';
import '../data/repositories/cycle_repository.dart';
import '../data/tables/cycle_summaries.dart';
import '../data/tables/plot_cycle_results.dart';
import '../services/data_export_service.dart';
import '../theme/colors.dart';
import '../theme/plot_swatches.dart';
import '../widgets/avatar_picker_sheet.dart';
import '../widgets/cropkeep_toast.dart';
import '../widgets/cycle_rates_sheet.dart';
import '../widgets/secondary_currency_picker_sheet.dart';

class FarmerScreen extends StatelessWidget {
  const FarmerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<AppSettingsRow?>(
          stream: scope.appSettings.watch(),
          builder: (context, snap) {
            final settings = snap.data;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileSection(settings: settings),
                  const SizedBox(height: 24),
                  _SavingsBarnSection(
                    baseCurrencyCode: settings?.baseCurrencyCode,
                  ),
                  const SizedBox(height: 20),
                  _HarvestHistorySection(
                    baseCurrencyCode: settings?.baseCurrencyCode,
                  ),
                  // Dev tools section hidden for now — re-mount
                  // `_DevToolsSection` here when testing shortcuts are needed.
                  const SizedBox(height: 20),
                  _SettingsSection(settings: settings),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Profile section — hero block, no card.

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.settings});

  final AppSettingsRow? settings;

  static const double _avatarSize = 104;

  @override
  Widget build(BuildContext context) {
    final String avatarId = settings?.avatarId ?? 'farmer';
    final String name = settings?.farmerName ?? 'Farmer';

    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openAvatarPicker(context, avatarId),
          child: Container(
            width: _avatarSize,
            height: _avatarSize,
            decoration: const BoxDecoration(
              color: CropkeepColors.greenHint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              AvatarPickerSheet.assetFor(avatarId),
              width: 76,
              height: 76,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: CropkeepColors.textPrimary,
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Future<void> _openAvatarPicker(
    BuildContext context,
    String currentAvatarId,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarPickerSheet(currentAvatarId: currentAvatarId),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Savings barn section.

class _SavingsBarnSection extends StatelessWidget {
  const _SavingsBarnSection({required this.baseCurrencyCode});

  final String? baseCurrencyCode;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return _SectionCard(
      child: StreamBuilder<SavingsBarnRow?>(
        stream: scope.savingsBarn.watch(),
        builder: (context, barnSnap) {
          final int total = barnSnap.data?.totalSaved ?? 0;
          return StreamBuilder<CurrencyRow?>(
            stream: _watchBaseCurrency(scope.database, baseCurrencyCode),
            builder: (context, currencySnap) {
              final currency = currencySnap.data;
              final String symbol = currency?.symbol ?? r'$';
              final int decimals = currency?.decimalPlaces ?? 2;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/barn.svg',
                        width: 36,
                        height: 36,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Savings barn',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CropkeepColors.textPrimary,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Saved across all cycles',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: CropkeepColors.textSecondary,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatMoney(total, symbol, decimals),
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: CropkeepColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<List<_SavingsPoint>>(
                    stream: _watchSavingsPoints(scope.database),
                    builder: (context, pointsSnap) {
                      final points =
                          pointsSnap.data ?? const <_SavingsPoint>[];
                      // The cumulative curve needs at least two points to be
                      // meaningful. Below that we surface a cozy empty state.
                      if (points.length < 2) {
                        return const _EmptyStatePlaceholder(
                          iconAsset: 'assets/icons/barn.svg',
                          title: 'Your barn is empty',
                          subtitle:
                              "Save part of each cycle's surplus and watch the barn grow.",
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: _MonthlySavingsChart(
                          points: points,
                          symbol: symbol,
                          decimals: decimals,
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

Stream<CurrencyRow?> _watchBaseCurrency(AppDatabase db, String? code) {
  if (code == null) return Stream<CurrencyRow?>.value(null);
  return (db.select(db.currencies)..where((t) => t.code.equals(code)))
      .watchSingleOrNull();
}

Stream<List<_SavingsPoint>> _watchSavingsPoints(AppDatabase db) {
  final query = db.select(db.cycleSummaries).join([
    innerJoin(db.cycles, db.cycles.id.equalsExp(db.cycleSummaries.cycleId)),
  ])
    ..orderBy([
      OrderingTerm(
        expression: db.cycles.startDate,
        mode: OrderingMode.asc,
      ),
    ]);
  return query.watch().map((rows) => [
        for (final row in rows)
          _SavingsPoint(
            startDate: DateTime.fromMillisecondsSinceEpoch(
              row.readTable(db.cycles).startDate,
            ),
            amountSaved: row.readTable(db.cycleSummaries).amountSaved,
          ),
      ]);
}

class _SavingsPoint {
  const _SavingsPoint({required this.startDate, required this.amountSaved});

  final DateTime startDate;
  final int amountSaved;

  String get monthLabel => _monthAbbrev[startDate.month - 1];
}

class _MonthlySavingsChart extends StatelessWidget {
  const _MonthlySavingsChart({
    required this.points,
    required this.symbol,
    required this.decimals,
  });

  final List<_SavingsPoint> points; // oldest → newest, ≥ 2 entries
  final String symbol;
  final int decimals;

  static const int _windowMonths = 12;

  @override
  Widget build(BuildContext context) {
    final all = points;
    final int splitAt =
        all.length > _windowMonths ? all.length - _windowMonths : 0;
    final List<_SavingsPoint> window = all.sublist(splitAt);

    int prior = 0;
    for (int i = 0; i < splitAt; i++) {
      prior += all[i].amountSaved;
    }

    int running = prior;
    final List<int> cumulative = [];
    for (final p in window) {
      running += p.amountSaved;
      cumulative.add(running);
    }

    final int maxVal = cumulative.last;
    final int range = maxVal - prior;
    final List<double> normalized = range == 0
        ? List<double>.filled(cumulative.length, 0.5)
        : [for (final c in cumulative) (c - prior) / range];

    final int windowDelta = maxVal - prior;
    final bool isFullYear = window.length >= _windowMonths;
    final String subtitle = isFullYear
        ? 'Barn growth · last 12 months'
        : 'Barn growth · last ${window.length} months';
    final String deltaSuffix = isFullYear ? 'this year' : 'to date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CropkeepColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _GrowthDeltaPill(
              amount: windowDelta,
              suffix: deltaSuffix,
              symbol: symbol,
              decimals: decimals,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _GrowthChartCanvas(
          normalized: normalized,
          monthLabels: [for (final p in window) p.monthLabel],
        ),
      ],
    );
  }
}

class _GrowthDeltaPill extends StatelessWidget {
  const _GrowthDeltaPill({
    required this.amount,
    required this.suffix,
    required this.symbol,
    required this.decimals,
  });

  final int amount;
  final String suffix;
  final String symbol;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: CropkeepColors.greenHint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: CropkeepColors.greenLight, width: 1),
      ),
      child: Text(
        '+${_formatMoney(amount, symbol, decimals)} $suffix',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: CropkeepColors.textGreen,
          height: 1,
        ),
      ),
    );
  }
}

class _GrowthChartCanvas extends StatelessWidget {
  const _GrowthChartCanvas({
    required this.normalized,
    required this.monthLabels,
  });

  final List<double> normalized;
  final List<String> monthLabels;

  static const double _curveHeight = 138;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CropkeepColors.bgGoldWash,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      child: Column(
        children: [
          SizedBox(
            height: _curveHeight,
            width: double.infinity,
            child: CustomPaint(
              painter: _AreaCurvePainter(normalized: normalized),
            ),
          ),
          const SizedBox(height: 8),
          _MonthLabelStrip(monthLabels: monthLabels),
        ],
      ),
    );
  }
}

class _MonthLabelStrip extends StatelessWidget {
  const _MonthLabelStrip({required this.monthLabels});

  final List<String> monthLabels;

  @override
  Widget build(BuildContext context) {
    final int n = monthLabels.length;
    if (n < 2) return const SizedBox(height: 12);
    // Show 4 evenly-spaced labels: first, ~⅓, ~⅔, last.
    final Set<int> showIndices = {0, n ~/ 3, (n * 2) ~/ 3, n - 1};
    const labelStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: CropkeepColors.textNavInactive,
      height: 1,
    );
    return SizedBox(
      height: 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final i in showIndices)
            Positioned.fill(
              child: Align(
                alignment: i == 0
                    ? Alignment.centerLeft
                    : i == n - 1
                        ? Alignment.centerRight
                        : FractionalOffset(i / (n - 1), 0.5),
                child: Text(monthLabels[i], style: labelStyle),
              ),
            ),
        ],
      ),
    );
  }
}

class _AreaCurvePainter extends CustomPainter {
  const _AreaCurvePainter({required this.normalized});

  final List<double> normalized;

  // Inset so the curve doesn't kiss the top edge and the end dot has air.
  static const double _topPad = 8;
  static const double _bottomPad = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final int n = normalized.length;
    if (n < 2) return;

    final double usableHeight = size.height - _topPad - _bottomPad;
    final List<Offset> points = [
      for (int i = 0; i < n; i++)
        Offset(
          (i / (n - 1)) * size.width,
          _topPad + (1 - normalized[i]) * usableHeight,
        ),
    ];

    // Catmull-Rom → cubic Bezier (tension 0.5), gives a natural soft curve
    // without overshoot on monotone-rising data.
    final Path linePath = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < n - 1; i++) {
      final Offset p0 = i == 0 ? points[i] : points[i - 1];
      final Offset p1 = points[i];
      final Offset p2 = points[i + 1];
      final Offset p3 = (i + 2) < n ? points[i + 2] : points[i + 1];
      final Offset cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final Offset cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }

    // Fill: close the line down to the bottom corners.
    final Path fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final Paint fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          CropkeepColors.greenPrimary.withValues(alpha: 0.32),
          CropkeepColors.greenLight.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Soft drop-shadow under the curve for depth.
    final Paint shadowPaint = Paint()
      ..color = CropkeepColors.greenPrimary.withValues(alpha: 0.20)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.save();
    canvas.translate(0, 2);
    canvas.drawPath(linePath, shadowPaint);
    canvas.restore();

    // The curve itself.
    final Paint linePaint = Paint()
      ..color = CropkeepColors.greenPrimary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // End dot — gold accent marks "where we are now".
    final Offset end = points.last;
    final Paint endHalo = Paint()
      ..color = CropkeepColors.goldPrimary.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(end, 9, endHalo);
    final Paint endRing = Paint()..color = Colors.white;
    canvas.drawCircle(end, 6, endRing);
    final Paint endFill = Paint()..color = CropkeepColors.goldPrimary;
    canvas.drawCircle(end, 4, endFill);
  }

  @override
  bool shouldRepaint(_AreaCurvePainter old) {
    if (old.normalized.length != normalized.length) return true;
    for (int i = 0; i < normalized.length; i++) {
      if (old.normalized[i] != normalized[i]) return true;
    }
    return false;
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Harvest history section.
//
// Design: a horizontal ribbon of harvest cards, newest first. Each card leads
// with the cycle's surplus (the hero number — per the README's "overall
// outcome matters more than any single plot"); the tier is a small colored
// qualifier with calmer wording on negative ("Tough month") so the timeline
// never feels punishing; per-plot detail lives as a tidy dot strip at the
// bottom rather than a cramped grid. Card backgrounds tint by tier so the
// best cycles pop out of the ribbon at a glance.

class _HarvestHistorySection extends StatelessWidget {
  const _HarvestHistorySection({required this.baseCurrencyCode});

  final String? baseCurrencyCode;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<CurrencyRow?>(
      stream: _watchBaseCurrency(scope.database, baseCurrencyCode),
      builder: (context, currencySnap) {
        final currency = currencySnap.data;
        final String symbol = currency?.symbol ?? r'$';
        final int decimals = currency?.decimalPlaces ?? 2;
        return _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader('Harvest history'),
              StreamBuilder<List<_HarvestEntry>>(
                stream: _watchHarvests(scope.database),
                builder: (context, harvestsSnap) {
                  final harvests =
                      harvestsSnap.data ?? const <_HarvestEntry>[];
                  if (harvests.isEmpty) {
                    return const _EmptyStatePlaceholder(
                      iconAsset: 'assets/icons/cornucopia.svg',
                      title: 'No harvests yet',
                      subtitle:
                          'When your first cycle closes, the result will show up here.',
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(
                      height: _HarvestCard.height,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        itemCount: harvests.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _HarvestCard(
                          harvest: harvests[i],
                          symbol: symbol,
                          decimals: decimals,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

Stream<List<_HarvestEntry>> _watchHarvests(AppDatabase db) {
  // Latest 12 closed cycles, newest first. We pair each summary with its
  // cycle to read the calendar month/year, then batch-load plot results.
  final query = db.select(db.cycleSummaries).join([
    innerJoin(db.cycles, db.cycles.id.equalsExp(db.cycleSummaries.cycleId)),
  ])
    ..orderBy([
      OrderingTerm(
        expression: db.cycleSummaries.completedAt,
        mode: OrderingMode.desc,
      ),
    ])
    ..limit(12);

  return query.watch().asyncMap((rows) async {
    if (rows.isEmpty) return <_HarvestEntry>[];
    final cycleIds = [
      for (final r in rows) r.readTable(db.cycleSummaries).cycleId,
    ];
    final plotResults = await (db.select(db.plotCycleResults)
          ..where((t) => t.cycleId.isIn(cycleIds)))
        .get();
    final byCycle = <int, List<PlotCycleResultRow>>{};
    for (final r in plotResults) {
      byCycle.putIfAbsent(r.cycleId, () => []).add(r);
    }
    return [
      for (final row in rows)
        _harvestEntryFrom(
          summary: row.readTable(db.cycleSummaries),
          cycle: row.readTable(db.cycles),
          plotResults: byCycle[row.readTable(db.cycleSummaries).cycleId] ??
              const [],
        ),
    ];
  });
}

_HarvestEntry _harvestEntryFrom({
  required CycleSummaryRow summary,
  required CycleRow cycle,
  required List<PlotCycleResultRow> plotResults,
}) {
  _HarvestPlot? unplanned;
  final regular = <_HarvestPlot>[];
  for (final p in plotResults) {
    final hp = _HarvestPlot(
      state: p.finalState,
      swatch: plotSwatchFor(p.plotColorIdSnapshot),
    );
    if (p.isUnplanned) {
      unplanned = hp;
    } else {
      regular.add(hp);
    }
  }
  return _HarvestEntry(
    startDate: DateTime.fromMillisecondsSinceEpoch(cycle.startDate),
    tier: summary.resultTier,
    surplus: summary.surplus,
    unplanned: unplanned,
    plots: regular,
  );
}

class _HarvestEntry {
  const _HarvestEntry({
    required this.startDate,
    required this.tier,
    required this.surplus,
    required this.unplanned,
    required this.plots,
  });

  final DateTime startDate;
  final CycleResultTier tier;
  final int surplus; // in minor units; negative for deficit
  final _HarvestPlot? unplanned;
  final List<_HarvestPlot> plots;

  String get monthLabel => _monthAbbrev[startDate.month - 1];
  int get year => startDate.year;
}

// Per-plot snapshot the harvest strip renders. Pairs the cosmetic
// identity (swatch, from plot_color_id_snapshot) with the actionable
// signal (final state).
class _HarvestPlot {
  const _HarvestPlot({required this.state, required this.swatch});
  final PlotFinalState state;
  final Color swatch;
}

// Plot swatch lookup lives in `theme/plot_swatches.dart` so the Farm,
// Farmer, and Ledger surfaces all read from one source.

class _TierVisuals {
  const _TierVisuals({
    required this.label,
    required this.bg,
    required this.border,
    required this.textColor,
    required this.sparkle,
  });

  final String label;
  final Color bg;
  final Color border;
  final Color textColor;
  final bool sparkle;

  static _TierVisuals forTier(CycleResultTier tier) {
    switch (tier) {
      case CycleResultTier.excellent:
        return const _TierVisuals(
          label: 'Excellent',
          bg: CropkeepColors.bgGoldWash,
          border: CropkeepColors.goldPrimary,
          textColor: CropkeepColors.textGold,
          sparkle: true,
        );
      case CycleResultTier.solidlyPositive:
        return const _TierVisuals(
          label: 'Net positive',
          bg: CropkeepColors.greenHint,
          border: CropkeepColors.greenLight,
          textColor: CropkeepColors.textGreen,
          sparkle: false,
        );
      case CycleResultTier.barelyPositive:
        return const _TierVisuals(
          label: 'Just barely',
          bg: Colors.white,
          border: CropkeepColors.borderCard,
          textColor: CropkeepColors.textGold,
          sparkle: false,
        );
      case CycleResultTier.negative:
        return const _TierVisuals(
          label: 'Tough month',
          bg: Colors.white,
          border: CropkeepColors.borderCard,
          textColor: CropkeepColors.textSecondary,
          sparkle: false,
        );
    }
  }
}

class _HarvestCard extends StatelessWidget {
  const _HarvestCard({
    required this.harvest,
    required this.symbol,
    required this.decimals,
  });

  final _HarvestEntry harvest;
  final String symbol;
  final int decimals;

  static const double width = 144;
  static const double height = 132;

  @override
  Widget build(BuildContext context) {
    final tv = _TierVisuals.forTier(harvest.tier);
    final bool isNegative = harvest.surplus < 0;
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: tv.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tv.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${harvest.monthLabel.toUpperCase()}  ${harvest.year}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textNavInactive,
              letterSpacing: 0.7,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              if (tv.sparkle) ...[
                Icon(Icons.auto_awesome, size: 11, color: tv.textColor),
                const SizedBox(width: 3),
              ],
              Flexible(
                child: Text(
                  tv.label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tv.textColor,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // FittedBox keeps the surplus fully visible — most cards render at
          // the natural 18px hero size; only the longest amounts (e.g. an NTD
          // value with no decimals) scale down quietly.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatSurplus(harvest.surplus, symbol, decimals),
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isNegative
                    ? CropkeepColors.textRed
                    : CropkeepColors.textPrimary,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PlotStrip(unplanned: harvest.unplanned, plots: harvest.plots),
        ],
      ),
    );
  }
}

class _PlotStrip extends StatelessWidget {
  const _PlotStrip({required this.unplanned, required this.plots});

  final _HarvestPlot? unplanned;
  final List<_HarvestPlot> plots;

  static const double _dotSize = 13;
  static const double _gap = 4;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (unplanned != null) {
      children.add(_PlotDot(plot: unplanned!, isUnplanned: true));
    }
    for (final p in plots.take(5)) {
      if (children.isNotEmpty) children.add(const SizedBox(width: _gap));
      children.add(_PlotDot(plot: p));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

// Per-plot summary cell. Two channels stacked in one dot:
//   • fill   = plot's cosmetic swatch  (identity — which plot was this?)
//   • border = final-state color       (signal — how did it do?)
// Unplanned takes a rounded square instead of a circle so the wild
// patch reads as "not a tended plot" without leaning on color.
class _PlotDot extends StatelessWidget {
  const _PlotDot({required this.plot, this.isUnplanned = false});

  final _HarvestPlot plot;
  final bool isUnplanned;

  static const double _ringWidth = 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _PlotStrip._dotSize,
      height: _PlotStrip._dotSize,
      decoration: BoxDecoration(
        color: plot.swatch,
        shape: isUnplanned ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isUnplanned ? BorderRadius.circular(3) : null,
        border: Border.all(
          color: _plotStateColor(plot.state),
          width: _ringWidth,
        ),
      ),
    );
  }
}

Color _plotStateColor(PlotFinalState state) {
  // Solid colors only — the ring is a 2px signal layer and alpha-blended
  // reds collapse to pink at that width, which confuses the ring with
  // the swatch fill (identity channel). Severity escalates by *hue*:
  // green (good) → gold (caution) → brick (warning) → bright red (alarm).
  switch (state) {
    case PlotFinalState.harvested:
      return CropkeepColors.greenPrimary;
    case PlotFinalState.mildStress:
      return CropkeepColors.goldPrimary;
    case PlotFinalState.withered:
      return CropkeepColors.textRedDeep;
    case PlotFinalState.dead:
      return CropkeepColors.redAlert;
  }
}

String _formatSurplus(int amount, String symbol, int decimals) {
  if (amount == 0) return _formatMoney(0, symbol, decimals);
  final String sign = amount < 0 ? '−' : '+';
  return '$sign${_formatMoney(amount.abs(), symbol, decimals)}';
}

// ──────────────────────────────────────────────────────────────────────────
// Dev tools — temporary testing shortcuts. Remove before shipping.
//
// • Grant coins: calls AppSettingsRepository.grantCoinsForTesting,
//   which bumps `app_settings.coins_balance` and writes a matching
//   `manualAdjustment` coin_ledger row in one transaction. Mirrors the
//   production write path so the ledger stays the source of truth.
// • Advance cycle: backdates the active cycle's start/end into the
//   previous calendar month via CycleRepository.forceCycleExpiredFor
//   Testing. The Farm tab's _CycleStatusStrip detects past-end on its
//   next stream emission and surfaces the "Cycle ended" banner — from
//   there the user walks through the natural close UX (reconciliation,
//   exchange rates, surplus split). When no active cycle exists yet,
//   kicks off the very first one instead.

// ignore: unused_element
class _DevToolsSection extends StatelessWidget {
  const _DevToolsSection();

  static const int _grantAmount = 1000;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('Dev tools'),
          const SizedBox(height: 6),
          const Text(
            'Temporary shortcuts for testing. Removed before shipping.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: CropkeepColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DevButton(
                  label: '+$_grantAmount coins',
                  icon: Icons.monetization_on_outlined,
                  onPressed: () => _grantCoins(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DevButton(
                  label: 'Advance cycle',
                  icon: Icons.fast_forward_rounded,
                  onPressed: () => _advanceCycle(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _grantCoins(BuildContext context) async {
    final repo = AppScope.of(context).appSettings;
    await repo.grantCoinsForTesting(_grantAmount);
    if (!context.mounted) return;
    CropkeepToast.success(
      context,
      title: '+$_grantAmount coins',
      flavor: 'Granted via Dev tools.',
    );
  }

  Future<void> _advanceCycle(BuildContext context) async {
    final scope = AppScope.of(context);
    final active = await scope.cycles.watchActiveCycle().first;
    if (active == null) {
      // No active cycle — bootstrap the first one with the standard
      // calendar-month range so the rest of the app comes alive without
      // having to walk through onboarding's begin-tracking step.
      final range = CycleRepository.proposedNextCycleRange();
      await scope.cycles.startFirstCycle(
        startDate: range.start,
        endDate: range.end,
      );
      if (!context.mounted) return;
      CropkeepToast.success(
        context,
        title: 'First cycle started',
        flavor: 'Dev tool: kicked off cycle 1.',
      );
      return;
    }
    await scope.cycles.forceCycleExpiredForTesting();
    if (!context.mounted) return;
    CropkeepToast.info(
      context,
      title: 'Cycle marked as ended',
      flavor: 'Open the Farm tab to close it via the normal flow.',
    );
  }
}

class _DevButton extends StatelessWidget {
  const _DevButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: CropkeepColors.greenHint,
          foregroundColor: CropkeepColors.textGreen,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: CropkeepColors.greenLight,
              width: 1,
            ),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Settings (inline).

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.settings});

  final AppSettingsRow? settings;

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).appSettings;
    final String baseCode = settings?.baseCurrencyCode ?? '—';

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader('Settings'),
          const SizedBox(height: 4),
          _SettingsRow(
            label: 'Base currency',
            valueText: _formatBaseValue(baseCode),
          ),
          StreamBuilder<List<CurrencyRow>>(
            stream: repo.watchCurrencies(),
            builder: (context, snap) {
              final rows = snap.data ?? const <CurrencyRow>[];
              return _SettingsRow(
                label: 'Secondary currencies',
                valueText: _formatSecondaryValue(rows),
                trailingChevron: true,
                onTap: () => _openSecondaryPicker(context),
              );
            },
          ),
          _SettingsRow(
            label: 'Exchange rates',
            trailingChevron: true,
            onTap: () => _openRatesSheet(context),
          ),
          _SettingsRow(
            label: 'Reset',
            trailingChevron: true,
            onTap: () => _confirmReset(context),
          ),
          // TODO(export-data): re-enable when the export flow is ready to
          // ship — the row, _exportData(), and DataExportService are wired
          // and only need this _SettingsRow uncommented to come back.
          // _SettingsRow(
          //   label: 'Export data',
          //   trailingChevron: true,
          //   onTap: () => _exportData(context),
          // ),
          // TODO(app-version): read from package_info_plus once available.
          const _SettingsRow(
            label: 'Version',
            valueText: _appVersion,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // Single source for the app version label and the export envelope.
  // Replace with package_info_plus once that dep lands.
  static const String _appVersion = '0.1.0';

  // ignore: unused_element
  Future<void> _exportData(BuildContext context) async {
    final scope = AppScope.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    try {
      final service = DataExportService(scope.database);
      final file = await service.exportToTempFile(
        farmerName: settings?.farmerName ?? '',
        appVersion: _appVersion,
      );
      if (!context.mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Cropkeep backup',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (!context.mounted) return;
      CropkeepToast.error(
        context,
        title: 'Export failed',
        flavor: e.toString(),
        duration: const Duration(seconds: 3),
      );
    }
  }

  String _formatBaseValue(String code) {
    final spec = CurrencyCatalog.findByCode(code);
    if (spec == null) return code;
    return '${spec.code} — ${spec.name}';
  }

  String _formatSecondaryValue(List<CurrencyRow> rows) {
    final enabled = [
      for (final r in rows)
        if (r.isActive && !r.isBase) r.code,
    ];
    if (enabled.isEmpty) return 'None';
    if (enabled.length <= 3) return enabled.join(', ');
    return '${enabled.length} enabled';
  }

  Future<void> _openSecondaryPicker(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SecondaryCurrencyPickerSheet(),
    );
  }

  Future<void> _openRatesSheet(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CycleRatesSheet(),
    );
  }


  Future<void> _confirmReset(BuildContext context) async {
    final repo = AppScope.of(context).appSettings;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const _ResetConfirmDialog(),
    );
    if (confirmed != true) return;
    await repo.resetAll();
    // main.dart's StreamBuilder swaps to OnboardingFlow automatically.
  }
}

class _ResetConfirmDialog extends StatelessWidget {
  const _ResetConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: CropkeepColors.redAlert.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.refresh_rounded,
                  size: 32,
                  color: CropkeepColors.redAlert,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Reset your farm?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1.2,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Everything you\'ve logged will be removed — wells, plots, harvests, coins. You\'ll start over from the welcome screen. This can\'t be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: CropkeepColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CropkeepColors.redAlert,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                child: const Text('Reset everything'),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: CropkeepColors.textSecondary,
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Keep my farm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    this.valueText,
    this.trailingChevron = false,
    this.onTap,
    this.isLast = false,
  });

  final String label;
  final String? valueText;
  final bool trailingChevron;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Widget row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textPrimary,
              ),
            ),
          ),
          if (valueText != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                valueText!,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: CropkeepColors.textSecondary,
                ),
              ),
            ),
          if (trailingChevron)
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: CropkeepColors.textSecondary,
            ),
        ],
      ),
    );

    final Widget tappable = onTap == null
        ? row
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: row,
          );

    if (isLast) return tappable;
    return Column(
      children: [
        tappable,
        const Divider(
          height: 1,
          thickness: 1,
          color: CropkeepColors.borderDivider,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Shared section primitives.

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CropkeepColors.borderCard, width: 1.5),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: CropkeepColors.textPrimary,
      ),
    );
  }
}

class _EmptyStatePlaceholder extends StatelessWidget {
  const _EmptyStatePlaceholder({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
  });

  final String iconAsset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: 0.4,
            child: SvgPicture.asset(iconAsset, width: 52, height: 52),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: CropkeepColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Helpers.

const List<String> _monthAbbrev = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatMoney(int minorUnits, String symbol, int decimals) {
  int divisor = 1;
  for (int i = 0; i < decimals; i++) {
    divisor *= 10;
  }
  final int whole = minorUnits ~/ divisor;
  final String wholeStr = _withThousandsSeparator(whole);
  if (decimals == 0) return '$symbol$wholeStr';
  final String frac =
      (minorUnits % divisor).toString().padLeft(decimals, '0');
  return '$symbol$wholeStr.$frac';
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
