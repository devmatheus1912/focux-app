import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../avaliacao/utils/evolucao_comparativo_display.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_display.dart';
import '../providers/evolucao_home_provider.dart';
import '../utils/evolucao_home_client_cache.dart';
import '../widgets/evolucao_help_sheet.dart';

part 'evolucao_screen_widgets.part.dart';

class EvolucaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EvolucaoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<EvolucaoScreen> createState() => _EvolucaoScreenState();
}

class _EvolucaoScreenState extends ConsumerState<EvolucaoScreen> {
  EvolucaoHubView _view = EvolucaoHubView.medidas;
  DateTime? _fetchedAt;

  Future<void> _abrirVista() async {
    final picked = await showFxInsetPickerSheet<EvolucaoHubView>(
      context,
      title: 'Ver',
      selected: _view,
      items: [
        for (final v in EvolucaoHubView.values)
          FxInsetPickerSheetItem(value: v, label: evolucaoHubViewLabel(v)),
      ],
    );
    if (!mounted || picked == null || picked == _view) return;
    setState(() => _view = picked);
  }

  void _registrar() {
    if (_view == EvolucaoHubView.medidas) {
      _mostrarDialogMedida();
    } else {
      _mostrarDialogRecorde();
    }
  }

  void _abrirFotos() {
    context.push(
      '/alunos/${widget.alunoId}/fotos',
      extra: widget.alunoNome,
    );
  }

  void _abrirComparativo() {
    context.push(
      '/alunos/${widget.alunoId}/evolucao-comparativo',
      extra: widget.alunoNome,
    );
  }

