import 'package:drift/drift.dart';

@DataClassName('SavingsBarnRow')
class SavingsBarn extends Table {
  IntColumn get id => integer()();
  IntColumn get totalSaved => integer().withDefault(const Constant(0))();
  TextColumn get barnSkinId => text().withDefault(const Constant('default'))();
  IntColumn get lastUpdatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (id = 1)'];
}
