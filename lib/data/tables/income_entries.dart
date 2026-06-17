import 'package:drift/drift.dart';

import 'currencies.dart';
import 'cycles.dart';
import 'wells.dart';

@DataClassName('IncomeEntryRow')
class IncomeEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wellId => integer().references(Wells, #id)();
  IntColumn get cycleId => integer().references(Cycles, #id)();
  IntColumn get amount => integer()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).references(Currencies, #code)();
  IntColumn get baseAmount => integer()();
  RealColumn get exchangeRate => real()();
  IntColumn get receivedAt => integer()();
  TextColumn get note => text().nullable()();
  BoolColumn get isSystemGenerated =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
}
