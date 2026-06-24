import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';

// ──────────────────────────────────────────────────────────────────────────
// BreakdownEnvelopeHeader — full-bleed sand band that IS the drill-down
// screen's identity. Replaces the generic Material AppBar + inset
// StatusHeaderCard pattern: the user just tapped a sand-toned hero card
// on Crops, and this band is the visual continuation of that surface
// (same bgHero, same shadow tokens, rounded bottom corners).
//
// Carries the back arrow, an uppercase eyebrow (e.g. "CYCLE LEDGER" with
// a small ledger mark on the spending breakdown, or the plot's kind label
// on the plot breakdown), the page title, the spent headline with an
// inline " · $X over" overrun chip when applicable, the reference/cycle
// caption, and a spent-vs-reference progress bar. All page-defining
// context lives here instead of being repeated by a card below.

class BreakdownEnvelopeHeader extends StatelessWidget {
  const BreakdownEnvelopeHeader({
    super.key,
    this.iconAsset,
    this.eyebrowMarkAsset,
    required this.eyebrowText,
    required this.title,
    required this.amountMinor,
    this.overrunMinor = 0,
    required this.captionSpans,
    required this.progressFraction,
  });

  // Large left-side identity icon (56px). Plot breakdown supplies the
  // plot SVG; spending breakdown leaves this null since there's no single
  // icon for "the whole cycle."
  final String? iconAsset;
  // Small mark (14px) to the left of the eyebrow text. Spending
  // breakdown supplies ledger.svg here; plot breakdown leaves it null
  // since the plot icon already plays the identity role.
  final String? eyebrowMarkAsset;
  final String eyebrowText;
  final String title;
  // Spent amount in minor units (cents). The header formats it internally
  // so callers don't have to keep a formatter in sync with each other.
  final int amountMinor;
  // Positive when spent exceeds reference (income/budget); 0 otherwise.
  // Surfaced as an inline red chip beside the spent amount.
  final int overrunMinor;
  // Reference + cycle position caption ("of $X budget · Day N of M",
  // or for the wild patch "of $X income · Y% of income · Day N of M").
  // Pre-composed by the caller because the reference noun and the
  // optional share fragment vary per screen.
  final List<InlineSpan> captionSpans;
  // Fraction of the reference consumed (spent/budget or spent/income, or
  // share/danger-cap for the wild patch). Clamped to [0, 1] internally;
  // overrun is signaled by the inline chip, the bar itself never goes red.
  final double progressFraction;

  @override
  Widget build(BuildContext context) {
    final bool isOver = overrunMinor > 0;
    // Status-bar icons need to read dark against the sand band that
    // extends under the system inset.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: CropkeepColors.bgHero,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: CropkeepColors.shadowCard,
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back arrow kept at the leading position a Material AppBar
                // would put it in, so muscle memory still works. Pastel-glyph
                // SVG (built-in circle outline carries the button affordance,
                // no extra pill chrome needed) tinted to textSecondaryOnHero
                // so the arrow reads as native to the sand band rather than
                // a pure-black foreign glyph.
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/back.svg',
                    width: 28,
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      CropkeepColors.textSecondaryOnHero,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IdentityStrip(
                        iconAsset: iconAsset,
                        eyebrowMarkAsset: eyebrowMarkAsset,
                        eyebrowText: eyebrowText,
                        title: title,
                      ),
                      const SizedBox(height: 14),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _formatMoney(amountMinor),
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: CropkeepColors.textPrimary,
                                  height: 1,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const TextSpan(
                                text: ' spent',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: CropkeepColors.textSecondaryOnHero,
                                  height: 1,
                                ),
                              ),
                              if (isOver)
                                TextSpan(
                                  text:
                                      '  ·  ${_formatMoney(overrunMinor)} over',
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: CropkeepColors.textRedDeep,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: CropkeepColors.textSecondaryOnHero,
                            height: 1.3,
                          ),
                          children: captionSpans,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HeaderProgressBar(fraction: progressFraction),
                    ],
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

class _IdentityStrip extends StatelessWidget {
  const _IdentityStrip({
    this.iconAsset,
    this.eyebrowMarkAsset,
    required this.eyebrowText,
    required this.title,
  });

  final String? iconAsset;
  final String? eyebrowMarkAsset;
  final String eyebrowText;
  final String title;

  @override
  Widget build(BuildContext context) {
    const TextStyle eyebrowStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: CropkeepColors.textGoldDeep,
      letterSpacing: 0.8,
      height: 1,
    );
    const TextStyle titleStyle = TextStyle(
      fontFamily: 'Nunito',
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: CropkeepColors.textPrimary,
      height: 1.1,
      letterSpacing: -0.3,
    );

    final Widget textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (eyebrowMarkAsset != null) ...[
              SvgPicture.asset(eyebrowMarkAsset!, width: 14, height: 14),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                eyebrowText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: eyebrowStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
      ],
    );

    if (iconAsset == null) return textBlock;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: SvgPicture.asset(iconAsset!, fit: BoxFit.contain),
        ),
        const SizedBox(width: 14),
        Expanded(child: textBlock),
      ],
    );
  }
}

// Gold fill on a sand-shadow groove — same visual grammar as the per-row
// share bars on the section card below, so the header bar and the row
// bars read as one consistent "money" track. The bar itself never goes
// red; overrun is signaled by the inline chip on the spent headline.
class _HeaderProgressBar extends StatelessWidget {
  const _HeaderProgressBar({required this.fraction});

  final double fraction;

  static const double _height = 10;

  @override
  Widget build(BuildContext context) {
    final double clamped = fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: _height,
        child: Stack(
          children: [
            Container(color: CropkeepColors.progressTrackOnHero),
            FractionallySizedBox(
              widthFactor: clamped,
              alignment: Alignment.centerLeft,
              child: Container(color: CropkeepColors.textGoldDeep),
            ),
          ],
        ),
      ),
    );
  }
}

// Minor-units (cents) → "$1,234.56". Local copy so this widget has no
// upstream formatter dependency; the two breakdown screens keep their
// own formatters for the row-level amounts they render.
String _formatMoney(int minorUnits, {String symbol = r'$', int decimals = 2}) {
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
