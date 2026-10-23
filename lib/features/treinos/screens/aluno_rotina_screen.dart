import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../models/rotina_fila.dart';
import '../providers/treinos_provider.dart';
import '../utils/rotina_frase.dart';
import '../utils/semana_da_fila.dart';
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
                    ? 'Nenhum treino ainda. Toque um dia e dê o nome da sessão.'
                    : (frase ?? s.rotinaVazia),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
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
                          for (final sessao in dia.sessoes)
                            Text(
                              sessao.nome,
                              style: FocuxHubTypography.bodyMuted(color: chrome.ink),
                            )
                        else if (dia.descanso)
                          Text(
                            s.rotinaDescanso,
                            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                          ),
                        TextButton(
                          onPressed: _salvando ? null : () => _nomear(index),
                          child: Text(
                            dia.sessoes.isEmpty
                                ? 'Toque para nomear'
                                : 'Mais um neste dia',
                          ),
                        ),
                        if (dia.sessoes.isNotEmpty)
                          TextButton(
                            onPressed: _salvando ? null : () => _marcarDescanso(index),
                            child: Text(s.rotinaDescanso),
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
                child: const Text('Usar em outro aluno'),
              ),
              const SizedBox(height: TokensStrip.s2),
              FxLiquidPrimaryButton(
                label: 'Pronto',
                loading: _salvando,
                loadingLabel: 'Pronto',
                onPressed: _salvando ? null : () => context.pop(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _persistir(List<DiaDaSemana> dias) {
    return _aplicar(
      () => ref.read(treinoRepositoryProvider).gravarSemana(widget.alunoId, dias),
    );
  }

  Future<void> _nomear(int index) async {
    final controle = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nome da sessão'),
        content: TextField(
          controller: controle,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Peito'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controle.text.trim()),
            child: const Text('Pronto'),
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
        title: const Text('Usar em outro aluno'),
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

