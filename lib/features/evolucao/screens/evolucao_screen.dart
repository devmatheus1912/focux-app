import '../../../core/observability/sentry_performance.dart';
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
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../alunos/providers/aluno_detail_providers.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/utils/aluno360_medida_plausivel.dart';
import '../../alunos/utils/satellite_screen_utils.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../avaliacao/data/avaliacao_repository.dart';
import '../../avaliacao/utils/evolucao_comparativo_display.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_aneis.dart';
import '../utils/evolucao_display.dart';
import '../utils/evolucao_series.dart';
import '../providers/evolucao_home_provider.dart';
import '../utils/evolucao_home_client_cache.dart';
import '../../avaliacao/screens/evolucao_comparativo_screen.dart';
import '../widgets/escolher_exercicio_campo.dart';
import '../data/meta_corporal.dart';
import '../widgets/evolucao_conquistas.dart';
import '../widgets/evolucao_hero.dart';
import '../widgets/evolucao_metas_bloco.dart';
import '../widgets/evolucao_medidas_aba.dart';
import '../widgets/evolucao_recordes_aba.dart';
import '../widgets/medida_form_sheet.dart';
import '../../../l10n/pt.dart';
import '../widgets/evolucao_help_sheet.dart';
import '../widgets/evolucao_historico_folha.dart';
import 'evolucao_fotos_screen.dart';
import '../../../core/theme/fx_icons.dart';


class EvolucaoScreen extends ConsumerStatefulWidget {
  final int alunoId;
  final String alunoNome;
  const EvolucaoScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    this.abaInicial = EvolucaoHubView.medidas,
    this.dataDestaque,
  });

  /// "aaaa-mm-dd" vindo da linha do tempo: abre o Histórico com ele marcado.
  final String? dataDestaque;

  /// Aberta direto em uma aba, como Comparar a partir do 360.
  final EvolucaoHubView abaInicial;

  @override
  ConsumerState<EvolucaoScreen> createState() => _EvolucaoScreenState();
}

class _EvolucaoScreenState extends ConsumerState<EvolucaoScreen> {
  var _recolhido = false;

  /// O Histórico com o registro da linha do tempo abre uma vez só.
  var _destaqueAberto = false;

