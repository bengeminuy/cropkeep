import 'package:drift/drift.dart';

import 'crops_catalog.dart';
import 'currencies.dart';
import 'enum_converters.dart';

enum PlotKind { discretionary, fixedObligation, investment }

@DataClassName('PlotRow')
class Plots extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get kind => text()
      .map(const SnakeEnumConverter<PlotKind>(PlotKind.values))
      .withDefault(const Constant('discretionary'))();
  IntColumn get budgetAmount => integer().nullable()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).references(Currencies, #code)();
  TextColumn get cropTypeId => text().references(CropsCatalog, #cropId)();
  TextColumn get plotColorId => text().nullable()();
  IntColumn get dueDay => integer().nullable()();
  BoolColumn get isUnplanned => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  List<String> get customConstraints => [
        "CHECK (kind IN ('discretionary', 'fixed_obligation', 'investment'))",
        'CHECK (due_day IS NULL OR (due_day BETWEEN 1 AND 31))',
        "CHECK (is_unplanned = 0 OR kind = 'discretionary')",
        "CHECK (kind <> 'fixed_obligation' OR due_day IS NOT NULL)",
      ];
}
