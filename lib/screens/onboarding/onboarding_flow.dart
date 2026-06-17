import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../data/currency_catalog.dart';
import '../../theme/colors.dart';
import '../../widgets/avatar_picker_sheet.dart';
import '../../widgets/secondary_currency_picker_sheet.dart';
import 'onboarding_shell.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const int _welcome = 0;
  static const int _name = 1;
  static const int _baseCurrency = 2;
  static const int _secondaryCurrencies = 3;
  static const int _wellsTeach = 4;
  static const int _bonusWellsTeach = 5;
  static const int _cropsTeach = 6;
  static const int _marketTeach = 7;
  static const int _exchangeTeach = 8;
  static const int _allSet = 9;

  final TextEditingController _nameController = TextEditingController();
  String _avatarId = 'farmer';
  String? _baseCode;
  final Set<String> _secondaryCodes = <String>{};
  int _pageIndex = _welcome;
  bool _submitting = false;
  bool _localeDefaultApplied = false;

  List<int> get _pageSequence {
    final base = <int>[
      _welcome,
      _name,
      _baseCurrency,
      _secondaryCurrencies,
      _wellsTeach,
      _bonusWellsTeach,
      _cropsTeach,
      _marketTeach,
    ];
    if (_secondaryCodes.isNotEmpty) base.add(_exchangeTeach);
    base.add(_allSet);
    return base;
  }

  int get _totalSteps => _pageSequence.length;
  int get _currentStep => _pageSequence.indexOf(_pageIndex) + 1;

  void _goNext() {
    final pos = _pageSequence.indexOf(_pageIndex);
    if (pos < _pageSequence.length - 1) {
      setState(() => _pageIndex = _pageSequence[pos + 1]);
    }
  }

  void _goBack() {
    final pos = _pageSequence.indexOf(_pageIndex);
    if (pos > 0) {
      setState(() => _pageIndex = _pageSequence[pos - 1]);
    }
  }

  VoidCallback? get _backCallback => _pageIndex == _welcome ? null : _goBack;

  void _applyLocaleDefault(BuildContext context) {
    if (_localeDefaultApplied) return;
    _localeDefaultApplied = true;
    final locale = View.of(context).platformDispatcher.locale;
    _baseCode = _currencyForLocale(locale.countryCode?.toUpperCase());
  }

  static String _currencyForLocale(String? country) {
    const eu = {
      'DE', 'FR', 'IT', 'ES', 'NL', 'BE', 'AT',
      'PT', 'GR', 'IE', 'FI', 'LU', 'SK', 'SI', 'EE', 'LV', 'LT', 'CY', 'MT',
    };
    switch (country) {
      case 'US':
        return 'USD';
      case 'GB':
        return 'GBP';
      case 'JP':
        return 'JPY';
      case 'TW':
        return 'TWD';
      case 'KR':
        return 'KRW';
      case 'PH':
        return 'PHP';
      default:
        if (country != null && eu.contains(country)) return 'EUR';
        return 'USD';
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameController.text.trim();
    final baseCode = _baseCode;
    if (name.isEmpty || baseCode == null) return;
    setState(() => _submitting = true);
    try {
      await AppScope.of(context).appSettings.completeOnboarding(
            name: name,
            avatarId: _avatarId,
            baseCode: baseCode,
            secondaryCodes: _secondaryCodes,
          );
      // main.dart's StreamBuilder will swap to RootShell automatically.
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      rethrow;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _applyLocaleDefault(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.04),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(_pageIndex),
        child: _buildPage(),
      ),
    );
  }

  Widget _buildPage() {
    switch (_pageIndex) {
      case _welcome:
        return _WelcomePage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onContinue: _goNext,
        );
      case _name:
        return _NamePage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onBack: _backCallback,
          nameController: _nameController,
          avatarId: _avatarId,
          onAvatarChanged: (id) => setState(() => _avatarId = id),
          onContinue: _goNext,
        );
      case _baseCurrency:
        return _BaseCurrencyPage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onBack: _backCallback,
          selectedCode: _baseCode,
          onSelected: (code) {
            setState(() {
              _baseCode = code;
              _secondaryCodes.remove(code);
            });
          },
          onContinue: _goNext,
        );
      case _secondaryCurrencies:
        return _SecondaryCurrenciesPage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onBack: _backCallback,
          baseCode: _baseCode ?? 'USD',
          selectedCodes: _secondaryCodes,
          onToggle: (code, enabled) {
            setState(() {
              if (enabled) {
                _secondaryCodes.add(code);
              } else {
                _secondaryCodes.remove(code);
              }
            });
          },
          onContinue: _goNext,
          onSkip: () {
            setState(_secondaryCodes.clear);
            _goNext();
          },
        );
      case _wellsTeach:
        return _TeachPage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onBack: _backCallback,
          heroAsset: 'assets/icons/well.svg',
          heading: 'Wells are where money comes from',
          subtext:
              "Foundation wells are reliable income — salary, rent, pension. They fill the reservoir, which is what every plot's budget gets carved out of. You'll dig your own wells on the Farm tab next.",
          onContinue: _goNext,
        );
      case _bonusWellsTeach:
        return _TeachPage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onBack: _backCallback,
          heroAsset: 'assets/icons/treasure.svg',
          heading: 'Variable income is a bonus, not a budget',
          subtext:
              "Freelance, gigs, gifts go into bonus wells. The amounts they bring in fill a separate pool — they never inflate your budget. At cycle close, anything you didn't spend gets split between saving (your barn on the Farmer tab) and rolling over into next month's Carryover well.",
          onContinue: _goNext,
        );
      case _cropsTeach:
        return _CropsTeachPage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onBack: _backCallback,
          onContinue: _goNext,
        );
      case _marketTeach:
        return _TeachPage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onBack: _backCallback,
          heroAsset: 'assets/icons/fertilizers/fertilizer.svg',
          heading: 'Healthy harvests earn coins',
          subtext:
              "When the cycle closes, every healthy plot pays out coins — with the biggest bonus reserved for spending less than you earned overall. Spend coins on the Market tab: new crop types, fertilizers that boost a plot's yield, farm decorations, and skins. Purchases are forever; there's no sell-back.",
          onContinue: _goNext,
        );
      case _exchangeTeach:
        return _TeachPage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onBack: _backCallback,
          heroAsset: 'assets/icons/exchange.svg',
          heading: 'Exchange rates are set at harvest',
          subtext:
              "At the start of each cycle you set one rate per currency pair. It's locked for the whole cycle — no live FX during the month — so the math is predictable. You'll set your first rates at the next harvest.",
          onContinue: _goNext,
        );
      case _allSet:
        return _AllSetPage(
          step: _currentStep,
          totalSteps: _totalSteps,
          onBack: _backCallback,
          farmerName: _nameController.text.trim(),
          submitting: _submitting,
          onEnterFarm: _submit,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.step,
    required this.totalSteps,
    required this.onContinue,
  });

  final int step;
  final int totalSteps;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: step,
      totalSteps: totalSteps,
      heroAsset: 'assets/branding/logo.png',
      heading: 'Welcome to Cropkeep',
      subtext:
          "Tend a small farm. Tend your money. We'll walk you through how the farm works in a couple of minutes — you'll set up real wells and crops afterwards from the Farm tab.",
      onContinue: onContinue,
      continueLabel: 'Get started',
    );
  }
}

