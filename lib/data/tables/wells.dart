import 'package:drift/drift.dart';

import 'currencies.dart';

enum WellType { foundation, bonus }

@DataClassName('WellRow')
class Wells extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get wellType => textEnum<WellType>()();
  BoolColumn get isCarryover => boolean().withDefault(const Constant(false))();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).references(Currencies, #code)();
  IntColumn get expectedAmount => integer().nullable()();
  IntColumn get estimateMin => integer().nullable()();
  IntColumn get estimateMax => integer().nullable()();
  TextColumn get wellIconId => text().withDefault(const Constant('default'))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();

  @override
  List<String> get customConstraints => [
        "CHECK (well_type IN ('foundation', 'bonus'))",
        "CHECK (is_carryover = 0 OR well_type = 'bonus')",
        "CHECK (well_type <> 'foundation' OR expected_amount IS NOT NULL)",
      ];
}
