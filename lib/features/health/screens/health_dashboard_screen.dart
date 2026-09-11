import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/health/health_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/health/home_widget_service.dart';
import '../data/health_repository.dart';
import '../utils/health_dashboard_display.dart';
import '../widgets/recovery_score_ring.dart';

/// Screen showing synced Apple Health / Google Fit data.
///
/// Displays: steps, calories, heart rate, sleep.
/// Authorization flow is handled inline.
class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  bool _authorized = false;
  bool _loading = true;
  String? _erro;
  String? _syncSoftError;
  HealthSummary? _summary;
  RecoverySnapshot? _recovery;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final auth = await HealthService.isAuthorized();
      if (auth) {
        await _loadData();
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _erro = null;
            _syncSoftError = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
          _syncSoftError = null;
        });
      }
    }
  }

  Future<void> _requestAccess() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final granted = await HealthService.requestAuthorization();
      if (granted) {
        await _loadData();
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(
            e,
            fallback: 'Saúde não disponível neste dispositivo.',
          );
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final summary = await HealthService.getTodaySummary();
      RecoverySnapshot? synced;
      String? soft;
      try {
        final repo = HealthRepository.fromClient(ApiClient());
        synced = await repo.syncToday(summary);
        await HomeWidgetService.updateRecovery(
          recoveryScore: synced.recoveryScore,
          recoveryLabel: synced.recoveryLabel,
          recoveryHint: synced.recoveryHint,
          steps: synced.steps,
        );
      } catch (e) {
        synced = RecoverySnapshot.fromSummary(summary);
        soft = saudeSyncSoftError(friendlyError(e));
      }
      if (mounted) {
        setState(() {
          _authorized = true;
          _summary = summary;
          _recovery = synced;
          _loading = false;
          _erro = null;
          _syncSoftError = soft;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          // Só troca a tela por erro quando ainda não há dados em tela.
          if (_summary == null) {
            _erro = friendlyError(e);
            _syncSoftError = null;
          } else {
            _syncSoftError = friendlyError(
              e,
              fallback: saudeSyncSoftError(),
            );
          }
        });
      }
    }
  }

  Future<void> _desconectar() async {
    final ok = await showFxConfirmSheet(
      context,
      title: saudeDesconectarConfirmTitle(),
      message: saudeDesconectarConfirmMessage(),
      confirmLabel: saudeDesconectarLabel(),
      destructive: true,
    );
    if (!ok || !mounted) return;
    await HealthService.revokeAccess();
    if (!mounted) return;
    setState(() {
      _authorized = false;
      _summary = null;
      _recovery = null;
      _fetchedAt = null;
      _syncSoftError = null;
      _erro = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final subtitle =
        freshness ??
        (_authorized ? 'Apple Health e Google Fit' : 'Conecte o wearable');

    return fxScreenA11yScope(
      label: 'Saúde',
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Saúde',
          subtitle: subtitle,
          showBack: false,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar Saúde',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.homeHelpOpened,
                  props: {'surface': 'saude'},
                );
                showFxHelpSheet(
                  context,
                  title: 'Saúde',
                  subtitle: 'Prontidão do dia a partir do wearable.',
                  tips: const [
                    FxHelpTip('Como calculamos', saudeComoCalculamos),
                    FxHelpTip(
                      'Conectar',
                      'Autorize o Apple Health ou o Google Fit.',
                    ),
                    FxHelpTip('Prontidão', 'O card do topo é o foco do dia.'),
                    FxHelpTip(
                      'Desconectar',
                      'Revogue o acesso no fim da tela.',
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(TokensStrip.s4),
                  child: SkeletonList(count: 5),
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  message: _erro!,
                  title: FocuxMicrocopy.naoFoiPossivelCarregar,
                  onRetry: () {
                    setState(() {
                      _erro = null;
                      _loading = true;
                    });
                    _checkAuth();
                  },
                )
                : !_authorized
                ? _buildAuthPrompt()
                : FxContentWidthLimiter(child: _buildDashboard(isDark)),
      ),
    );
  }

  Widget _buildAuthPrompt() {
    return RefreshIndicator(
      onRefresh: _checkAuth,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: TokensStrip.s6),
          FxEmptyState(
            icon: 'spark',
            title: 'Conecte seu Apple Health ou Google Fit',
            subtitle:
                'Sincronize passos, frequência cardíaca, calorias e sono para acompanhar sua saúde.',
            action: FxEmptyAction(
              label: saudeConectarCtaLabel(),
              onTap: _requestAccess,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(bool isDark) {
    final s = _summary!;
    final recovery = _recovery ?? RecoverySnapshot.fromSummary(s);
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    return RefreshIndicator(
      onRefresh: () async {
        AnalyticsService.instance.track(
          ProductEvents.homeRefreshed,
          props: {'surface': 'saude'},
        );
        await _loadData();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(TokensStrip.s4),
        children: [
          FxStripCard(
            emphasize: true,
            glowStrength: 0.06,
            semanticsLabel:
                'Prontidão ${recovery.recoveryScore} por cento. ${recovery.recoveryLabel}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RecoveryScoreRing(
                      score: recovery.recoveryScore,
                      color: primary,
                      size: 72,
                    ),
                    const SizedBox(width: TokensStrip.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prontidão',
                            style: FocuxHubTypography.chip(chrome.mute),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${recovery.recoveryScore}%',
                            style: FocuxHubTypography.kpi(
                              color: chrome.ink,
                              fontSize: FocuxHubTypography.metricLg,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            recovery.recoveryLabel,
                            style: FocuxHubTypography.body(
                              color: chrome.ink,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  recovery.recoveryHint,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
                const SizedBox(height: TokensStrip.s3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DashboardHomeActionChip(
                    label:
                        _syncSoftError != null
                            ? saudeSyncSoftRetryLabel()
                            : saudeAtualizarLabel(),
                    accent: primary,
                    isDark: isDark,
                    onPressed: _loadData,
                  ),
                ),
              ],
            ),
          ),
          if (_syncSoftError != null) ...[
            const SizedBox(height: TokensStrip.s3),
            _SaudeSoftSyncBanner(
              isDark: isDark,
              message: _syncSoftError!,
              onRetry: _loadData,
            ),
          ],
          const SizedBox(height: TokensStrip.s4),
          const DashboardSectionHeader(title: 'Resumo de hoje'),
          const SizedBox(height: TokensStrip.s3),
          OperationalMetricTile(
            label: 'Passos',
            value: '${s.steps}',
            hint: 'Hoje',
            color: EagleTokens.good,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Calorias',
            value: '${s.caloriesBurned.toInt()} kcal',
            hint: 'Gasto estimado',
            color: EagleTokens.warn,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'FC média',
            value: s.avgHeartRate > 0 ? '${s.avgHeartRate.toInt()} bpm' : '--',
            hint: 'Frequência',
            color: EagleTokens.bad,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s2),
          OperationalMetricTile(
            label: 'Sono',
            value:
                s.sleepHours > 0 ? '${s.sleepHours.toStringAsFixed(1)}h' : '--',
            hint: 'Última noite',
            color: EagleTokens.purple,
            isDark: isDark,
          ),
          const SizedBox(height: TokensStrip.s5),
          FxConversionTextLink(
            text: '',
            actionText: saudeDesconectarLabel(),
            onTap: _desconectar,
          ),
        ],
      ),
    );
  }
}

class _SaudeSoftSyncBanner extends StatelessWidget {
  const _SaudeSoftSyncBanner({
    required this.isDark,
    required this.message,
    required this.onRetry,
  });

  final bool isDark;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final chrome = ShellChrome.forDark(isDark);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primary.withValues(alpha: 0.18)),
          color: primary.withValues(alpha: isDark ? 0.10 : 0.06),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync parcial',
              style: FocuxHubTypography.body(
                color: chrome.ink,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(saudeSyncSoftRetryLabel()),
            ),
          ],
        ),
      ),
    );
  }
}
