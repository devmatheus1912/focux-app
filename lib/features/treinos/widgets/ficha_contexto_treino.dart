import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/treinos_provider.dart';
import '../utils/semana_da_fila.dart';
import '../utils/treino_criacao_fluxo.dart';
import 'ficha_acoes.dart';

/// Quando o treino foi aberto pela ficha de um aluno: de quem é, de que dia, e
/// uma fileira para pular para as outras sessões da semana sem voltar.
class FichaContextoDoTreino extends ConsumerWidget {
  const FichaContextoDoTreino({
    super.key,
    required this.alunoId,
    required this.alunoNome,
    required this.treinoId,
    this.inicio,
  });

  final int alunoId;
  final String? alunoNome;
  final int treinoId;

  /// Vai à esquerda da linha do contexto (o estado do salvo).
  final Widget? inicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rotina = ref.watch(alunoRotinaProvider(alunoId)).asData?.value;
    if (rotina == null) return inicio ?? const SizedBox.shrink();

    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final nomes = nomesDosDias(s);
    final sessoes = [
      for (final dia in semanaDaFila(rotina))
        for (final sessao in dia.sessoes)
          if (sessao.treinoId != null) (dia.dia, sessao),
    ];
    final atual = sessoes.where((e) => e.$2.treinoId == treinoId).firstOrNull;
    if (atual == null) return inicio ?? const SizedBox.shrink();

    final nome = alunoNome?.trim() ?? '';
    final diaNome = nomes[atual.$1 - 1];
    final linha = nome.isEmpty
        ? s.treinoContextoFichaSemNome(diaNome)
        : s.treinoContextoFicha(nome, diaNome);

    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LinhaDoContexto(inicio: inicio, texto: linha, cor: chrome.mute),
          if (sessoes.length > 1)
            FxChoiceStrip<int>(
              itens: [
                for (final e in sessoes)
                  FxChoiceItem(value: e.$2.treinoId!, label: e.$2.nome),
              ],
              selecionado: treinoId,
              onSelecionar: (id) {
                if (id == treinoId) return;
                context.pushReplacement(
                  '/treinos/$id',
                  extra: TreinoRouteExtra(
                    alunoId: alunoId,
                    alunoNome: nome,
                  ).toExtra(),
                );
              },
              cheio: true,
            ),
        ],
      ),
    );
  }
}

/// "Tudo salvo" à esquerda e o contexto à direita, numa linha só.
class _LinhaDoContexto extends StatelessWidget {
  const _LinhaDoContexto({
    required this.inicio,
    required this.texto,
    required this.cor,
  });

  final Widget? inicio;
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final rotulo = Text(
      texto,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: inicio == null ? TextAlign.start : TextAlign.end,
      style: FocuxHubTypography.bodyMuted(color: cor),
    );
    if (inicio == null) return rotulo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        inicio!,
        const SizedBox(width: TokensStrip.s3),
        Expanded(child: rotulo),
      ],
    );
  }
}
