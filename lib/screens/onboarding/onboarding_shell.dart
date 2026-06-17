import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/colors.dart';

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.heroAsset,
    required this.heading,
    required this.subtext,
    required this.step,
    required this.totalSteps,
    this.child,
    this.onContinue,
    this.continueLabel,
    this.onSkip,
    this.skipLabel,
    this.onBack,
  });

  final String heroAsset;
  final String heading;
  final String subtext;
  final int step;
  final int totalSteps;
  final Widget? child;
  final VoidCallback? onContinue;
  final String? continueLabel;
  final VoidCallback? onSkip;
  final String? skipLabel;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CropkeepColors.bgScreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              _TopBar(
                onBack: onBack,
                step: step,
                totalSteps: totalSteps,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.62,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Center(child: _HeroDisc(assetPath: heroAsset)),
                        const SizedBox(height: 36),
                        Text(
                          heading,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: CropkeepColors.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            subtext,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: CropkeepColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ),
                        if (child != null) ...[
                          const SizedBox(height: 28),
                          child!,
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              _FooterButtons(
                onContinue: onContinue,
                continueLabel: continueLabel ?? 'Continue',
                onSkip: onSkip,
                skipLabel: skipLabel ?? 'Skip for now',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  final VoidCallback? onBack;
  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: onBack == null
                ? null
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onBack,
                      borderRadius: BorderRadius.circular(12),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: CropkeepColors.textPrimary,
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: Center(child: _ProgressPills(step: step, total: totalSteps)),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _ProgressPills extends StatelessWidget {
  const _ProgressPills({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= total; i++) ...[
          if (i > 1) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            width: i == step ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i <= step
                  ? CropkeepColors.greenPrimary
                  : CropkeepColors.borderDivider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroDisc extends StatelessWidget {
  const _HeroDisc({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: CropkeepColors.greenHint,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CropkeepColors.greenPrimary.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: assetPath.endsWith('.svg')
          ? SvgPicture.asset(
              assetPath,
              width: 144,
              height: 144,
              fit: BoxFit.contain,
            )
          : Image.asset(
              assetPath,
              width: 144,
              height: 144,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
    );
  }
}

class _FooterButtons extends StatelessWidget {
  const _FooterButtons({
    required this.onContinue,
    required this.continueLabel,
    required this.onSkip,
    required this.skipLabel,
  });

  final VoidCallback? onContinue;
  final String continueLabel;
  final VoidCallback? onSkip;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: CropkeepColors.greenPrimary,
              disabledBackgroundColor:
                  CropkeepColors.greenPrimary.withValues(alpha: 0.3),
              foregroundColor: CropkeepColors.textOnGreenBtn,
              disabledForegroundColor:
                  CropkeepColors.textOnGreenBtn.withValues(alpha: 0.8),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            child: Text(continueLabel),
          ),
        ),
        if (onSkip != null) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: CropkeepColors.textSecondary,
                textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(skipLabel),
            ),
          ),
        ],
      ],
    );
  }
}
