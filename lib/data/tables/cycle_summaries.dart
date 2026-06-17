import 'package:drift/drift.dart';

import 'cycles.dart';
import 'enum_converters.dart';

enum CycleResultTier {
  excellent,
  solidlyPositive,
  barelyPositive,
  negative,
}

@DataClassName('CycleSummaryRow')
class CycleSummaries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cycleId => integer().unique().references(Cycles, #id)();
  IntColumn get totalFoundationIncome => integer()();
  IntColumn get totalBonusIncome => integer()();
  IntColumn get totalSpentPlanned => integer()();
  IntColumn get totalSpentUnplanned => integer()();
  IntColumn get totalSpent => integer()();
  IntColumn get surplus => integer()();
  TextColumn get resultTier => text()
      .map(const SnakeEnumConverter<CycleResultTier>(CycleResultTier.values))();
  IntColumn get overallBonusCoins => integer().withDefault(const Constant(0))();
  IntColumn get perPlotCoins => integer().withDefault(const Constant(0))();
  IntColumn get surplusSavedCoins => integer().withDefault(const Constant(0))();
  IntColumn get totalCoinsEarned => integer().withDefault(const Constant(0))();
  IntColumn get amountSaved => integer().withDefault(const Constant(0))();
  IntColumn get amountRolledToNext =>
      integer().withDefault(const Constant(0))();
  IntColumn get completedAt => integer()();

  @override
  List<String> get customConstraints => [
        "CHECK (result_tier IN ('excellent', 'solidly_positive', "
            "'barely_positive', 'negative'))",
        '''CHECK (
            (surplus <= 0 AND amount_saved = 0 AND amount_rolled_to_next = 0)
         OR (surplus > 0  AND amount_saved >= 0 AND amount_rolled_to_next >= 0
                          AND amount_saved + amount_rolled_to_next = surplus)
        )''',
      ];
}
