import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../models/rotina_fila.dart';
import '../providers/treinos_provider.dart';
import '../utils/rotina_frase.dart';
import '../utils/semana_da_fila.dart';
import '../utils/treino_criacao_fluxo.dart';
import '../../alunos/providers/alunos_provider.dart';

/// Linha da ficha de treinos do aluno. O subtítulo é a fila numa frase.
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
    final linha = rotina?.linha(s.rotinaDescanso) ?? '';

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

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final nome = widget.alunoNome.trim();
    final titulo = nome.isEmpty ? s.rotinaLinha : s.rotinaDe(nome);

    return fxScreenA11yScope(
      label: s.rotinaLinha,
      child: FxShellScaffold(
        appBar: FxShellAppBar(title: s.rotinaLinha),
        body: _carregando
            ? const Center(child: FxLoading())
            : _falhou || _rotina == null
            ? Center(
                child: TextButton(
                  onPressed: _carregar,
                  child: Text(s.rotinaNaoAbriu),
                ),
              )
            : _corpo(s, chrome, titulo, _rotina!),
      ),
    );
  }

  Widget _corpo(
    S s,
    ShellPalette chrome,
    String titulo,
    RotinaFila rotina,
  ) {
    final frase = fraseQueAlunoVe(
      s,
      nome: widget.alunoNome,
      rotina: rotina,
      agora: DateTime.now(),
    );
    final nomes = [
      s.rotinaDiaSeg,
      s.rotinaDiaTer,
      s.rotinaDiaQua,
      s.rotinaDiaQui,
      s.rotinaDiaSex,
      s.rotinaDiaSab,
      s.rotinaDiaDom,
    ];
    final vazia = _dias.every((dia) => dia.sessoes.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s4,
            TokensStrip.s4,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                vazia
                    ? s.rotinaVaziaDica
                    : (frase ?? s.rotinaVazia),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        if (vazia) _frequencia(s, chrome),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
            itemCount: _dias.length,
            itemBuilder: (context, index) {
              final dia = _dias[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                child: DecoratedBox(
                  decoration: chrome.panel(radius: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(TokensStrip.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomes[index],
                          style: FocuxHubTypography.cardTitle(color: chrome.ink),
                        ),
                        if (dia.sessoes.isNotEmpty)
                          for (var i = 0; i < dia.sessoes.length; i++)
                            _sessao(s, chrome, dia.sessoes[i], segunda: i > 0)
                        else if (dia.descanso)
                          Text(
                            s.rotinaDescanso,
                            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                          ),
                        TextButton(
                          onPressed: _salvando ? null : () => _nomear(index),
                          child: Text(
                            dia.sessoes.isEmpty
                                ? s.rotinaToqueParaNomear
                                : s.rotinaMaisUmNesteDia,
                          ),
                        ),
                        if (dia.sessoes.isNotEmpty)
                          TextButton(
                            onPressed: _salvando ? null : () => _marcarDescanso(index),
                            child: Text(s.rotinaMarcarDescanso),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            TokensStrip.s4,
            TokensStrip.s4,
            TokensStrip.s4,
            TokensStrip.s2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton(
                onPressed: _salvando ? null : _usarEmOutro,
                child: Text(s.rotinaUsarEmOutro),
              ),
              const SizedBox(height: TokensStrip.s2),
              FxLiquidPrimaryButton(
                label: s.rotinaPronto,
                loading: _salvando,
                loadingLabel: s.rotinaPronto,
                onPressed: _salvando ? null : () => context.pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _frequencia(S s, ShellPalette chrome) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        0,
        TokensStrip.s4,
        TokensStrip.s4,
      ),
      child: DecoratedBox(
        decoration: chrome.panel(radius: 20),
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.rotinaFrequenciaTitulo,
                style: FocuxHubTypography.cardTitle(color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                s.rotinaFrequenciaDica,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s3),
              Wrap(
                spacing: TokensStrip.s2,
                children: [
                  for (final n in const [2, 3, 4, 5, 6, 7])
                    OutlinedButton(
                      key: ValueKey('rotina-frequencia-$n'),
                      onPressed: _salvando
                          ? null
                          : () => _persistir(semanaPorFrequencia(n)),
                      child: Text('$n'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessao(
    S s,
    ShellPalette chrome,
    SessaoDaSemana sessao, {
    required bool segunda,
  }) {
    final treinoId = sessao.treinoId;
    final nome = Text(
      segunda ? '${sessao.nome} · ${s.rotinaSegundoTreino}' : sessao.nome,
      style: FocuxHubTypography.bodyMuted(color: chrome.ink),
    );
    if (treinoId == null) return nome;
    return InkWell(
      onTap: _salvando ? null : () => _abrirSessao(treinoId),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  nome,
                  Text(
                    s.rotinaSessaoMontar,
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: chrome.mute),
          ],
        ),
      ),
    );
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

  Future<void> _persistir(List<DiaDaSemana> dias) {
    return _aplicar(
      () => ref.read(treinoRepositoryProvider).gravarSemana(widget.alunoId, dias),
    );
  }

  Future<void> _nomear(int index) async {
    final s = S.of(context);
    final controle = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.rotinaNomeDaSessao),
        content: TextField(
          controller: controle,
          autofocus: true,
          decoration: InputDecoration(hintText: s.rotinaNomeExemplo),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(FocuxMicrocopy.cancelar),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controle.text.trim()),
            child: Text(s.rotinaPronto),
          ),
        ],
      ),
    );
    controle.dispose();
    if (nome == null || nome.isEmpty || !mounted) return;
    final dias = [
      for (var i = 0; i < _dias.length; i++)
        i == index
            ? _dias[i].copyWith(
                descanso: false,
                sessoes: [
                  ..._dias[i].sessoes,
                  SessaoDaSemana(nome: nome),
                ],
              )
            : _dias[i],
    ];
    setState(() => _dias = dias);
    await _persistir(dias);
  }

  Future<void> _marcarDescanso(int index) async {
    final s = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: s.rotinaDescansoConfirmaTitulo,
      message: s.rotinaDescansoConfirmaTexto,
      confirmLabel: s.rotinaMarcarDescanso,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final dias = [
      for (var i = 0; i < _dias.length; i++)
        i == index
            ? DiaDaSemana(dia: _dias[i].dia, descanso: true)
            : _dias[i],
    ];
    setState(() => _dias = dias);
    await _persistir(dias);
  }

  Future<void> _usarEmOutro() async {
    final alunos = await ref.read(alunosProvider.future);
    if (!mounted) return;
    final destino = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(S.of(context).rotinaUsarEmOutro),
        children: [
          for (final aluno in alunos)
            if (aluno.id != widget.alunoId)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, aluno.id),
                child: Text(aluno.nome),
              ),
        ],
      ),
    );
    if (destino == null) return;
    await _aplicar(
      () => ref.read(treinoRepositoryProvider).copiarSemana(widget.alunoId, destino),
    );
  }
}

