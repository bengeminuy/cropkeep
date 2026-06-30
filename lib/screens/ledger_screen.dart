import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../data/currency_catalog.dart';
import '../data/database.dart';
import '../data/tables/cycles.dart' show CycleState;
import '../data/tables/plots.dart' show PlotKind;
import '../theme/colors.dart';
import '../theme/plot_swatches.dart';
import '../widgets/cropkeep_toast.dart';
import '../widgets/edit_ledger_entry_sheet.dart';
import '../widgets/ledger_entry_detail_sheet.dart';

// ──────────────────────────────────────────────────────────────────────────
// LedgerScreen — the calm record-of-truth tab.
//
// Plan reference: C:\Users\Bengemin\.claude\plans\as-the-ui-ux-rosy-emerson.md
//
//   • Plain, ungamified list of expenses + incomes, grouped by day.
//   • Toggle: All / Expenses / Income.
//   • Default scope: current (active) cycle, with "Show older cycles" to
//     lazy-load prior cycles into the same list.
//   • Tap a row → coming-soon info (edit sheet ships when LogTransactionSheet
//     gets its full implementation). Long-press → action sheet with
//     soft-delete + undo SnackBar.
//   • Kebab → Recently removed mode (banner, strikethrough rows, restore on
//     tap). System-generated rows (Carryover opening entry) are locked.
//   • Search and filter ship in a follow-up pass; the title bar already
//     reserves the slots.

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

enum _LedgerMode { all, expenses, income }

// Immutable bundle of every filter dimension the Ledger supports.
// Keeping these in one value object means state ops are one assignment
// and predicate checks (`isActive`, `matches`) live next to the data.
@immutable
class _LedgerFilters {
  const _LedgerFilters({
    this.plotIds = const <int>{},
    this.wellIds = const <int>{},
    this.currencyCodes = const <String>{},
    this.dateRange,
    this.emergencyOnly = false,
  });

  final Set<int> plotIds;
  final Set<int> wellIds;
  final Set<String> currencyCodes;
  final DateTimeRange? dateRange;
  final bool emergencyOnly;

  bool get isActive =>
      plotIds.isNotEmpty ||
      wellIds.isNotEmpty ||
      currencyCodes.isNotEmpty ||
      dateRange != null ||
      emergencyOnly;

  static const _LedgerFilters empty = _LedgerFilters();

  _LedgerFilters copyWith({
    Set<int>? plotIds,
    Set<int>? wellIds,
    Set<String>? currencyCodes,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    bool? emergencyOnly,
  }) {
    return _LedgerFilters(
      plotIds: plotIds ?? this.plotIds,
      wellIds: wellIds ?? this.wellIds,
      currencyCodes: currencyCodes ?? this.currencyCodes,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      emergencyOnly: emergencyOnly ?? this.emergencyOnly,
    );
  }

  bool matches(_LedgerEntry e) {
    if (plotIds.isNotEmpty) {
      if (e is! _ExpenseEntry || !plotIds.contains(e.row.plotId)) {
        // Plot filter implies expenses only; income rows fail unless a
        // matching well filter independently includes them.
        if (!(e is _IncomeEntry && wellIds.contains(e.row.wellId))) {
          return false;
        }
      }
    }
    if (wellIds.isNotEmpty) {
      if (e is! _IncomeEntry || !wellIds.contains(e.row.wellId)) {
        if (!(e is _ExpenseEntry && plotIds.contains(e.row.plotId))) {
          return false;
        }
      }
    }
    if (currencyCodes.isNotEmpty) {
      final code = e is _ExpenseEntry
          ? e.row.currencyCode
          : (e as _IncomeEntry).row.currencyCode;
      if (!currencyCodes.contains(code)) return false;
    }
    if (dateRange != null) {
      final when = e.when;
      final startMs = dateRange!.start.millisecondsSinceEpoch;
      // Inclusive of the end-day by extending to its last millisecond.
      final endDay = DateTime(
        dateRange!.end.year,
        dateRange!.end.month,
        dateRange!.end.day,
        23,
        59,
        59,
        999,
      );
      final endMs = endDay.millisecondsSinceEpoch;
      final whenMs = when.millisecondsSinceEpoch;
      if (whenMs < startMs || whenMs > endMs) return false;
    }
    if (emergencyOnly && !e.isEmergency) return false;
    return true;
  }
}

class _LedgerScreenState extends State<LedgerScreen> {
  _LedgerMode _mode = _LedgerMode.all;
  bool _showingRecentlyRemoved = false;
  // How many cycles back the user has expanded into. 0 = active cycle only.
  int _extraCyclesShown = 0;

  // Search state. `_searchOpen` controls the text field's visibility;
  // `_searchQuery` is the live text. Closing search clears both — search
  // sessions are intentionally transient.
  bool _searchOpen = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Filter state — sticky within the session, reset on app restart.
  _LedgerFilters _filters = _LedgerFilters.empty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectMode(_LedgerMode m) {
    if (m == _mode) return;
    setState(() => _mode = m);
  }

  void _enterRecentlyRemoved() {
    setState(() => _showingRecentlyRemoved = true);
  }

  void _exitRecentlyRemoved() {
    setState(() => _showingRecentlyRemoved = false);
  }

