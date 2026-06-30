import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../data/currency_catalog.dart';
import '../data/database.dart';
import '../data/pending_rates_store.dart';
import '../data/tables/cycles.dart' show CycleState;
import '../services/fx_rates_service.dart';
import '../theme/colors.dart';

// Modal sheet for viewing, editing, and refreshing the active cycle's
// exchange rates. Values are displayed in the per-base form ("1 USD =
// 56.30 PHP") and inverted to storage form (rate-to-base) on save. Each
// row also surfaces a "last fetched" timestamp so the user knows whether
// they're looking at fresh or stale data.
//
// The body uses one-shot reads instead of streams so the user's
// in-progress edits aren't clobbered when the DB updates after a refresh
// or save — those flows explicitly re-sync the controllers.
class CycleRatesSheet extends StatefulWidget {
  const CycleRatesSheet({super.key});

  @override
  State<CycleRatesSheet> createState() => _CycleRatesSheetState();
}

class _CycleRatesSheetState extends State<CycleRatesSheet> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, DateTime?> _setAt = {};
  CycleRow? _cycle;
  CurrencyRow? _baseCurrency;
  List<CurrencyRow> _secondaries = const <CurrencyRow>[];
  bool _loading = true;
  bool _refreshing = false;
  bool _saving = false;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitial() async {
    if (!mounted) return;
    final scope = AppScope.of(context);
    final db = scope.database;
    final cycle = await (db.select(db.cycles)
          ..where((t) => t.state.equalsValue(CycleState.active))
          ..limit(1))
        .getSingleOrNull();
    final currencies = await (db.select(db.currencies)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.isBase, mode: drift.OrderingMode.desc),
            (t) => drift.OrderingTerm(expression: t.code),
          ]))
        .get();
    final base = currencies.firstWhere(
      (c) => c.isBase,
      orElse: () => currencies.first,
    );
    final secondaries = [for (final c in currencies) if (!c.isBase) c];
    // Pre-cycle: read the pending-rates store. Post-cycle: read the
    // cycle-scoped exchange_rates rows. Either way, every secondary
    // gets a controller — empty if no entry yet.
    final cycleRates = cycle == null
        ? const <ExchangeRateRow>[]
        : await scope.exchangeRates.readForCycle(cycle.id);
    final Map<String, PendingRate> pending =
        cycle == null ? scope.pendingRates.current : const {};
    if (!mounted) return;
    setState(() {
      _cycle = cycle;
      _baseCurrency = base;
      _secondaries = secondaries;
      _controllers.clear();
      _setAt.clear();
      for (final c in secondaries) {
        final controller = TextEditingController();
        if (cycle != null) {
          final row = cycleRates.firstWhere(
            (r) =>
                r.fromCurrencyCode == c.code &&
                r.toCurrencyCode == base.code,
            orElse: () => _missing,
          );
          if (!identical(row, _missing) && row.rate > 0) {
            controller.text = _formatPerBase(1.0 / row.rate);
            _setAt[c.code] = DateTime.fromMillisecondsSinceEpoch(row.setAt);
          }
        } else {
          final p = pending[c.code];
          if (p != null && p.rate > 0) {
            controller.text = _formatPerBase(1.0 / p.rate);
            _setAt[c.code] = p.setAt;
          }
        }
        _controllers[c.code] = controller;
      }
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    final base = _baseCurrency;
    if (base == null) return;
    if (_secondaries.isEmpty) return;
    setState(() {
      _refreshing = true;
      _refreshError = null;
    });
    final scope = AppScope.of(context);
    final cycle = _cycle;
    try {
      if (cycle != null) {
        await scope.exchangeRates.snapshotFromApi(
          cycleId: cycle.id,
          baseCode: base.code,
          secondaryCodes: [for (final c in _secondaries) c.code],
        );
      } else {
        await scope.exchangeRates.snapshotPendingFromApi(
          baseCode: base.code,
          secondaryCodes: [for (final c in _secondaries) c.code],
        );
      }
      await _loadInitial();
    } on FxRatesException catch (e) {
      if (mounted) {
        setState(() => _refreshError = e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _refreshError = '$e');
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _save() async {
    final base = _baseCurrency;
    if (base == null) return;
    final updates = <String, double>{};
    for (final entry in _controllers.entries) {
      final perBase = double.tryParse(entry.value.text.trim());
      if (perBase == null || perBase <= 0) continue;
      updates[entry.key] = 1.0 / perBase;
    }
    if (updates.isEmpty) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _saving = true);
    final scope = AppScope.of(context);
    final cycle = _cycle;
    try {
      if (cycle != null) {
        final repo = scope.exchangeRates;
        for (final entry in updates.entries) {
          await repo.upsertRate(
            cycleId: cycle.id,
            fromCode: entry.key,
            toCode: base.code,
            rate: entry.value,
          );
        }
      } else {
        await scope.pendingRates.upsertMany(updates);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    Navigator.of(context).maybePop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: CropkeepColors.borderDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Exchange rates',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: CropkeepColors.textPrimary,
                    ),
                  ),
                ),
                _RefreshButton(
                  refreshing: _refreshing,
                  enabled: !_loading && _secondaries.isNotEmpty,
                  onTap: _refresh,
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Today\'s cycle. Tap a value to override, or pull fresh from '
              'the internet. Past transactions keep their original rate.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: CropkeepColors.greenPrimary,
                  ),
                ),
              )
            else if (_secondaries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No secondary currencies are active. Enable one from the '
                  'Farmer tab to manage rates.',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CropkeepColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              )
            else ...[
              if (_refreshError != null) ...[
                _FxFallbackBanner(message: _refreshError!),
                const SizedBox(height: 12),
              ],
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: CropkeepColors.borderCard,
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (int i = 0; i < _secondaries.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              thickness: 1,
                              color: CropkeepColors.borderDivider,
                            ),
                          _RateRow(
                            baseCode: _baseCurrency!.code,
                            currency: _secondaries[i],
                            controller: _controllers[_secondaries[i].code]!,
                            setAt: _setAt[_secondaries[i].code],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CropkeepColors.greenPrimary,
                    disabledBackgroundColor:
                        CropkeepColors.greenPrimary.withValues(alpha: 0.3),
                    foregroundColor: CropkeepColors.textOnGreenBtn,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({
    required this.baseCode,
    required this.currency,
    required this.controller,
    required this.setAt,
  });

  final String baseCode;
  final CurrencyRow currency;
  final TextEditingController controller;
  final DateTime? setAt;

  @override
  Widget build(BuildContext context) {
    final spec = CurrencyCatalog.findByCode(currency.code);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (spec != null)
            SvgPicture.asset(
              spec.flagAsset,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 $baseCode = · ${currency.code}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CropkeepColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                Text(
                  setAt == null ? 'never fetched' : _relativeTime(setAt!),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: CropkeepColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: '0.00',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: CropkeepColors.borderCard,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: CropkeepColors.greenPrimary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.refreshing,
    required this.enabled,
    required this.onTap,
  });

  final bool refreshing;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: refreshing || !enabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: refreshing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: CropkeepColors.greenPrimary,
                  ),
                )
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: CropkeepColors.greenPrimary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: CropkeepColors.greenPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FxFallbackBanner extends StatelessWidget {
  const _FxFallbackBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEED6A6), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 18,
            color: Color(0xFFB97A1A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Couldn't refresh: $message",
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A4416),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatPerBase(double perBase) {
  if (perBase >= 100) return perBase.toStringAsFixed(2);
  if (perBase >= 1) return perBase.toStringAsFixed(3);
  return perBase.toStringAsFixed(5);
}

String _relativeTime(DateTime ts) {
  final now = DateTime.now();
  final diff = now.difference(ts);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  final days = diff.inDays;
  if (days < 7) return '${days}d ago';
  return '${ts.year}-${_pad(ts.month)}-${_pad(ts.day)}';
}

String _pad(int v) => v.toString().padLeft(2, '0');

final ExchangeRateRow _missing = ExchangeRateRow(
  id: -1,
  cycleId: -1,
  fromCurrencyCode: '',
  toCurrencyCode: '',
  rate: 0,
  setAt: 0,
);
