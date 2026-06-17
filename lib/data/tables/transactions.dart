import 'package:drift/drift.dart';

import 'currencies.dart';
import 'cycles.dart';
import 'plots.dart';

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get plotId => integer().references(Plots, #id)();
  IntColumn get cycleId => integer().references(Cycles, #id)();
  IntColumn get amount => integer()();
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).references(Currencies, #code)();
  IntColumn get baseAmount => integer()();
  IntColumn get plotAmount => integer()();
  RealColumn get exchangeRate => real()();
  IntColumn get spentAt => integer()();
  TextColumn get note => text().nullable()();
  BoolColumn get isEmergency => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer().nullable()();
  IntColumn get deletedAt => integer().nullable()();
}
