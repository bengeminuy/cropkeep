import 'package:cropkeep/data/database.dart';
import 'package:cropkeep/data/repositories/income_entry_repository.dart';
import 'package:cropkeep/data/repositories/transaction_repository.dart';
import 'package:cropkeep/data/tables/cycles.dart';
import 'package:cropkeep/data/tables/wells.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository txnRepo;
  late IncomeEntryRepository incomeRepo;
  late int cycleId;
  late int plotId;
  late int wellId;

  Future<void> seedConfig() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.currencies).insert(
          CurrenciesCompanion.insert(
            code: 'USD',
            symbol: r'$',
            name: 'US Dollar',
            decimalPlaces: 2,
          ),
        );
    await db.into(db.cropsCatalog).insert(
          CropsCatalogCompanion.insert(
            cropId: 'wheat',
            name: 'Wheat',
            baseCoinYield: 10,
            isStarter: const Value(true),
          ),
        );
    cycleId = await db.into(db.cycles).insert(
          CyclesCompanion.insert(
            startDate: now - 86400000,
            endDate: now + (30 * 86400000),
            state: CycleState.active,
            createdAt: now,
          ),
        );
    plotId = await db.into(db.plots).insert(
          PlotsCompanion.insert(
            name: 'Groceries',
            currencyCode: 'USD',
            cropTypeId: 'wheat',
            budgetAmount: const Value(50000),
            createdAt: now,
          ),
        );
    wellId = await db.into(db.wells).insert(
          WellsCompanion.insert(
            name: 'Salary',
            wellType: WellType.foundation,
            currencyCode: 'USD',
            expectedAmount: const Value(300000),
            createdAt: now,
          ),
        );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    txnRepo = TransactionRepository(db);
    incomeRepo = IncomeEntryRepository(db);
    await seedConfig();
  });

  tearDown(() async {
    await db.close();
  });

  test('logExpense persists row and emits on watchByPlot', () async {
    final id = await txnRepo.logExpense(
      plotId: plotId,
      cycleId: cycleId,
      amountMinor: 1250,
      currencyCode: 'USD',
      baseAmountMinor: 1250,
      plotAmountMinor: 1250,
      exchangeRate: 1.0,
      spentAt: DateTime.now(),
      note: 'milk and eggs',
    );

    expect(id, greaterThan(0));

    final rows =
        await txnRepo.watchByPlot(plotId: plotId, cycleId: cycleId).first;
    expect(rows.length, 1);
    expect(rows.single.baseAmount, 1250);
    expect(rows.single.note, 'milk and eggs');
    expect(rows.single.isEmergency, false);
  });

  test('logExpense with isEmergency tags the row', () async {
    await txnRepo.logExpense(
      plotId: plotId,
      cycleId: cycleId,
      amountMinor: 8000,
      currencyCode: 'USD',
      baseAmountMinor: 8000,
      plotAmountMinor: 8000,
      exchangeRate: 1.0,
      spentAt: DateTime.now(),
      isEmergency: true,
    );

    final rows =
        await txnRepo.watchByPlot(plotId: plotId, cycleId: cycleId).first;
    expect(rows.single.isEmergency, true);
  });

  test('logIncome persists row and emits on watchByWell', () async {
    await incomeRepo.logIncome(
      wellId: wellId,
      cycleId: cycleId,
      amountMinor: 250000,
      currencyCode: 'USD',
      baseAmountMinor: 250000,
      exchangeRate: 1.0,
      receivedAt: DateTime.now(),
    );

    final rows =
        await incomeRepo.watchByWell(wellId: wellId, cycleId: cycleId).first;
    expect(rows.length, 1);
    expect(rows.single.baseAmount, 250000);
    expect(rows.single.isSystemGenerated, false);
  });

  test('softDelete excludes rows from active queries and sums', () async {
    final id = await txnRepo.logExpense(
      plotId: plotId,
      cycleId: cycleId,
      amountMinor: 500,
      currencyCode: 'USD',
      baseAmountMinor: 500,
      plotAmountMinor: 500,
      exchangeRate: 1.0,
      spentAt: DateTime.now(),
    );

    expect(
      (await txnRepo.watchByPlot(plotId: plotId, cycleId: cycleId).first).length,
      1,
    );

    await txnRepo.softDelete(id);

    expect(
      (await txnRepo.watchByPlot(plotId: plotId, cycleId: cycleId).first).length,
      0,
    );
    expect(
      await txnRepo
          .watchPlotSpentMinor(plotId: plotId, cycleId: cycleId)
          .first,
      0,
    );
  });

  test('restore brings a soft-deleted row back', () async {
    final id = await txnRepo.logExpense(
      plotId: plotId,
      cycleId: cycleId,
      amountMinor: 1234,
      currencyCode: 'USD',
      baseAmountMinor: 1234,
      plotAmountMinor: 1234,
      exchangeRate: 1.0,
      spentAt: DateTime.now(),
    );
    await txnRepo.softDelete(id);
    await txnRepo.restore(id);

    final rows =
        await txnRepo.watchByPlot(plotId: plotId, cycleId: cycleId).first;
    expect(rows.length, 1);
  });

  test('watchPlotSpentMinor sums non-deleted expenses', () async {
    final now = DateTime.now();
    for (final amount in [1000, 2500]) {
      await txnRepo.logExpense(
        plotId: plotId,
        cycleId: cycleId,
        amountMinor: amount,
        currencyCode: 'USD',
        baseAmountMinor: amount,
        plotAmountMinor: amount,
        exchangeRate: 1.0,
        spentAt: now,
      );
    }
    final doomed = await txnRepo.logExpense(
      plotId: plotId,
      cycleId: cycleId,
      amountMinor: 9999,
      currencyCode: 'USD',
      baseAmountMinor: 9999,
      plotAmountMinor: 9999,
      exchangeRate: 1.0,
      spentAt: now,
    );
    await txnRepo.softDelete(doomed);

    final total = await txnRepo
        .watchPlotSpentMinor(plotId: plotId, cycleId: cycleId)
        .first;
    expect(total, 3500);
  });

  test('watchWellLoggedMinor sums income entries for a well', () async {
    final now = DateTime.now();
    await incomeRepo.logIncome(
      wellId: wellId,
      cycleId: cycleId,
      amountMinor: 100000,
      currencyCode: 'USD',
      baseAmountMinor: 100000,
      exchangeRate: 1.0,
      receivedAt: now,
    );
    await incomeRepo.logIncome(
      wellId: wellId,
      cycleId: cycleId,
      amountMinor: 150000,
      currencyCode: 'USD',
      baseAmountMinor: 150000,
      exchangeRate: 1.0,
      receivedAt: now,
    );

    final total = await incomeRepo
        .watchWellLoggedMinor(wellId: wellId, cycleId: cycleId)
        .first;
    expect(total, 250000);
  });

  test('CHECK: foundation well requires expected_amount', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    expect(
      () => db.into(db.wells).insert(
            WellsCompanion.insert(
              name: 'Broken',
              wellType: WellType.foundation,
              currencyCode: 'USD',
              createdAt: now,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('CHECK: is_carryover only allowed on bonus wells', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    expect(
      () => db.into(db.wells).insert(
            WellsCompanion.insert(
              name: 'Bad Carryover',
              wellType: WellType.foundation,
              currencyCode: 'USD',
              expectedAmount: const Value(100),
              isCarryover: const Value(true),
              createdAt: now,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('Unique index: only one carryover well allowed', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.wells).insert(
          WellsCompanion.insert(
            name: 'Carryover',
            wellType: WellType.bonus,
            currencyCode: 'USD',
            isCarryover: const Value(true),
            createdAt: now,
          ),
        );
    expect(
      () => db.into(db.wells).insert(
            WellsCompanion.insert(
              name: 'Carryover 2',
              wellType: WellType.bonus,
              currencyCode: 'USD',
              isCarryover: const Value(true),
              createdAt: now,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });
}
