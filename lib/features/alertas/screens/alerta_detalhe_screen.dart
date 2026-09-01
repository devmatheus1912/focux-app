import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../../../core/widgets/skeleton_loader.dart';
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
            : RefreshIndicator(
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
                  8,
                  FxSettingsLayout.pageInset,
                  110,
                ),
                children: [
                  FxSettingsGroup(
                    header: 'Situação',
                    caption: 'O que esfriou neste aluno.',
                    children: [
                      FxSettingsTile(
                        fxIcon: 'dumbbell',
                        label: 'Último treino',
                        value: alertaUltimoTreinoLabel(
                          _detalhe!.ultimoTreino,
                        ),
                        onTap: () => context.push(
                          '/alunos/${widget.alunoId}',
                          extra: nome,
                        ),
                      ),
                      FxSettingsTile(
                        fxIcon: 'circle-check',
                        label: 'Check-ins',
                        value: alertaCheckinsLabel(
                          _detalhe!.checkIns30Dias,
                        ),
                        onTap: () => context.push(
                          '/alunos/${widget.alunoId}',
                          extra: nome,
                        ),
                      ),
                      FxSettingsTile(
                        fxIcon: 'dollar-sign',
                        label: 'Mensalidade',
                        value: alertaStatusFinanceiroLabel(
                          _detalhe!.statusFinanceiro,
                        ),
                        danger: alertaStatusFinanceiroRuim(
                          _detalhe!.statusFinanceiro,
                        ),
                        showDivider: false,
                        onTap: () => context.push(
                          '/alunos/${widget.alunoId}',
                          extra: nome,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FxSettingsLayout.groupGap),
                  FxSettingsGroup(
                    header: 'Como retomar',
                    caption: _detalhe!.sugestaoIa.trim().isEmpty
                        ? 'Sem sugestão agora. Fale com o aluno pelo chat.'
                        : _detalhe!.sugestaoIa.trim(),
                    footer: const IaSafetyDisclaimer(compact: true),
                    children: [
                      FxSettingsTile(
                        fxIcon: 'spark',
                        label: _gerandoIa
                            ? 'Gerando…'
                            : _detalhe!.sugestaoFonte == 'IA'
                            ? 'Gerar outra sugestão'
                            : 'Melhorar com IA',
                        value: '',
                        locked: !_detalhe!.podeGerarIa,
                        upgradeTierLabel:
                            _detalhe!.podeGerarIa ? null : 'Pro',
                        onTap: _gerandoIa ? () {} : _gerarIa,
                      ),
                      FxSettingsTile(
                        fxIcon: 'message-circle',
                        label: 'Enviar mensagem',
                        value: 'Chat',
                        onTap: () => context.push(
                          '/alunos/${widget.alunoId}/chat',
                          extra: nome,
                        ),
                      ),
                      FxSettingsTile(
                        fxIcon: 'article',
                        label: 'Ver relatório',
                        value: '',
                        onTap: () => context.push(
                          '/alunos/${widget.alunoId}/relatorio',
                          extra: nome,
                        ),
                      ),
                      FxSettingsTile(
                        fxIcon: 'circle-check',
                        label: _resolving ? 'Resolvendo…' : 'Resolver alerta',
                        value: '',
                        showDivider: false,
                        onTap: _resolving ? () {} : _resolver,
                      ),
                    ],
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
