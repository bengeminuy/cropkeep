import 'package:drift/drift.dart';

import 'cycles.dart';
import 'enum_converters.dart';

enum CoinReason {
  plotHarvestedHealthy,
  unplannedHealthyShare,
  cycleOverallPositive,
  cycleComboBonus,
  // Dormant — set bonuses are paused for v1 (see md/to-do.md). The
  // enum value and the 'crop_set_bonus' CHECK entry below stay in place
  // because dropping the CHECK string requires a `.g.dart` regen, and
  // build_runner 2.15.0 is broken on Dart 3.10. Nothing inserts rows
  // with this reason while the feature is paused.
  cropSetBonus,
  surplusSaved,
  // Dormant — progression (XP, levels, badges) was removed from v1.
  badgeUnlocked,
  levelUpBonus,
  marketPurchase,
  manualAdjustment,
}

@DataClassName('CoinLedgerRow')
class CoinLedger extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cycleId => integer().nullable().references(Cycles, #id)();
  IntColumn get amount => integer()();
  TextColumn get reason =>
      text().map(const SnakeEnumConverter<CoinReason>(CoinReason.values))();
  IntColumn get relatedId => integer().nullable()();
  TextColumn get relatedType => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get occurredAt => integer()();

  @override
  List<String> get customConstraints => [
        "CHECK (reason IN ("
            "'plot_harvested_healthy', 'unplanned_healthy_share', "
            "'cycle_overall_positive', 'cycle_combo_bonus', 'crop_set_bonus', "
            "'surplus_saved', 'badge_unlocked', 'level_up_bonus', "
            "'market_purchase', 'manual_adjustment'"
            "))",
      ];
}
