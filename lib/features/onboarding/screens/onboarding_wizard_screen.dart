import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
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
  String? _erro;
  int _previousCompleted = 0;
  bool _celebratedAllDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
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
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Primeiros passos, configuração inicial',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Primeiros passos',
          subtitle: 'Deixe seu espaço pronto em cerca de 10 min',
          onBack: () => context.go('/dashboard/personal'),
        ),
        body:
            _loading
                ? const SkeletonList(count: 5)
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: chrome.isDark,
                  primary: primary,
                  message: _erro!,
                  onRetry: _load,
                )
                : wizard == null
                ? FxEmptyState(
                  icon: 'spark',
                  title: 'Setup ainda não disponível',
                  subtitle: 'Não encontramos os passos iniciais agora.',
                  action: FxEmptyAction(
                    label: 'Tentar novamente',
                    onTap: _load,
                  ),
                )
                : RefreshIndicator(
                  onRefresh: _load,
                  child: FxContentWidthLimiter(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            TokensStrip.s4,
                            TokensStrip.s3,
                            TokensStrip.s4,
                            0,
                          ),
                          child: SetupProgressHeroCard(
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
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: chrome.cardFill,
                            border: Border(
                              top: BorderSide(
                                color: chrome.line.withValues(alpha: 0.35),
                              ),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
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
                                        : () =>
                                            _abrirStep(wizard.nextActionRoute),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
            isLead: entry.key == 0,
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
