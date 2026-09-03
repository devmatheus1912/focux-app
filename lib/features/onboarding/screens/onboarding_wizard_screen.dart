import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/utils/dashboard_home_client_cache.dart';
import '../../planos/data/plano_features_bff_cache.dart';
import '../../dashboard/utils/dashboard_onboarding_logic.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/onboarding_repository.dart';
import '../data/onboarding_wizard_client_cache.dart';
import '../utils/onboarding_wizard_display.dart';
import '../widgets/setup_step_widgets.dart';

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
  DateTime? _fetchedAt;
  bool _viewTracked = false;
  bool _ttvTracked = false;
  bool _concluindo = false;
  final DateTime _openedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _appBarSubtitle {
    final remaining = _wizard?.remainingMinutes ?? 10;
    final mins = remaining <= 0 ? 'pronto' : '~$remaining min';
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    if (freshness == null) {
      return remaining <= 0
          ? 'Tudo pronto por aqui'
          : 'Deixe seu espaço pronto em cerca de $remaining min';
    }
    return '$freshness · $mins';
  }

  void _evictHomeCaches() {
    DashboardHomeClientCache.clear();
    PlanoFeaturesBffCache.clear();
    OnboardingWizardClientCache.clear();
    ref.invalidate(dashboardHomeProvider);
  }

  Future<void> _load({bool silent = false}) async {
    final cached = OnboardingWizardClientCache.getIfFresh();
    final keepFold = silent && _wizard != null;
    if (!keepFold) {
      if (cached != null) {
        setState(() {
          _wizard = cached;
          _loading = false;
          _erro = null;
          _fetchedAt = OnboardingWizardClientCache.fetchedAt;
          _previousCompleted = cached.completedCount;
        });
      } else {
        setState(() {
          _loading = true;
          _erro = null;
        });
      }
    }
    try {
      final w =
          await OnboardingRepository(ref.read(apiClientProvider)).wizard();
      if (!mounted) return;
      OnboardingWizardClientCache.put(w);
      final completed = w.completedCount;
      if (completed > _previousCompleted && _previousCompleted > 0) {
        HapticFeedback.mediumImpact();
        _evictHomeCaches();
        OnboardingWizardClientCache.put(w);
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
        _fetchedAt = DateTime.now();
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
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
        },
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
    await context.push<dynamic>(normalizeSetupActionRoute(route));
    if (mounted) await _load(silent: true);
  }

  void _sairSemConcluir() {
    HapticFeedback.selectionClick();
    DashboardOnboardingWizardGate.dismissForSession();
    context.go('/dashboard/personal');
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
          subtitle: _appBarSubtitle,
          onBack: _sairSemConcluir,
          actions: [
            FxHelpIconButton(
              tooltip: wizardHelpTitle(),
              onTap: _abrirAjuda,
            ),
            Padding(
              padding: const EdgeInsets.only(right: TokensStrip.s3),
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Fechar',
                  child: ShellHeaderIconButton(
                    icon: 'x',
                    tooltip: 'Fechar',
                    onTap: _sairSemConcluir,
                  ),
                ),
              ),
            ),
          ],
        ),
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
                  icon: 'spark',
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
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                FxSettingsLayout.pageInset,
                                TokensStrip.s3,
                                FxSettingsLayout.pageInset,
                                0,
                              ),
                              child: SetupProgressHeroCard(
                                progressPercent: wizard.progressPercent,
                                completedCount: wizard.completedCount,
                                totalCount: wizard.totalCount,
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  FxSettingsLayout.pageInset,
                                  FxSettingsLayout.headerToGroup,
                                  FxSettingsLayout.pageInset,
                                  TokensStrip.s9 + TokensStrip.s2,
                                ),
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: _buildStepList(wizard),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                FxSettingsLayout.pageInset,
                                TokensStrip.s2,
                                FxSettingsLayout.pageInset,
                                TokensStrip.s3,
                              ),
                              child: FxLiquidPrimaryButton(
                                label: wizardStickyLabel(
                                  allDone:
                                      wizard.allStepsDone ||
                                      wizard.wizardCompleto,
                                ),
                                onPressed:
                                    wizard.allStepsDone ||
                                            wizard.wizardCompleto
                                        ? _pedirConcluir
                                        : () => _abrirStep(
                                          wizard.nextActionRoute,
                                          fromChip: true,
                                        ),
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
      if (pending.isNotEmpty)
        for (var i = 0; i < pending.length; i++)
          SetupStepCard(
            title: pending[i].title,
            description: pending[i].description,
            estimatedMinutes: pending[i].estimatedMinutes,
            icon: pending[i].icon,
            completed: false,
            showDivider: i < pending.length - 1,
            onTap: () => _abrirStep(pending[i].actionRoute),
          ),
      if (completed.isNotEmpty) ...[
        if (pending.isNotEmpty)
          const SizedBox(height: FxSettingsLayout.groupGap),
        const DashboardSectionHeader(title: 'Concluídos'),
        for (var i = 0; i < completed.length; i++)
          SetupStepCard(
            title: completed[i].title,
            icon: completed[i].icon,
            completed: true,
            showDivider: i < completed.length - 1,
          ),
      ],
    ];
  }
}
