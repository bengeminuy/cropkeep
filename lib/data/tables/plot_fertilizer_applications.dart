import 'package:drift/drift.dart';

import 'cycles.dart';
import 'plots.dart';

@DataClassName('PlotFertilizerApplicationRow')
class PlotFertilizerApplications extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cycleId => integer().references(Cycles, #id)();
  IntColumn get plotId => integer().references(Plots, #id)();
  TextColumn get fertilizerItemId => text()();
  IntColumn get appliedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {cycleId, plotId},
      ];
}
