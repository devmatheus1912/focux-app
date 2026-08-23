import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/api/api_client.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../../core/health/health_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/health/home_widget_service.dart';
import '../data/health_repository.dart';
import 'package:focux_app/core/widgets/feedback_helper.dart';

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
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  Future<void> _requestAccess() async {
    setState(() => _loading = true);
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        FeedbackHelper.showError(
          context,
          'Saúde não disponível neste dispositivo',
        );
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final summary = await HealthService.getTodaySummary();
      RecoverySnapshot? synced;
      try {
        final repo = HealthRepository.fromClient(ApiClient());
        synced = await repo.syncToday(summary);
        await HomeWidgetService.updateRecovery(
          recoveryScore: synced.recoveryScore,
          recoveryLabel: synced.recoveryLabel,
          recoveryHint: synced.recoveryHint,
          steps: synced.steps,
        );
      } catch (_) {
        synced = RecoverySnapshot.fromSummary(summary);
      }
      if (mounted) {
        setState(() {
          _authorized = true;
          _summary = summary;
          _recovery = synced;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          // Só troca a tela por erro quando ainda não há dados em tela.
          if (_summary == null) _erro = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Saúde & Wearables',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Saúde & Wearables',
          subtitle:
              FxHubFreshness.fromFetchedAt(_fetchedAt) ??
              'Dados do Apple Health e Google Fit',
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
                    setState(() => _erro = null);
                    _checkAuth();
                  },
                )
                : !_authorized
                ? _buildAuthPrompt()
                : _buildDashboard(isDark, primary),
      ),
    );
  }

  Widget _buildAuthPrompt() {
    return FxEmptyState(
      icon: 'spark',
      title: 'Conecte seu Apple Health ou Google Fit',
      subtitle:
          'Sincronize passos, frequência cardíaca, calorias e sono para acompanhar sua saúde.',
      action: FxEmptyAction(label: 'Conectar', onTap: _requestAccess),
    );
  }

  Widget _buildDashboard(bool isDark, Color primary) {
    final s = _summary!;
    final recovery = _recovery ?? RecoverySnapshot.fromSummary(s);
    final chrome = ShellChrome.forDark(isDark);
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              gradient: LinearGradient(
                colors: [primary, primary.withValues(alpha: 0.72)],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.24),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prontidao ${recovery.recoveryScore}%',
                  style: FocuxTypography.headline(color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  recovery.recoveryLabel,
                  style: FocuxHubTypography.body(
                    color: Colors.white,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  recovery.recoveryHint,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TokensStrip.s4),
          Text(
            'Resumo de Hoje',
            style: FocuxTypography.headline(color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s4),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.directions_walk,
                  label: 'Passos',
                  value: '${s.steps}',
                  color: EagleTokens.good,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.local_fire_department,
                  label: 'Calorias',
                  value: '${s.caloriesBurned.toInt()} kcal',
                  color: EagleTokens.warn,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.favorite,
                  label: 'FC Média',
                  value:
                      s.avgHeartRate > 0
                          ? '${s.avgHeartRate.toInt()} bpm'
                          : '--',
                  color: EagleTokens.bad,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.bedtime,
                  label: 'Sono',
                  value:
                      s.sleepHours > 0
                          ? '${s.sleepHours.toStringAsFixed(1)}h'
                          : '--',
                  color: EagleTokens.purple,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s5),
          OutlinedButton.icon(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await HealthService.revokeAccess();
              if (mounted) {
                setState(() {
                  _authorized = false;
                  _summary = null;
                });
              }
            },
            icon: const Icon(Icons.link_off, size: 18),
            label: const Text('Desconectar saúde'),
            style: OutlinedButton.styleFrom(foregroundColor: EagleTokens.bad),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: chrome.listCard(primary: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
        ],
      ),
    );
  }
}
