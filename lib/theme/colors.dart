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
}
