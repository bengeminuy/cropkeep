import 'package:drift/drift.dart';

import 'currencies.dart';
import 'cycles.dart';

@DataClassName('ExchangeRateRow')
class ExchangeRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cycleId => integer().references(Cycles, #id)();
  TextColumn get fromCurrencyCode =>
      text().withLength(min: 3, max: 3).references(Currencies, #code)();
  TextColumn get toCurrencyCode =>
      text().withLength(min: 3, max: 3).references(Currencies, #code)();
  RealColumn get rate => real()();
  IntColumn get setAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {cycleId, fromCurrencyCode, toCurrencyCode},
      ];
}
