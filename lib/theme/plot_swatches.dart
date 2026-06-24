import 'package:flutter/painting.dart';

import 'colors.dart';

// Single source of truth for the pastel swatch a plot is painted with.
//
// `plots.plot_color_id` is a free-text column today; the eventual
// plot-color catalog will replace this map with FK lookups. Until then,
// every surface that renders a plot identity (Farm Crops grid, Farmer
// harvest strip, Ledger row icon) reads from here so they agree.
Color plotSwatchFor(String? id) {
  switch (id) {
    case 'sand':
      return const Color(0xFFE6D8BC);
    case 'lavender':
      return const Color(0xFFE1D4F0);
    case 'sky':
      return const Color(0xFFCFE3F2);
    case 'peach':
      return const Color(0xFFFFD9B8);
    case 'pink':
      return const Color(0xFFFFCFD0);
    case 'butter':
      return const Color(0xFFFFE9A8);
    case 'mint':
      return const Color(0xFFCFEBC2);
    default:
      // Null / unknown id falls back to the soft brand-green wash the
      // new-plot form previews, so legacy rows still render coherently.
      return CropkeepColors.greenHint;
  }
}