class _NamePage extends StatelessWidget {
  const _NamePage({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.nameController,
    required this.avatarId,
    required this.onAvatarChanged,
    required this.onContinue,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final TextEditingController nameController;
  final String avatarId;
  final ValueChanged<String> onAvatarChanged;
  final VoidCallback onContinue;

  static const List<String> _avatarOptions = ['farmer', 'farmer-fl'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: nameController,
      builder: (context, _) {
        final hasName = nameController.text.trim().isNotEmpty;
        return OnboardingShell(
          step: step,
          totalSteps: totalSteps,
          onBack: onBack,
          heroAsset: AvatarPickerSheet.assetFor(avatarId),
          heading: 'What should we call you?',
          subtext:
              'Your farmer\'s name shows up on the Farmer tab. Change it any time.',
          onContinue: hasName ? onContinue : null,
          child: Column(
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CropkeepColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Farmer name',
                  hintStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: CropkeepColors.textSecondary,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: CropkeepColors.borderCard,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: CropkeepColors.greenPrimary,
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) {
                  if (hasName) onContinue();
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (int i = 0; i < _avatarOptions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: AvatarTile(
                        avatarId: _avatarOptions[i],
                        isSelected: _avatarOptions[i] == avatarId,
                        onTap: () => onAvatarChanged(_avatarOptions[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BaseCurrencyPage extends StatelessWidget {
  const _BaseCurrencyPage({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.selectedCode,
    required this.onSelected,
    required this.onContinue,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final String? selectedCode;
  final ValueChanged<String> onSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: step,
      totalSteps: totalSteps,
      onBack: onBack,
      heroAsset: 'assets/icons/coin.svg',
      heading: 'What currency do you think in?',
      subtext: 'All your totals show in this one. Pick whichever you mostly spend in.',
      onContinue: selectedCode == null ? null : onContinue,
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
            for (int i = 0; i < CurrencyCatalog.all.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: CropkeepColors.borderDivider,
                ),
              _CurrencyRadioRow(
                spec: CurrencyCatalog.all[i],
                isSelected: CurrencyCatalog.all[i].code == selectedCode,
                onTap: () => onSelected(CurrencyCatalog.all[i].code),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CurrencyRadioRow extends StatelessWidget {
  const _CurrencyRadioRow({
    required this.spec,
    required this.isSelected,
    required this.onTap,
  });

  final CurrencySpec spec;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      fontWeight: FontWeight.w600,
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
            _RadioDot(isSelected: isSelected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? CropkeepColors.greenPrimary
              : CropkeepColors.borderCard,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: CropkeepColors.greenPrimary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

class _SecondaryCurrenciesPage extends StatelessWidget {
  const _SecondaryCurrenciesPage({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.baseCode,
    required this.selectedCodes,
    required this.onToggle,
    required this.onContinue,
    required this.onSkip,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final String baseCode;
  final Set<String> selectedCodes;
  final void Function(String code, bool enabled) onToggle;
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final visible = <CurrencySpec>[
      for (final spec in CurrencyCatalog.all)
        if (spec.code != baseCode) spec,
    ];
    return OnboardingShell(
      step: step,
      totalSteps: totalSteps,
      onBack: onBack,
      heroAsset: 'assets/icons/coin.svg',
      heading: 'Use any other currencies?',
      subtext:
          'Toggle on any currency you also earn or spend in. Skip if just the one.',
      onContinue: onContinue,
      onSkip: onSkip,
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            for (int i = 0; i < visible.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: CropkeepColors.borderDivider,
                ),
              CurrencyToggleRow(
                spec: visible[i],
                isActive: selectedCodes.contains(visible[i].code),
                onChanged: (enabled) => onToggle(visible[i].code, enabled),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TeachPage extends StatelessWidget {
  const _TeachPage({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.heroAsset,
    required this.heading,
    required this.subtext,
    required this.onContinue,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final String heroAsset;
  final String heading;
  final String subtext;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: step,
      totalSteps: totalSteps,
      onBack: onBack,
      heroAsset: heroAsset,
      heading: heading,
      subtext: subtext,
      onContinue: onContinue,
    );
  }
}

class _CropsTeachPage extends StatelessWidget {
  const _CropsTeachPage({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.onContinue,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onContinue;

  static const List<String> _exampleCrops = [
    'assets/icons/crops/wheat.svg',
    'assets/icons/crops/apple.svg',
    'assets/icons/crops/potato.svg',
  ];

  @override
  Widget build(BuildContext context) {
    return OnboardingShell(
      step: step,
      totalSteps: totalSteps,
      onBack: onBack,
      heroAsset: 'assets/icons/crops/wheat.svg',
      heading: 'Plots are your budget categories',
      subtext:
          'Each category becomes a crop plot — Food, Transport, Fun. Spending against it waters it. Crops grow steady, mild-stress, or wither based on your pace (remaining ÷ days left). Every farm also gets an Unplanned plot for spending that doesn\'t fit a category — it\'s already planted for you.',
      onContinue: onContinue,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _exampleCrops.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            _CropExampleTile(assetPath: _exampleCrops[i]),
          ],
        ],
      ),
    );
  }
}

class _CropExampleTile extends StatelessWidget {
  const _CropExampleTile({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CropkeepColors.borderCard,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: SvgPicture.asset(assetPath),
    );
  }
}

class _AllSetPage extends StatelessWidget {
  const _AllSetPage({
    required this.step,
    required this.totalSteps,
    required this.onBack,
    required this.farmerName,
    required this.submitting,
    required this.onEnterFarm,
  });

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final String farmerName;
  final bool submitting;
  final VoidCallback onEnterFarm;

  @override
  Widget build(BuildContext context) {
    final name = farmerName.isEmpty ? 'farmer' : farmerName;
    return OnboardingShell(
      step: step,
      totalSteps: totalSteps,
      onBack: submitting ? null : onBack,
      heroAsset: 'assets/icons/cornucopia.svg',
      heading: 'Your farm is ready',
      subtext:
          'Welcome, $name. Your Unplanned plot and Carryover well are already in place. Open the Farm tab to dig your wells and plant your first plots. Tap the + button any time to log money in or out.',
      onContinue: submitting ? null : onEnterFarm,
      continueLabel: submitting ? 'Setting up your farm…' : 'Enter your farm',
    );
  }
}
