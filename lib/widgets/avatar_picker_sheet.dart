import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_scope.dart';
import '../theme/colors.dart';

class AvatarPickerSheet extends StatelessWidget {
  const AvatarPickerSheet({super.key, required this.currentAvatarId});

  final String currentAvatarId;

  static const List<String> _options = ['farmer', 'farmer-fl'];

  static String assetFor(String id) {
    switch (id) {
      case 'farmer-fl':
        return 'assets/icons/farmer-fl.svg';
      case 'farmer':
      default:
        return 'assets/icons/farmer.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CropkeepColors.bgScreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
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
              'Choose your avatar',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: CropkeepColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (int i = 0; i < _options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: AvatarTile(
                      avatarId: _options[i],
                      isSelected: _options[i] == currentAvatarId,
                      onTap: () async {
                        final repo = AppScope.of(context).appSettings;
                        await repo.updateAvatar(_options[i]);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AvatarTile extends StatelessWidget {
  const AvatarTile({
    super.key,
    required this.avatarId,
    required this.isSelected,
    required this.onTap,
  });

  final String avatarId;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? CropkeepColors.greenPrimary
                : CropkeepColors.borderCard,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: CropkeepColors.greenHint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              AvatarPickerSheet.assetFor(avatarId),
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
