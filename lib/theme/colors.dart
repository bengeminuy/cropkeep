import 'package:flutter/material.dart';

/// Cropkeep color tokens.
///
/// Tokens are organized to match `colors.md`. Always reference colors by
/// semantic name (e.g. `textGreen`) rather than by hex, even when two tokens
/// share a value — the meaning is what should drive the call site.
class CropkeepColors {
  const CropkeepColors._();

  // Backgrounds
  static const Color bgScreen = Color(0xFFFAF6EE);
  static const Color bgNav = Color(0xFFE5D2A8);
  static const Color bgPlot = Color(0xFFD4C8A8);
  static const Color bgPlotReady = Color(0xFFD6F0C2);
  static const Color bgPageAlt = Color(0xFFE8EEF4);
  static const Color bgGoldWash = Color(0xFFFEF3D0);
  // Sand wash sitting between bgScreen and bgNav — reserved for hero
  // surfaces (page-defining numbers) so they read distinct from the
  // white data cards beneath them. Tuned deeper than first pass so the
  // surface jumps out from bgScreen without drifting into bgNav territory.
  static const Color bgHero = Color(0xFFECDFC0);

  // Navigation bar (floating island)
  static const Color bgPillActive = Color(0xFFFAF6EE);
  static const Color borderNav = Color(0xFFA88458);
  static const Color shadowNav = Color(0x33604015);
  static const Color textNavInactive = Color(0xFF6B5530);
  static const Color iconNavInactive = Color(0xFFA89070);

  // Greens — growth & health
  static const Color greenPrimary = Color(0xFF5BAF3A);
  static const Color greenLight = Color(0xFFD6F0C2);
  static const Color greenHint = Color(0xFFE8F5E0);

  // Gold — currency & rewards
  static const Color goldPrimary = Color(0xFFF0A020);
  static const Color goldWash = Color(0xFFFEF3D0);

  // Alerts & status
  static const Color redAlert = Color(0xFFE53030);
  static const Color bluePremium = Color(0xFF5AACDC);

  // Typography
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textGreen = Color(0xFF5BAF3A);
  static const Color textGold = Color(0xFFF0A020);
  static const Color textRed = Color(0xFFE53030);
  // Deep siblings used when text sits on a same-hue tinted background — the
  // bright primaries fail WCAG AA on washes (≈2.5–3.8:1), these clear ≥5:1.
  static const Color textGreenDeep = Color(0xFF2F7A22);
  static const Color textGoldDeep = Color(0xFFA26800);
  static const Color textRedDeep = Color(0xFFB21F1F);
  // Secondary text on the warm sand bgHero. textSecondary (#888888) lands
  // at ~3.4:1 on sand and fails AA — this warm brown sibling clears 6:1
  // while staying in the same palette family as bgNav text.
  static const Color textSecondaryOnHero = Color(0xFF6B5530);
  static const Color textOnGreenBtn = Color(0xFFFFFFFF);
  static const Color textOnGoldPill = Color(0xFF7A5000);

  // Borders & dividers
  static const Color borderCard = Color(0xFFE0D8CC);
  static const Color borderPlot = Color(0xFFC8BA90);
  static const Color borderPlotReady = Color(0xFF5BAF3A);
  static const Color borderPlotWarn = Color(0xFFE53030);
  static const Color borderGoldPill = Color(0xFFF0A020);
  static const Color borderBluePill = Color(0xFF5AACDC);
  static const Color borderDivider = Color(0xFFEEEBE4);

  // Elevation
  static const Color shadowCard = Color(0x0F000000);

  // Hero-context progress track. greenHint / redAlert@18% (the data-card
  // tracks) sit on white and clash against bgHero — this sand-shadow tone
  // is a third-of-a-step darker than bgHero so the bar reads as a carved
  // groove that accepts both green-deep and red-deep fills harmoniously.
  static const Color progressTrackOnHero = Color(0xFFD8CAA8);
}
