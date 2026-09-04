import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/anamnese_repository.dart';
import '../providers/anamnese_provider.dart';
import '../utils/anamnese_display.dart';
import '../utils/anamnese_pdf.dart';

/// S3 — Personal solicita e revisa. Não edita PAR-Q/saúde do aluno.
class AnamneseScreen extends ConsumerStatefulWidget {
  final int alunoId;
  const AnamneseScreen({super.key, required this.alunoId});

  @override
  ConsumerState<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends ConsumerState<AnamneseScreen> {
  Anamnese? _anamnese;
  bool _loading = true;
  bool _acting = false;
  String? _erro;
  DateTime? _fetchedAt;

  AnamneseRepository get _repo =>
      AnamneseRepository(ref.read(apiClientProvider));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _erro = null;
      });
    }
    try {
      final a = await _repo.buscar(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _anamnese = a;
        _fetchedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final semFicha = e is DioException && e.response?.statusCode == 404;
      if (semFicha) {
        setState(() {
          _anamnese = Anamnese();
          _fetchedAt = DateTime.now();
          _loading = false;
        });
      } else {
        setState(() {
          _erro = friendlyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _exportarPdf() async {
    final a = _anamnese;
    if (a == null) return;
    await exportAnamnesePdf(AnamnesePdfSnapshot(anamnese: a));
  }

  Future<void> _solicitar() async {
    HapticFeedback.mediumImpact();
    setState(() => _acting = true);
    try {
      final a = await _repo.solicitar(widget.alunoId);
      if (!mounted) return;
      ref.invalidate(alunoAnamneseProvider(widget.alunoId));
      setState(() => _anamnese = a);
      FeedbackHelper.showSuccess(context, 'Anamnese solicitada ao aluno.');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _revisar({
    required String status,
    required String title,
    required String confirmLabel,
    String? subtitle,
    bool pedirAtestado = false,
  }) async {
    final notasCtrl = TextEditingController(
      text: _anamnese?.notasProfissional ?? '',
    );
    final atestadoCtrl = TextEditingController(
      text: _anamnese?.atestadoObs ?? '',
    );
    final ok = await showFxFormSheet(
      context,
      title: title,
      subtitle: subtitle,
      confirmLabel: confirmLabel,
      icon: Icons.fact_check_outlined,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: notasCtrl,
            maxLines: 4,
            decoration: FxInputDeco.build(
              context,
              'Notas do profissional',
              icon: Icons.sticky_note_2_outlined,
            ),
          ),
          if (pedirAtestado) ...[
            const SizedBox(height: TokensStrip.s3),
            TextField(
              controller: atestadoCtrl,
              maxLines: 3,
              decoration: FxInputDeco.build(
                context,
                'Observação do atestado',
                icon: Icons.medical_information_outlined,
              ),
            ),
          ],
        ],
      ),
    );
    if (!ok || !mounted) {
      notasCtrl.dispose();
      atestadoCtrl.dispose();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _acting = true);
    try {
      final a = await _repo.revisar(
        widget.alunoId,
        AnamneseRevisaoRequest(
          status: status,
          notasProfissional: notasCtrl.text.trim(),
          atestadoObs: pedirAtestado ? atestadoCtrl.text.trim() : null,
        ),
      );
      if (!mounted) return;
      ref.invalidate(alunoAnamneseProvider(widget.alunoId));
      setState(() => _anamnese = a);
      FeedbackHelper.showSuccess(
        context,
        status == AnamneseStatus.revisada
            ? 'Anamnese marcada como revisada.'
            : status == AnamneseStatus.precisaAtestado
            ? 'Atestado solicitado ao aluno.'
            : 'Atualização solicitada ao aluno.',
      );
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      notasCtrl.dispose();
      atestadoCtrl.dispose();
      if (mounted) setState(() => _acting = false);
    }
  }

  String? get _primaryCtaLabel {
    final a = _anamnese;
    if (a == null || a.isNaoIniciada || a.isSolicitada) return null;
    if (a.isPreenchida || a.isPrecisaAtestado) return 'Marcar revisada';
    if (a.isRevisada) return 'Pedir atualização';
    return null;
  }

  VoidCallback? get _primaryCtaAction {
    final a = _anamnese;
    if (a == null || _acting) return null;
    if (a.isPreenchida || a.isPrecisaAtestado) {
      return () => _revisar(
        status: AnamneseStatus.revisada,
        title: 'Marcar como revisada',
        subtitle: 'Registre notas para o acompanhamento.',
        confirmLabel: 'Marcar revisada',
      );
    }
    if (a.isRevisada) {
      return () => _revisar(
        status: AnamneseStatus.solicitada,
        title: 'Pedir atualização',
        subtitle: 'O aluno será notificado para atualizar a ficha.',
        confirmLabel: 'Pedir atualização',
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = chrome.isDark;

    if (_loading) {
      return fxScreenA11yScope(
        label: 'Anamnese',
        child: const FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Anamnese',
            subtitle: 'Solicite e revise a ficha do aluno',
          ),
          body: SkeletonList(count: 5),
        ),
      );
    }
    if (_erro != null) {
      return fxScreenA11yScope(
        label: 'Anamnese',
        child: FxShellScaffold(
          useMesh: true,
          appBar: const FxShellAppBar(
            title: 'Anamnese',
            subtitle: 'Solicite e revise a ficha do aluno',
          ),
          body: FxErrorState(
            chromeOnDark: isDark,
            primary: primary,
            message: _erro!,
            onRetry: _load,
            title: 'Não conseguimos carregar a anamnese',
          ),
        ),
      );
    }

    final a = _anamnese!;
    final ctaLabel = _primaryCtaLabel;
    final ctaAction = _primaryCtaAction;

    return fxScreenA11yScope(
      label: 'Anamnese',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Anamnese',
          subtitle: 'Solicite e revise a ficha do aluno',
          actions: [
            if (a.personalPodeRevisar)
              ShellHeaderIconButton(
                icon: 'article',
                tooltip: 'Exportar PDF',
                onTap: _exportarPdf,
              ),
          ],
        ),
        bottomNavigationBar:
            ctaLabel == null
                ? null
                : SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3 +
                          MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    child: Semantics(
                      button: true,
                      enabled: !_acting,
                      label: ctaLabel,
                      child: FxLiquidPrimaryButton(
                        label: ctaLabel,
                        loading: _acting,
                        loadingLabel: 'Salvando…',
                        onPressed: ctaAction,
                      ),
                    ),
                  ),
                ),
        body: SafeArea(
          bottom: false,
          child: FxContentWidthLimiter(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s4,
                  FxSettingsLayout.pageInset,
                  24,
                ),
                children: [
                  FxHubHeader(
                    title: anamneseStatusLabel(a.status),
                    subtitle:
                        FxHubFreshness.fromFetchedAt(_fetchedAt) ??
                        anamneseStatusSubtitle(a.status),
                  ),
                  const SizedBox(height: TokensStrip.s3),
                  Text(
                    anamneseStatusSubtitle(a.status),
                    style: FocuxHubTypography.bodyMuted(
                      color: fxScreenMute(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (a.alertas.isNotEmpty) ...[
                    const SizedBox(height: TokensStrip.s4),
                    Wrap(
                      spacing: TokensStrip.s2,
                      runSpacing: TokensStrip.s2,
                      children: [
                        for (final alerta in a.alertas)
                          _AlertaChip(
                            label: alerta,
                            isDark: isDark,
                            warn: true,
                          ),
                        if (a.parqPositivo == true)
                          _AlertaChip(
                            label: 'PAR-Q+ positivo',
                            isDark: isDark,
                            warn: true,
                          ),
                      ],
                    ),
                  ],
                  if (a.isNaoIniciada) ...[
                    const SizedBox(height: TokensStrip.s5),
                    FxEmptyState(
                      icon: 'article',
                      title: 'Nenhuma ficha ainda',
                      subtitle:
                          'O aluno preenche a anamnese. Você solicita e revisa.',
                      action: FxEmptyAction(
                        label: 'Solicitar anamnese',
                        onTap: _acting ? () {} : _solicitar,
                      ),
                    ),
                  ] else if (a.isSolicitada && !a.personalPodeRevisar) ...[
                    const SizedBox(height: TokensStrip.s5),
                    FxEmptyState(
                      icon: 'calendar',
                      title: 'Aguardando preenchimento',
                      subtitle:
                          'O aluno foi notificado. Quando enviar, você revisa aqui.',
                    ),
                  ] else ...[
                    const SizedBox(height: TokensStrip.s4),
                    Wrap(
                      spacing: TokensStrip.s2,
                      runSpacing: TokensStrip.s2,
                      children: [
                        if (!a.isNaoIniciada && !a.isSolicitada)
                          DashboardHomeActionChip(
                            label: 'Pedir atestado',
                            accent: primary,
                            isDark: isDark,
                            enabled: !_acting,
                            onPressed:
                                () => _revisar(
                                  status: AnamneseStatus.precisaAtestado,
                                  title: 'Pedir atestado',
                                  subtitle:
                                      'Oriente o aluno sobre o que o atestado deve cobrir.',
                                  confirmLabel: 'Pedir atestado',
                                  pedirAtestado: true,
                                ),
                          ),
                        if (a.isPreenchida || a.isPrecisaAtestado)
                          DashboardHomeActionChip(
                            label: 'Pedir atualização',
                            accent: primary,
                            isDark: isDark,
                            enabled: !_acting,
                            onPressed:
                                () => _revisar(
                                  status: AnamneseStatus.solicitada,
                                  title: 'Pedir atualização',
                                  subtitle:
                                      'O aluno será notificado para atualizar a ficha.',
                                  confirmLabel: 'Pedir atualização',
                                ),
                          ),
                        if (!a.isNaoIniciada)
                          DashboardHomeActionChip(
                            label: 'Solicitar de novo',
                            accent: primary,
                            isDark: isDark,
                            enabled: !_acting,
                            onPressed: _solicitar,
                          ),
                        DashboardHomeActionChip(
                          label: 'Chat',
                          accent: primary,
                          isDark: isDark,
                          onPressed:
                              () => context.push(
                                '/alunos/${widget.alunoId}/chat',
                              ),
                        ),
                      ],
                    ),
                    if (a.personalPodeRevisar) ...[
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxSettingsGroup(
                        header: 'PAR-Q+',
                        caption:
                            a.parqCompleto == true
                                ? (a.parqPositivo == true
                                    ? 'Respostas positivas — atenção.'
                                    : 'Questionário completo.')
                                : 'Questionário incompleto ou não enviado.',
                        children: [
                          for (var i = 0; i < anamneseParqPerguntas.length; i++)
                            FxSettingsTile(
                              fxIcon: 'alert-triangle',
                              label: anamneseParqPerguntas[i].label,
                              value: anamneseBoolLabel(
                                anamneseParqValue(
                                  a,
                                  anamneseParqPerguntas[i].key,
                                ),
                              ),
                              showDivider:
                                  i < anamneseParqPerguntas.length - 1 ||
                                  (a.parqOutraRazaoDetalhe ?? '')
                                      .trim()
                                      .isNotEmpty,
                              danger:
                                  anamneseParqValue(
                                    a,
                                    anamneseParqPerguntas[i].key,
                                  ) ==
                                  true,
                            ),
                          if ((a.parqOutraRazaoDetalhe ?? '')
                              .trim()
                              .isNotEmpty)
                            FxSettingsTile(
                              fxIcon: 'help',
                              label: 'Detalhe (outra razão)',
                              value: a.parqOutraRazaoDetalhe!.trim(),
                              showDivider: false,
                            ),
                        ],
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxSettingsGroup(
                        header: 'Saúde',
                        caption: 'Preenchido pelo aluno — só leitura.',
                        children: [
                          _ro('Histórico médico', a.historicoMedico, 'article'),
                          _ro('Cirurgias', a.cirurgias, 'alert-triangle'),
                          _ro('Dores crônicas', a.doresCronicas, 'zap'),
                          _ro('Lesões / limitações', a.lesoes, 'trend'),
                          _ro('Medicamentos', a.medicamentos, 'spark'),
                          _ro('Alergias', a.alergias, 'alert-triangle'),
                          _ro(
                            'Gestação / pós-parto',
                            a.gestacaoPosParto,
                            'users',
                          ),
                          _ro(
                            'Histórico familiar CV',
                            a.historicoFamiliarCv,
                            'users',
                          ),
                          _ro(
                            'Sintomas CV',
                            a.sintomasCv,
                            'flame',
                            showDivider: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxSettingsGroup(
                        header: 'Hábitos',
                        children: [
                          FxSettingsTile(
                            fxIcon: 'moon',
                            label: 'Sono',
                            value: anamneseSonoHorasLabel(a.sonoHoras),
                          ),
                          _ro('Qualidade do sono', a.qualidadeSono, 'moon'),
                          _ro('Nível de estresse', a.nivelEstresse, 'zap'),
                          _ro('Tabagismo', a.tabagismo, 'x'),
                          _ro('Álcool', a.alcool, 'spark'),
                          _ro(
                            'Observações',
                            a.observacoes,
                            'article',
                            showDivider: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxSettingsGroup(
                        header: 'Treino e objetivos',
                        children: [
                          _ro('Objetivo', a.objetivo, 'target'),
                          _ro(
                            'Objetivo detalhado',
                            a.objetivoDetalhado,
                            'target',
                          ),
                          FxSettingsTile(
                            fxIcon: 'calendar',
                            label: 'Disponibilidade',
                            value:
                                a.disponibilidadeSemanal == null
                                    ? '—'
                                    : anamneseDisponibilidadeLabel(
                                      a.disponibilidadeSemanal!,
                                    ),
                          ),
                          _ro(
                            'Preferências de treino',
                            a.preferenciasTreino,
                            'dumbbell',
                          ),
                          _ro(
                            'Restrições alimentares',
                            a.restricoesAlimentares,
                            'spark',
                          ),
                          _ro(
                            'Histórico de atividade',
                            a.historicoAtividade,
                            'trend',
                          ),
                          _ro(
                            'Motivo de interrupções',
                            a.motivoInterrupcoes,
                            'x',
                          ),
                          _ro('Motivação atual', a.motivacaoAtual, 'flame'),
                          _ro(
                            'Algo mais',
                            a.algoMais,
                            'message-circle',
                            showDivider: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxSettingsGroup(
                        header: 'Notas do profissional',
                        caption: 'Só você edita na revisão.',
                        children: [
                          _ro(
                            'Notas',
                            a.notasProfissional,
                            'article',
                          ),
                          _ro(
                            'Atestado',
                            a.atestadoObs,
                            'circle-check',
                            showDivider: false,
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  FxSettingsTile _ro(
    String label,
    String? value,
    String icon, {
    bool showDivider = true,
  }) {
    return FxSettingsTile(
      fxIcon: icon,
      label: label,
      value: anamneseTextOrDash(value),
      showDivider: showDivider,
    );
  }
}

class _AlertaChip extends StatelessWidget {
  const _AlertaChip({
    required this.label,
    required this.isDark,
    this.warn = false,
  });

  final String label;
  final bool isDark;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final color = warn ? EagleTokens.warn : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensStrip.s3,
        vertical: TokensStrip.s2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
