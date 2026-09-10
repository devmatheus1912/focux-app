import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_wizard_chrome.dart';
import '../../../core/widgets/fx_icon.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/utils/dashboard_home_client_cache.dart';
import '../../dashboard/utils/dashboard_onboarding_logic.dart';
import '../../planos/data/plano_features_bff_cache.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../data/onboarding_repository.dart';
import '../data/onboarding_wizard_client_cache.dart';
import '../utils/onboarding_wizard_display.dart';
import '../utils/onboarding_wizard_normalize.dart';
import '../utils/setup_action_navigation.dart';
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
    DashboardHomeClientCache.clear();
    PlanoFeaturesBffCache.clear();
    OnboardingWizardClientCache.clear();
    ref.invalidate(dashboardHomeProvider);
  }

  Future<void> _load({bool silent = false}) async {
    final landingCompleta =
        ref.read(planoFeaturesProvider).valueOrNull?.landingCompleta ?? false;
    final cachedRaw = OnboardingWizardClientCache.getIfFresh();
    final cached =
        cachedRaw == null
            ? null
            : normalizeOnboardingWizard(
              cachedRaw,
              landingCompleta: landingCompleta,
            );
    final keepFold = silent && _wizard != null;
    if (!keepFold) {
      if (cached != null) {
        setState(() {
          _wizard = cached;
          _loading = false;
          _erro = null;
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
      final raw =
          await OnboardingRepository(ref.read(apiClientProvider)).wizard();
      if (!mounted) return;
      final liveLanding =
          ref.read(planoFeaturesProvider).valueOrNull?.landingCompleta ??
          landingCompleta;
      final w = normalizeOnboardingWizard(
        raw,
        landingCompleta: liveLanding,
      );
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
    await pushSetupActionRoute(context, ref, route);
    if (mounted) await _load(silent: true);
  }

  Future<void> _sairSemConcluir() async {
    HapticFeedback.selectionClick();
    final leave = await showFxConfirmSheet(
      context,
      title: wizardLeaveTitle(),
      message: wizardLeaveMessage(),
      confirmLabel: wizardLeaveConfirm(),
    );
    if (!leave || !mounted) return;
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
          leadingWidth: 108,
          leading: TextButton(
            onPressed: _sairSemConcluir,
            style: TextButton.styleFrom(
              foregroundColor: chrome.mute,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              wizardFazerDepoisLabel(),
              style: FocuxHubTypography.bodyMuted(
                color: chrome.mute,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          actions: [
            FxHelpIconButton(
              tooltip: wizardHelpTitle(),
              onTap: _abrirAjuda,
            ),
          ],
        ),
        bottomNavigationBar:
            ready
                ? FxWizardStickyBar(
                    primary: FxLiquidPrimaryButton(
                      label: wizardStickyLabel(allDone: _allDone),
                      loading: _concluindo,
                      loadingLabel: 'Concluindo…',
                      onPressed:
                          _allDone
                              ? _pedirConcluir
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

  List<Widget> _buildCurrentStep(
    OnboardingWizard wizard,
    ShellPalette chrome,
  ) {
    final pending = wizard.steps.where((s) => !s.completed).toList();
    final completed = wizard.steps.where((s) => s.completed).toList();
    final current = pending.isEmpty ? null : pending.first;
    final later = pending.length > 1
        ? pending.skip(1).map((s) => s.title).toList()
        : const <String>[];
    final doneCaption = wizardTitlesCaption(
      prefix: 'Já feito:',
      titles: completed.map((s) => s.title).toList(),
    );
    final laterCaption = wizardTitlesCaption(prefix: 'Depois:', titles: later);
    final remaining = wizard.remainingMinutes;
    final title = current?.title ?? wizardDoneTitle();
    final body =
        current == null
            ? wizardDoneBody()
            : (current.description.trim().isEmpty
                ? null
                : current.description.trim());
    final minutes =
        current != null && current.estimatedMinutes > 0
            ? '~${current.estimatedMinutes} min'
            : remaining > 0 && current != null
            ? '~$remaining min'
            : '';

    final brand = BrandPalette.softened(Theme.of(context).colorScheme.primary);
    // Contexto (Já feito / Depois) fica abaixo do foco — §11/§12.
    final contextStyle = FocuxHubTypography.bodyMuted(
      color: chrome.mute,
      fontWeight: FontWeight.w500,
      height: 1.35,
    ).copyWith(fontSize: TokensStrip.fontBodySm);
    final metaStyle = FocuxHubTypography.bodyMuted(
      color: chrome.mute,
      fontWeight: FontWeight.w500,
    ).copyWith(fontSize: TokensStrip.fontBodySm);

    return [
      FxWizardStepDots(
        current: wizardEtapaCurrent(
          completedCount: wizard.completedCount,
          totalCount: wizard.totalCount,
          allDone: _allDone,
        ),
        total: wizard.totalCount <= 0 ? 1 : wizard.totalCount,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: TokensStrip.s4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FxIcon(
            name:
                current == null
                    ? 'spark'
                    : setupStepFxIconName(current.icon),
            size: FxSettingsLayout.iconSize,
            color: brand,
          ),
          const SizedBox(width: FxSettingsLayout.iconGap),
          Expanded(
            child: Text(
              title,
              style: FocuxHubTypography.sectionTitle(
                context,
                color: chrome.ink,
              ),
            ),
          ),
        ],
      ),
      if (body != null && body.isNotEmpty) ...[
        const SizedBox(height: TokensStrip.s2),
        Text(body, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
      ],
      if (minutes.isNotEmpty) ...[
        const SizedBox(height: TokensStrip.s2),
        Text(minutes, style: metaStyle),
      ],
      if (doneCaption.isNotEmpty || laterCaption.isNotEmpty) ...[
        const SizedBox(height: TokensStrip.s6),
        if (doneCaption.isNotEmpty)
          Text(
            doneCaption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: contextStyle,
          ),
        if (laterCaption.isNotEmpty) ...[
          if (doneCaption.isNotEmpty) const SizedBox(height: TokensStrip.s2),
          Text(
            laterCaption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: contextStyle,
          ),
        ],
      ],
    ];
  }
}
