import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/onboarding_repository.dart';
import '../widgets/setup_step_widgets.dart';
import '../../../core/widgets/fx_screen_a11y.dart';

class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key});

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  OnboardingWizard? _wizard;
  bool _loading = true;
  int _previousCompleted = 0;
  bool _celebratedAllDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final w =
          await OnboardingRepository(ref.read(apiClientProvider)).wizard();
      if (!mounted) return;
      final completed = w.completedCount;
      if (completed > _previousCompleted && _previousCompleted > 0) {
        HapticFeedback.mediumImpact();
      }
      if (w.allStepsDone && !_celebratedAllDone) {
        HapticFeedback.heavyImpact();
        _celebratedAllDone = true;
      }
      setState(() {
        _wizard = w;
        _loading = false;
        _previousCompleted = completed;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _concluir() async {
    HapticFeedback.heavyImpact();
    await OnboardingRepository(ref.read(apiClientProvider)).marcarCompleto();
    if (mounted) context.go('/dashboard/personal');
  }

  Future<void> _abrirStep(String route) async {
    await context.push<dynamic>(normalizeSetupActionRoute(route));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final wizard = _wizard;

    return fxScreenA11yScope(
      label: 'Setup D0',
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Setup D0',
          subtitle: 'Primeira vitória em 10 min',
          onBack: () => context.go('/dashboard/personal'),
        ),
        body:
            _loading
                ? const SetupWizardSkeleton()
                : wizard == null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(TokensStrip.s5),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Não foi possível carregar o setup.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: TokensStrip.s4),
                        SetupWizardCta(
                          label: 'Tentar novamente',
                          onPressed: _load,
                        ),
                      ],
                    ),
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _load,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          TokensStrip.s3,
                          TokensStrip.s4,
                          0,
                        ),
                        child: SetupProgressHeader(
                          progressPercent: wizard.progressPercent,
                          completedCount: wizard.completedCount,
                          totalCount: wizard.totalCount,
                          nextActionLabel: wizard.nextActionLabel,
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            TokensStrip.s4,
                            TokensStrip.s4,
                            TokensStrip.s2,
                          ),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: _buildStepList(wizard),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(TokensStrip.s4),
                          child: SetupWizardCta(
                            label:
                                wizard.allStepsDone
                                    ? 'Concluir setup'
                                    : 'Continuar setup',
                            onPressed:
                                wizard.allStepsDone || wizard.wizardCompleto
                                    ? _concluir
                                    : () => _abrirStep(wizard.nextActionRoute),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  List<Widget> _buildStepList(OnboardingWizard wizard) {
    final pending = wizard.steps.where((s) => !s.completed).toList();
    final completed = wizard.steps.where((s) => s.completed).toList();

    return [
      if (wizard.allStepsDone) const SetupAllDoneBanner(),
      ...pending.asMap().entries.map(
        (entry) => SetupStepEntrance(
          index: entry.key,
          child: SetupStepCard(
            title: entry.value.title,
            description: entry.value.description,
            estimatedMinutes: entry.value.estimatedMinutes,
            icon: entry.value.icon,
            completed: false,
            onTap: () => _abrirStep(entry.value.actionRoute),
          ),
        ),
      ),
      SetupCompletedStepsCollapse(
        titles: completed.map((s) => s.title).toList(),
      ),
    ];
  }
}
