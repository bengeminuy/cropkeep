import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../data/currency_catalog.dart';
import '../data/database.dart';
import '../theme/colors.dart';

class SecondaryCurrencyPickerSheet extends StatelessWidget {
  const SecondaryCurrencyPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context).appSettings;
    return Container(
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
            const SizedBox(height: 16),
            const Text(
              'Secondary currencies',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick currencies you also receive income in or spend in. '
              'Your base currency is always available.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: StreamBuilder<List<CurrencyRow>>(
                stream: repo.watchCurrencies(),
                builder: (context, snap) {
                  final rows = snap.data ?? const <CurrencyRow>[];
                  final byCode = <String, CurrencyRow>{
                    for (final r in rows) r.code: r,
                  };
                  final visible = <CurrencySpec>[
                    for (final spec in CurrencyCatalog.all)
                      if (byCode[spec.code]?.isBase != true) spec,
                  ];
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: CropkeepColors.borderDivider,
                    ),
                    itemBuilder: (context, i) {
                      final spec = visible[i];
                      final row = byCode[spec.code];
                      final isActive = row?.isActive ?? false;
                      return CurrencyToggleRow(
                        spec: spec,
                        isActive: isActive,
                        onChanged: (newValue) =>
                            _handleToggle(context, spec, newValue),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    CurrencySpec spec,
    bool enable,
  ) async {
    final repo = AppScope.of(context).appSettings;
    if (!enable) {
      final usages = await repo.findActiveCurrencyUsages(spec.code);
      if (usages.isNotEmpty) {
        if (!context.mounted) return;
        await _showInUseDialog(context, spec, usages);
        return;
      }
    }
    await repo.setSecondaryCurrencyEnabled(spec, enable);
  }

  Future<void> _showInUseDialog(
    BuildContext context,
    CurrencySpec spec,
    List<String> usages,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Cannot disable ${spec.code}',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CropkeepColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "It's still used by:",
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CropkeepColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            for (final name in usages)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $name',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: CropkeepColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Archive or change the currency on those first.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: CropkeepColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CropkeepColors.textGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencyToggleRow extends StatelessWidget {
  const CurrencyToggleRow({
    super.key,
    required this.spec,
    required this.isActive,
    required this.onChanged,
  });

  final CurrencySpec spec;
  final bool isActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SvgPicture.asset(
            spec.flagAsset,
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.code,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: CropkeepColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                Text(
                  spec.name,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: CropkeepColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isActive,
            activeThumbColor: CropkeepColors.greenPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
