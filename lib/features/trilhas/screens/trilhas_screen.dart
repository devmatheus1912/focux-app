import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_hub_header.dart';
import '../../../core/widgets/fx_inset_picker_row.dart';
import '../../../core/widgets/fx_inset_picker_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../dashboard/widgets/dashboard_home_action_chip.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../models/trilha.dart';
import '../providers/trilhas_provider.dart';
import '../utils/trilhas_display.dart';
import '../widgets/trilhas_help_sheet.dart';

part 'trilhas_screen_cards.part.dart';

class TrilhasScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;

  const TrilhasScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  @override
  ConsumerState<TrilhasScreen> createState() => _TrilhasScreenState();
}

class _TrilhasScreenState extends ConsumerState<TrilhasScreen> {
  DateTime? _fetchedAt;
  String _filtro = trilhaFiltroAndamento;

  Future<void> _refresh() async {
    ref.invalidate(trilhasAlunoProvider(widget.alunoId));
    try {
      await ref.read(trilhasAlunoProvider(widget.alunoId).future);
      if (mounted) setState(() => _fetchedAt = DateTime.now());
    } catch (_) {}
  }

  void _stampFreshness() {
    if (_fetchedAt != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fetchedAt != null) return;
      setState(() => _fetchedAt = DateTime.now());
    });
  }

  Future<void> _criarTrilha() async {
    HapticFeedback.selectionClick();
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final metaValorCtrl = TextEditingController();
    final marco1 = TextEditingController();
    final marco2 = TextEditingController();
    final marco3 = TextEditingController();
    var metaTipo = 'TREINOS';
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Atribuir trilha',
        subtitle: 'Meta, valor e as primeiras etapas.',
        icon: Icons.flag_outlined,
        confirmLabel: 'Atribuir trilha',
        child: StatefulBuilder(
          builder:
              (ctx, setSheetState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AlunoInsetFormField(
                    controller: tituloCtrl,
                    label: 'Título da trilha',
                    icon: Icons.title_outlined,
                  ),
                  AlunoInsetFormField(
                    controller: descCtrl,
                    label: 'Descrição (opcional)',
                    icon: Icons.notes_outlined,
                    maxLines: 2,
                  ),
                  FxInsetPickerRow(
                    icon: Icons.flag_outlined,
                    label: 'Tipo de meta',
                    value: trilhaMetaTipoLabel(metaTipo),
                    onTap: () async {
                      final picked = await showFxInsetPickerSheet<String>(
                        ctx,
                        title: 'Tipo de meta',
                        selected: metaTipo,
                        items: [
                          for (final tipo in trilhaMetaTipos)
                            FxInsetPickerSheetItem(
                              value: tipo,
                              label: trilhaMetaTipoLabel(tipo),
                            ),
                        ],
                      );
                      if (picked == null) return;
                      setSheetState(() => metaTipo = picked);
                    },
                  ),
                  AlunoInsetFormField(
                    controller: metaValorCtrl,
                    label: trilhaMetaValorHint(metaTipo),
                    icon: Icons.tune_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  AlunoInsetFormField(
                    controller: marco1,
                    label: 'Primeira etapa',
                    icon: Icons.check_circle_outline,
                  ),
                  AlunoInsetFormField(
                    controller: marco2,
                    label: 'Segunda etapa (opcional)',
                    icon: Icons.check_circle_outline,
                  ),
                  AlunoInsetFormField(
                    controller: marco3,
                    label: 'Terceira etapa (opcional)',
                    icon: Icons.check_circle_outline,
                    showDivider: false,
                  ),
                ],
              ),
        ),
      );
      if (ok != true) return;
      if (tituloCtrl.text.trim().isEmpty) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Título da trilha é obrigatório.');
        }
        return;
      }
      final marcos = trilhaMarcosTitulos([
        marco1.text,
        marco2.text,
        marco3.text,
      ]);
      if (marcos.isEmpty && trilhaParseNumero(metaValorCtrl.text) == null) {
        if (mounted) {
          FeedbackHelper.showWarn(
            context,
            'Inclua uma etapa ou o valor da meta.',
          );
        }
        return;
      }
      await ref
          .read(trilhasRepositoryProvider)
          .criarTrilha(
            NovaTrilhaRequest(
              alunoId: widget.alunoId,
              titulo: tituloCtrl.text.trim(),
              descricao:
                  descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
              metaTipo: metaTipo,
              metaValor: trilhaParseNumero(metaValorCtrl.text),
              marcos: marcos,
            ),
          );
      created = true;
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      tituloCtrl.dispose();
      descCtrl.dispose();
      metaValorCtrl.dispose();
      marco1.dispose();
      marco2.dispose();
      marco3.dispose();
    }
    if (created) {
      if (mounted) FeedbackHelper.showSuccess(context, 'Trilha atribuída.');
      await _refresh();
    }
  }

  Future<void> _atualizarProgresso(TrilhaModel trilha) async {
    HapticFeedback.selectionClick();
    final valorCtrl = TextEditingController(
      text:
          trilha.valorAtual == 0
              ? ''
              : trilha.valorAtual.toStringAsFixed(
                trilha.valorAtual == trilha.valorAtual.roundToDouble() ? 0 : 1,
              ),
    );
    var saved = false;
    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Atualizar progresso',
        subtitle: trilha.titulo,
        icon: Icons.tune_outlined,
        confirmLabel: 'Salvar progresso',
        child: AlunoInsetFormField(
          controller: valorCtrl,
          label: trilhaMetaValorHint(trilha.metaTipo),
          icon: Icons.tune_outlined,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          showDivider: false,
        ),
      );
      if (ok != true) return;
      final valor = trilhaParseNumero(valorCtrl.text);
      if (valor == null) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Informe um número válido.');
        }
        return;
      }
      await ref
          .read(trilhasRepositoryProvider)
          .atualizarProgresso(trilhaId: trilha.id, valor: valor);
      saved = true;
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      valorCtrl.dispose();
    }
    if (saved) {
      if (mounted) FeedbackHelper.showSuccess(context, 'Progresso atualizado.');
      await _refresh();
    }
  }

  Future<void> _adicionarMarco(TrilhaModel trilha) async {
    HapticFeedback.selectionClick();
    final tituloCtrl = TextEditingController();
    var saved = false;
    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Nova etapa',
        subtitle: trilha.titulo,
        icon: Icons.flag_outlined,
        confirmLabel: 'Adicionar etapa',
        child: AlunoInsetFormField(
          controller: tituloCtrl,
          label: 'Título da etapa',
          icon: Icons.check_circle_outline,
          showDivider: false,
        ),
      );
      if (ok != true) return;
      final titulo = tituloCtrl.text.trim();
      if (titulo.isEmpty) {
        if (mounted) {
          FeedbackHelper.showWarn(context, 'Título da etapa é obrigatório.');
        }
        return;
      }
      await ref
          .read(trilhasRepositoryProvider)
          .adicionarMarco(trilhaId: trilha.id, titulo: titulo);
      saved = true;
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      tituloCtrl.dispose();
    }
    if (saved) {
      if (mounted) FeedbackHelper.showSuccess(context, 'Etapa adicionada.');
      await _refresh();
    }
  }

  Future<void> _concluirMarco(TrilhaModel trilha, MarcoModel marco) async {
    try {
      await ref
          .read(trilhasRepositoryProvider)
          .concluirMarco(trilhaId: trilha.id, marcoId: marco.id);
      if (mounted) FeedbackHelper.showSuccess(context, 'Marco concluído.');
      await _refresh();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _deletarTrilha(TrilhaModel trilha) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Excluir trilha?',
      subtitle: trilha.titulo,
      message: 'Some da lista deste aluno. Os marcos vão junto.',
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(trilhasRepositoryProvider).deletar(trilha.id);
      if (mounted) FeedbackHelper.showSuccess(context, 'Trilha excluída.');
      await _refresh();
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final trilhasAsync = ref.watch(trilhasAlunoProvider(widget.alunoId));
    final freshness = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final showSticky = !trilhasAsync.isLoading && !trilhasAsync.hasError;

    return fxScreenA11yScope(
      label: 'Trilhas de Progresso — ${widget.alunoNome}',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Trilhas de Progresso',
          subtitle: trilhaHubSubtitle(
            alunoNome: widget.alunoNome,
            freshness: freshness,
          ),
          onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar as trilhas',
              onTap: () => showTrilhasHelpSheet(context),
            ),
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Atribuir trilha',
              onTap: _criarTrilha,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: trilhasAsync.when(
                loading:
                    () => const Padding(
                      padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                      child: SkeletonList(count: 4),
                    ),
                error:
                    (e, _) => FxErrorState(
                      chromeOnDark: chrome.isDark,
                      primary: primary,
                      message: friendlyError(e),
                      onRetry: _refresh,
                      title: 'Não conseguimos carregar as trilhas',
                    ),
                data: (trilhas) {
                  _stampFreshness();
                  return FxContentWidthLimiter(
                    child: _TrilhasListBody(
                      trilhas: trilhas,
                      freshness: freshness,
                      alunoNome: widget.alunoNome,
                      filtro: _filtro,
                      onFiltro: (value) => setState(() => _filtro = value),
                      onRefresh: _refresh,
                      onAtualizarProgresso: _atualizarProgresso,
                      onAdicionarMarco: _adicionarMarco,
                      onDeletar: _deletarTrilha,
                      onConcluirMarco: _concluirMarco,
                    ),
                  );
                },
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
                    TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: FxLiquidPrimaryButton(
                    label: 'Atribuir trilha',
                    onPressed: _criarTrilha,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
