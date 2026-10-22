import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_toggle_chip.dart';
import '../../../l10n/app_localizations.dart';
import '../models/rotina_fila.dart';
import '../providers/treinos_provider.dart';
import '../utils/rotina_frase.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nome = widget.alunoNome.trim();
    final titulo = nome.isEmpty ? s.rotinaLinha : s.rotinaDe(nome);

    return FxShellScaffold(
      appBar: FxShellAppBar(title: s.rotinaLinha),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _falhou || _rotina == null
          ? Center(
              child: TextButton(
                onPressed: _carregar,
                child: Text(s.rotinaNaoAbriu),
              ),
            )
          : _corpo(s, chrome, isDark, titulo, _rotina!),
    );
  }

  Widget _corpo(
    S s,
    ShellPalette chrome,
    bool isDark,
    String titulo,
    RotinaFila rotina,
  ) {
    final frase = fraseQueAlunoVe(
      s,
      nome: widget.alunoNome,
      rotina: rotina,
      agora: DateTime.now(),
    );
    final dias = [
      s.rotinaDiaSeg,
      s.rotinaDiaTer,
      s.rotinaDiaQua,
      s.rotinaDiaQui,
      s.rotinaDiaSex,
      s.rotinaDiaSab,
      s.rotinaDiaDom,
    ];

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
                frase ?? s.rotinaVazia,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        Expanded(
          child: rotina.itens.isEmpty
              ? const SizedBox.shrink()
              : ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
                  itemCount: rotina.itens.length,
                  onReorderItem: (oldIndex, newIndex) {
                    if (_salvando) return;
                    final itens = [...rotina.itens];
                    final item = itens.removeAt(oldIndex);
                    itens.insert(newIndex, item);
                    setState(() => _rotina = _copia(rotina, itens: itens));
                    _aplicar(
                      () => ref.read(treinoRepositoryProvider).reordenarRotina(
                        widget.alunoId,
                        itens.map((item) => item.id).toList(),
                      ),
                    );
                  },
                  itemBuilder: (context, index) {
                    final item = rotina.itens[index];
                    return ReorderableDragStartListener(
                      key: ValueKey(item.id),
                      index: index,
                      child: _Cartao(
                        item: item,
                        chrome: chrome,
                        descanso: s.rotinaDescanso,
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
              Text(
                s.rotinaAvisar,
                style: FocuxHubTypography.cardTitle(color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s2),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (var dia = 1; dia <= 7; dia++)
                    FxToggleChip(
                      label: dias[dia - 1],
                      selected: rotina.diasAviso.contains(dia),
                      isDark: isDark,
                      onTap: _salvando
                          ? null
                          : () {
                              final proximos = {...rotina.diasAviso};
                              if (!proximos.add(dia)) proximos.remove(dia);
                              setState(
                                () => _rotina = _copia(rotina, dias: proximos),
                              );
                              _aplicar(
                                () => ref
                                    .read(treinoRepositoryProvider)
                                    .definirAvisos(
                                      widget.alunoId,
                                      proximos.toList()..sort(),
                                    ),
                              );
                            },
                    ),
                ],
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                s.rotinaAvisoLinha,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: TokensStrip.s4),
              if (rotina.temTreino)
                FxLiquidPrimaryButton(
                  label: s.rotinaPorDescanso,
                  loading: _salvando,
                  loadingLabel: s.rotinaPorDescanso,
                  onPressed: _salvando
                      ? null
                      : () => _aplicar(
                          () => ref
                              .read(treinoRepositoryProvider)
                              .porDescanso(widget.alunoId),
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  RotinaFila _copia(
    RotinaFila rotina, {
    List<RotinaItem>? itens,
    Set<int>? dias,
  }) => RotinaFila(
    itens: itens ?? rotina.itens,
    diasAviso: dias ?? rotina.diasAviso,
    sessaoAbertaTreinoId: rotina.sessaoAbertaTreinoId,
    ultimoTreinoId: rotina.ultimoTreinoId,
    concluiuHoje: rotina.concluiuHoje,
  );
}

class _Cartao extends StatelessWidget {
  const _Cartao({
    required this.item,
    required this.chrome,
    required this.descanso,
  });

  final RotinaItem item;
  final ShellPalette chrome;
  final String descanso;

  @override
  Widget build(BuildContext context) {
    final quieto = item.descanso;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: DecoratedBox(
        decoration: chrome.panel(radius: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s4,
              vertical: TokensStrip.s2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.rotulo(descanso),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: quieto
                        ? FocuxHubTypography.bodyMuted(color: chrome.mute)
                        : FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                ),
                Icon(Icons.drag_handle_rounded, color: chrome.mute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
