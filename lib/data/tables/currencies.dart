import 'package:drift/drift.dart';

@DataClassName('CurrencyRow')
class Currencies extends Table {
  TextColumn get code => text().withLength(min: 3, max: 3)();
  TextColumn get symbol => text()();
  TextColumn get name => text()();
  IntColumn get decimalPlaces => integer()();
  BoolColumn get isBase => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {code};

  @override
  List<String> get customConstraints => [
        'CHECK (decimal_places >= 0 AND decimal_places <= 4)',
      ];
}
