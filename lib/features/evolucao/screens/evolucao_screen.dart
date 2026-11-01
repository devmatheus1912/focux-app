import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/utils/fx_utils.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/providers/aluno_detail_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/utils/aluno360_medida_plausivel.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../avaliacao/data/avaliacao_repository.dart';
import '../../avaliacao/utils/evolucao_comparativo_display.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_display.dart';
import '../providers/evolucao_home_provider.dart';
import '../utils/evolucao_home_client_cache.dart';
import '../../avaliacao/screens/evolucao_comparativo_screen.dart';
import '../widgets/escolher_exercicio_campo.dart';
import '../widgets/evolucao_hero.dart';
import '../widgets/evolucao_medidas_aba.dart';
import '../widgets/evolucao_recordes_aba.dart';
import '../widgets/medida_form_sheet.dart';
import '../../../l10n/pt.dart';
import '../widgets/evolucao_help_sheet.dart';
import 'evolucao_fotos_screen.dart';


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

  void _registrar() {
    if (_view == EvolucaoHubView.medidas) {
      _mostrarDialogMedida();
    } else {
      _mostrarDialogRecorde();
    }
  }

  Future<void> _atualizar() async {
    EvolucaoHomeClientCache.invalidate(widget.alunoId);
    ref.invalidate(evolucaoHomeProvider(widget.alunoId));
    await ref.read(evolucaoHomeProvider(widget.alunoId).future);
  }

  Future<void> _abrirMedida(MedidaCorporal medida) async {
    final repo = EvolucaoRepository(ref.read(apiClientProvider));
    final acao = await escolherAcaoDaMedida(
      context,
      podeEditar: medida.registradoPor != 'ALUNO',
    );
    if (acao == null || !mounted) return;
    try {
      if (acao == AcaoDaMedida.editar) {
        final novo = await editarMedidaSheet(context, medida);
        if (novo == null || !mounted) return;
        await repo.editarMedida(
          widget.alunoId,
          medida,
          peso: novo.peso,
          cintura: novo.cintura,
          quadril: novo.quadril,
          braco: novo.braco,
        );
        if (mounted) FeedbackHelper.showSuccess(context, ptS.evolucaoMedidaSalva);
      } else {
        final ok = await showFxConfirmSheet(
          context,
          title: ptS.evolucaoExcluirTitulo,
          message: ptS.evolucaoExcluirMensagem,
          icon: Icons.delete_outline_rounded,
          confirmLabel: ptS.evolucaoExcluir,
          destructive: true,
        );
        if (!ok || !mounted) return;
        await repo.excluirMedida(widget.alunoId, medida.id);
        if (mounted) FeedbackHelper.showSuccess(context, ptS.evolucaoMedidaExcluida);
      }
      await _atualizar();
      await invalidateAluno360Providers(ref, widget.alunoId);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
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
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Evolução — ${widget.alunoNome}',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          safePopOrGo(context, '/alunos/${widget.alunoId}');
        },
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Evolução',
            subtitle: fxTitleCaseName(widget.alunoNome),
            onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
            actions: [
              IconButton(
                tooltip: 'Enviar no chat',
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                onPressed: _compartilharNoChat,
              ),
              FxHelpIconButton(
                tooltip: 'Como usar a evolução',
                onTap: () => showEvolucaoHelpSheet(context),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: homeAsync.when(
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
                        onRetry:
                            () => ref.invalidate(
                              evolucaoHomeProvider(widget.alunoId),
                            ),
                        title: 'Não conseguimos carregar a evolução',
                      ),
                  data:
                      (_) => FxContentWidthLimiter(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                FxSettingsLayout.pageInset,
                                TokensStrip.s4,
                                FxSettingsLayout.pageInset,
                                TokensStrip.s2,
                              ),
                              child: Column(
                                children: [
                                  EvolucaoHero(medidas: medidas ?? const []),
                                  const SizedBox(height: TokensStrip.s4),
                                  AlunoSegmentedChoice(
                                    options: evolucaoDetalheSecoes,
                                    selected: _view.name,
                                    isDark: chrome.isDark,
                                    onSelect:
                                        (value) => setState(
                                          () =>
                                              _view = evolucaoHubViewFromSecao(
                                                value,
                                              ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: IndexedStack(
                                index: _view.index,
                                children: [
                                  EvolucaoMedidasAba(
                                    medidas: medidas ?? const [],
                                    vazioSubtitulo:
                                        'Registre peso e circunferências de ${satelliteFirstName(widget.alunoNome)} para acompanhar a evolução.',
                                    onAtualizar: _atualizar,
                                    onAbrirMedida: _abrirMedida,
                                  ),
                                  EvolucaoRecordesAba(
                                    recordes:
                                        recordesAsync.asData?.value ?? const [],
                                    vazioSubtitulo:
                                        'Marque o primeiro recorde de ${satelliteFirstName(widget.alunoNome)} após um check-in ou treino forte.',
                                    onAtualizar: _atualizar,
                                  ),
                                  EvolucaoFotosScreen(
                                    alunoId: widget.alunoId,
                                    alunoNome: widget.alunoNome,
                                    embutida: true,
                                  ),
                                  EvolucaoComparativoScreen(
                                    alunoId: widget.alunoId,
                                    alunoNome: widget.alunoNome,
                                    embutida: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ),
              // Fotos e Comparar têm a própria ação no rodapé.
              if (homeAsync.hasValue &&
                  _view.index < 2 &&
                  MediaQuery.viewInsetsOf(context).bottom == 0)
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
      ),
    );
  }

  Future<void> _mostrarDialogMedida() async {
    final pesoCtrl = TextEditingController();
    final abdomenCtrl = TextEditingController();
    final quadrilCtrl = TextEditingController();
    final bracoCtrl = TextEditingController();
    final gorduraCtrl = TextEditingController();
    final massaCtrl = TextEditingController();
    try {
      Future<bool> abrirFormulario() => showFxFormSheet(
        context,
        title: 'Nova medida',
        icon: Icons.monitor_weight_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: pesoCtrl,
              label: 'Peso (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: abdomenCtrl,
              label: ptS.evolucaoCampoCintura,
              icon: Icons.straighten_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: quadrilCtrl,
              label: 'Quadril (cm)',
              icon: Icons.straighten_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: bracoCtrl,
              label: 'Braço (cm)',
              icon: Icons.straighten_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: gorduraCtrl,
              label: 'Gordura corporal (%)',
              icon: Icons.pie_chart_outline_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: massaCtrl,
              label: 'Massa magra (%)',
              icon: Icons.fitness_center_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              showDivider: false,
            ),
          ],
        ),
      );
      double? ler(TextEditingController c) =>
          double.tryParse(c.text.replaceAll(',', '.'));
      // Valor impossível (458 kg, 818 %) pede confirmação; os campos ficam
      // como estão para o personal corrigir sem digitar tudo de novo.
      while (true) {
        final saved = await abrirFormulario();
        if (saved != true) return;
        final suspeitas = medidasSuspeitas(
          peso: ler(pesoCtrl),
          gordura: ler(gorduraCtrl),
          massaMagra: ler(massaCtrl),
        );
        if (suspeitas.isEmpty) break;
        if (!mounted) return;
        final manter = await showFxConfirmSheet(
          context,
          title: S.of(context).aluno360ConfirmeValoresTitulo,
          message: S
              .of(context)
              .aluno360ConfirmeValoresMensagem(suspeitas.join(', ')),
          confirmLabel: S.of(context).aluno360ConfirmeValoresSalvar,
          cancelLabel: S.of(context).aluno360ConfirmeValoresCorrigir,
          icon: Icons.warning_amber_rounded,
        );
        if (manter) break;
      }
      final peso = double.tryParse(pesoCtrl.text.replaceAll(',', '.'));
      final cintura = double.tryParse(abdomenCtrl.text.replaceAll(',', '.'));
      final quadril = double.tryParse(quadrilCtrl.text.replaceAll(',', '.'));
      final braco = double.tryParse(bracoCtrl.text.replaceAll(',', '.'));
      final gordura = double.tryParse(gorduraCtrl.text.replaceAll(',', '.'));
      final massa = double.tryParse(massaCtrl.text.replaceAll(',', '.'));
      if (peso == null &&
          cintura == null &&
          quadril == null &&
          braco == null &&
          gordura == null &&
          massa == null) {
        if (!mounted) return;
        FeedbackHelper.showError(context, 'Informe ao menos um valor.');
        return;
      }
      final api = ref.read(apiClientProvider);
      await EvolucaoRepository(api).adicionarMedida(
        widget.alunoId,
        peso: peso,
        cintura: cintura,
        quadril: quadril,
        braco: braco,
      );
      // Medida já persistiu — refresh UI mesmo se avaliação complementar falhar.
      EvolucaoHomeClientCache.invalidate(widget.alunoId);
      ref.invalidate(evolucaoHomeProvider(widget.alunoId));
      await invalidateAluno360Providers(ref, widget.alunoId);
      if (gordura != null || massa != null) {
        try {
          await AvaliacaoRepository(api).registrar(widget.alunoId, {
            if (peso != null) 'pesoKg': peso,
            if (cintura != null) 'cinturaCm': cintura,
            if (quadril != null) 'quadrilCm': quadril,
            if (gordura != null) 'percGordura': gordura,
            if (massa != null) 'percMassa': massa,
            'observacoes': 'Registrado via evolução (nova medida)',
          });
          await invalidateAluno360Providers(ref, widget.alunoId);
        } catch (avaliacaoErr) {
          if (mounted) {
            FeedbackHelper.showError(
              context,
              friendlyError(
                avaliacaoErr,
                fallback:
                    'Medida salva. Gordura/massa não entraram na avaliação.',
              ),
            );
          }
          return;
        }
      }
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
      gorduraCtrl.dispose();
      massaCtrl.dispose();
    }
  }

  Future<void> _mostrarDialogRecorde() async {
    final exercicioCtrl = TextEditingController();
    final cargaCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    try {
      final saved = await showFxFormSheet(
        context,
        title: 'Novo recorde',
        icon: Icons.emoji_events_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EscolherExercicioCampo(controller: exercicioCtrl),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: cargaCtrl,
              label: 'Carga (kg)',
              icon: Icons.tune_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            AlunoInsetFormField(
              rotuloVisivel: true,
              controller: repsCtrl,
              label: 'Repetições (opcional)',
              icon: Icons.repeat_outlined,
              keyboardType: TextInputType.number,
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
        repeticoes: int.tryParse(repsCtrl.text.trim()),
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
      repsCtrl.dispose();
    }
  }
}
