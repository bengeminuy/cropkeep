import 'package:drift/drift.dart';

import 'cycles.dart';
import 'plots.dart';

@DataClassName('BonusAllocationRow')
class BonusAllocations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cycleId => integer().references(Cycles, #id)();
  IntColumn get targetPlotId => integer().references(Plots, #id)();
  IntColumn get amount => integer()();
  IntColumn get allocatedAt => integer()();
}
