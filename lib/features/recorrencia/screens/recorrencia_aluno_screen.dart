import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/recorrencia_repository.dart';
import '../utils/recorrencia_display.dart';
import '../widgets/recorrencia_aluno_help_sheet.dart';

class RecorrenciaAlunoScreen extends ConsumerStatefulWidget {
  const RecorrenciaAlunoScreen({super.key});

  @override
  ConsumerState<RecorrenciaAlunoScreen> createState() =>
      _RecorrenciaAlunoScreenState();
}

class _RecorrenciaAlunoScreenState
    extends ConsumerState<RecorrenciaAlunoScreen> {
  RecorrenciaAssinatura? _assinatura;
  bool _loading = true;
  bool _mutando = false;
  String? _erro;
  DateTime? _fetchedAt;

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
      final a =
          await RecorrenciaRepository(ref.read(apiClientProvider)).minha();
      if (mounted) {
        setState(() {
          _assinatura = a;
          _loading = false;
          _fetchedAt = DateTime.now();
        });
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

  Future<void> _autorizar() async {
    final link = _assinatura?.initPoint?.trim();
    if (link == null || link.isEmpty) return;
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _pausar() async {
    final ok = await showFxConfirmSheet(
      context,
      title: recorrenciaPausarConfirmTitle(),
      message: recorrenciaPausarConfirmMessage(),
      confirmLabel: recorrenciaAlunoStickyLabel(
        RecorrenciaAlunoStickyKind.pausar,
      ),
    );
    if (!ok || !mounted) return;
    setState(() => _mutando = true);
    try {
      final a =
          await RecorrenciaRepository(ref.read(apiClientProvider)).pausarMinha();
      if (!mounted) return;
      setState(() {
        _assinatura = a;
        _fetchedAt = DateTime.now();
      });
      FeedbackHelper.showSuccess(context, 'Cobrança pausada.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _mutando = false);
    }
  }

  Future<void> _retomar() async {
    final ok = await showFxConfirmSheet(
      context,
      title: recorrenciaRetomarConfirmTitle(),
      message: recorrenciaRetomarConfirmMessage(),
      confirmLabel: recorrenciaAlunoStickyLabel(
        RecorrenciaAlunoStickyKind.retomar,
      ),
    );
    if (!ok || !mounted) return;
    setState(() => _mutando = true);
    try {
      final a = await RecorrenciaRepository(
        ref.read(apiClientProvider),
      ).retomarMinha();
      if (!mounted) return;
      setState(() {
        _assinatura = a;
        _fetchedAt = DateTime.now();
      });
      FeedbackHelper.showSuccess(context, 'Cobrança retomada.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _mutando = false);
    }
  }

  void _leave() => safePopOrGo(context, '/dashboard/aluno');

  VoidCallback _stickyOnPressed(RecorrenciaAlunoStickyKind kind) {
    return switch (kind) {
      RecorrenciaAlunoStickyKind.autorizar => _autorizar,
      RecorrenciaAlunoStickyKind.pausar => _pausar,
      RecorrenciaAlunoStickyKind.retomar => _retomar,
      RecorrenciaAlunoStickyKind.chat => () => context.push('/chat/aluno'),
    };
  }

  Widget _chips({required Color primary, required bool isDark}) {
    return Wrap(
      spacing: TokensStrip.s2,
      runSpacing: TokensStrip.s2,
      children: [
        DashboardHomeActionChip(
          label: 'Financeiro',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push('/financeiro/aluno'),
        ),
        DashboardHomeActionChip(
          label: 'Chat',
          accent: primary,
          isDark: isDark,
          onPressed: () => context.push('/chat/aluno'),
        ),
      ],
    );
  }

  List<Widget> _metricTiles({
    required String valor,
    required String valorHint,
    required String status,
    required String statusHint,
    required String proxima,
    required bool proximaMuted,
    required String pagamento,
    required String pagamentoHint,
    required bool muted,
    required Color primary,
    required bool isDark,
  }) {
    final emphasis =
        muted
            ? OperationalMetricEmphasis.muted
            : OperationalMetricEmphasis.normal;
    return [
      OperationalMetricTile(
        label: 'Valor mensal',
        value: valor,
        hint: valorHint,
        color: primary,
        isDark: isDark,
        emphasis: emphasis,
      ),
      const SizedBox(height: TokensStrip.s2),
      OperationalMetricTile(
        label: 'Status',
        value: status,
        hint: statusHint,
        color: primary,
        isDark: isDark,
        emphasis: emphasis,
      ),
      const SizedBox(height: TokensStrip.s2),
      OperationalMetricTile(
        label: 'Próxima',
        value: proxima,
        hint: recorrenciaCicloValue(),
        color: primary,
        isDark: isDark,
        emphasis:
            muted || proximaMuted
                ? OperationalMetricEmphasis.muted
                : OperationalMetricEmphasis.normal,
      ),
      const SizedBox(height: TokensStrip.s2),
      OperationalMetricTile(
        label: 'Pagamento',
        value: pagamento,
        hint: pagamentoHint,
        color: primary,
        isDark: isDark,
        emphasis: emphasis,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final assinatura = _assinatura;
    final stickyKind = recorrenciaAlunoStickyKind(
      status: assinatura?.status,
      initPoint: assinatura?.initPoint,
    );
    final showSticky = !_loading && _erro == null;

    return fxScreenA11yScope(
      label: 'Minha assinatura',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _leave();
        },
        child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Assinatura',
          subtitle: freshnessLabel,
          onBack: _leave,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar sua assinatura',
              onTap: () => showRecorrenciaAlunoHelpSheet(context),
            ),
          ],
        ),
        body:
            _loading
                ? const Padding(
                  padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                  child: SkeletonList(count: 4),
                )
                : _erro != null
                ? FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  title: 'Não conseguimos carregar sua assinatura',
                  message: _erro!,
                  onRetry: _load,
                )
                : Column(
                  children: [
                    Expanded(
                      child: FxContentWidthLimiter(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(
                              FxSettingsLayout.pageInset,
                              TokensStrip.s4,
                              FxSettingsLayout.pageInset,
                              TokensStrip.s4,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              if (assinatura == null) ...[
                                FxHubHeader(
                                  title: 'Sem assinatura ainda',
                                  subtitle: recorrenciaAlunoEmptySubtitle(),
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                ..._metricTiles(
                                  valor: '—',
                                  valorHint: 'Quando o personal criar a cobrança',
                                  status: 'Sem ciclo',
                                  statusHint: recorrenciaAlunoEmptySubtitle(),
                                  proxima: '—',
                                  proximaMuted: true,
                                  pagamento: '—',
                                  pagamentoHint: 'Sem autorização ainda',
                                  muted: true,
                                  primary: primary,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                _chips(primary: primary, isDark: isDark),
                                const SizedBox(height: TokensStrip.s4),
                                FxEmptyState(
                                  icon: 'coin',
                                  title: 'Sem assinatura recorrente ainda',
                                  subtitle:
                                      'Seu personal ainda não configurou cobrança automática mensal.',
                                  action: FxEmptyAction(
                                    label: 'Abrir chat',
                                    onTap: () => context.push('/chat/aluno'),
                                  ),
                                ),
                              ] else ...[
                                FxHubHeader(
                                  title: recorrenciaStatusLabel(
                                    assinatura.status,
                                  ),
                                  subtitle: recorrenciaAlunoHubSubtitle(),
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                FxStripCard(
                                  emphasize: true,
                                  accent: primary,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recorrenciaStatusLabel(
                                          assinatura.status,
                                        ),
                                        style: FocuxHubTypography.sectionTitle(
                                          context,
                                          color: ShellChrome.forDark(isDark).ink,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        recorrenciaValorLabel(assinatura.valor),
                                        style: FocuxHubTypography.kpi(
                                          color: ShellChrome.forDark(isDark).ink,
                                          fontSize: FocuxHubTypography.metricLg,
                                        ),
                                      ),
                                      const SizedBox(height: TokensStrip.s3),
                                      DashboardHomeActionChip(
                                        label: recorrenciaAlunoStickyLabel(
                                          stickyKind,
                                        ),
                                        accent: primary,
                                        isDark: isDark,
                                        enabled: !_mutando,
                                        onPressed: _stickyOnPressed(stickyKind),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                ..._metricTiles(
                                  valor: recorrenciaValorLabel(
                                    assinatura.valor,
                                  ),
                                  valorHint: recorrenciaCicloHint(),
                                  status: recorrenciaStatusLabel(
                                    assinatura.status,
                                  ),
                                  statusHint: recorrenciaCicloValue(),
                                  proxima: recorrenciaProximaValue(
                                    assinatura.proximaCobranca,
                                  ),
                                  proximaMuted:
                                      assinatura.proximaCobranca == null,
                                  pagamento: recorrenciaPagamentoValue(
                                    status: assinatura.status,
                                    initPoint: assinatura.initPoint,
                                  ),
                                  pagamentoHint: recorrenciaPagamentoHint(
                                    status: assinatura.status,
                                    initPoint: assinatura.initPoint,
                                  ),
                                  muted: false,
                                  primary: primary,
                                  isDark: isDark,
                                ),
                                const SizedBox(height: TokensStrip.s4),
                                _chips(primary: primary, isDark: isDark),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (showSticky)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            TokensStrip.s2,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s3 +
                                MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          child: FxLiquidPrimaryButton(
                            label: recorrenciaAlunoStickyLabel(stickyKind),
                            loading: _mutando,
                            loadingLabel: 'Salvando…',
                            onPressed:
                                _mutando ? null : _stickyOnPressed(stickyKind),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