  void _abrirDestaqueSePreciso(EvolucaoHomeBundle? home) {
    final data = widget.dataDestaque;
    if (_destaqueAberto || home == null || data == null || data.length < 10) {
      return;
    }
    _destaqueAberto = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _conferir(home, {data.substring(0, 10)});
    });
  }

  /// Redesenha a folha do recorde quando a validação muda.
  VoidCallback? _avisarFormulario;
  late EvolucaoHubView _view = widget.abaInicial;

  /// Fotos e Comparar só carregam quando abertas.
  late final Set<EvolucaoHubView> _abertas = {_view};

  /// Quem chega por notificação ou tarefa não traz o nome na rota.
  String get _nome =>
      widget.alunoNome != 'Aluno'
          ? widget.alunoNome
          : ref.watch(alunoProvider(widget.alunoId)).value?.nome ?? widget.alunoNome;

  void _registrar() {
    if (_view == EvolucaoHubView.medidas) {
      _registrarMedida();
    } else {
      _formularioRecorde();
    }
  }

  /// Muda a cada recarga: o Comparar busca de novo com outra chave.
  var _versao = 0;

  /// "Confira" do Comparar: o Histórico com as datas comparadas marcadas.
  Future<void> _conferir(EvolucaoHomeBundle? home, Set<String> datas) async {
    if (home == null) return;
    final r = await abrirHistoricoDaEvolucao(
      context,
      registros: registrosDoHistorico(
        home.medidas.where(evolucaoMedidaTemConteudo).toList(),
        gordura: home.gordura,
        massa: home.massa,
      ),
      destaque: datas,
      podeAbrir: _podeAbrirRegistro,
      onEstaCerto: () => _estaCerto(home, datas),
    );
    if (r != null && mounted) await _abrirRegistro(r);
  }

  /// "Está certo": confere o registro mais novo do par (medida e avaliação).
  Future<void> _estaCerto(EvolucaoHomeBundle home, Set<String> datas) async {
    if (datas.isEmpty) return;
    final nova = (datas.toList()..sort()).last;
    final api = ref.read(apiClientProvider);
    final repo = EvolucaoRepository(api);
    try {
      for (final m in home.medidas) {
        if (m.data.startsWith(nova) && m.conferidoEm == null) {
          await repo.conferirMedida(widget.alunoId, m.id);
        }
      }
      final avaliacoes = {
        for (final p in [...home.gordura, ...home.massa])
          if (p.data.startsWith(nova) && !p.conferido && p.avaliacaoId != null)
            p.avaliacaoId!,
      };
      for (final id in avaliacoes) {
        await repo.conferirAvaliacao(widget.alunoId, id);
      }
      await _atualizar();
      if (mounted) FeedbackHelper.showSuccess(context, 'Conferido. O aviso saiu.');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _atualizar() async {
    if (mounted) setState(() => _versao++);
    EvolucaoHomeClientCache.invalidate(widget.alunoId);
    ref.invalidate(evolucaoHomeProvider(widget.alunoId));
    await ref.read(evolucaoHomeProvider(widget.alunoId).future);
  }

  /// Composição que dá para corrigir: veio de uma avaliação com id.
  static bool _composicaoEditavel(RegistroDoHistorico r) =>
      (r.gordura?.avaliacaoId ?? r.massa?.avaliacaoId) != null;

  bool _podeAbrirRegistro(RegistroDoHistorico r) =>
      r.medida != null || _composicaoEditavel(r);

  Future<void> _abrirRegistro(RegistroDoHistorico r) async {
    final api = ref.read(apiClientProvider);
    final repo = EvolucaoRepository(api);
    final medida = r.medida;
    final medidaEditavel = medida != null && medida.registradoPor != 'ALUNO';
    final composicao = _composicaoEditavel(r);
    final acao = await escolherAcaoDaMedida(
      context,
      podeEditar: medidaEditavel || composicao,
      podeExcluir: medida != null,
    );
    if (acao == null || !mounted) return;
    try {
      if (acao == AcaoDaMedida.editar) {
        final novo = await editarMedidaSheet(
          context,
          medidaEditavel ? medida : null,
          gordura: r.gordura?.valor,
          massa: r.massa?.valor,
          comComposicao: composicao,
        );
        if (novo == null || !mounted) return;
        if (medidaEditavel) {
          await repo.editarMedida(
            widget.alunoId,
            medida,
            peso: novo.peso,
            cintura: novo.cintura,
            quadril: novo.quadril,
            braco: novo.braco,
          );
        }
        if (composicao && (novo.gordura != r.gordura?.valor || novo.massa != r.massa?.valor)) {
          await _corrigirComposicao(
            (r.gordura?.avaliacaoId ?? r.massa?.avaliacaoId)!,
            gordura: novo.gordura,
            massa: novo.massa,
          );
        }
        if (mounted) FeedbackHelper.showSuccess(context, ptS.evolucaoMedidaSalva);
      } else {
        final ok = await showFxConfirmSheet(
          context,
          title: ptS.evolucaoExcluirTitulo,
          message: ptS.evolucaoExcluirMensagem,
          icon: FxIcons.excluir,
          confirmLabel: ptS.evolucaoExcluir,
          destructive: true,
        );
        if (!ok || !mounted) return;
        await repo.excluirMedida(widget.alunoId, medida!.id);
        if (mounted) FeedbackHelper.showSuccess(context, ptS.evolucaoMedidaExcluida);
      }
      await _atualizar();
      await invalidateAluno360Providers(ref, widget.alunoId);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  /// O PUT da avaliação troca todos os campos: lê a avaliação inteira e
  /// muda só gordura e massa magra.
  Future<void> _corrigirComposicao(int avaliacaoId, {double? gordura, double? massa}) async {
    final repo = AvaliacaoRepository(ref.read(apiClientProvider));
    final pagina = await repo.listarPagina(widget.alunoId);
    final av = pagina.content.firstWhere((a) => a.id == avaliacaoId);
    await repo.editar(widget.alunoId, avaliacaoId, {
      'pesoKg': av.pesoKg,
      'alturaCm': av.alturaCm,
      'percGordura': gordura,
      'percMassa': massa,
      'cinturaCm': av.cinturaCm,
      'quadrilCm': av.quadrilCm,
      'observacoes': av.observacoes,
    });
  }

  Future<void> _compartilharNoChat() async {
    HapticFeedback.mediumImpact();
    final ok = await showFxConfirmSheet(
      context,
      title: evolucaoComparativoConfirmTitle(),
      message: evolucaoComparativoConfirmMessage(),
      icon: FxIcons.chat,
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

  /// Rolagem de cada aba: ao trocar, o topo segue a posição da aba nova em
  /// vez de pular entre anéis e faixa.
  final _rolagem = <EvolucaoHubView, double>{};

  /// Anéis recolhem depois de um pouco de rolagem; voltam ao topo.
  Widget _aoRolar(Widget filho) => NotificationListener<ScrollUpdateNotification>(
    onNotification: (n) {
      if (n.metrics.axis != Axis.vertical) return false;
      // Só a aba visível rola; guarda a posição de cada uma.
      _rolagem[_view] = n.metrics.pixels;
      final recolher = n.metrics.pixels > 48;
      if (recolher != _recolhido) setState(() => _recolhido = recolher);
      return false;
    },
    child: filho,
  );

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(evolucaoHomeProvider(widget.alunoId));
    if (homeAsync.hasValue) reportarTelaPronta();
    final home = homeAsync.value;
    _abrirDestaqueSePreciso(home);
    final medidas = home?.medidas ?? const <MedidaCorporal>[];
    final recordes = home?.recordes ?? const <RecordePessoal>[];
    final metas = home?.metas ?? const <MetaCorporal>[];
    final aneis = home?.aneis ?? const EvolucaoAneis();
    final ocupadas = {
      for (final m in metas)
        if (m.aberta) m.metrica,
    };
    final conquistas = conquistasDe(
      metas,
      recordes,
      medidas: medidas,
      gordura: home?.gordura ?? const [],
      massa: home?.massa ?? const [],
    );
    final nome = _nome;
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Evolução — $nome',
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
            subtitle: fxTitleCaseName(nome),
            onBack: () => safePopOrGo(context, '/alunos/${widget.alunoId}'),
            actions: [
              IconButton(
                tooltip: ptS.evolucaoMais,
                icon: const Icon(FxIcons.mais),
                onPressed: () => _maisAcoes(ocupadas, aneis.cicloMedidasDias),
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
                                  EvolucaoHero(
                                    aneis: aneis,
                                    metaNome: nomeDaMetaPrincipal(metas),
                                    onDefinirMeta: () => _definirMeta(ocupadas),
                                    recolhido: _recolhido,
                                  ),
                                  const SizedBox(height: TokensStrip.s4),
                                  AlunoSegmentedChoice(
                                    options: evolucaoDetalheSecoes,
                                    selected: _view.name,
                                    isDark: chrome.isDark,
                                    onSelect:
                                        (value) => setState(() {
                                          _view = evolucaoHubViewFromSecao(value);
                                          _abertas.add(_view);
                                          _recolhido = (_rolagem[_view] ?? 0) > 48;
                                        }),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _aoRolar(EvolucaoFadeTopo(child: IndexedStack(
                                index: _view.index,
                                children: [
                                  EvolucaoMedidasAba(
                                    medidas: medidas,
                                    metas: metas,
                                    gordura: home?.gordura ?? const [],
                                    massa: home?.massa ?? const [],
                                    vazioSubtitulo:
                                        'Registre peso e circunferências de ${satelliteFirstName(nome)} para acompanhar a evolução.',
                                    onAtualizar: _atualizar,
                                    onAbrirRegistro: _abrirRegistro,
                                    podeAbrirRegistro: _podeAbrirRegistro,
                                    topo: [
                                      EvolucaoMetasBloco(
                                        alunoId: widget.alunoId,
                                        metas: metas,
                                      ),
                                    ],
                                    depois: [
                                      if (conquistas.isNotEmpty) ...[
                                        EvolucaoConquistas(
                                          conquistas: conquistas,
                                        ),
                                        const SizedBox(
                                          height: TokensStrip.s3,
                                        ),
                                      ],
                                    ],
                                  ),
                                  EvolucaoRecordesAba(
                                    recordes: recordes,
                                    vazioSubtitulo:
                                        'Marque o primeiro recorde de ${satelliteFirstName(nome)} após um check-in ou treino forte.',
                                    onAtualizar: _atualizar,
                                    onEditar: (r) => _formularioRecorde(recorde: r),
                                    onExcluir: _excluirRecorde,
                                  ),
                                  _abertas.contains(EvolucaoHubView.fotos)
                                      ? EvolucaoFotosScreen(
                                        alunoId: widget.alunoId,
                                        alunoNome: nome,
                                      )
                                      : const SizedBox.shrink(),
                                  _abertas.contains(EvolucaoHubView.comparativo)
                                      ? EvolucaoComparativoScreen(
                                        // Recarrega depois de corrigir um registro.
                                        key: ValueKey(_versao),
                                        alunoId: widget.alunoId,
                                        alunoNome: nome,
                                        onConfira: (datas) => _conferir(home, datas),
                                        conferidas: home == null
                                            ? const {}
                                            : datasConferidas(
                                              home.medidas,
                                              gordura: home.gordura,
                                              massa: home.massa,
                                            ),
                                      )
                                      : const SizedBox.shrink(),
                                ],
                              ))),
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
                              : ptS.evolucaoRecordeNovoTitulo,
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

  Future<void> _registrarMedida() async {
    final bundle = ref.read(evolucaoHomeProvider(widget.alunoId)).value;
    NovaMedida? nova;
    // "Salvar assim" numa medida improvável já grava como conferida.
    var conferirAoSalvar = false;
    // "Corrigir" reabre a folha.
    while (true) {
      nova = await novaMedidaSheet(
        context,
        medidas: bundle?.medidas ?? const [],
        inicial: nova,
      );
      if (nova == null || !mounted) return;
      // Fora da faixa de um adulto (458 kg) ou mudança grande demais desde a
      // última medida (90 → 110 kg em 5 dias): os dois pedem confirmação.
      final suspeitas = [
        ...medidasSuspeitas(
          peso: nova.peso,
          gordura: nova.gordura,
          massaMagra: nova.massa,
        ),
        ...variacoesSuspeitas(
          data: nova.data,
          medidas: bundle?.medidas ?? const [],
          gordura: bundle?.gordura ?? const [],
          massa: bundle?.massa ?? const [],
          peso: nova.peso,
          cintura: nova.cintura,
          quadril: nova.quadril,
          braco: nova.braco,
          percGordura: nova.gordura,
          percMassa: nova.massa,
        ),
      ];
      if (suspeitas.isEmpty) break;
      final manter = await showFxConfirmSheet(
        context,
        title: S.of(context).aluno360ConfirmeValoresTitulo,
        message: ptS.evolucaoConfirmeMedida(suspeitas.join(', ')),
        confirmLabel: S.of(context).aluno360ConfirmeValoresSalvar,
        cancelLabel: S.of(context).aluno360ConfirmeValoresCorrigir,
        icon: FxIcons.alerta,
      );
      if (manter || !mounted) {
        conferirAoSalvar = manter;
        break;
      }
    }
    final m = nova;
    if (!mounted) return;
    if (m.peso == null &&
        m.cintura == null &&
        m.quadril == null &&
        m.braco == null &&
        m.gordura == null &&
        m.massa == null) {
      FeedbackHelper.showError(context, ptS.evolucaoInformeValor);
      return;
    }
    final api = ref.read(apiClientProvider);
    try {
      final salva = await EvolucaoRepository(api).adicionarMedida(
        widget.alunoId,
        data: m.data,
        peso: m.peso,
        cintura: m.cintura,
        quadril: m.quadril,
        braco: m.braco,
      );
      if (conferirAoSalvar) {
        await EvolucaoRepository(api).conferirMedida(widget.alunoId, salva.id);
      }
      // Medida já persistiu: a tela atualiza mesmo se a avaliação falhar.
      await invalidateAluno360Providers(ref, widget.alunoId);
      if (m.gordura != null || m.massa != null) {
        try {
          final avaliacao = await AvaliacaoRepository(api).registrar(widget.alunoId, {
            if (m.peso != null) 'pesoKg': m.peso,
            if (m.cintura != null) 'cinturaCm': m.cintura,
            if (m.quadril != null) 'quadrilCm': m.quadril,
            if (m.gordura != null) 'percGordura': m.gordura,
            if (m.massa != null) 'percMassa': m.massa,
            'observacoes': 'Registrado via evolução (nova medida)',
          });
          if (conferirAoSalvar) {
            await EvolucaoRepository(api).conferirAvaliacao(
              widget.alunoId,
              avaliacao.id,
            );
          }
          await invalidateAluno360Providers(ref, widget.alunoId);
        } catch (avaliacaoErr) {
          if (mounted) {
            FeedbackHelper.showError(
              context,
              friendlyError(
                avaliacaoErr,
                fallback: 'Medida salva. Gordura/massa não entraram na avaliação.',
              ),
            );
          }
          return;
        }
      }
      if (mounted) FeedbackHelper.showSuccess(context, ptS.evolucaoMedidaAdicionada);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  /// Novo recorde ou, com [recorde], correção de um existente.
  Future<void> _formularioRecorde({RecordePessoal? recorde}) async {
    final recordes = ref.read(evolucaoHomeProvider(widget.alunoId)).value?.recordes ?? const [];
    final vistos = <String>{};
    final recentes = <ExercicioEscolhido>[
      for (final r in recordes)
        if (vistos.add(r.exercicioNome.toLowerCase()))
          (id: r.exercicioId, nome: r.exercicioNome),
    ].take(5).toList();
    ExercicioEscolhido? escolhido =
        recorde == null ? null : (id: recorde.exercicioId, nome: recorde.exercicioNome);
    final cargaCtrl = TextEditingController(
      text: recorde?.cargaKg == null ? '' : formatBrDecimal(recorde!.cargaKg!),
    );
    final repsCtrl = TextEditingController(text: recorde?.repeticoes?.toString() ?? '');
    // Validação dentro da folha: o erro aparece no campo e nada do que foi
    // digitado se perde.
    String? erroExercicio;
    String? erroCarga;
    double? lerCarga() =>
        double.tryParse(cargaCtrl.text.trim().replaceAll(',', '.'));
    try {
      final saved = await showFxFormSheet(
        context,
        title: recorde == null ? ptS.evolucaoRecordeNovoTitulo : ptS.evolucaoRecordeEditarTitulo,
        icon: FxIcons.trofeu,
        confirmLabel: ptS.evolucaoSalvar,
        podeConfirmar: () {
          final carga = lerCarga();
          erroExercicio = escolhido == null ? ptS.evolucaoInformeExercicio : null;
          erroCarga =
              carga == null || carga < 0.5 || carga > 1000
                  ? ptS.evolucaoCargaInvalida
                  : null;
          _avisarFormulario?.call();
          return erroExercicio == null && erroCarga == null;
        },
        child: StatefulBuilder(
          builder: (context, setSheet) {
            _avisarFormulario = () => setSheet(() {});
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EscolherExercicioCampo(
                  escolhido: escolhido,
                  recentes: recentes,
                  erro: erroExercicio,
                  onEscolher: (e) => setSheet(() {
                    escolhido = e;
                    erroExercicio = null;
                  }),
                ),
                AlunoInsetFormField(
                  rotuloVisivel: true,
                  obrigatorio: true,
                  controller: cargaCtrl,
                  label: ptS.evolucaoCampoCarga,
                  icon: FxIcons.filtros,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ajuda: erroCarga,
                  ajudaErro: erroCarga != null,
                ),
                AlunoInsetFormField(
                  rotuloVisivel: true,
                  controller: repsCtrl,
                  label: ptS.evolucaoCampoReps,
                  icon: FxIcons.repetir,
                  keyboardType: TextInputType.number,
                  showDivider: false,
                ),
              ],
            );
          },
        ),
      );
      if (saved != true || !mounted) return;
      final exercicio = escolhido!;
      final carga = lerCarga()!;
      final repo = EvolucaoRepository(ref.read(apiClientProvider));
      final reps = int.tryParse(repsCtrl.text.trim());
      if (recorde == null) {
        await repo.adicionarRecorde(
          widget.alunoId,
          exercicioId: exercicio.id,
          exercicioNome: exercicio.nome,
          carga: carga,
          repeticoes: reps,
        );
      } else {
        await repo.editarRecorde(
          widget.alunoId,
          recorde,
          exercicioId: exercicio.id,
          exercicioNome: exercicio.nome,
          carga: carga,
          repeticoes: reps,
        );
      }
      await invalidateAluno360Providers(ref, widget.alunoId);
      if (mounted) FeedbackHelper.showSuccess(context, ptS.evolucaoRecordeSalvo);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      _avisarFormulario = null;
      cargaCtrl.dispose();
      repsCtrl.dispose();
    }
  }

  Future<void> _excluirRecorde(RecordePessoal recorde) async {
    final ok = await showFxConfirmSheet(
      context,
      title: ptS.evolucaoRecordeExcluirTitulo,
      message: ptS.evolucaoRecordeExcluirTexto,
      icon: FxIcons.excluir,
      confirmLabel: ptS.evolucaoExcluir,
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await EvolucaoRepository(ref.read(apiClientProvider)).excluirRecorde(widget.alunoId, recorde.id);
      await invalidateAluno360Providers(ref, widget.alunoId);
      if (mounted) FeedbackHelper.showSuccess(context, ptS.evolucaoRecordeExcluido);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _definirMeta(Set<String> ocupadas) async {
    final salvou = await abrirFormularioDeMeta(
      context,
      ref,
      alunoId: widget.alunoId,
      ocupadas: ocupadas,
      onRegistrarMedida: _registrarMedida,
    );
    if (salvou) await invalidateAluno360Providers(ref, widget.alunoId);
  }

  Future<void> _ajustarCiclo(int atual) async {
    final dias = await showFxGroupedActionSheet<int>(
      context,
      titulo: ptS.evolucaoCiclo,
      icone: FxIcons.recorrencia,
      grupos: [
        FxActionGroup<int>(ptS.evolucaoCicloTexto(satelliteFirstName(_nome)), [
          for (final d in const [15, 30, 45, 60])
            FxActionItem(
              valor: d,
              rotulo: ptS.evolucaoCicloOpcao('$d'),
              icone: d == atual ? FxIcons.check : FxIcons.calendario,
            ),
        ]),
      ],
    );
    if (dias == null || dias == atual || !mounted) return;
    try {
      await EvolucaoRepository(ref.read(apiClientProvider)).definirCicloMedidas(widget.alunoId, dias);
      await invalidateAluno360Providers(ref, widget.alunoId);
      if (mounted) FeedbackHelper.showSuccess(context, ptS.evolucaoCicloSalvo);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _maisAcoes(Set<String> ocupadas, int ciclo) async {
    // Sem meta, o caminho é o anel do topo; aqui só para criar outra.
    final podeMeta = ocupadas.isNotEmpty && !metaMetricas.every(ocupadas.contains);
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: ptS.evolucaoMais,
      icone: FxIcons.mais,
      grupos: [
        FxActionGroup<String>(null, [
          if (podeMeta)
            FxActionItem(valor: 'meta', rotulo: ptS.evolucaoDefinirMeta, icone: FxIcons.meta),
          FxActionItem(valor: 'ciclo', rotulo: ptS.evolucaoCiclo, icone: FxIcons.recorrencia),
          FxActionItem(valor: 'chat', rotulo: ptS.evolucaoEnviarNoChat, icone: FxIcons.chat),
          FxActionItem(valor: 'ajuda', rotulo: ptS.evolucaoAjuda, icone: FxIcons.ajuda),
        ]),
      ],
    );
    if (!mounted) return;
    switch (escolha) {
      case 'meta':
        await _definirMeta(ocupadas);
      case 'ciclo':
        await _ajustarCiclo(ciclo);
      case 'chat':
        await _compartilharNoChat();
      case 'ajuda':
        showEvolucaoHelpSheet(context);
    }
  }
}
