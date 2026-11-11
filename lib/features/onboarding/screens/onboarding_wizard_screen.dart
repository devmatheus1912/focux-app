import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_wizard_chrome.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/utils/dashboard_onboarding_logic.dart';
import '../../planos/data/plano_features_bff_cache.dart';
import '../data/onboarding_repository.dart';
import '../providers/onboarding_provider.dart';
import '../data/onboarding_wizard_client_cache.dart';
import '../utils/onboarding_wizard_display.dart';
import '../utils/onboarding_wizard_normalize.dart';
import '../utils/setup_action_navigation.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/theme/fx_icons.dart';

part 'onboarding_wizard_screen_actions.part.dart';

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
  bool _viewTracked = false;
  bool _ttvTracked = false;
  bool _concluindo = false;
  final DateTime _openedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _evictHomeCaches() {
    PlanoFeaturesBffCache.clear();
    OnboardingWizardClientCache.clear();
    invalidatePersonalDashboardHome(ref);
  }

  Future<void> _load({bool silent = false}) async {
    final cachedRaw = OnboardingWizardClientCache.getIfFresh();
    final cached =
        cachedRaw == null ? null : normalizeOnboardingWizard(cachedRaw);
    final keepFold = silent && _wizard != null;
    if (!keepFold) {
      if (cached != null) {
        setState(() {
          _wizard = cached;
          _loading = false;
          _erro = null;
          _previousCompleted = cached.completedCount;
        });
        if (!silent && OnboardingWizardClientCache.getIfJustFetched() != null) {
          _trackViewedOnce(cached);
          _trackTtvOnce();
          return;
        }
      } else {
        setState(() {
          _loading = true;
          _erro = null;
        });
      }
    }
    try {
      final raw =
          await OnboardingRepository(ref.read(apiClientProvider)).wizard();
      if (!mounted) return;
      final w = normalizeOnboardingWizard(raw);
      OnboardingWizardClientCache.put(raw);
      final completed = w.completedCount;
      if (completed > _previousCompleted && _previousCompleted > 0) {
        HapticFeedback.mediumImpact();
        _evictHomeCaches();
        OnboardingWizardClientCache.put(raw);
      }
      if (w.allStepsDone && !_celebratedAllDone) {
        HapticFeedback.heavyImpact();
        _celebratedAllDone = true;
      }
      setState(() {
        _wizard = w;
        _loading = false;
        _erro = null;
        _previousCompleted = completed;
      });
      _trackViewedOnce(w);
      _trackTtvOnce();
    } catch (e) {
      if (!mounted) return;
      if (_wizard != null) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  void _trackViewedOnce(OnboardingWizard wizard) {
    if (_viewTracked) return;
    _viewTracked = true;
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.setupWizardViewed,
        props: {
          'completed': wizard.completedCount,
          'total': wizard.totalCount,
          'all_done': wizard.allStepsDone,
        },
      ),
    );
  }

  void _trackTtvOnce() {
    if (_ttvTracked) return;
    _ttvTracked = true;
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.setupWizardTtv,
        props: {'ms': DateTime.now().difference(_openedAt).inMilliseconds},
      ),
    );
  }

  Future<void> _refresh() async {
    unawaited(
      AnalyticsService.instance.track(ProductEvents.setupWizardRefreshed),
    );
    await _load(silent: true);
  }

  Future<void> _abrirStep(String route, {bool fromChip = false}) async {
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.setupWizardContinue,
        props: {'route': route, 'from_chip': fromChip},
      ),
    );
    if (fromChip) {
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.activationCtaTapped,
          props: {'source': 'wizard'},
        ),
      );
    }
    await pushSetupActionRoute(context, ref, route);
    if (mounted) await _load(silent: true);
  }

  Future<void> _sairSemConcluir() async {
    HapticFeedback.selectionClick();
    DashboardOnboardingWizardGate.dismissForSession();
    if (!mounted) return;
    context.go('/dashboard/personal');
  }

  bool get _allDone {
    final wizard = _wizard;
    if (wizard == null) return false;
    return wizard.allStepsDone || wizard.wizardCompleto;
  }

  @override
  Widget build(BuildContext context) {
    final wizard = _wizard;
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final ready = !_loading && _erro == null && wizard != null;

    return FxWizardPopGuard(
      onLeave: _sairSemConcluir,
      child: fxScreenA11yScope(
        label: 'Primeiros passos, configuração inicial',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Primeiros passos',
            subtitle:
                wizard == null
                    ? null
                    : wizardEtapaLabel(
                      completedCount: wizard.completedCount,
                      totalCount: wizard.totalCount,
                      allDone: _allDone,
                    ),
            // Concluído: sem "Agora não" (não há o que adiar); a seta sai sem
            // concluir, e "Concluir" fica no rodapé.
            leadingWidth: _allDone ? null : 108,
            leading:
                _allDone
                    ? null
                    : FxTonalButton(
                      label: wizardFazerDepoisLabel(),
                      onPressed: _sairSemConcluir,
                      compact: true,
                    ),
            showBack: _allDone ? true : null,
            onBack: _allDone ? _sairSemConcluir : null,
            actions: [
              FxHelpIconButton(tooltip: wizardHelpTitle(), onTap: _abrirAjuda),
            ],
          ),
          bottomNavigationBar:
              ready
                  ? FxWizardStickyBar(
                    primary: FxLiquidPrimaryButton(
                      label: wizardStickyLabel(
                        allDone: _allDone,
                        steps: wizard.steps,
                      ),
                      loading: _concluindo,
                      loadingLabel: 'Concluindo…',
                      onPressed:
                          _allDone
                              ? _concluir
                              : () => _abrirStep(
                                wizard.nextActionRoute,
                                fromChip: true,
                              ),
                    ),
                  )
                  : null,
          body:
              _loading && wizard == null
                  ? const SkeletonList(count: 5)
                  : _erro != null && wizard == null
                  ? FxErrorState(
                    chromeOnDark: chrome.isDark,
                    primary: primary,
                    message: _erro!,
                    onRetry: () => _load(),
                  )
                  : wizard == null
                  ? FxEmptyState(
                    icon: FxIcons.ia,
                    title: 'Setup ainda não disponível',
                    subtitle: 'Não encontramos os passos iniciais agora.',
                    action: FxEmptyAction(
                      label: 'Tentar novamente',
                      onTap: () => _load(),
                    ),
                  )
                  : RefreshIndicator(
                    onRefresh: _refresh,
                    child: FxContentWidthLimiter(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          FxSettingsLayout.headerToGroup,
                          FxSettingsLayout.pageInset,
                          TokensStrip.s5,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: _buildCurrentStep(wizard, chrome),
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  List<Widget> _buildCurrentStep(OnboardingWizard wizard, ShellPalette chrome) {
    final primary = Theme.of(context).colorScheme.primary;
    if (_allDone) return _buildConcluido(wizard, chrome);
    final atual = wizard.steps.where((s) => !s.completed).firstOrNull;
    return [
      Text(
        wizardIntroTitle(),
        style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
      ),
      const SizedBox(height: TokensStrip.s1),
      Text(
        wizardIntroBody(),
        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
      ),
      const SizedBox(height: TokensStrip.s4),
      for (final (i, step) in wizard.steps.indexed)
        Container(
          margin: const EdgeInsets.only(bottom: TokensStrip.s2),
          padding: const EdgeInsets.all(TokensStrip.s3),
          decoration: fxListCardDecoration(
            context,
            accent: step == atual ? primary : null,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child:
                    step.completed
                        ? Icon(FxIcons.check, color: primary, size: 22)
                        : Text(
                          '${i + 1}',
                          style: FocuxHubTypography.metric(
                            color: step == atual ? primary : chrome.mute,
                            fontSize: TokensStrip.fontBody,
                          ),
                        ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: FocuxHubTypography.cardTitle(
                        color: step.completed ? chrome.mute : chrome.ink,
                      ),
                    ),
                    if (step == atual && step.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        step.description,
                        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  /// Fim da ativação: bloco de marca com o ✓, os passos feitos em lista
  /// simples (não são botões) e o que vem depois.
  List<Widget> _buildConcluido(OnboardingWizard wizard, ShellPalette chrome) {
    final sobre = fxPaletaSobreMarca(context);
    final reduzir = TokensStrip.prefersReducedMotion(context);
    return [
      FxStripCard(
        marca: true,
        semanticsLabel: '${wizardDoneTitle()}. ${wizardDoneBody()}',
        child: Row(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduzir ? 1 : 0.8, end: 1),
              duration:
                  reduzir ? Duration.zero : const Duration(milliseconds: 360),
              curve: Curves.easeOutBack,
              builder:
                  (_, escala, child) =>
                      Transform.scale(scale: escala, child: child),
              child: Icon(FxIcons.concluido, color: sobre.ink, size: 40),
            ),
            const SizedBox(width: TokensStrip.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    wizardDoneTitle(),
                    style: FocuxHubTypography.sectionTitle(
                      context,
                      color: sobre.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    wizardDoneBody(),
                    style: FocuxHubTypography.bodyMuted(color: sobre.mute),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: FxSettingsLayout.groupGap),
      // Lista simples, sem cartão: os passos feitos não são botões.
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, step) in wizard.steps.indexed)
            Container(
              constraints: const BoxConstraints(
                minHeight: FxSettingsLayout.rowMinHeight,
              ),
              decoration: BoxDecoration(
                border:
                    i < wizard.steps.length - 1
                        ? Border(bottom: BorderSide(color: chrome.line))
                        : null,
              ),
              child: Row(
                children: [
                  Icon(
                    FxIcons.check,
                    color: Theme.of(context).colorScheme.primary,
                    size: FxSettingsLayout.iconSize,
                  ),
                  const SizedBox(width: FxSettingsLayout.iconGap),
                  Expanded(
                    child: Text(
                      step.title,
                      style: FxSettingsLayout.rowLabel(color: chrome.ink),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: TokensStrip.s3),
      Text(
        wizardProximoPasso(),
        style: FocuxHubTypography.bodyMuted(color: chrome.mute),
      ),
    ];
  }
}
