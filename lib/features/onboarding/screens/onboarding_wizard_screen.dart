import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/utils/dashboard_home_client_cache.dart';
import '../data/onboarding_repository.dart';
import '../widgets/setup_step_widgets.dart';

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
  final DateTime _openedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _appBarSubtitle {
    const job = 'Deixe seu espaço pronto em cerca de 10 min';
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    if (freshness == null) return job;
    return '$freshness · ~10 min';
  }

  void _evictHomeCaches() {
    DashboardHomeClientCache.clear();
    ref.invalidate(dashboardHomeProvider);
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

  Future<void> _load({bool silent = false}) async {
    final keepFold = silent && _wizard != null;
    if (!keepFold) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }
    try {
      final w =
          await OnboardingRepository(ref.read(apiClientProvider)).wizard();
      if (!mounted) return;
      final completed = w.completedCount;
      if (completed > _previousCompleted && _previousCompleted > 0) {
        HapticFeedback.mediumImpact();
        _evictHomeCaches();
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
      if (keepFold) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  Future<void> _refresh() async {
    unawaited(
      AnalyticsService.instance.track(ProductEvents.setupWizardRefreshed),
    );
    await _load(silent: true);
  }

  Future<void> _concluir() async {
    HapticFeedback.heavyImpact();
    unawaited(
      AnalyticsService.instance.track(
        ProductEvents.setupWizardCompleted,
        props: {
          'completed': _wizard?.completedCount,
          'total': _wizard?.totalCount,
        },
      ),
    );
    await OnboardingRepository(ref.read(apiClientProvider)).marcarCompleto();
    _evictHomeCaches();
    if (mounted) context.go('/dashboard/personal');
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

  @override
  Widget build(BuildContext context) {
    final wizard = _wizard;
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final accent = BrandPalette.softened(primary);

    return fxScreenA11yScope(
      label: 'Primeiros passos, configuração inicial',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Primeiros passos',
          subtitle: _appBarSubtitle,
          onBack: () => context.go('/dashboard/personal'),
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
                                nextActionLabel: wizard.nextActionLabel,
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  FxSettingsLayout.pageInset,
                                  FxSettingsLayout.groupGap,
                                  FxSettingsLayout.pageInset,
                                  96,
                                ),
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: _buildStepList(wizard),
                              ),
                            ),
                          ],
                        ),
                        SetupWizardCta(
                          label:
                              wizard.allStepsDone
                                  ? 'Concluir setup'
                                  : 'Continuar setup',
                          accent: accent,
                          isDark: chrome.isDark,
                          onPressed:
                              wizard.allStepsDone || wizard.wizardCompleto
                                  ? _concluir
                                  : () => _abrirStep(
                                    wizard.nextActionRoute,
                                    fromChip: true,
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
        FxSettingsGroup(
          children: [
            for (var i = 0; i < pending.length; i++)
              SetupStepEntrance(
                index: i,
                child: SetupStepCard(
                  title: pending[i].title,
                  description: pending[i].description,
                  estimatedMinutes: pending[i].estimatedMinutes,
                  icon: pending[i].icon,
                  completed: false,
                  isLead: i == 0,
                  showDivider: i < pending.length - 1,
                  onTap: () => _abrirStep(pending[i].actionRoute),
                ),
              ),
          ],
        ),
      if (completed.isNotEmpty) ...[
        if (pending.isNotEmpty)
          const SizedBox(height: FxSettingsLayout.groupGap),
        FxSettingsGroup(
          header: 'Concluídos',
          children: [
            for (var i = 0; i < completed.length; i++)
              SetupStepCard(
                title: completed[i].title,
                icon: completed[i].icon,
                completed: true,
                showDivider: i < completed.length - 1,
              ),
          ],
        ),
      ],
    ];
  }
}
