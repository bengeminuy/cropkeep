import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';

// Optional trailing action rendered inside a toast (e.g. ledger "Undo").
// When present the toast stays put for the full duration and ignores
// tap-to-dismiss so the user can actually hit the label.
class ToastAction {
  const ToastAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

// Themed snackbar shell used everywhere transient feedback is needed.
// Two layers of information: a literal change on top (`Expense logged`,
// `+5 Apple seeds`, `Need more coins`) and an optional flavor line below
// (`Tucked into the seed pouch`). Replaces the default Material snackbar
// so toasts read as part of Cropkeep rather than as a system notification
// floating over it.
class CropkeepToast {
  const CropkeepToast._();

  // Confirmation path — purchases, "logged", "updated". Market call sites
  // pass an item SVG via `iconAsset`; everywhere else gets the default
  // check glyph.
  static void success(
    BuildContext context, {
    required String title,
    String? flavor,
    String? iconAsset,
    IconData? icon,
    ToastAction? action,
    Duration? duration,
  }) {
    _show(
      context,
      accent: CropkeepColors.greenPrimary,
      title: title,
      flavor: flavor,
      iconAsset: iconAsset,
      icon: icon ?? Icons.check_circle_outline_rounded,
      action: action,
      duration: duration,
    );
  }

  // Error path — exceptions, insufficient coins, already owned, etc.
  static void error(
    BuildContext context, {
    required String title,
    String? flavor,
    IconData? icon,
    ToastAction? action,
    Duration? duration,
  }) {
    _show(
      context,
      accent: CropkeepColors.redAlert,
      title: title,
      flavor: flavor,
      icon: icon ?? Icons.error_outline_rounded,
      action: action,
      duration: duration,
    );
  }

  // Cautions — gated FAB, "seeds out", anything where the user needs to
  // do something elsewhere before this action will work.
  static void warning(
    BuildContext context, {
    required String title,
    String? flavor,
    IconData? icon,
    ToastAction? action,
    Duration? duration,
  }) {
    _show(
      context,
      accent: CropkeepColors.goldPrimary,
      title: title,
      flavor: flavor,
      icon: icon ?? Icons.report_problem_outlined,
      action: action,
      duration: duration,
    );
  }

  // Neutral acks — "coming soon", soft-deletes with Undo, dev-tool output.
  // Warm-brown accent stays in-palette without taking on a semantic charge.
  static void info(
    BuildContext context, {
    required String title,
    String? flavor,
    IconData? icon,
    ToastAction? action,
    Duration? duration,
  }) {
    _show(
      context,
      accent: CropkeepColors.textSecondaryOnHero,
      title: title,
      flavor: flavor,
      icon: icon ?? Icons.info_outline_rounded,
      action: action,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required Color accent,
    required String title,
    String? flavor,
    String? iconAsset,
    IconData? icon,
    ToastAction? action,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    // Actions need the toast to stay long enough to reach for; otherwise
    // keep the snappy 2.4s used by the market toast.
    final effectiveDuration = duration ??
        (action != null
            ? const Duration(seconds: 4)
            : const Duration(milliseconds: 2400));
    messenger.showSnackBar(
      SnackBar(
        content: _ToastBody(
          accent: accent,
          title: title,
          flavor: flavor,
          iconAsset: iconAsset,
          materialIcon: iconAsset == null ? icon : null,
          action: action,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        duration: effectiveDuration,
        // SnackBarBehavior.floating already clears the bottomNavigationBar
        // slot (the nav island). Only side breathing room is needed here —
        // adding bottom margin would lift the toast into mid-screen.
        margin: const EdgeInsets.symmetric(horizontal: 16),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

class _ToastBody extends StatelessWidget {
  const _ToastBody({
    required this.accent,
    required this.title,
    this.flavor,
    this.iconAsset,
    this.materialIcon,
    this.action,
  }) : assert(iconAsset != null || materialIcon != null);

  final Color accent;
  final String title;
  final String? flavor;
  final String? iconAsset;
  final IconData? materialIcon;
  final ToastAction? action;

  @override
  Widget build(BuildContext context) {
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CropkeepColors.bgHero,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: CropkeepColors.shadowCard,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _LeadingTile(
            accent: accent,
            iconAsset: iconAsset,
            materialIcon: materialIcon,
          ),
          const SizedBox(width: 12),
          Expanded(child: _TitleAndFlavor(title: title, flavor: flavor)),
          if (action != null) ...[
            const SizedBox(width: 8),
            _ActionLabel(accent: accent, action: action!),
          ],
        ],
      ),
    );

    // When there's no action, the whole toast is a dismiss target. With
    // an action the dismiss gesture would race the button, so we drop it
    // — the user can still swipe horizontally or wait out the 4s.
    if (action != null) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      child: body,
    );
  }
}

class _TitleAndFlavor extends StatelessWidget {
  const _TitleAndFlavor({required this.title, this.flavor});

  final String title;
  final String? flavor;

  @override
  Widget build(BuildContext context) {
    final flavor = this.flavor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: CropkeepColors.textPrimary,
            height: 1.15,
          ),
        ),
        if (flavor != null) ...[
          const SizedBox(height: 2),
          Text(
            flavor,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CropkeepColors.textSecondaryOnHero,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({required this.accent, required this.action});

  final Color accent;
  final ToastAction action;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        action.onPressed();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Text(
          action.label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: accent,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _LeadingTile extends StatelessWidget {
  const _LeadingTile({
    required this.accent,
    this.iconAsset,
    this.materialIcon,
  });

  final Color accent;
  final String? iconAsset;
  final IconData? materialIcon;

  @override
  Widget build(BuildContext context) {
    // Market items carry intricate SVG art that needs a white plate
    // to keep colors readable against the sand band. Material glyphs
    // are silhouettes — tinting the accent color and letting them sit
    // directly on bgHero reads cleaner with no plate fighting the
    // outer accent border.
    if (iconAsset != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(iconAsset!, width: 28, height: 28),
      );
    }
    return SizedBox(
      width: 40,
      height: 40,
      child: Icon(materialIcon, size: 28, color: accent),
    );
  }
}