  Future<void> _compartilharNoChat() async {
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: evolucaoComparativoConfirmTitle(),
      message: evolucaoComparativoConfirmMessage(),
      icon: Icons.chat_bubble_outline_rounded,
      confirmLabel: evolucaoComparativoConfirmLabel(),
    );
    if (!ok || !mounted) return;
    try {
      await EvolucaoRepository(
        ref.read(apiClientProvider),
      ).compartilharEvolucao(widget.alunoId);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Evolução compartilhada via chat.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(evolucaoHomeProvider(widget.alunoId));
    final medidasAsync = homeAsync.whenData((h) => h.medidas);
    final recordesAsync = homeAsync.whenData((h) => h.recordes);
    final medidas = medidasAsync.asData?.value;
    final variacao = medidas == null ? null : evolucaoVariacaoPeso(medidas);
    if (homeAsync.hasValue && _fetchedAt == null) {
      _fetchedAt = DateTime.now();
    }
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Evolução — ${widget.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Evolução',
          subtitle: evolucaoHubSubtitle(view: _view, variacao: variacao),
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar a evolução',
              onTap: () => showEvolucaoHelpSheet(context),
            ),
            ShellHeaderIconButton(
              icon: 'trend',
              tooltip: 'Trocar visão',
              onTap: _abrirVista,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: FxContentWidthLimiter(
                child: Column(
                  children: [
                    if (homeAsync.hasValue)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          TokensStrip.s4,
                          FxSettingsLayout.pageInset,
                          TokensStrip.s2,
                        ),
                        child: Column(
                          children: [
                            FxHubHeader(
                              title: fxTitleCaseName(widget.alunoNome),
                              freshnessLabel: FxHubFreshness.fromFetchedAt(
                                _fetchedAt,
                              ),
                              subtitle: evolucaoHubViewLabel(_view),
                            ),
                            const SizedBox(height: TokensStrip.s4),
                            OperationalMetricTile(
                              label:
                                  _view == EvolucaoHubView.medidas
                                      ? 'Peso'
                                      : 'Recordes',
                              value:
                                  _view == EvolucaoHubView.medidas
                                      ? evolucaoPesoAtual(medidas ?? const [])
                                      : '${recordesAsync.asData?.value.length ?? 0}',
                              hint:
                                  _view == EvolucaoHubView.medidas
                                      ? (variacao == null || variacao.isEmpty
                                          ? 'Registre duas medidas para ver a variação'
                                          : variacao)
                                      : 'Marcas pessoais',
                              color: primary,
                              isDark: chrome.isDark,
                            ),
                            const SizedBox(height: TokensStrip.s3),
                            Wrap(
                              spacing: TokensStrip.s2,
                              runSpacing: TokensStrip.s2,
                              children: [
                                DashboardHomeActionChip(
                                  label: 'Fotos',
                                  accent: primary,
                                  isDark: chrome.isDark,
                                  onPressed: _abrirFotos,
                                ),
                                DashboardHomeActionChip(
                                  label: 'Comparativo',
                                  accent: primary,
                                  isDark: chrome.isDark,
                                  onPressed: _abrirComparativo,
                                ),
                                DashboardHomeActionChip(
                                  label: 'Enviar no chat',
                                  accent: primary,
                                  isDark: chrome.isDark,
                                  onPressed: _compartilharNoChat,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: IndexedStack(
                        index: _view.index,
                        children: [
                          _TabMedidas(
                            alunoNome: widget.alunoNome,
                            medidasAsync: medidasAsync,
                            onRegister: _mostrarDialogMedida,
                            onRetry:
                                () => ref.invalidate(
                                  evolucaoHomeProvider(widget.alunoId),
                                ),
                          ),
                          _TabRecordes(
                            alunoNome: widget.alunoNome,
                            recordesAsync: recordesAsync,
                            onRegister: _mostrarDialogRecorde,
                            onRetry:
                                () => ref.invalidate(
                                  evolucaoHomeProvider(widget.alunoId),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s2,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                child: FxLiquidPrimaryButton(
                  label:
                      _view == EvolucaoHubView.medidas
                          ? 'Registrar medida'
                          : 'Registrar recorde',
                  onPressed: _registrar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogMedida() async {
    final pesoCtrl = TextEditingController();
    final abdomenCtrl = TextEditingController();
    final quadrilCtrl = TextEditingController();
    final bracoCtrl = TextEditingController();
    try {
      final saved = await showFxFormSheet(
        context,
        title: 'Nova medida',
        icon: Icons.monitor_weight_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: pesoCtrl,
              label: 'Peso (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              controller: abdomenCtrl,
              label: 'Circunf. abdômen (cm)',
              icon: Icons.straighten_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              controller: quadrilCtrl,
              label: 'Quadril (cm)',
              icon: Icons.straighten_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              controller: bracoCtrl,
              label: 'Braço (cm)',
              icon: Icons.straighten_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              showDivider: false,
            ),
          ],
        ),
      );
      if (saved != true) return;
      await EvolucaoRepository(ref.read(apiClientProvider)).adicionarMedida(
        widget.alunoId,
        peso: double.tryParse(pesoCtrl.text.replaceAll(',', '.')),
        cintura: double.tryParse(abdomenCtrl.text.replaceAll(',', '.')),
        quadril: double.tryParse(quadrilCtrl.text.replaceAll(',', '.')),
        braco: double.tryParse(bracoCtrl.text.replaceAll(',', '.')),
      );
      EvolucaoHomeClientCache.invalidate(widget.alunoId);
      ref.invalidate(evolucaoHomeProvider(widget.alunoId));
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Medida adicionada!');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      pesoCtrl.dispose();
      abdomenCtrl.dispose();
      quadrilCtrl.dispose();
      bracoCtrl.dispose();
    }
  }

  Future<void> _mostrarDialogRecorde() async {
    final exercicioCtrl = TextEditingController();
    final cargaCtrl = TextEditingController();
    final unidadeCtrl = TextEditingController(text: 'kg');
    final obsCtrl = TextEditingController();
    try {
      final saved = await showFxFormSheet(
        context,
        title: 'Novo recorde',
        icon: Icons.emoji_events_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: exercicioCtrl,
              label: 'Exercício',
              icon: Icons.fitness_center_outlined,
            ),
            AlunoInsetFormField(
              controller: cargaCtrl,
              label: 'Carga',
              icon: Icons.tune_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              controller: unidadeCtrl,
              label: 'Unidade (kg, reps…)',
              icon: Icons.straighten_outlined,
            ),
            AlunoInsetFormField(
              controller: obsCtrl,
              label: 'Observação',
              icon: Icons.notes_outlined,
              maxLines: 2,
              showDivider: false,
            ),
          ],
        ),
      );
      if (saved != true) return;
      final nome = exercicioCtrl.text.trim();
      if (nome.isEmpty) {
        if (!mounted) return;
        FeedbackHelper.showError(context, 'Informe o exercício.');
        return;
      }
      await EvolucaoRepository(ref.read(apiClientProvider)).adicionarRecorde(
        widget.alunoId,
        exercicioNome: nome,
        carga: double.tryParse(cargaCtrl.text.replaceAll(',', '.')),
        unidade: unidadeCtrl.text.trim(),
        observacao: obsCtrl.text.trim(),
      );
      EvolucaoHomeClientCache.invalidate(widget.alunoId);
      ref.invalidate(evolucaoHomeProvider(widget.alunoId));
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Recorde adicionado!');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      exercicioCtrl.dispose();
      cargaCtrl.dispose();
      unidadeCtrl.dispose();
      obsCtrl.dispose();
    }
  }
}
