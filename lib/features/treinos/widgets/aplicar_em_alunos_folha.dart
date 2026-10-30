import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_bottom_sheet.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_sheet_frame.dart';
import '../../../core/widgets/fx_sheet_search_field.dart';
import '../../alunos/data/aluno_repository.dart';
import '../models/rotina_fila.dart';
import '../providers/treinos_provider.dart';
import '../utils/ficha_vigencia.dart';

/// Situação da ficha numa linha: "Treinando agora", "Sem ficha" ou "Ficha até 12/12".
String situacaoDaFicha(RotinaFila? fila) {
  if (fila == null) return '';
  if (fila.sessaoAbertaTreinoId != null) return 'Treinando agora';
  if (fila.itens.where((i) => !i.descanso).isEmpty) return 'Sem ficha';
  final fim = fila.vigencia.fim;
  return fim == null ? 'Ficha sem prazo' : 'Ficha até ${dataCurta(fim)}';
}

/// "AC" de "Ana Clara"; uma letra para nome único.
String iniciais(String nome) {
  final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes.first[0].toUpperCase();
  return (partes.first[0] + partes.last[0]).toUpperCase();
}

/// Escolhe um ou vários alunos para receber uma ficha (modelo ou cópia).
/// [varios] falso = um aluno só (tocar já escolhe).
Future<List<Aluno>?> escolherAlunos(
  BuildContext context, {
  required List<Aluno> alunos,
  required String titulo,
  bool varios = true,
  int? excluirId,
}) => showFxBottomSheet<List<Aluno>>(
  context: context,
  builder: (_) => _EscolherAlunosFolha(
    alunos: [for (final a in alunos) if (a.id != excluirId) a],
    titulo: titulo,
    varios: varios,
  ),
);

class _EscolherAlunosFolha extends StatefulWidget {
  const _EscolherAlunosFolha({required this.alunos, required this.titulo, required this.varios});

  final List<Aluno> alunos;
  final String titulo;
  final bool varios;

  @override
  State<_EscolherAlunosFolha> createState() => _EscolherAlunosFolhaState();
}

class _EscolherAlunosFolhaState extends State<_EscolherAlunosFolha> {
  var _busca = '';
  final _marcados = <int>{};

  @override
  Widget build(BuildContext context) {
    final alvo = _busca.trim().toLowerCase();
    final visiveis = [
      for (final a in widget.alunos)
        if (alvo.isEmpty || a.nome.toLowerCase().contains(alvo)) a,
    ];
    final escolhidos = [for (final a in widget.alunos) if (_marcados.contains(a.id)) a];
    return FxSheetFrame(
      title: widget.titulo,
      expand: true,
      footer: widget.varios
          ? Padding(
              padding: const EdgeInsets.all(TokensStrip.s3),
              child: FxLiquidPrimaryButton(
                label: escolhidos.length <= 1 ? 'Aplicar' : 'Aplicar em ${escolhidos.length} alunos',
                onPressed: escolhidos.isEmpty ? null : () => Navigator.pop(context, escolhidos),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxSheetSearchField(
            dica: 'Buscar aluno',
            onChanged: (texto) => setState(() => _busca = texto),
          ),
          const SizedBox(height: TokensStrip.s2),
          for (final aluno in visiveis)
            _LinhaDoAluno(
              aluno: aluno,
              marcado: _marcados.contains(aluno.id),
              varios: widget.varios,
              onTap: () {
                if (!widget.varios) {
                  Navigator.pop(context, [aluno]);
                  return;
                }
                setState(() {
                  if (!_marcados.add(aluno.id)) _marcados.remove(aluno.id);
                });
              },
            ),
        ],
      ),
    );
  }
}

class _LinhaDoAluno extends ConsumerWidget {
  const _LinhaDoAluno({required this.aluno, required this.marcado, required this.varios, required this.onTap});

  final Aluno aluno;
  final bool marcado;
  final bool varios;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final situacao = situacaoDaFicha(ref.watch(alunoRotinaProvider(aluno.id)).asData?.value);
    return Semantics(
      button: true,
      selected: marcado,
      label: situacao.isEmpty ? aluno.nome : '${aluno.nome}, $situacao',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rCard),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withValues(alpha: 0.14),
                child: Text(
                  iniciais(aluno.nome),
                  style: FocuxHubTypography.cardTitle(color: chrome.ink).copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(width: TokensStrip.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(aluno.nome, style: FocuxHubTypography.cardTitle(color: chrome.ink)),
                    if (situacao.isNotEmpty)
                      Text(situacao, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
                  ],
                ),
              ),
              if (varios)
                Icon(
                  marcado ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: marcado ? primary : chrome.mute,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
