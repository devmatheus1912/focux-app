import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../ia/data/ia_repository.dart';
import '../../ia/widgets/ia_quota_upgrade.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../data/alertas_repository.dart';
import '../utils/alerta_detalhe_display.dart';
import '../widgets/alerta_detalhe_help_sheet.dart';

class AlertaDetalheScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const AlertaDetalheScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<AlertaDetalheScreen> createState() =>
      _AlertaDetalheScreenState();
}

class _AlertaDetalheScreenState extends ConsumerState<AlertaDetalheScreen> {
  final _openedAt = DateTime.now();
  AlertaDetalhe? _detalhe;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;
  var _viewTracked = false;
  var _ttvTracked = false;
  var _resolving = false;
  var _gerandoIa = false;

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
      final detalhe = await AlertasRepository(
        ref.read(apiClientProvider),
      ).detalheAluno(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _detalhe = detalhe;
        _loading = false;
        _fetchedAt = DateTime.now();
      });
      _trackViewIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = friendlyError(e);
        _loading = false;
      });
    }
  }

  void _trackViewIfNeeded() {
    if (_viewTracked) return;
    _viewTracked = true;
    AnalyticsService.instance.track(
      ProductEvents.alertasDetalheViewed,
      props: {'aluno_id': widget.alunoId},
    );
    if (!_ttvTracked) {
      _ttvTracked = true;
      AnalyticsService.instance.track(
        ProductEvents.alertasDetalheTtv,
        props: {
          'ms': DateTime.now().difference(_openedAt).inMilliseconds,
          'aluno_id': widget.alunoId,
        },
      );
    }
  }

  Future<void> _gerarIa() async {
    final atual = _detalhe;
    if (atual == null || _gerandoIa) return;
    if (!atual.podeGerarIa) {
      await UpgradePromptSheet.show(
        context: context,
        featureName: 'IA Copiloto',
        capability: 'iaCopiloto',
      );
      return;
    }
    setState(() => _gerandoIa = true);
    try {
      final next = await AlertasRepository(
        ref.read(apiClientProvider),
      ).aplicarSugestaoIa(atual, widget.alunoId);
      if (!mounted) return;
      setState(() => _detalhe = next);
      AnalyticsService.instance.track(
        ProductEvents.alertasDetalheIaGenerated,
        props: {'fonte': next.sugestaoFonte},
      );
    } on DioException catch (e) {
      final ia = IaOperationalException.fromDio(e);
      if (!mounted) return;
      await IaQuotaUpgrade.handleError(context, ref, ia);
      if (!mounted) return;
      if (ia.suggestsUpgrade || ia.planUpgradeRequired || ia.quotaExhausted) {
        return;
      }
      FeedbackHelper.showError(context, friendlyError(e));
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _gerandoIa = false);
    }
  }

  Future<void> _resolver() async {
    if (_resolving) return;
    setState(() => _resolving = true);
    try {
      await AlertasRepository(
        ref.read(apiClientProvider),
      ).resolver(widget.alunoId);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Alerta resolvido.');
      safePopOrGo(context, '/alertas');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final nome = _detalhe?.alunoNome.isNotEmpty == true
        ? _detalhe!.alunoNome
        : widget.alunoNome;

    return fxScreenA11yScope(
      label: 'Alerta — $nome',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: nome,
          subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
          onBack: () => safePopOrGo(context, '/alertas'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar este alerta',
              onTap: () {
                AnalyticsService.instance.track(
                  ProductEvents.alertasDetalheHelpOpened,
                );
                showAlertaDetalheHelpSheet(context);
              },
            ),
          ],
        ),
        body: _loading
            ? const Padding(
              padding: EdgeInsets.all(FxSettingsLayout.pageInset),
              child: SkeletonList(count: 6),
            )
            : _erro != null
            ? FxErrorState(
              chromeOnDark: isDark,
              primary: primary,
              message: _erro!,
              onRetry: _load,
            )
            : _detalhe == null
            ? FxEmptyState(
              icon: 'alert-triangle',
              title: 'Sem dados deste alerta',
              subtitle:
                  'Não encontramos o detalhe agora. Puxe para atualizar.',
              action: FxEmptyAction(label: 'Tentar de novo', onTap: _load),
            )
            : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    color: primary,
                    onRefresh: () async {
                      AnalyticsService.instance.track(
                        ProductEvents.alertasDetalheRefreshed,
                      );
                      await _load();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        TokensStrip.s4,
                        FxSettingsLayout.pageInset,
                        TokensStrip.s4,
                      ),
                      children: [
                        OperationalMetricTile(
                          label: 'Último treino',
                          value: alertaUltimoTreinoLabel(
                            _detalhe!.ultimoTreino,
                          ),
                          hint: alertaCheckinsLabel(_detalhe!.checkIns30Dias),
                          color: primary,
                          isDark: isDark,
                          emphasis: OperationalMetricEmphasis.alert,
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        OperationalMetricTile(
                          label: 'Mensalidade',
                          value: alertaStatusFinanceiroLabel(
                            _detalhe!.statusFinanceiro,
                          ),
                          hint: 'Situação financeira',
                          color:
                              alertaStatusFinanceiroRuim(
                                    _detalhe!.statusFinanceiro,
                                  )
                                  ? EagleTokens.bad
                                  : primary,
                          isDark: isDark,
                          emphasis:
                              alertaStatusFinanceiroRuim(
                                    _detalhe!.statusFinanceiro,
                                  )
                                  ? OperationalMetricEmphasis.alert
                                  : OperationalMetricEmphasis.normal,
                        ),
                        const SizedBox(height: TokensStrip.s4),
                        Text(
                          _detalhe!.sugestaoIa.trim().isEmpty
                              ? 'Sem sugestão agora. Fale com o aluno pelo chat.'
                              : _detalhe!.sugestaoIa.trim(),
                          style: FocuxHubTypography.bodyMuted(
                            color: fxScreenMute(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: TokensStrip.s3),
                        const IaSafetyDisclaimer(compact: true),
                        const SizedBox(height: TokensStrip.s4),
                        Wrap(
                          spacing: TokensStrip.s2,
                          runSpacing: TokensStrip.s2,
                          children: [
                            DashboardHomeActionChip(
                              label: 'Chat',
                              accent: primary,
                              isDark: isDark,
                              onPressed: () => context.push(
                                '/alunos/${widget.alunoId}/chat',
                                extra: nome,
                              ),
                            ),
                            DashboardHomeActionChip(
                              label: 'Relatório',
                              accent: primary,
                              isDark: isDark,
                              onPressed: () => context.push(
                                '/alunos/${widget.alunoId}/relatorio',
                                extra: nome,
                              ),
                            ),
                            DashboardHomeActionChip(
                              label: _gerandoIa
                                  ? 'Gerando…'
                                  : _detalhe!.sugestaoFonte == 'IA'
                                  ? 'Gerar outra'
                                  : 'Melhorar com IA',
                              accent: primary,
                              isDark: isDark,
                              enabled: !_gerandoIa,
                              onPressed: _gerarIa,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3,
                    ),
                    child: FxLiquidPrimaryButton(
                      label: 'Resolver alerta',
                      loading: _resolving,
                      loadingLabel: 'Resolvendo…',
                      onPressed: _resolving ? null : _resolver,
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
