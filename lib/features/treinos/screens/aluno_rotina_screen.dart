import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_sticky_actions.dart';
import '../../../l10n/app_localizations.dart';
import '../../alunos/providers/alunos_provider.dart';
import '../models/rotina_fila.dart';
import '../providers/treinos_provider.dart';
import '../utils/ficha_medicao.dart';
import '../utils/semana_da_fila.dart';
import '../utils/treino_criacao_fluxo.dart';
import '../widgets/ficha_acoes.dart';
import '../widgets/ficha_semana.dart';

/// Linha da ficha de treinos do aluno. O subtítulo é a semana numa frase.
class AlunoRotinaLinha extends ConsumerWidget {
  const AlunoRotinaLinha({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  final int alunoId;
  final String alunoNome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final rotina = ref.watch(alunoRotinaProvider(alunoId)).asData?.value;
    final linha = rotina == null
        ? ''
        : resumoDaSemana(
            rotina,
            nomesDosDias: nomesDosDias(s),
            palavraDescanso: s.rotinaDescanso,
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          '/alunos/$alunoId/rotina',
          extra: alunoNome.trim(),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: chrome.panel(radius: 20),
          child: Padding(
            padding: const EdgeInsets.all(TokensStrip.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.rotinaLinha,
                  style: FocuxHubTypography.cardTitle(color: chrome.ink),
                ),
                if (linha.isNotEmpty) ...[
                  const SizedBox(height: TokensStrip.s2),
                  Text(
                    linha,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AlunoRotinaScreen extends ConsumerStatefulWidget {
  const AlunoRotinaScreen({
    super.key,
    required this.alunoId,
    required this.alunoNome,
  });

  final int alunoId;
  final String alunoNome;

  @override
  ConsumerState<AlunoRotinaScreen> createState() => _AlunoRotinaScreenState();
}

class _AlunoRotinaScreenState extends ConsumerState<AlunoRotinaScreen> {
  RotinaFila? _rotina;
  List<DiaDaSemana> _dias = const [];
  var _carregando = true;
  var _falhou = false;
  var _salvando = false;
  final _medicao = FichaMedicao();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = _rotina == null;
      _falhou = false;
    });
    try {
      final fila = await ref
          .read(treinoRepositoryProvider)
          .buscarRotina(widget.alunoId);
      if (!mounted) return;
      setState(() {
        _rotina = fila;
        _dias = semanaDaFila(fila);
        _carregando = false;
      });
      _marcarInicioSeVazia();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _falhou = _rotina == null;
      });
    }
  }

  Future<void> _aplicar(Future<RotinaFila> Function() gravar) async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      final fila = await gravar();
      ref.invalidate(alunoRotinaProvider(widget.alunoId));
      if (!mounted) return;
      setState(() {
        _rotina = fila;
        _dias = semanaDaFila(fila);
        _salvando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      FeedbackHelper.showError(context, S.of(context).checkinNaoSalvou);
      await _carregar();
    }
  }

  void _marcarInicioSeVazia() {
    if (estadoDaFicha(_dias).vazia) _medicao.iniciar(DateTime.now());
  }

  Future<void> _persistir(List<DiaDaSemana> dias) {
    setState(() => _dias = dias);
    if (estadoDaFicha(dias).vazia) _medicao.iniciar(DateTime.now());
    return _aplicar(
      () => ref.read(treinoRepositoryProvider).gravarSemana(widget.alunoId, dias),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final pronta = !_carregando && !_falhou && _rotina != null;

    return fxScreenA11yScope(
      label: s.rotinaLinha,
      child: FxShellScaffold(
        appBar: FxShellAppBar(
          title: s.rotinaLinha,
          actions: [
            if (pronta)
              IconButton(
                tooltip: s.rotinaMenuFicha,
                onPressed: _salvando ? null : _menuDaFicha,
                icon: const Icon(Icons.more_horiz_rounded),
              ),
          ],
        ),
        body: _carregando
            ? const Center(child: FxLoading())
            : !pronta
            ? Center(
                child: TextButton(
                  onPressed: _carregar,
                  child: Text(s.rotinaNaoAbriu),
                ),
              )
            : _corpo(s, ShellChrome.of(context)),
      ),
    );
  }

  Widget _corpo(S s, ShellPalette chrome) {
    final nome = widget.alunoNome.trim();
    final titulo = nome.isEmpty ? s.rotinaLinha : s.rotinaDe(nome);
    final estado = estadoDaFicha(_dias);
    final linhaDeEstado = estado.vazia
        ? s.rotinaEstadoVazia
        : estado.completa
        ? s.rotinaEstadoCompleta(estado.dias)
        : s.rotinaEstado(estado.dias, estado.prontas, estado.sessoes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(TokensStrip.s4),
            children: [
              Text(
                titulo,
                style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                linhaDeEstado,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s4),
              if (estado.vazia)
                FichaFrequencia(
                  ocupado: _salvando,
                  onEscolher: (n) => _persistir(semanaPorFrequencia(n)),
                ),
              FichaSemana(
                dias: _dias,
                hoje: DateTime.now().weekday,
                ocupado: _salvando,
                onAdicionar: _adicionar,
                onAbrir: _abrirSessao,
                onMais: _menuDaSessao,
              ),
              if (estado.incompletas > 0)
                Padding(
                  padding: const EdgeInsets.only(top: TokensStrip.s2),
                  child: Text(
                    s.rotinaIncompletas(estado.incompletas),
                    textAlign: TextAlign.center,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ),
            ],
          ),
        ),
        FxStickyActions(
          primaryLabel: s.rotinaPronto,
          loading: _salvando,
          onPrimary: _concluir,
        ),
      ],
    );
  }

  void _concluir() {
    final props = _medicao.aoConcluir(estadoDaFicha(_dias), DateTime.now());
    if (props != null) {
      AnalyticsService.instance.track(
        ProductEvents.fichaPrimeiroPronto,
        props: props,
      );
    }
    context.pop();
  }

  Future<void> _abrirSessao(int treinoId) async {
    await context.push(
      '/treinos/$treinoId',
      extra: TreinoRouteExtra(
        alunoId: widget.alunoId,
        alunoNome: widget.alunoNome.trim(),
      ).toExtra(),
    );
    if (!mounted) return;
    ref.invalidate(alunoRotinaProvider(widget.alunoId));
    await _carregar();
  }

  Future<void> _adicionar(int dia) async {
    final nome = await pedirNomeDaSessao(context);
    if (nome == null || !mounted) return;
    await _persistir(
      comSessaoNoDia(_dias, dia: dia, sessao: SessaoDaSemana(nome: nome)),
    );
  }

  Future<void> _menuDaSessao(int dia, int indice) async {
    final sessao = _dias[dia - 1].sessoes[indice];
    final acao = await mostrarMenuDaSessao(
      context,
      nome: sessao.nome,
      podeCopiar: sessao.treinoId != null,
    );
    if (acao == null || !mounted) return;
    switch (acao) {
      case SessaoAcao.maisUm:
        await _adicionar(dia);
      case SessaoAcao.descanso:
        await _marcarDescanso(dia);
      case SessaoAcao.mover:
        final para = await escolherDia(context, excluir: dia);
        if (para == null || !mounted) return;
        await _persistir(moverDia(_dias, de: dia, para: para));
      case SessaoAcao.copiar:
        final para = await escolherDia(context);
        if (para == null || !mounted) return;
        await _copiarSessao(sessao, para);
    }
  }

  Future<void> _marcarDescanso(int dia) async {
    final s = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: s.rotinaDescansoConfirmaTitulo,
      message: s.rotinaDescansoConfirmaTexto,
      confirmLabel: s.rotinaMarcarDescanso,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _persistir([
      for (final d in _dias)
        d.dia == dia ? DiaDaSemana(dia: d.dia, descanso: true) : d,
    ]);
  }

  Future<void> _copiarSessao(SessaoDaSemana sessao, int para) async {
    if (_salvando || sessao.treinoId == null) return;
    setState(() => _salvando = true);
    try {
      final copia = await ref
          .read(treinoRepositoryProvider)
          .duplicar(sessao.treinoId!);
      if (!mounted) return;
      setState(() => _salvando = false);
      await _persistir(
        comSessaoNoDia(
          _dias,
          dia: para,
          sessao: SessaoDaSemana(
            treinoId: copia.id,
            nome: copia.nome,
            exerciciosCount: sessao.exerciciosCount,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _salvando = false);
      FeedbackHelper.showError(context, S.of(context).checkinNaoSalvou);
    }
  }

  Future<void> _menuDaFicha() async {
    final acao = await mostrarMenuDaFicha(context);
    if (acao == null || !mounted) return;
    switch (acao) {
      case FichaAcao.recomecar:
        await _recomecar();
      case FichaAcao.duplicarBase:
        await _copiarFicha(widget.alunoId);
      case FichaAcao.usarEmOutro:
        await _usarEmOutro();
    }
  }

  Future<void> _recomecar() async {
    final s = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: s.rotinaRecomecarTitulo,
      message: s.rotinaRecomecarTexto,
      confirmLabel: s.rotinaRecomecar,
      destructive: true,
    );
    if (!ok || !mounted) return;
    await _persistir(semanaVazia());
  }

  Future<void> _copiarFicha(int destinoId) async {
    final manterCargas = await escolherCargas(context);
    if (manterCargas == null || !mounted) return;
    await _aplicar(
      () => ref
          .read(treinoRepositoryProvider)
          .copiarSemana(widget.alunoId, destinoId, manterCargas: manterCargas),
    );
  }

  Future<void> _usarEmOutro() async {
    final alunos = await ref.read(alunosProvider.future);
    if (!mounted) return;
    final destino = await escolherAluno(
      context,
      alunos: alunos,
      excluirId: widget.alunoId,
    );
    if (destino == null || !mounted) return;
    await _copiarFicha(destino);
  }
}
