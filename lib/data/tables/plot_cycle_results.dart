import 'package:drift/drift.dart';

import 'currencies.dart';
import 'cycles.dart';
import 'enum_converters.dart';
import 'plots.dart';

enum PlotFinalState { harvested, mildStress, withered, dead }

@DataClassName('PlotCycleResultRow')
class PlotCycleResults extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cycleId => integer().references(Cycles, #id)();
  IntColumn get plotId => integer().references(Plots, #id)();
  TextColumn get plotNameSnapshot => text()();
  TextColumn get kindSnapshot => text()
      .map(const SnakeEnumConverter<PlotKind>(PlotKind.values))
      .withDefault(const Constant('discretionary'))();
  TextColumn get cropTypeIdSnapshot => text()();
  TextColumn get plotColorIdSnapshot => text().nullable()();
  BoolColumn get isUnplanned => boolean().withDefault(const Constant(false))();
  IntColumn get budgetAmountSnapshot => integer().nullable()();
  TextColumn get currencyCodeSnapshot =>
      text().withLength(min: 3, max: 3).references(Currencies, #code)();
  IntColumn get totalSpent => integer()();
  RealColumn get incomeShareAtClose => real().nullable()();
  TextColumn get finalState => text()
      .map(const SnakeEnumConverter<PlotFinalState>(PlotFinalState.values))();
  IntColumn get completedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {cycleId, plotId},
      ];

  @override
  List<String> get customConstraints => [
        "CHECK (kind_snapshot IN ('discretionary', 'fixed_obligation'))",
        "CHECK (final_state IN ('harvested', 'mild_stress', 'withered', 'dead'))",
      ];
}
