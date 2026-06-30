import 'package:drift/drift.dart';

import '../database.dart';
import '../pending_rates_store.dart';
import '../../services/fx_rates_service.dart';

class ExchangeRateRepository {
  ExchangeRateRepository(
    this._db, {
    FxRatesService? fxService,
    required PendingRatesStore pendingRates,
  })  : _fxService = fxService ?? FxRatesService(),
        _pendingRates = pendingRates;

  final AppDatabase _db;
  final FxRatesService _fxService;
  final PendingRatesStore _pendingRates;

  Stream<List<ExchangeRateRow>> watchForCycle(int cycleId) {
    return (_db.select(_db.exchangeRates)
          ..where((t) => t.cycleId.equals(cycleId)))
        .watch();
  }

  Future<List<ExchangeRateRow>> readForCycle(int cycleId) {
    return (_db.select(_db.exchangeRates)
          ..where((t) => t.cycleId.equals(cycleId)))
        .get();
  }

  // Upserts a single rate row on the (cycleId, fromCode, toCode) unique
  // key. `setAt` is refreshed on every write so "last fetched/edited"
  // displays stay accurate.
  Future<void> upsertRate({
    required int cycleId,
    required String fromCode,
    required String toCode,
    required double rate,
    DateTime? setAt,
  }) async {
    final stamp = (setAt ?? DateTime.now()).millisecondsSinceEpoch;
    await _db.into(_db.exchangeRates).insert(
          ExchangeRatesCompanion.insert(
            cycleId: cycleId,
            fromCurrencyCode: fromCode,
            toCurrencyCode: toCode,
            rate: rate,
            setAt: stamp,
          ),
          onConflict: DoUpdate(
            (_) => ExchangeRatesCompanion(
              rate: Value(rate),
              setAt: Value(stamp),
            ),
            target: [
              _db.exchangeRates.cycleId,
              _db.exchangeRates.fromCurrencyCode,
              _db.exchangeRates.toCurrencyCode,
            ],
          ),
        );
  }

  // Fetches fresh rates from the FX provider and upserts one row per
  // secondary code → base. Throws (via `FxRatesException`) when the
  // provider is unreachable so the caller can show a manual-entry UI.
  // Cycle-close should call this once the next cycle becomes active so
  // day one of every cycle starts with current rates.
  Future<void> snapshotFromApi({
    required int cycleId,
    required String baseCode,
    required List<String> secondaryCodes,
  }) async {
    if (secondaryCodes.isEmpty) return;
    final rates = await _fxService.fetchRatesToBase(
      baseCode: baseCode,
      targetCodes: secondaryCodes,
    );
    final now = DateTime.now();
    await _db.transaction(() async {
      for (final entry in rates.entries) {
        await upsertRate(
          cycleId: cycleId,
          fromCode: entry.key,
          toCode: baseCode,
          rate: entry.value,
          setAt: now,
        );
      }
    });
  }

  // Pre-cycle counterpart to `snapshotFromApi`: fetches fresh rates and
  // writes them into the pending-rates store instead of the
  // `exchange_rates` table. Used by the rates sheet's Refresh button
  // before the user has tapped Begin tracking. Throws via
  // `FxRatesException` for the same reasons as `snapshotFromApi`.
  Future<void> snapshotPendingFromApi({
    required String baseCode,
    required List<String> secondaryCodes,
  }) async {
    if (secondaryCodes.isEmpty) return;
    final rates = await _fxService.fetchRatesToBase(
      baseCode: baseCode,
      targetCodes: secondaryCodes,
    );
    await _pendingRates.upsertMany(rates);
  }

  // Fire-and-forget launch hook: skip if today's rates are already
  // written, otherwise pull a fresh snapshot. Caller swallows network
  // exceptions so the UI never blocks on FX availability.
  Future<void> refreshDailyIfStale({
    required int cycleId,
    required String baseCode,
    required List<String> secondaryCodes,
  }) async {
    if (await hasFreshRatesForToday(
      cycleId: cycleId,
      baseCode: baseCode,
      secondaryCodes: secondaryCodes,
    )) {
      return;
    }
    await snapshotFromApi(
      cycleId: cycleId,
      baseCode: baseCode,
      secondaryCodes: secondaryCodes,
    );
  }

  // True when every secondary code has a row for this cycle whose
  // `setAt` is on the same local calendar day as `now`. Used by the
  // daily-refresh trigger on app launch to no-op if today's fetch
  // already happened.
  Future<bool> hasFreshRatesForToday({
    required int cycleId,
    required String baseCode,
    required List<String> secondaryCodes,
    DateTime? now,
  }) async {
    if (secondaryCodes.isEmpty) return true;
    final reference = now ?? DateTime.now();
    final dayStart = DateTime(reference.year, reference.month, reference.day)
        .millisecondsSinceEpoch;
    final rows = await readForCycle(cycleId);
    for (final code in secondaryCodes) {
      final match = rows.firstWhere(
        (r) =>
            r.fromCurrencyCode == code &&
            r.toCurrencyCode == baseCode &&
            r.setAt >= dayStart,
        orElse: () => _missing,
      );
      if (identical(match, _missing)) return false;
    }
    return true;
  }
}

final ExchangeRateRow _missing = ExchangeRateRow(
  id: -1,
  cycleId: -1,
  fromCurrencyCode: '',
  toCurrencyCode: '',
  rate: 0,
  setAt: 0,
);