  void _showMoreCycles() {
    setState(() => _extraCyclesShown += 1);
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _setFilters(_LedgerFilters next) {
    if (identical(next, _filters)) return;
    setState(() => _filters = next);
  }

  void _clearFilters() => _setFilters(_LedgerFilters.empty);

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _LedgerFilterSheet(
        initial: _filters,
        onChanged: _setFilters,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: _BaseCurrencyProvider(
        child: _showingRecentlyRemoved
            ? _RecentlyRemovedView(onBack: _exitRecentlyRemoved)
            : _DefaultLedgerView(
                mode: _mode,
                onModeChanged: _selectMode,
                extraCyclesShown: _extraCyclesShown,
                onShowMoreCycles: _showMoreCycles,
                onOpenRecentlyRemoved: _enterRecentlyRemoved,
                searchOpen: _searchOpen,
                searchQuery: _searchQuery,
                searchController: _searchController,
                onToggleSearch: _toggleSearch,
                onSearchChanged: _onSearchChanged,
                filters: _filters,
                onOpenFilters: _openFilterSheet,
                onClearFilters: _clearFilters,
                onUpdateFilters: _setFilters,
              ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Base-currency provider (mirrors FarmScreen's pattern, scoped to this tab
// so money rendering reads symbol/decimals without prop-threading).

class _BaseCurrencyProvider extends StatelessWidget {
  const _BaseCurrencyProvider({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<AppSettingsRow?>(
      stream: scope.appSettings.watch(),
      builder: (context, settingsSnap) {
        final String? code = settingsSnap.data?.baseCurrencyCode;
        return StreamBuilder<CurrencyRow?>(
          stream: _watchBaseCurrency(scope.database, code),
          builder: (context, currencySnap) {
            final currency = currencySnap.data;
            return _BaseCurrencyScope(
              code: currency?.code ?? code ?? 'USD',
              symbol: currency?.symbol ?? r'$',
              decimals: currency?.decimalPlaces ?? 2,
              child: child,
            );
          },
        );
      },
    );
  }
}

class _BaseCurrencyScope extends InheritedWidget {
  const _BaseCurrencyScope({
    required this.code,
    required this.symbol,
    required this.decimals,
    required super.child,
  });

  final String code;
  final String symbol;
  final int decimals;

  static _BaseCurrencyScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_BaseCurrencyScope>();
    assert(
      scope != null,
      '_BaseCurrencyScope missing — wrap with _BaseCurrencyProvider.',
    );
    return scope!;
  }

  @override
  bool updateShouldNotify(_BaseCurrencyScope old) =>
      code != old.code ||
      symbol != old.symbol ||
      decimals != old.decimals;
}

Stream<CurrencyRow?> _watchBaseCurrency(AppDatabase db, String? code) {
  if (code == null) return Stream<CurrencyRow?>.value(null);
  return (db.select(db.currencies)..where((t) => t.code.equals(code)))
      .watchSingleOrNull();
}

// ──────────────────────────────────────────────────────────────────────────
// LedgerEntry — sealed-style union for the unified day-grouped list. Holds
// just enough to render and route gestures without exposing the row types
// to every nested widget.

abstract class _LedgerEntry {
  const _LedgerEntry();
  int get id;
  DateTime get when;
  int get baseAmountMinor;
  String? get note;
  String? get currencyCode; // null when matches base
  int get originalAmountMinor;
  int get originalDecimals;
  // Rate-to-base snapshotted at log time. Used in the detail sheet to
  // show the user what conversion produced their base amount.
  double get exchangeRate;
  int? get editedAtMs;
  bool get isExpense;
  bool get isLocked;
  bool get isEmergency;
  int get sourceCycleId;
  // Display name of the source — plot name (expense) or well name
  // (income). May be missing if the underlying row has been archived;
  // the sheet renders an em-dash in that case.
  String? get sourceName;
}

class _ExpenseEntry extends _LedgerEntry {
  const _ExpenseEntry({
    required this.row,
    required this.plot,
    required this.originalDecimals,
    required this.isCurrencyNonBase,
  });

  final TransactionRow row;
  final PlotRow? plot;
  @override
  final int originalDecimals;
  final bool isCurrencyNonBase;

  @override
  int get id => row.id;
  @override
  DateTime get when => DateTime.fromMillisecondsSinceEpoch(row.spentAt);
  @override
  int get baseAmountMinor => row.baseAmount;
  @override
  String? get note => row.note;
  @override
  String? get currencyCode => isCurrencyNonBase ? row.currencyCode : null;
  @override
  int get originalAmountMinor => row.amount;
  @override
  double get exchangeRate => row.exchangeRate;
  @override
  int? get editedAtMs => row.editedAt;
  @override
  bool get isExpense => true;
  @override
  bool get isLocked => false;
  @override
  bool get isEmergency => row.isEmergency;
  @override
  int get sourceCycleId => row.cycleId;
  @override
  String? get sourceName => plot?.name;
}

class _IncomeEntry extends _LedgerEntry {
  const _IncomeEntry({
    required this.row,
    required this.well,
    required this.originalDecimals,
    required this.isCurrencyNonBase,
  });

  final IncomeEntryRow row;
  final WellRow? well;
  @override
  final int originalDecimals;
  final bool isCurrencyNonBase;

  @override
  int get id => row.id;
  @override
  DateTime get when => DateTime.fromMillisecondsSinceEpoch(row.receivedAt);
  @override
  int get baseAmountMinor => row.baseAmount;
  @override
  String? get note => row.note;
  @override
  String? get currencyCode => isCurrencyNonBase ? row.currencyCode : null;
  @override
  int get originalAmountMinor => row.amount;
  @override
  double get exchangeRate => row.exchangeRate;
  @override
  int? get editedAtMs => row.editedAt;
  @override
  bool get isExpense => false;
  @override
  bool get isLocked => row.isSystemGenerated;
  @override
  bool get isEmergency => false;
  @override
  int get sourceCycleId => row.cycleId;
  @override
  String? get sourceName => well?.name;
}

// ──────────────────────────────────────────────────────────────────────────
// Default view — title bar, segment, day-grouped list, older-cycles button.

class _DefaultLedgerView extends StatelessWidget {
  const _DefaultLedgerView({
    required this.mode,
    required this.onModeChanged,
    required this.extraCyclesShown,
    required this.onShowMoreCycles,
    required this.onOpenRecentlyRemoved,
    required this.searchOpen,
    required this.searchQuery,
    required this.searchController,
    required this.onToggleSearch,
    required this.onSearchChanged,
    required this.filters,
    required this.onOpenFilters,
    required this.onClearFilters,
    required this.onUpdateFilters,
  });

  final _LedgerMode mode;
  final ValueChanged<_LedgerMode> onModeChanged;
  final int extraCyclesShown;
  final VoidCallback onShowMoreCycles;
  final VoidCallback onOpenRecentlyRemoved;
  final bool searchOpen;
  final String searchQuery;
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onSearchChanged;
  final _LedgerFilters filters;
  final VoidCallback onOpenFilters;
  final VoidCallback onClearFilters;
  final ValueChanged<_LedgerFilters> onUpdateFilters;

  @override
  Widget build(BuildContext context) {
    // Escape closes search whether focus sits in the field or anywhere
    // else under this subtree. Bubbles from the focused TextField up to
    // here, so the field's own keyboard handling stays intact.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (searchOpen) onToggleSearch();
        },
      },
      child: Padding(
        // 8px top matches FarmScreen — couples the title to the shell header.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LedgerTitleBar(
              searchOpen: searchOpen,
              onToggleSearch: onToggleSearch,
              filtersActive: filters.isActive,
              onOpenFilters: onOpenFilters,
              onOpenRecentlyRemoved: onOpenRecentlyRemoved,
            ),
            // AnimatedSize collapses to zero when the bar isn't visible
            // and slides it in/out without the children below jumping.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: searchOpen
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _LedgerSearchBar(
                        controller: searchController,
                        onChanged: onSearchChanged,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 12),
            _LedgerModeSegment(
              mode: mode,
              onChanged: onModeChanged,
            ),
            // Active-filter strip — visible only when at least one
            // filter is set. Renders summary chips with per-filter ✕
            // and a trailing Clear-all link. Stays visible even when
            // the list is empty, so the empty state always has the
            // breadcrumb context.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: filters.isActive
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ActiveFilterStrip(
                        filters: filters,
                        onUpdate: onUpdateFilters,
                        onClearAll: onClearFilters,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _LedgerListWrapper(
                mode: mode,
                extraCyclesShown: extraCyclesShown,
                onShowMoreCycles: onShowMoreCycles,
                searchQuery: searchQuery,
                onClearSearch: onToggleSearch,
                filters: filters,
                onClearFilters: onClearFilters,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Title bar — title + search/filter/kebab affordances. The search icon
// toggles a text field that lives below this bar (see _LedgerSearchBar);
// when open it swaps for an X to read as "close search."

class _LedgerTitleBar extends StatelessWidget {
  const _LedgerTitleBar({
    required this.searchOpen,
    required this.onToggleSearch,
    required this.filtersActive,
    required this.onOpenFilters,
    required this.onOpenRecentlyRemoved,
  });

  final bool searchOpen;
  final VoidCallback onToggleSearch;
  final bool filtersActive;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenRecentlyRemoved;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              'Ledger',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1.1,
              ),
            ),
          ),
          _IconAction(
            tooltip: searchOpen ? 'Close search' : 'Search',
            icon: searchOpen
                ? Icons.close_rounded
                : Icons.search_rounded,
            onTap: onToggleSearch,
          ),
          const SizedBox(width: 4),
          _IconAction(
            tooltip: 'Filter',
            icon: Icons.tune_rounded,
            onTap: onOpenFilters,
            // Small green dot in the top-right of the icon when any
            // filter is set — instant "you're filtered" signal that
            // pairs with the visible chip strip below the segment.
            badge: filtersActive,
          ),
          const SizedBox(width: 4),
          _LedgerKebabMenu(
            onRecentlyRemoved: onOpenRecentlyRemoved,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Search bar — appears between the title row and the mode segment when
// search is open. Manages just the field/styling/clear-text affordance;
// the surrounding open/close state, query state, and Esc binding live on
// `_LedgerScreenState` so search composes cleanly with everything else.

class _LedgerSearchBar extends StatefulWidget {
  const _LedgerSearchBar({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_LedgerSearchBar> createState() => _LedgerSearchBarState();
}

class _LedgerSearchBarState extends State<_LedgerSearchBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Autofocus on first mount — the search affordance feels broken if
    // the user has to tap a second time to start typing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
    widget.controller.addListener(_rebuildOnTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuildOnTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  // The clear-text ⓧ visibility depends on whether the field has text.
  // The controller already notifies on change; piggy-back to refresh.
  void _rebuildOnTextChange() {
    if (mounted) setState(() {});
  }

  void _clearText() {
    widget.controller.clear();
    widget.onChanged('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    // Matches the canonical `_FieldShell` chrome used by every form
    // field in the app: white fill, soft warm `borderCard` border,
    // 12px radius, light shadow lift. Keeps the Ledger search reading
    // as the same "input" surface the user already knows from
    // new-plot/new-well/onboarding instead of inventing a new tone.
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
        boxShadow: const [
          BoxShadow(
            color: CropkeepColors.shadowCard,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 18,
            color: CropkeepColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textPrimary,
                height: 1.2,
              ),
              cursorColor: CropkeepColors.greenPrimary,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search the ledger...',
                hintStyle: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CropkeepColors.textSecondary,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (hasText) ...[
            const SizedBox(width: 8),
            Semantics(
              label: 'Clear search text',
              button: true,
              child: InkResponse(
                onTap: _clearText,
                radius: 18,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: CropkeepColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Active filter strip — sits between the mode segment and the list while
// any filter is on. Renders one chip per active criterion; each chip's
// `×` removes that one filter, the trailing "Clear" removes all.
//
// The strip needs human labels for plot/well ids and currency codes, so
// it briefly subscribes to plots/wells/currencies streams. Lightweight:
// these streams are already running for the list and Drift dedupes.

class _ActiveFilterStrip extends StatelessWidget {
  const _ActiveFilterStrip({
    required this.filters,
    required this.onUpdate,
    required this.onClearAll,
  });

  final _LedgerFilters filters;
  final ValueChanged<_LedgerFilters> onUpdate;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return StreamBuilder<_FilterMetaData>(
      stream: _watchFilterMeta(scope.database),
      builder: (context, snap) {
        final meta = snap.data ?? const _FilterMetaData.empty();
        final chips = _buildChips(meta);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: CropkeepColors.bgPageAlt,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < chips.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        chips[i],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onClearAll,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    'Clear',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CropkeepColors.textGreenDeep,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildChips(_FilterMetaData meta) {
    final chips = <Widget>[];

    // Sources (plots + wells in one combined chip group — Cropkeep's
    // user thinks of "where this came from" as one concept).
    final plotChip = _summariseSourceChip(
      ids: filters.plotIds,
      lookup: (id) => meta.plotNames[id],
      removeOne: (id) {
        final next = {...filters.plotIds}..remove(id);
        onUpdate(filters.copyWith(plotIds: next));
      },
      removeAll: () => onUpdate(filters.copyWith(plotIds: const {})),
    );
    if (plotChip != null) chips.add(plotChip);

    final wellChip = _summariseSourceChip(
      ids: filters.wellIds,
      lookup: (id) => meta.wellNames[id],
      removeOne: (id) {
        final next = {...filters.wellIds}..remove(id);
        onUpdate(filters.copyWith(wellIds: next));
      },
      removeAll: () => onUpdate(filters.copyWith(wellIds: const {})),
    );
    if (wellChip != null) chips.add(wellChip);

    if (filters.currencyCodes.isNotEmpty) {
      chips.add(_FilterChip(
        label: filters.currencyCodes.length == 1
            ? filters.currencyCodes.first
            : '${filters.currencyCodes.length} currencies',
        onRemove: () =>
            onUpdate(filters.copyWith(currencyCodes: const {})),
      ));
    }

    if (filters.dateRange != null) {
      chips.add(_FilterChip(
        label: _formatDateRange(filters.dateRange!),
        onRemove: () => onUpdate(filters.copyWith(clearDateRange: true)),
      ));
    }

    if (filters.emergencyOnly) {
      chips.add(_FilterChip(
        label: 'Emergencies only',
        onRemove: () => onUpdate(filters.copyWith(emergencyOnly: false)),
      ));
    }

    return chips;
  }

  Widget? _summariseSourceChip({
    required Set<int> ids,
    required String? Function(int) lookup,
    required void Function(int) removeOne,
    required VoidCallback removeAll,
  }) {
    if (ids.isEmpty) return null;
    final names = [
      for (final id in ids) lookup(id) ?? '#$id',
    ];
    final label = names.length == 1
        ? names.first
        : '${names.first} + ${names.length - 1} more';
    return _FilterChip(
      label: label,
      onRemove: () {
        if (ids.length == 1) {
          removeAll();
        } else {
          removeOne(ids.first);
        }
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CropkeepColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(width: 4),
          InkResponse(
            onTap: onRemove,
            radius: 14,
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(
                Icons.close_rounded,
                size: 14,
                color: CropkeepColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Metadata the chip strip and the filter sheet need to render their
// human labels. Computed once and shared via stream.
class _FilterMetaData {
  const _FilterMetaData({
    required this.plots,
    required this.wells,
    required this.currencyCodes,
    required this.plotNames,
    required this.wellNames,
  });
  const _FilterMetaData.empty()
      : plots = const [],
        wells = const [],
        currencyCodes = const [],
        plotNames = const {},
        wellNames = const {};

  final List<PlotRow> plots;
  final List<WellRow> wells;
  final List<String> currencyCodes;
  final Map<int, String> plotNames;
  final Map<int, String> wellNames;
}

Stream<_FilterMetaData> _watchFilterMeta(AppDatabase db) {
  final sources = _watchFilterableSources(db);
  final currencies = (db.select(db.currencies)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([
          (t) => drift.OrderingTerm(expression: t.displayOrder),
          (t) => drift.OrderingTerm(expression: t.code),
        ]))
      .watch();

  return _combineLatest2(sources, currencies, (
    _FilterableSources s,
    List<CurrencyRow> c,
  ) {
    return _FilterMetaData(
      plots: s.plots,
      wells: s.wells,
      currencyCodes: [for (final row in c) row.code],
      plotNames: {for (final row in s.plots) row.id: row.name},
      wellNames: {for (final row in s.wells) row.id: row.name},
    );
  });
}

// Active plots/wells get joined with anything that's been referenced
// by at least one non-deleted transaction or income entry. The active
// flag controls Farm-screen visibility (archive a category = it leaves
// the daily grid); historical entries on archived sources still need
// to be filterable. Without this union the demo seeder's inactive
// demo plots/wells were invisible to the filter sheet even though they
// own the seeded transactions.
class _FilterableSources {
  const _FilterableSources({required this.plots, required this.wells});
  final List<PlotRow> plots;
  final List<WellRow> wells;
}

Stream<_FilterableSources> _watchFilterableSources(AppDatabase db) {
  final allPlots = (db.select(db.plots)
        ..orderBy([
          (t) => drift.OrderingTerm(expression: t.displayOrder),
          (t) => drift.OrderingTerm(expression: t.name),
        ]))
      .watch();
  final allWells = (db.select(db.wells)
        ..orderBy([
          (t) => drift.OrderingTerm(expression: t.displayOrder),
          (t) => drift.OrderingTerm(expression: t.name),
        ]))
      .watch();
  final referencedPlotIds = (db.selectOnly(db.transactions, distinct: true)
        ..addColumns([db.transactions.plotId])
        ..where(db.transactions.deletedAt.isNull()))
      .watch()
      .map((rows) => rows
          .map((r) => r.read(db.transactions.plotId))
          .whereType<int>()
          .toSet());
  final referencedWellIds = (db.selectOnly(db.incomeEntries, distinct: true)
        ..addColumns([db.incomeEntries.wellId])
        ..where(db.incomeEntries.deletedAt.isNull()))
      .watch()
      .map((rows) => rows
          .map((r) => r.read(db.incomeEntries.wellId))
          .whereType<int>()
          .toSet());

  return _combineLatest4(
    allPlots,
    allWells,
    referencedPlotIds,
    referencedWellIds,
    (
      List<PlotRow> plots,
      List<WellRow> wells,
      Set<int> refPlotIds,
      Set<int> refWellIds,
    ) {
      return _FilterableSources(
        plots: plots
            .where((p) => p.isActive || refPlotIds.contains(p.id))
            .toList(),
        wells: wells
            .where((w) => w.isActive || refWellIds.contains(w.id))
            .toList(),
      );
    },
  );
}

// Two-way combine-latest mirror of _combineLatest6.
Stream<R> _combineLatest2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A, B) combiner,
) {
  late StreamController<R> controller;
  A? va;
  B? vb;
  bool ha = false;
  bool hb = false;
  final subs = <StreamSubscription<dynamic>>[];

  void maybeEmit() {
    if (ha && hb) {
      controller.add(combiner(va as A, vb as B));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subs.add(a.listen((v) {
        va = v;
        ha = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(b.listen((v) {
        vb = v;
        hb = true;
        maybeEmit();
      }, onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
    },
  );
  return controller.stream;
}

String _formatDateRange(DateTimeRange range) {
  final from = range.start;
  final to = range.end;
  final sameYear = from.year == to.year;
  final sameMonth = sameYear && from.month == to.month;
  final fromLabel = '${_monthShort(from.month)} ${from.day}';
  final toLabel = sameMonth
      ? '${to.day}'
      : '${_monthShort(to.month)} ${to.day}';
  return sameYear ? '$fromLabel – $toLabel' : '$fromLabel – ${_monthShort(to.month)} ${to.day}, ${to.year}';
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final iconChild = Icon(icon, size: 22, color: CropkeepColors.textPrimary);
    return Semantics(
      label: tooltip,
      button: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox(
          width: 40,
          height: 40,
          child: badge
              ? Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    iconChild,
                    Positioned(
                      top: 7,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: CropkeepColors.greenPrimary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: CropkeepColors.bgScreen,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : iconChild,
        ),
      ),
    );
  }
}

class _LedgerKebabMenu extends StatelessWidget {
  const _LedgerKebabMenu({required this.onRecentlyRemoved});

  final VoidCallback onRecentlyRemoved;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 22,
        color: CropkeepColors.textPrimary,
      ),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: CropkeepColors.borderCard),
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) {
        switch (value) {
          case 'removed':
            onRecentlyRemoved();
        }
      },
      itemBuilder: (_) => const <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'removed',
          child: _KebabMenuItem(
            icon: Icons.restore_from_trash_rounded,
            label: 'Recently removed',
          ),
        ),
      ],
    );
  }
}

class _KebabMenuItem extends StatelessWidget {
  const _KebabMenuItem({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: CropkeepColors.textPrimary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: CropkeepColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Mode segment — All / Expenses / Income.

class _LedgerModeSegment extends StatelessWidget {
  const _LedgerModeSegment({required this.mode, required this.onChanged});

  final _LedgerMode mode;
  final ValueChanged<_LedgerMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CropkeepColors.bgPageAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final m in _LedgerMode.values)
            Expanded(
              child: _SegmentTab(
                label: _labelFor(m),
                isActive: m == mode,
                onTap: () => onChanged(m),
              ),
            ),
        ],
      ),
    );
  }

  String _labelFor(_LedgerMode m) {
    switch (m) {
      case _LedgerMode.all:
        return 'All';
      case _LedgerMode.expenses:
        return 'Expenses';
      case _LedgerMode.income:
        return 'Income';
    }
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? CropkeepColors.greenPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive
                ? CropkeepColors.textOnGreenBtn
                : CropkeepColors.textNavInactive,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// List wrapper — resolves the active cycle, then the list of cycles to
// query, then streams transactions + incomes for those cycles plus the
// plot/well lookups needed for rendering.

class _LedgerListWrapper extends StatelessWidget {
  const _LedgerListWrapper({
    required this.mode,
    required this.extraCyclesShown,
    required this.onShowMoreCycles,
    required this.searchQuery,
    required this.onClearSearch,
    required this.filters,
    required this.onClearFilters,
  });

  final _LedgerMode mode;
  final int extraCyclesShown;
  final VoidCallback onShowMoreCycles;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final _LedgerFilters filters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    // Build the list of cycles in scope, newest first. Active cycle plus
    // any older ones the user has expanded into — UNLESS a search query
    // or filter is active, in which case we load every cycle so the
    // narrowing operations reach the user's full history.
    return StreamBuilder<List<CycleRow>>(
      stream: _watchCyclesNewestFirst(scope.database),
      builder: (context, snap) {
        final all = snap.data ?? const <CycleRow>[];
        if (all.isEmpty) {
          // No cycle exists yet — shouldn't happen post-onboarding, but render
          // a calm empty state rather than an empty void.
          return const _EmptyState(
            title: 'No transactions yet this cycle.',
            hint: 'Tap ＋ to log a watering.',
          );
        }
        final isSearching = searchQuery.trim().isNotEmpty;
        final isNarrowing = isSearching || filters.isActive;
        final shown = isNarrowing
            ? all
            : all.take(1 + extraCyclesShown).toList();
        final more = !isNarrowing && all.length > shown.length;
        return _CycleScopedList(
          mode: mode,
          cycles: shown,
          hasMore: more,
          onShowMore: onShowMoreCycles,
          searchQuery: searchQuery,
          onClearSearch: onClearSearch,
          filters: filters,
          onClearFilters: onClearFilters,
        );
      },
    );
  }
}

Stream<List<CycleRow>> _watchCyclesNewestFirst(AppDatabase db) {
  // Active first, then completed/archived by end date descending.
  return (db.select(db.cycles)
        ..orderBy([
          (t) => drift.OrderingTerm.desc(t.endDate),
        ]))
      .watch();
}

class _CycleScopedList extends StatelessWidget {
  const _CycleScopedList({
    required this.mode,
    required this.cycles,
    required this.hasMore,
    required this.onShowMore,
    required this.searchQuery,
    required this.onClearSearch,
    required this.filters,
    required this.onClearFilters,
  });

  final _LedgerMode mode;
  final List<CycleRow> cycles;
  final bool hasMore;
  final VoidCallback onShowMore;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final _LedgerFilters filters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final cycleIds = [for (final c in cycles) c.id];
    final wantsExpenses = mode != _LedgerMode.income;
    final wantsIncome = mode != _LedgerMode.expenses;
    final trimmedQuery = searchQuery.trim();
    final isSearching = trimmedQuery.isNotEmpty;
    final hasFilter = filters.isActive;
    final isNarrowing = isSearching || hasFilter;
    return StreamBuilder<_LedgerData>(
      stream: _watchLedger(
        scope.database,
        cycleIds: cycleIds,
        includeExpenses: wantsExpenses,
        includeIncome: wantsIncome,
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox.shrink();
        }
        final data = snap.data!;
        final entries = _buildEntries(
          data,
          mode: mode,
          baseCurrencyCode: data.baseCurrencyCode,
          searchQuery: trimmedQuery,
          filters: filters,
        );
        if (entries.isEmpty) {
          // Empty-state precedence: search + filter together → search
          // copy (most specific signal). Filter alone → filter copy.
          // Search alone → search copy. Neither → default mode copy.
          if (isSearching) {
            return _SearchEmptyState(
              query: trimmedQuery,
              onClear: onClearSearch,
            );
          }
          if (hasFilter) {
            return _FilterEmptyState(onClear: onClearFilters);
          }
          return _EmptyState(
            title: switch (mode) {
              _LedgerMode.all => 'No transactions yet this cycle.',
              _LedgerMode.expenses => 'No expenses yet this cycle.',
              _LedgerMode.income => 'No income logged yet this cycle.',
            },
            hint: switch (mode) {
              _LedgerMode.all => 'Tap ＋ to log a watering.',
              _LedgerMode.expenses => 'Tap ＋ to log an expense.',
              _LedgerMode.income => 'Tap ＋ to log income.',
            },
          );
        }
        // Group by local-date.
        final groups = _groupByDay(entries);
        // The "Show older cycles" footer is a chronological-scroll
        // affordance; it doesn't make sense while we're already
        // reaching across every cycle for search or filter.
        final showFooter = !isNarrowing;
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: groups.length + (showFooter ? 1 : 0),
          itemBuilder: (context, i) {
            if (showFooter && i == groups.length) {
              return _OlderCyclesFooter(
                activeCycleStart: DateTime.fromMillisecondsSinceEpoch(
                  cycles.first.startDate,
                ),
                hasMore: hasMore,
                onShowMore: onShowMore,
              );
            }
            final g = groups[i];
            return _LedgerDayGroup(group: g);
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Stream composition — merges transactions, incomes, plots, wells, and the
// base currency code into a single tick that the list can render in one
// frame. Re-emits whenever any source changes.

class _LedgerData {
  const _LedgerData({
    required this.expenses,
    required this.incomes,
    required this.plotsById,
    required this.wellsById,
    required this.currencyDecimals,
    required this.baseCurrencyCode,
  });

  final List<TransactionRow> expenses;
  final List<IncomeEntryRow> incomes;
  final Map<int, PlotRow> plotsById;
  final Map<int, WellRow> wellsById;
  final Map<String, int> currencyDecimals;
  final String baseCurrencyCode;
}

Stream<_LedgerData> _watchLedger(
  AppDatabase db, {
  required List<int> cycleIds,
  required bool includeExpenses,
  required bool includeIncome,
}) {
  final txStream = includeExpenses
      ? (db.select(db.transactions)
            ..where((t) =>
                t.cycleId.isIn(cycleIds) & t.deletedAt.isNull())
            ..orderBy([(t) => drift.OrderingTerm.desc(t.spentAt)]))
          .watch()
      : Stream<List<TransactionRow>>.value(const []);
  final incomeStream = includeIncome
      ? (db.select(db.incomeEntries)
            ..where((t) =>
                t.cycleId.isIn(cycleIds) & t.deletedAt.isNull())
            ..orderBy([(t) => drift.OrderingTerm.desc(t.receivedAt)]))
          .watch()
      : Stream<List<IncomeEntryRow>>.value(const []);
  final plotsStream = db.select(db.plots).watch();
  final wellsStream = db.select(db.wells).watch();
  final currenciesStream = db.select(db.currencies).watch();
  final settingsStream =
      (db.select(db.appSettings)..where((t) => t.id.equals(1)))
          .watchSingleOrNull();

  // Plain combine via async generators to avoid pulling rxdart. Each tick
  // pulls the latest of every dependent stream.
  return _combineLatest6<
      List<TransactionRow>,
      List<IncomeEntryRow>,
      List<PlotRow>,
      List<WellRow>,
      List<CurrencyRow>,
      AppSettingsRow?,
      _LedgerData>(
    txStream,
    incomeStream,
    plotsStream,
    wellsStream,
    currenciesStream,
    settingsStream,
    (tx, inc, plots, wells, currencies, settings) {
      return _LedgerData(
        expenses: tx,
        incomes: inc,
        plotsById: {for (final p in plots) p.id: p},
        wellsById: {for (final w in wells) w.id: w},
        currencyDecimals: {for (final c in currencies) c.code: c.decimalPlaces},
        baseCurrencyCode: settings?.baseCurrencyCode ?? 'USD',
      );
    },
  );
}

// Six-way combine-latest. Emits once all six have produced at least one
// value, and then on every subsequent update.
Stream<R> _combineLatest6<A, B, C, D, E, F, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  Stream<E> e,
  Stream<F> f,
  R Function(A, B, C, D, E, F) combiner,
) {
  late StreamController<R> controller;
  A? va;
  B? vb;
  C? vc;
  D? vd;
  E? ve;
  F? vf;
  bool ha = false;
  bool hb = false;
  bool hc = false;
  bool hd = false;
  bool he = false;
  bool hf = false;
  final subs = <StreamSubscription<dynamic>>[];

  void maybeEmit() {
    if (ha && hb && hc && hd && he && hf) {
      controller.add(combiner(va as A, vb as B, vc as C, vd as D, ve as E, vf as F));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subs.add(a.listen((v) {
        va = v;
        ha = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(b.listen((v) {
        vb = v;
        hb = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(c.listen((v) {
        vc = v;
        hc = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(d.listen((v) {
        vd = v;
        hd = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(e.listen((v) {
        ve = v;
        he = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(f.listen((v) {
        vf = v;
        hf = true;
        maybeEmit();
      }, onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
    },
  );
  return controller.stream;
}

List<_LedgerEntry> _buildEntries(
  _LedgerData data, {
  required _LedgerMode mode,
  required String baseCurrencyCode,
  String searchQuery = '',
  _LedgerFilters filters = _LedgerFilters.empty,
}) {
  final out = <_LedgerEntry>[];
  if (mode != _LedgerMode.income) {
    for (final t in data.expenses) {
      out.add(_ExpenseEntry(
        row: t,
        plot: data.plotsById[t.plotId],
        originalDecimals: data.currencyDecimals[t.currencyCode] ?? 2,
        isCurrencyNonBase: t.currencyCode != baseCurrencyCode,
      ));
    }
  }
  if (mode != _LedgerMode.expenses) {
    for (final e in data.incomes) {
      out.add(_IncomeEntry(
        row: e,
        well: data.wellsById[e.wellId],
        originalDecimals: data.currencyDecimals[e.currencyCode] ?? 2,
        isCurrencyNonBase: e.currencyCode != baseCurrencyCode,
      ));
    }
  }
  out.sort((a, b) => b.when.compareTo(a.when));

  // Filter pass first (cheaper drops more rows than search), then search.
  Iterable<_LedgerEntry> filtered = out;
  if (filters.isActive) {
    filtered = filtered.where(filters.matches);
  }
  if (searchQuery.isNotEmpty) {
    // Case-insensitive substring match on the note + the linked plot/well
    // name. No fuzzy, no regex — typed text is treated literally so users
    // never have to think about escaping.
    final needle = searchQuery.toLowerCase();
    filtered = filtered.where((e) {
      final name = _resolveName(e).toLowerCase();
      if (name.contains(needle)) return true;
      final note = e.note?.toLowerCase();
      if (note != null && note.contains(needle)) return true;
      return false;
    });
  }
  if (identical(filtered, out)) return out;
  return filtered.toList();
}

// ──────────────────────────────────────────────────────────────────────────
// Day grouping & rendering.

class _DayGroup {
  _DayGroup(this.date) : entries = <_LedgerEntry>[];
  final DateTime date; // local-date, midnight
  final List<_LedgerEntry> entries;
}

List<_DayGroup> _groupByDay(List<_LedgerEntry> entries) {
  final groups = <_DayGroup>[];
  for (final e in entries) {
    final d = DateTime(e.when.year, e.when.month, e.when.day);
    if (groups.isEmpty || groups.last.date != d) {
      groups.add(_DayGroup(d));
    }
    groups.last.entries.add(e);
  }
  return groups;
}

class _LedgerDayGroup extends StatelessWidget {
  const _LedgerDayGroup({required this.group});

  final _DayGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DayHeader(date: group.date),
          _DayCard(entries: group.entries),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        _formatDayLabel(date),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textSecondary,
          letterSpacing: 0.6,
          height: 1,
        ),
      ),
    );
  }
}

String _formatDayLabel(DateTime date) {
  final today = DateTime.now();
  final t0 = DateTime(today.year, today.month, today.day);
  final delta = t0.difference(date).inDays;
  if (delta == 0) {
    return 'TODAY · ${_weekday(date)} ${_monthShort(date.month)} ${date.day}';
  }
  if (delta == 1) {
    return 'YESTERDAY · ${_weekday(date)} ${_monthShort(date.month)} ${date.day}';
  }
  return '${_weekday(date).toUpperCase()}, ${_monthShort(date.month).toUpperCase()} ${date.day}';
}

String _weekday(DateTime d) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[d.weekday - 1];
}

String _monthShort(int m) {
  const names = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return names[m - 1];
}

// ──────────────────────────────────────────────────────────────────────────
// Day card — one rounded white container per day, rows separated by inset
// dividers. Tap/long-press handlers route via the row widget.

class _DayCard extends StatelessWidget {
  const _DayCard({required this.entries});

  final List<_LedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 60),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: CropkeepColors.borderDivider,
                ),
              ),
            _LedgerRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Single ledger row.

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry});

  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final scope = _BaseCurrencyScope.of(context);
    final name = _resolveName(entry);
    final iconAsset = _resolveIconAsset(entry);
    final swatch = _resolveSwatch(entry);
    final amountText = _formatSignedMoney(
      entry.baseAmountMinor,
      symbol: scope.symbol,
      decimals: scope.decimals,
      forceSign: true,
      negate: entry.isExpense,
    );
    final amountColor = entry.isExpense
        ? CropkeepColors.textPrimary
        : CropkeepColors.textGreenDeep;
    final meta = _buildMeta(entry);

    final tile = InkWell(
      onTap: () => _onTap(context, entry),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _RowIcon(
              asset: iconAsset,
              swatch: swatch,
              isExpense: entry.isExpense,
              isEmergency: entry.isEmergency,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _NameWithEditedMark(
                        name: name,
                        isEdited: entry.editedAtMs != null,
                      )),
                      const SizedBox(width: 8),
                      Text(
                        amountText,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: amountColor,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _MetaLine(spans: meta),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return tile;
  }
}

// Renders the plot/well name with an optional trailing `*` when the
// entry has been edited. The asterisk is a universal "modified" mark in
// text editors and form fields, so it reads as a status indicator
// rather than an actionable button. `semanticsLabel` on the span keeps
// screen readers informed.
class _NameWithEditedMark extends StatelessWidget {
  const _NameWithEditedMark({required this.name, required this.isEdited});

  final String name;
  final bool isEdited;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: CropkeepColors.textPrimary,
          height: 1.15,
        ),
        children: [
          TextSpan(text: name),
          if (isEdited)
            const TextSpan(
              text: ' *',
              semanticsLabel: ' edited',
              style: TextStyle(
                color: CropkeepColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

// Square swatch tile carrying the crop / well icon. Mirrors the 52×52
// Farm-tile pattern (color + 12px radius + padded SVG), scaled down to
// the Ledger's denser row height. An optional red corner dot signals
// `is_emergency = true` — notification-badge metaphor, zero horizontal
// cost in the row layout.
class _RowIcon extends StatelessWidget {
  const _RowIcon({
    required this.asset,
    required this.swatch,
    required this.isExpense,
    this.isEmergency = false,
  });

  final String? asset;
  final Color swatch;
  final bool isExpense;
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: swatch,
        borderRadius: BorderRadius.circular(10),
      ),
      child: asset != null
          ? SvgPicture.asset(asset!, fit: BoxFit.contain)
          : Icon(
              isExpense ? Icons.eco_outlined : Icons.savings_outlined,
              size: 18,
              color: CropkeepColors.textNavInactive,
            ),
    );
    if (!isEmergency) return tile;
    return Semantics(
      label: 'Emergency expense',
      child: SizedBox(
        width: 40,
        height: 40,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            tile,
            const Positioned(
              top: -3,
              right: -3,
              child: _EmergencyDot(),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyDot extends StatelessWidget {
  const _EmergencyDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: CropkeepColors.redAlert,
        shape: BoxShape.circle,
        // White ring lifts the dot off any swatch behind it; matches the
        // notification-badge convention so it reads as "alert" not
        // "another color blob on the tile."
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.spans});
  final List<InlineSpan> spans;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: CropkeepColors.textSecondary,
          height: 1.25,
        ),
        children: spans,
      ),
    );
  }
}

// Meta line content. The line is short on purpose now: timestamps were
// removed (people don't budget by clock-hour), emergency moved to a
// corner dot on the icon, and edits became an inline asterisk on the
// name. What's left: the user's note, the original currency amount
// when it differs from base, and the lock glyph for system-generated
// Carryover entries.
List<InlineSpan> _buildMeta(_LedgerEntry entry) {
  final spans = <InlineSpan>[];
  void appendDot() {
    if (spans.isNotEmpty) {
      spans.add(const TextSpan(text: '  ·  '));
    }
  }

  if (entry.note != null && entry.note!.trim().isNotEmpty) {
    spans.add(TextSpan(text: entry.note!.trim()));
  }
  if (entry.currencyCode != null) {
    appendDot();
    final originalFormatted = _formatPlain(
      entry.originalAmountMinor,
      decimals: entry.originalDecimals,
    );
    spans.add(TextSpan(text: '${entry.currencyCode} $originalFormatted'));
  }
  // Investment plots show up in the Ledger alongside every other outflow,
  // but the user's mental model is different — money put toward a target,
  // not money spent down. A soft "Contribution" tag (deep-blue tone to
  // echo bluePremium on the kind picker) lets investment rows surface
  // pre-attentively in mixed lists without inflating the row chrome.
  if (entry is _ExpenseEntry && entry.plot?.kind == PlotKind.investment) {
    appendDot();
    spans.add(const TextSpan(
      text: 'Contribution',
      style: TextStyle(
        color: CropkeepColors.bluePremium,
        fontWeight: FontWeight.w700,
      ),
    ));
  }
  if (entry.isLocked) {
    appendDot();
    spans.add(const WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Icon(
        Icons.lock_outline_rounded,
        size: 13,
        color: CropkeepColors.textSecondary,
      ),
    ));
  }
  return spans;
}

// ──────────────────────────────────────────────────────────────────────────
// Interactions — tap opens the read-only detail sheet; Edit and Remove
// both live behind the ⋮ in the detail sheet's header. Long-press is
// intentionally NOT wired: a swipe-and-mash gesture is the wrong entry
// point for either a traceable edit or a soft-delete, and routing both
// actions through tap → ⋮ forces a moment of deliberate intent that
// matches the plot-breakdown pattern.

void _onTap(BuildContext context, _LedgerEntry entry) {
  // System-generated rows (Carryover income) get a dedicated dialog
  // explaining why they can't be touched. Normal entries hand both
  // Edit and Remove callbacks to the detail sheet, which routes them
  // through its ⋮ overflow.
  if (entry.isLocked) {
    showDialog<void>(
      context: context,
      builder: (_) => const _LockedEntryDialog(),
    );
    return;
  }
  final base = _BaseCurrencyScope.of(context);
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LedgerEntryDetailSheet(
      isExpense: entry.isExpense,
      isEmergency: entry.isEmergency,
      sourceName: entry.sourceName,
      baseAmountMinor: entry.baseAmountMinor,
      baseCode: base.code,
      baseSymbol: base.symbol,
      baseDecimals: base.decimals,
      originalAmountMinor: entry.originalAmountMinor,
      originalCurrencyCode: entry.currencyCode,
      originalDecimals: entry.originalDecimals,
      exchangeRate: entry.exchangeRate,
      whenLogged: entry.when,
      note: entry.note,
      editedAt: entry.editedAtMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(entry.editedAtMs!),
      isLocked: entry.isLocked,
      // The detail sheet pops itself before dispatching, so the edit
      // form and the soft-delete snackbar land on the screen context
      // — not stacked on top of the detail modal.
      onEdit: () => _launchEdit(context, entry),
      onRemove: () => _softDelete(context, entry),
    ),
  );
}

void _launchEdit(BuildContext context, _LedgerEntry entry) {
  showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditLedgerEntrySheet(
      entryId: entry.id,
      isExpense: entry.isExpense,
    ),
  );
}

Future<void> _softDelete(BuildContext context, _LedgerEntry entry) async {
  final scope = AppScope.of(context);
  if (entry.isExpense) {
    await scope.transactions.softDelete(entry.id);
  } else {
    await scope.incomeEntries.softDelete(entry.id);
  }
  if (!context.mounted) return;
  CropkeepToast.info(
    context,
    title: entry.isExpense ? 'Transaction removed' : 'Income entry removed',
    action: ToastAction(
      label: 'Undo',
      onPressed: () async {
        if (entry.isExpense) {
          await scope.transactions.restore(entry.id);
        } else {
          await scope.incomeEntries.restore(entry.id);
        }
      },
    ),
  );
}

class _LockedEntryDialog extends StatelessWidget {
  const _LockedEntryDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Locked entry',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      content: const Text(
        "This entry was auto-logged from last cycle's surplus rollover. "
        "It can't be edited or removed.",
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: CropkeepColors.textPrimary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'OK',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              color: CropkeepColors.greenPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Recently-removed view — distinct mode of the same screen.

// ──────────────────────────────────────────────────────────────────────────
// Filter sheet — modal bottom sheet, live-apply. Composes the four
// dimensions (sources, currency, date range, emergency) under one
// scrollable column. No "Apply" button — each tap immediately calls
// `onChanged` which updates the screen-level filter state, so the
// underlying list narrows behind the sheet in real time. The "Done"
// button is just an explicit-close affordance; backdrop or swipe-down
// dismisses identically.

class _LedgerFilterSheet extends StatefulWidget {
  const _LedgerFilterSheet({required this.initial, required this.onChanged});

  final _LedgerFilters initial;
  final ValueChanged<_LedgerFilters> onChanged;

  @override
  State<_LedgerFilterSheet> createState() => _LedgerFilterSheetState();
}

class _LedgerFilterSheetState extends State<_LedgerFilterSheet> {
  late _LedgerFilters _filters = widget.initial;

  void _update(_LedgerFilters next) {
    setState(() => _filters = next);
    widget.onChanged(next);
  }

  Future<void> _pickRange(DateTime cycleStart) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _filters.dateRange ??
          DateTimeRange(start: cycleStart, end: now),
      firstDate: DateTime(cycleStart.year - 5),
      lastDate: now.add(const Duration(days: 1)),
      // Force the calendar variant — modal entry mode is jarring on
      // mobile and Cropkeep's quick-set chips already cover speed.
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null) return;
    _update(_filters.copyWith(dateRange: picked));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: CropkeepColors.bgScreen,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: StreamBuilder<_FilterSheetMeta>(
            stream: _watchFilterSheetMeta(scope.database),
            builder: (context, snap) {
              final meta = snap.data;
              return Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CropkeepColors.borderDivider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _FilterSheetTitle(),
                  const SizedBox(height: 8),
                  if (meta == null)
                    const Expanded(child: SizedBox.shrink())
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _FilterSectionCard(
                              title: 'From',
                              countLabel: _sourceCountLabel(
                                _filters.plotIds.length +
                                    _filters.wellIds.length,
                              ),
                              child: _SourceCardBody(
                                plots: meta.plots,
                                wells: meta.wells,
                                selectedPlotIds: _filters.plotIds,
                                selectedWellIds: _filters.wellIds,
                                onTogglePlot: (id) {
                                  final next = {..._filters.plotIds};
                                  if (!next.add(id)) next.remove(id);
                                  _update(_filters.copyWith(plotIds: next));
                                },
                                onToggleWell: (id) {
                                  final next = {..._filters.wellIds};
                                  if (!next.add(id)) next.remove(id);
                                  _update(_filters.copyWith(wellIds: next));
                                },
                              ),
                            ),
                            if (meta.activeCurrencyCodes.length >= 2) ...[
                              const SizedBox(height: 14),
                              _FilterSectionCard(
                                title: 'Currency',
                                countLabel: _filters.currencyCodes.isEmpty
                                    ? null
                                    : '${_filters.currencyCodes.length} selected',
                                child: _CurrencyChipsRow(
                                  codes: meta.activeCurrencyCodes,
                                  selected: _filters.currencyCodes,
                                  onToggle: (code) {
                                    final next = {..._filters.currencyCodes};
                                    if (!next.add(code)) next.remove(code);
                                    _update(_filters.copyWith(
                                      currencyCodes: next,
                                    ));
                                  },
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),
                            _FilterSectionCard(
                              title: 'Date range',
                              countLabel: _filters.dateRange == null
                                  ? null
                                  : _formatDateRange(_filters.dateRange!),
                              child: _DateRangeControls(
                                range: _filters.dateRange,
                                activeCycleStart: meta.activeCycleStart,
                                activeCycleEnd: meta.activeCycleEnd,
                                lastCycleStart: meta.lastCycleStart,
                                lastCycleEnd: meta.lastCycleEnd,
                                onPickRange: () =>
                                    _pickRange(meta.activeCycleStart),
                                onSetRange: (r) =>
                                    _update(_filters.copyWith(dateRange: r)),
                                onClear: () => _update(
                                  _filters.copyWith(clearDateRange: true),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _FilterSectionCard(
                              title: 'Emergencies',
                              leading: const _EmergencyDot(),
                              child: _EmergencySwitch(
                                value: _filters.emergencyOnly,
                                onChanged: (v) => _update(
                                  _filters.copyWith(emergencyOnly: v),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _FilterSheetFooter(
                    onClearAll: () => _update(_LedgerFilters.empty),
                    onDone: () => Navigator.of(context).pop(),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _FilterSheetTitle extends StatelessWidget {
  const _FilterSheetTitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Filter',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: CropkeepColors.textPrimary,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// One section in the filter sheet. Card chrome (white + borderCard +
// 14px radius, no shadow because the sheet itself already lifts the
// surface) plus a header row that can optionally lead with an icon /
// glyph (e.g., the red emergency dot) and trail with a meta label
// (count or summary like "Last cycle").
class _FilterSectionCard extends StatelessWidget {
  const _FilterSectionCard({
    required this.title,
    required this.child,
    this.leading,
    this.countLabel,
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const Spacer(),
              if (countLabel != null)
                Flexible(
                  child: Text(
                    countLabel!,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CropkeepColors.textSecondary,
                      height: 1.1,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// Builds "2 selected" / "1 selected" / null. Returning null hides the
// count label so the section header reads clean when nothing is on.
String? _sourceCountLabel(int n) =>
    n == 0 ? null : (n == 1 ? '1 selected' : '$n selected');

// The "From" card's body — combined plots + wells under one card but
// visually grouped by a small PLOTS / WELLS sub-eyebrow so the user
// reads them as two related concepts.
class _SourceCardBody extends StatelessWidget {
  const _SourceCardBody({
    required this.plots,
    required this.wells,
    required this.selectedPlotIds,
    required this.selectedWellIds,
    required this.onTogglePlot,
    required this.onToggleWell,
  });

  final List<PlotRow> plots;
  final List<WellRow> wells;
  final Set<int> selectedPlotIds;
  final Set<int> selectedWellIds;
  final ValueChanged<int> onTogglePlot;
  final ValueChanged<int> onToggleWell;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plots.isNotEmpty) ...[
          const _SubEyebrow('Plots'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in plots)
                _SourceChip(
                  label: p.name,
                  selected: selectedPlotIds.contains(p.id),
                  leading: _PlotSwatchDot(colorId: p.plotColorId),
                  onTap: () => onTogglePlot(p.id),
                ),
            ],
          ),
        ],
        if (wells.isNotEmpty) ...[
          if (plots.isNotEmpty) const SizedBox(height: 16),
          const _SubEyebrow('Wells'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in wells)
                _SourceChip(
                  label: w.name,
                  selected: selectedWellIds.contains(w.id),
                  leading: _WellIconGlyph(iconId: w.wellIconId),
                  onTap: () => onToggleWell(w.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SubEyebrow extends StatelessWidget {
  const _SubEyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: CropkeepColors.textSecondary,
        letterSpacing: 0.7,
        height: 1,
      ),
    );
  }
}

// 12px swatch dot — matches the swatch tile a plot row uses in the
// Ledger list, so the chip is recognisable at a glance.
class _PlotSwatchDot extends StatelessWidget {
  const _PlotSwatchDot({required this.colorId});
  final String? colorId;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: plotSwatchFor(colorId),
        shape: BoxShape.circle,
      ),
    );
  }
}

// Tiny SVG of the well's stored icon id, mirroring what the Ledger
// row icon tile uses for the same well.
class _WellIconGlyph extends StatelessWidget {
  const _WellIconGlyph({required this.iconId});
  final String iconId;

  @override
  Widget build(BuildContext context) {
    final asset = _wellIconAssetFor(iconId);
    if (asset == null) {
      return const Icon(
        Icons.savings_outlined,
        size: 14,
        color: CropkeepColors.textNavInactive,
      );
    }
    return SvgPicture.asset(asset, width: 14, height: 14);
  }
}

// Selectable chip with optional leading widget. Selected state is
// softened from solid `greenPrimary` to a `greenLight` fill +
// `greenPrimary` 1.5px border + `textGreenDeep` text. Reads as "tag
// is on" rather than "primary button," matching Cropkeep's tone.
class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CropkeepColors.greenLight : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? CropkeepColors.greenPrimary
                : CropkeepColors.borderCard,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? CropkeepColors.textGreenDeep
                    : CropkeepColors.textPrimary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrencyChipsRow extends StatelessWidget {
  const _CurrencyChipsRow({
    required this.codes,
    required this.selected,
    required this.onToggle,
  });

  final List<String> codes;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final code in codes)
          _SourceChip(
            label: code,
            selected: selected.contains(code),
            leading: _CurrencyFlag(code: code),
            onTap: () => onToggle(code),
          ),
      ],
    );
  }
}

// 14px flag glyph keyed off the currency catalog's `flagAsset` field.
// Falls back to a small currency-pill placeholder when no flag asset
// exists for that code (keeps the chip from looking broken).
class _CurrencyFlag extends StatelessWidget {
  const _CurrencyFlag({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    final spec = CurrencyCatalog.findByCode(code);
    final asset = spec?.flagAsset;
    if (asset == null) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: CropkeepColors.bgGoldWash,
          shape: BoxShape.circle,
          border: Border.all(
            color: CropkeepColors.borderGoldPill,
            width: 1,
          ),
        ),
      );
    }
    return ClipOval(
      child: SizedBox(
        width: 14,
        height: 14,
        child: SvgPicture.asset(asset, fit: BoxFit.cover),
      ),
    );
  }
}

// Single full-width "Jun 1 — Jun 30, 2026" button that launches a
// fullscreen `showDateRangePicker`, paired with quick-set chips below
// for the three common ranges users actually want.
class _DateRangeControls extends StatelessWidget {
  const _DateRangeControls({
    required this.range,
    required this.activeCycleStart,
    required this.activeCycleEnd,
    required this.lastCycleStart,
    required this.lastCycleEnd,
    required this.onPickRange,
    required this.onSetRange,
    required this.onClear,
  });

  final DateTimeRange? range;
  final DateTime activeCycleStart;
  final DateTime activeCycleEnd;
  final DateTime? lastCycleStart;
  final DateTime? lastCycleEnd;
  final VoidCallback onPickRange;
  final ValueChanged<DateTimeRange> onSetRange;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final hasRange = range != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPickRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: CropkeepColors.bgScreen,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CropkeepColors.borderCard,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: CropkeepColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasRange ? _formatDateRange(range!) : 'Any time',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasRange
                          ? CropkeepColors.textPrimary
                          : CropkeepColors.textSecondary,
                      height: 1.2,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: CropkeepColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickSetChip(
              label: 'This cycle',
              onTap: () => onSetRange(DateTimeRange(
                start: activeCycleStart,
                end: today.isAfter(activeCycleEnd) ? activeCycleEnd : today,
              )),
            ),
            if (lastCycleStart != null && lastCycleEnd != null)
              _QuickSetChip(
                label: 'Last cycle',
                onTap: () => onSetRange(DateTimeRange(
                  start: lastCycleStart!,
                  end: lastCycleEnd!,
                )),
              ),
            _QuickSetChip(
              label: 'Year to date',
              onTap: () => onSetRange(DateTimeRange(
                start: DateTime(now.year, 1, 1),
                end: today,
              )),
            ),
            if (hasRange)
              _QuickSetChip(
                label: 'Clear',
                tone: _QuickSetTone.muted,
                onTap: onClear,
              ),
          ],
        ),
      ],
    );
  }
}

enum _QuickSetTone { normal, muted }

class _QuickSetChip extends StatelessWidget {
  const _QuickSetChip({
    required this.label,
    required this.onTap,
    this.tone = _QuickSetTone.normal,
  });

  final String label;
  final VoidCallback onTap;
  final _QuickSetTone tone;

  @override
  Widget build(BuildContext context) {
    final isMuted = tone == _QuickSetTone.muted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: CropkeepColors.bgPageAlt,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isMuted
                ? CropkeepColors.textSecondary
                : CropkeepColors.textGreenDeep,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

// Sits inside the Emergencies card. The card's title slot already
// carries the red `_EmergencyDot` so this row stays clean — just the
// label + the adaptive switch.
class _EmergencySwitch extends StatelessWidget {
  const _EmergencySwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Show only emergency-tagged entries',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textPrimary,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: CropkeepColors.greenPrimary,
          ),
        ],
      ),
    );
  }
}

class _FilterSheetFooter extends StatelessWidget {
  const _FilterSheetFooter({
    required this.onClearAll,
    required this.onDone,
  });

  final VoidCallback onClearAll;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: CropkeepColors.bgScreen,
          border: Border(
            top: BorderSide(color: CropkeepColors.borderDivider, width: 1),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            TextButton(
              onPressed: onClearAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Clear all',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textSecondary,
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: CropkeepColors.greenPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: CropkeepColors.textOnGreenBtn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sheet meta — adds cycle date pairs (for the quick-set chips) on top
// of what the chip strip already needs.
class _FilterSheetMeta {
  const _FilterSheetMeta({
    required this.plots,
    required this.wells,
    required this.activeCurrencyCodes,
    required this.activeCycleStart,
    required this.activeCycleEnd,
    required this.lastCycleStart,
    required this.lastCycleEnd,
  });

  final List<PlotRow> plots;
  final List<WellRow> wells;
  final List<String> activeCurrencyCodes;
  final DateTime activeCycleStart;
  final DateTime activeCycleEnd;
  final DateTime? lastCycleStart;
  final DateTime? lastCycleEnd;
}

Stream<_FilterSheetMeta> _watchFilterSheetMeta(AppDatabase db) {
  final sources = _watchFilterableSources(db);
  final currencies = (db.select(db.currencies)
        ..where((t) => t.isActive.equals(true))
        ..orderBy([
          (t) => drift.OrderingTerm(expression: t.displayOrder),
          (t) => drift.OrderingTerm(expression: t.code),
        ]))
      .watch();
  final cycles = _watchCyclesNewestFirst(db);

  return _combineLatest3(sources, currencies, cycles, (
    _FilterableSources s,
    List<CurrencyRow> c,
    List<CycleRow> cyc,
  ) {
    final activeCycle = cyc.firstWhere(
      (e) => e.state == CycleState.active,
      orElse: () => cyc.first,
    );
    final completed = cyc.where((e) => e.state != CycleState.active).toList();
    final last = completed.isNotEmpty ? completed.first : null;
    return _FilterSheetMeta(
      plots: s.plots,
      wells: s.wells,
      activeCurrencyCodes: [for (final row in c) row.code],
      activeCycleStart:
          DateTime.fromMillisecondsSinceEpoch(activeCycle.startDate),
      activeCycleEnd: DateTime.fromMillisecondsSinceEpoch(activeCycle.endDate),
      lastCycleStart: last == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(last.startDate),
      lastCycleEnd: last == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(last.endDate),
    );
  });
}

// Three-way combine-latest used by the sheet meta. Generic enough to
// reuse anywhere a 3-stream merge is needed.
Stream<R> _combineLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A, B, C) combiner,
) {
  late StreamController<R> controller;
  A? va;
  B? vb;
  C? vc;
  bool ha = false;
  bool hb = false;
  bool hc = false;
  final subs = <StreamSubscription<dynamic>>[];

  void maybeEmit() {
    if (ha && hb && hc) {
      controller.add(combiner(va as A, vb as B, vc as C));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subs.add(a.listen((v) {
        va = v;
        ha = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(b.listen((v) {
        vb = v;
        hb = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(c.listen((v) {
        vc = v;
        hc = true;
        maybeEmit();
      }, onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
    },
  );
  return controller.stream;
}

// Four-way combine-latest mirror.
Stream<R> _combineLatest4<A, B, C, D, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  R Function(A, B, C, D) combiner,
) {
  late StreamController<R> controller;
  A? va;
  B? vb;
  C? vc;
  D? vd;
  bool ha = false;
  bool hb = false;
  bool hc = false;
  bool hd = false;
  final subs = <StreamSubscription<dynamic>>[];

  void maybeEmit() {
    if (ha && hb && hc && hd) {
      controller.add(combiner(va as A, vb as B, vc as C, vd as D));
    }
  }

  controller = StreamController<R>(
    onListen: () {
      subs.add(a.listen((v) {
        va = v;
        ha = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(b.listen((v) {
        vb = v;
        hb = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(c.listen((v) {
        vc = v;
        hc = true;
        maybeEmit();
      }, onError: controller.addError));
      subs.add(d.listen((v) {
        vd = v;
        hd = true;
        maybeEmit();
      }, onError: controller.addError));
    },
    onCancel: () async {
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
    },
  );
  return controller.stream;
}

class _RecentlyRemovedView extends StatelessWidget {
  const _RecentlyRemovedView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _RecentlyRemovedTitleBar(onBack: onBack),
          const SizedBox(height: 12),
          const _RemovedBanner(),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<_RemovedData>(
              stream: _watchRemoved(scope.database),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox.shrink();
                }
                final data = snap.data!;
                final entries = _buildRemovedEntries(data);
                if (entries.isEmpty) {
                  return const _EmptyState(
                    title: 'Nothing recently removed.',
                    hint:
                        'Soft-deleted entries appear here for 30 days before they hard-delete.',
                  );
                }
                final groups = _groupByDay(entries);
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: groups.length,
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DayHeader(date: g.date),
                          _RemovedDayCard(entries: g.entries),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyRemovedTitleBar extends StatelessWidget {
  const _RecentlyRemovedTitleBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          _IconAction(
            tooltip: 'Back',
            icon: Icons.arrow_back_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Text(
              'Recently removed',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemovedBanner extends StatelessWidget {
  const _RemovedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: CropkeepColors.bgGoldWash,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CropkeepColors.borderGoldPill, width: 1),
      ),
      child: const Text(
        "Soft-deleted within the last 30 days. After 30 days they're gone for good.",
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CropkeepColors.textOnGoldPill,
          height: 1.3,
        ),
      ),
    );
  }
}

class _RemovedData {
  const _RemovedData({
    required this.expenses,
    required this.incomes,
    required this.plotsById,
    required this.wellsById,
    required this.currencyDecimals,
    required this.baseCurrencyCode,
  });
  final List<TransactionRow> expenses;
  final List<IncomeEntryRow> incomes;
  final Map<int, PlotRow> plotsById;
  final Map<int, WellRow> wellsById;
  final Map<String, int> currencyDecimals;
  final String baseCurrencyCode;
}

Stream<_RemovedData> _watchRemoved(AppDatabase db) {
  final cutoff =
      DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
  final txStream = (db.select(db.transactions)
        ..where((t) =>
            t.deletedAt.isNotNull() & t.deletedAt.isBiggerThanValue(cutoff))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.deletedAt)]))
      .watch();
  final incStream = (db.select(db.incomeEntries)
        ..where((t) =>
            t.deletedAt.isNotNull() & t.deletedAt.isBiggerThanValue(cutoff))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.deletedAt)]))
      .watch();
  final plotsStream = db.select(db.plots).watch();
  final wellsStream = db.select(db.wells).watch();
  final currStream = db.select(db.currencies).watch();
  final settingsStream =
      (db.select(db.appSettings)..where((t) => t.id.equals(1)))
          .watchSingleOrNull();
  return _combineLatest6<
      List<TransactionRow>,
      List<IncomeEntryRow>,
      List<PlotRow>,
      List<WellRow>,
      List<CurrencyRow>,
      AppSettingsRow?,
      _RemovedData>(
    txStream,
    incStream,
    plotsStream,
    wellsStream,
    currStream,
    settingsStream,
    (tx, inc, plots, wells, currs, settings) => _RemovedData(
      expenses: tx,
      incomes: inc,
      plotsById: {for (final p in plots) p.id: p},
      wellsById: {for (final w in wells) w.id: w},
      currencyDecimals: {for (final c in currs) c.code: c.decimalPlaces},
      baseCurrencyCode: settings?.baseCurrencyCode ?? 'USD',
    ),
  );
}

List<_LedgerEntry> _buildRemovedEntries(_RemovedData data) {
  final out = <_LedgerEntry>[];
  for (final t in data.expenses) {
    out.add(_ExpenseEntry(
      row: t,
      plot: data.plotsById[t.plotId],
      originalDecimals: data.currencyDecimals[t.currencyCode] ?? 2,
      isCurrencyNonBase: t.currencyCode != data.baseCurrencyCode,
    ));
  }
  for (final e in data.incomes) {
    out.add(_IncomeEntry(
      row: e,
      well: data.wellsById[e.wellId],
      originalDecimals: data.currencyDecimals[e.currencyCode] ?? 2,
      isCurrencyNonBase: e.currencyCode != data.baseCurrencyCode,
    ));
  }
  // Sort by deletedAt desc (most recently removed first). For grouping we
  // still group by the original spent/received date, which feels more
  // intuitive — the user remembers when they spent, not when they deleted.
  out.sort((a, b) => b.when.compareTo(a.when));
  return out;
}

class _RemovedDayCard extends StatelessWidget {
  const _RemovedDayCard({required this.entries});
  final List<_LedgerEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CropkeepColors.borderCard, width: 1),
      ),
      child: Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 60),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: CropkeepColors.borderDivider,
                ),
              ),
            Opacity(
              opacity: 0.65,
              child: _RemovedRow(entry: entries[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _RemovedRow extends StatelessWidget {
  const _RemovedRow({required this.entry});
  final _LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final scope = _BaseCurrencyScope.of(context);
    final name = _resolveName(entry);
    final iconAsset = _resolveIconAsset(entry);
    final swatch = _resolveSwatch(entry);
    final amountText = _formatSignedMoney(
      entry.baseAmountMinor,
      symbol: scope.symbol,
      decimals: scope.decimals,
      forceSign: true,
      negate: entry.isExpense,
    );
    return InkWell(
      onTap: () => _confirmRestore(context, entry),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _RowIcon(
              asset: iconAsset,
              swatch: swatch,
              isExpense: entry.isExpense,
              isEmergency: entry.isEmergency,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: CropkeepColors.textPrimary,
                            decoration: TextDecoration.lineThrough,
                            height: 1.15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amountText,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CropkeepColors.textPrimary,
                          decoration: TextDecoration.lineThrough,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to restore',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CropkeepColors.textGreenDeep,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmRestore(BuildContext context, _LedgerEntry entry) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        entry.isExpense ? 'Restore this transaction?' : 'Restore this income entry?',
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: CropkeepColors.textPrimary,
        ),
      ),
      content: const Text(
        "It'll reappear on the Ledger and count toward this cycle's totals again.",
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: CropkeepColors.textPrimary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w600,
              color: CropkeepColors.textSecondary,
            ),
          ),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: CropkeepColors.greenPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(
            'Restore',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              color: CropkeepColors.textOnGreenBtn,
            ),
          ),
        ),
      ],
    ),
  );
  if (result != true || !context.mounted) return;
  final scope = AppScope.of(context);
  if (entry.isExpense) {
    await scope.transactions.restore(entry.id);
  } else {
    await scope.incomeEntries.restore(entry.id);
  }
}

// ──────────────────────────────────────────────────────────────────────────
// "Show older cycles" footer.

class _OlderCyclesFooter extends StatelessWidget {
  const _OlderCyclesFooter({
    required this.activeCycleStart,
    required this.hasMore,
    required this.onShowMore,
  });

  final DateTime activeCycleStart;
  final bool hasMore;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        'cycle started ${_monthShort(activeCycleStart.month)} ${activeCycleStart.day}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: CropkeepColors.borderDivider,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  dateLabel,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CropkeepColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: CropkeepColors.borderDivider,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hasMore)
            TextButton(
              onPressed: onShowMore,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Show older cycles',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textGreenDeep,
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'You\'ve reached the start of your ledger.',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: CropkeepColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Empty state.

// Special-cased no-results state for search. Inlines the query (bolded
// for context) and offers a one-tap "Clear search" affordance that
// bubbles back up to the screen-level toggle.
// Filter-only no-results state. Distinguished from the search variant
// by copy (no quoted query) and a slightly different glyph — the chip
// strip above the list already lists *which* filters are active, so the
// empty state doesn't need to repeat them.
class _FilterEmptyState extends StatelessWidget {
  const _FilterEmptyState({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: CropkeepColors.bgPlot,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.filter_alt_off_rounded,
                size: 44,
                color: CropkeepColors.textNavInactive,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No matches for these filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try removing a chip above, or clear all filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Clear filters',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textGreenDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query, required this.onClear});
  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: CropkeepColors.bgPlot,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.search_off_rounded,
                size: 44,
                color: CropkeepColors.textNavInactive,
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textPrimary,
                  height: 1.3,
                ),
                children: [
                  const TextSpan(text: 'No matches for '),
                  TextSpan(
                    text: '"$query"',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try a different word, or clear the search.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Clear search',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: CropkeepColors.textGreenDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.hint});
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: CropkeepColors.bgPlot,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.eco_outlined,
                size: 44,
                color: CropkeepColors.textNavInactive,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Helpers — name + icon resolution, money formatting.

String _resolveName(_LedgerEntry e) {
  if (e is _ExpenseEntry) {
    return e.plot?.name ?? 'Unknown plot';
  }
  if (e is _IncomeEntry) {
    return e.well?.name ?? 'Unknown well';
  }
  return '—';
}

// Swatch behind the icon. Expenses pull from the plot's `plot_color_id`
// via the shared `plotSwatchFor` mapping (same one Farm + Farmer use).
// Incomes default to a sandy neutral so wells read as a different
// surface kind from plots in mixed lists.
Color _resolveSwatch(_LedgerEntry e) {
  if (e is _ExpenseEntry) {
    final plot = e.plot;
    if (plot == null) return CropkeepColors.greenHint;
    if (plot.isUnplanned) return plotSwatchFor('sand');
    return plotSwatchFor(plot.plotColorId);
  }
  if (e is _IncomeEntry) {
    return plotSwatchFor('sand');
  }
  return CropkeepColors.greenHint;
}

// Maps plot/well identities to existing SVG assets when we can, returning
// null to fall back to a tinted glyph circle.
String? _resolveIconAsset(_LedgerEntry e) {
  if (e is _ExpenseEntry) {
    final plot = e.plot;
    if (plot == null) return null;
    if (plot.isUnplanned) {
      // Wildflower-y stand-in: use the cornucopia, the closest neutral
      // sticker among the existing assets.
      return 'assets/icons/cornucopia.svg';
    }
    return _cropIconAssetFor(plot.cropTypeId);
  }
  if (e is _IncomeEntry) {
    final well = e.well;
    if (well == null) return null;
    if (well.isCarryover) {
      return 'assets/icons/carryover.svg';
    }
    // Use the well's stored icon id if it maps to a known SVG, otherwise
    // fall back to the default stone-well asset.
    final mapped = _wellIconAssetFor(well.wellIconId);
    return mapped;
  }
  return null;
}

const Map<String, String> _cropIdToAsset = {
  'wheat': 'assets/icons/crops/wheat.svg',
  'apple': 'assets/icons/crops/apple.svg',
  'potato': 'assets/icons/crops/potato.svg',
  'barley': 'assets/icons/crops/icons8-barley.svg',
  'blueberry': 'assets/icons/crops/icons8-blueberry.svg',
  'carrot': 'assets/icons/crops/icons8-carrot.svg',
  'corn': 'assets/icons/crops/icons8-corn.svg',
  'eggplant': 'assets/icons/crops/icons8-eggplant.svg',
  'lettuce': 'assets/icons/crops/icons8-lettuce.svg',
  'mango': 'assets/icons/crops/icons8-mango.svg',
  'orange': 'assets/icons/crops/icons8-orange.svg',
  'peach': 'assets/icons/crops/icons8-peach.svg',
  'pear': 'assets/icons/crops/icons8-pear.svg',
  'bell_pepper': 'assets/icons/crops/icons8-bell-pepper.svg',
  'pineapple': 'assets/icons/crops/icons8-pineapple.svg',
  'raspberry': 'assets/icons/crops/icons8-raspberry.svg',
  'strawberry': 'assets/icons/crops/icons8-strawberry.svg',
  'tomato': 'assets/icons/crops/icons8-tomato.svg',
};

String? _cropIconAssetFor(String cropId) => _cropIdToAsset[cropId];

const Map<String, String> _wellIconIdToAsset = {
  'default': 'assets/icons/well.svg',
  'well': 'assets/icons/well.svg',
  'treasure': 'assets/icons/treasure.svg',
  'carryover': 'assets/icons/carryover.svg',
  'water': 'assets/icons/water.svg',
  'water-bottle': 'assets/icons/water-bottle.svg',
};

String? _wellIconAssetFor(String iconId) =>
    _wellIconIdToAsset[iconId] ?? 'assets/icons/well.svg';

// Plain money formatter — supports decimal_places 0–4 by integer math (no
// double rounding). Returns "1,234.56" for 123456 minor at 2 decimals.
String _formatPlain(int minor, {required int decimals}) {
  final absMinor = minor < 0 ? -minor : minor;
  String text;
  if (decimals == 0) {
    text = _withThousands(absMinor.toString());
  } else {
    final scale = _pow10(decimals);
    final whole = absMinor ~/ scale;
    final frac = absMinor % scale;
    text =
        '${_withThousands(whole.toString())}.${frac.toString().padLeft(decimals, '0')}';
  }
  return text;
}

String _formatSignedMoney(
  int minor, {
  required String symbol,
  required int decimals,
  bool forceSign = false,
  bool negate = false,
}) {
  final effective = negate ? -minor : minor;
  final isNeg = effective < 0;
  final body = _formatPlain(effective, decimals: decimals);
  final prefix = isNeg
      ? '−'
      : (forceSign && effective > 0 ? '+' : '');
  return '$prefix$symbol$body';
}

String _withThousands(String digits) {
  if (digits.length <= 3) return digits;
  final buf = StringBuffer();
  final start = digits.length % 3;
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (i - start) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

