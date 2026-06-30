import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/database.dart';
import '../data/tables/owned_items.dart';
import '../theme/colors.dart';
import '../widgets/market/market_category_chips.dart';
import '../widgets/market/market_resource_strip.dart';
import 'market/crops_category_page.dart';
import 'market/decorations_category_page.dart';
import 'market/fertilizers_category_page.dart';
import 'market/satchel_page.dart';
import 'market/skins_category_page.dart';

// Root Market scaffold. Five-cell PageView synced with an iconified
// chip row above. Satchel sits leftmost so swiping left from Crops
// "opens the bag" — the videogame gesture. The buy pages still load
// by default (index 1 = Crops) so first-run lands on shopping, not
// an empty inventory.
//
// Owns the affordable-only filter and the active page index;
// everything else is derived from streams.

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  // Satchel sits at index 0 (leftmost) so the swipe-left-from-Crops
  // gesture opens the inventory. The remaining chips keep their prior
  // order so muscle memory survives. Only the buy-page indices are
  // named here — nothing jumps to the satchel programmatically.
  static const _cropsIndex = 1;
  static const _fertilizersIndex = 2;
  static const _decorationsIndex = 3;
  static const _skinsIndex = 4;

  static const _chips = <MarketCategoryChipItem>[
    MarketCategoryChipItem(label: 'Satchel', icon: Icons.backpack_outlined),
    MarketCategoryChipItem(label: 'Crops', icon: Icons.eco_outlined),
    MarketCategoryChipItem(
        label: 'Fertilizers', icon: Icons.water_drop_outlined),
    MarketCategoryChipItem(
        label: 'Decorations', icon: Icons.auto_awesome_outlined),
    MarketCategoryChipItem(label: 'Skins', icon: Icons.face_outlined),
  ];

  // First-run lands on Crops, not the (likely empty) Satchel.
  final PageController _pageController =
      PageController(initialPage: _cropsIndex);
  int _index = _cropsIndex;
  bool _affordableOnly = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectIndex(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    _pageController.animateToPage(
      i,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  // Called from the Satchel's per-section "Shop ›" link. Avatars
  // live behind the Skins chip — plot/well/barn skins aren't shop
  // categories yet, so they fall back to the leftmost buy page.
  void _shopForType(OwnedItemType type) {
    switch (type) {
      case OwnedItemType.crop:
        _selectIndex(_cropsIndex);
      case OwnedItemType.fertilizer:
        _selectIndex(_fertilizersIndex);
      case OwnedItemType.decoration:
        _selectIndex(_decorationsIndex);
      case OwnedItemType.avatar:
        _selectIndex(_skinsIndex);
      case OwnedItemType.plotColor:
      case OwnedItemType.wellSkin:
      case OwnedItemType.barnSkin:
        _selectIndex(_cropsIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: StreamBuilder<_MarketData>(
        stream: _watchMarketData(scope.database),
        builder: (context, snapshot) {
          final data = snapshot.data;
          final int balance = data?.coinsBalance ?? 0;
          final Map<String, int> ownedQuantities = data?.ownedQuantities ?? {};

          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                MarketResourceStrip(
                  coinBalance: balance,
                  affordableOnly: _affordableOnly,
                  onAffordableToggled: (v) =>
                      setState(() => _affordableOnly = v),
                ),
                const SizedBox(height: 10),
                MarketCategoryChips(
                  items: _chips,
                  activeIndex: _index,
                  onSelected: _selectIndex,
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _index = i),
                    children: [
                      // _satchelIndex
                      SatchelPage(
                        ownedQuantities: ownedQuantities,
                        onShopForType: _shopForType,
                      ),
                      // _cropsIndex
                      CropsCategoryPage(
                        coinBalance: balance,
                        ownedQuantities: ownedQuantities,
                        affordableOnly: _affordableOnly,
                      ),
                      // _fertilizersIndex
                      FertilizersCategoryPage(
                        coinBalance: balance,
                        ownedQuantities: ownedQuantities,
                        affordableOnly: _affordableOnly,
                      ),
                      // _decorationsIndex
                      DecorationsCategoryPage(
                        coinBalance: balance,
                        ownedQuantities: ownedQuantities,
                        affordableOnly: _affordableOnly,
                      ),
                      // _skinsIndex
                      SkinsCategoryPage(
                        coinBalance: balance,
                        ownedQuantities: ownedQuantities,
                        affordableOnly: _affordableOnly,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Streams + data envelope. Two sources combine into one snapshot so the
// build method stays readable.

class _MarketData {
  const _MarketData({
    required this.coinsBalance,
    required this.ownedQuantities,
  });

  final int coinsBalance;
  final Map<String, int> ownedQuantities;
}

Stream<_MarketData> _watchMarketData(AppDatabase db) {
  final balanceStream = (db.select(db.appSettings)
        ..where((t) => t.id.equals(1)))
      .watchSingleOrNull()
      .map((s) => s?.coinsBalance ?? 0);
  final ownedStream = db.select(db.ownedItems).watch().map((rows) {
    return <String, int>{
      for (final row in rows) row.itemId: row.quantity,
    };
  });
  return _combine2<int, Map<String, int>, _MarketData>(
    balanceStream,
    ownedStream,
    (balance, owned) => _MarketData(
      coinsBalance: balance,
      ownedQuantities: owned,
    ),
  );
}

// Matches the inline combiner pattern used in `log_transaction_sheet.dart`.
// Kept local rather than extracted so the file is self-contained.
Stream<R> _combine2<A, B, R>(
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
