class XpCurve {
  const XpCurve._();

  // README: `100 + (current_level × 50)` to advance from `level` to `level + 1`.
  static int xpForNextLevel(int level) => 100 + level * 50;

  // Cumulative XP a farmer has earned at the moment they reach `level`.
  // Sum of advancement costs for L1→L2 through L(level-1)→Llevel.
  static int xpAtLevelStart(int level) {
    if (level <= 1) return 0;
    final int n = level - 1;
    return n * 100 + 50 * n * (n + 1) ~/ 2;
  }

  static double progress({required int totalXp, required int level}) {
    final int start = xpAtLevelStart(level);
    final int cost = xpForNextLevel(level);
    final double raw = (totalXp - start) / cost;
    if (raw.isNaN || raw < 0) return 0;
    if (raw > 1) return 1;
    return raw;
  }

  static String titleFor(int level) {
    if (level <= 4) return 'Sprout';
    if (level <= 9) return 'Sapling';
    if (level <= 19) return 'Tender';
    if (level <= 49) return 'Steward';
    return 'Elder';
  }
}
