import 'package:drift/drift.dart';

enum CycleState { active, completed, archived }

@DataClassName('CycleRow')
class Cycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get startDate => integer()();
  IntColumn get endDate => integer()();
  TextColumn get state => textEnum<CycleState>()();
  TextColumn get label => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();

  @override
  List<String> get customConstraints => [
        "CHECK (state IN ('active', 'completed', 'archived'))",
      ];
}
