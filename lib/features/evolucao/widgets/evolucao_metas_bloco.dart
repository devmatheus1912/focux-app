import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_sheet.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_quick_chips.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/pt.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../data/meta_corporal.dart';
import '../../alunos/providers/aluno_detail_providers.dart';

double? _numero(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

/// Cria ou corrige meta. Devolve true se salvou.
Future<bool> abrirFormularioDeMeta(
  BuildContext context,
  WidgetRef ref, {
  required int alunoId,
  required Set<String> ocupadas,
  MetaCorporal? meta,
  String? metricaInicial,
}) async {
  var metrica =
      meta?.metrica ??
      metricaInicial ??
      metaMetricas.firstWhere(
        (m) => !ocupadas.contains(m),
        orElse: () => metaMetricas.first,
      );
  final alvo = TextEditingController(
    text: meta == null ? '' : meta.valorAlvo.toString().replaceAll('.', ','),
  );
  final observacao = TextEditingController(text: meta?.observacao ?? '');
  DateTime? prazo = meta?.prazo == null ? null : DateTime.tryParse(meta!.prazo!);
  // Prazo de meta existente segue valendo até o personal trocar.
  var prazoDias = prazo == null ? 0 : -1;
  final livres = metaMetricas.where((m) => !ocupadas.contains(m)).toList();
  try {
    final ok = await showFxFormSheet(
      context,
      title: meta == null ? ptS.metaDefinir : ptS.metaEditar,
      icon: Icons.flag_outlined,
      confirmLabel: ptS.evolucaoSalvar,
      child: StatefulBuilder(
        builder:
            (context, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (meta == null) ...[
                  FxQuickChips<String>(
                    itens: livres,
                    selecionado: metrica,
                    rotuloDe: metaMetricaRotulo,
                    onSelecionar: (m) => setSheet(() => metrica = m),
                  ),
                  const SizedBox(height: TokensStrip.s2),
                ],
                AlunoInsetFormField(
                  rotuloVisivel: true,
                  controller: alvo,
                  label: ptS.metaAlvoCampo(metaUnidade(metrica)),
                  icon: Icons.flag_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                AlunoInsetFormField(
                  rotuloVisivel: true,
                  controller: observacao,
                  label: ptS.metaObservacaoCampo,
                  icon: Icons.notes_rounded,
                  showDivider: false,
                ),
                const SizedBox(height: TokensStrip.s2),
                FxQuickChips<int>(
                  itens: const [0, 30, 60, 90],
                  selecionado: prazoDias,
                  rotuloDe:
                      (d) =>
                          d == 0 ? ptS.metaPrazoSem : ptS.metaPrazoDias('$d'),
                  onSelecionar:
                      (d) => setSheet(() {
                        prazoDias = d;
                        prazo =
                            d == 0
                                ? null
                                : DateTime.now().add(Duration(days: d));
                      }),
                ),
              ],
            ),
      ),
    );
    if (!ok || !context.mounted) return false;
    final valor = _numero(alvo.text);
    if (valor == null) {
      FeedbackHelper.showError(context, ptS.metaAlvoInvalido);
      return false;
    }
    final repo = EvolucaoRepository(ref.read(apiClientProvider));
    if (meta == null) {
      await repo.criarMeta(
        alunoId,
        metrica: metrica,
        alvo: valor,
        prazo: prazo,
        observacao: observacao.text,
      );
    } else {
      await repo.editarMeta(
        alunoId,
        meta,
        alvo: valor,
        prazo: prazo,
        observacao: observacao.text,
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) FeedbackHelper.showError(context, friendlyError(e));
    return false;
  } finally {
    alvo.dispose();
    observacao.dispose();
  }
}

/// O que o personal precisa decidir sobre as metas deste aluno.
class EvolucaoMetasBloco extends ConsumerWidget {
  const EvolucaoMetasBloco({
    super.key,
    required this.alunoId,
    required this.metas,
  });

  final int alunoId;
  final List<MetaCorporal> metas;

  EvolucaoRepository _repo(WidgetRef ref) =>
      EvolucaoRepository(ref.read(apiClientProvider));

  Future<void> _rodar(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() acao,
  ) async {
    try {
      await acao();
      await invalidateAluno360Providers(ref, alunoId);
    } catch (e) {
      if (context.mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _opcoes(
    BuildContext context,
    WidgetRef ref,
    MetaCorporal meta,
  ) async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: metaMetricaRotulo(meta.metrica),
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'editar',
            rotulo: ptS.metaEditar,
            icone: Icons.edit_outlined,
          ),
          FxActionItem(
            valor: 'encerrar',
            rotulo: ptS.metaEncerrar,
            icone: Icons.close_rounded,
            perigo: true,
          ),
        ]),
      ],
    );
    if (!context.mounted) return;
    if (escolha == 'editar') {
      final salvou = await abrirFormularioDeMeta(
        context,
        ref,
        alunoId: alunoId,
        ocupadas: const {},
        meta: meta,
      );
      if (salvou) await invalidateAluno360Providers(ref, alunoId);
    } else if (escolha == 'encerrar') {
      final ok = await showFxConfirmSheet(
        context,
        title: ptS.metaEncerrarTitulo,
        message: ptS.metaEncerrarMensagem,
        icon: Icons.close_rounded,
        confirmLabel: ptS.metaEncerrar,
        destructive: true,
      );
      if (ok && context.mounted) {
        await _rodar(context, ref, () => _repo(ref).acaoDeMeta(alunoId, meta.id, 'encerrar'));
      }
    }
  }

  Future<void> _confirmar(
    BuildContext context,
    WidgetRef ref,
    MetaCorporal m,
  ) async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: ptS.metaConfirmarTitulo(metaMetricaRotulo(m.metrica)),
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'confirmar',
            rotulo: ptS.metaConfirmarAcao,
            descricao: ptS.metaConfirmarDescricao,
            icone: Icons.verified_outlined,
          ),
          FxActionItem(
            valor: 'devolver',
            rotulo: ptS.metaDevolver,
            descricao: ptS.metaDevolverDescricao,
            icone: Icons.undo_rounded,
          ),
        ]),
      ],
    );
    if (escolha == null || !context.mounted) return;
    await _rodar(context, ref, () => _repo(ref).acaoDeMeta(alunoId, m.id, escolha));
  }

  Future<void> _proximoPasso(
    BuildContext context,
    WidgetRef ref,
    MetaCorporal m,
  ) async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: ptS.metaProximoPassoTitulo(metaMetricaRotulo(m.metrica)),
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'nova',
            rotulo: ptS.metaNova,
            descricao: ptS.metaNovaDescricao,
            icone: Icons.flag_outlined,
          ),
          FxActionItem(
            valor: 'manter',
            rotulo: ptS.metaManter,
            descricao: ptS.metaManterDescricao,
            icone: Icons.shield_outlined,
          ),
          FxActionItem(
            valor: 'sem',
            rotulo: ptS.metaSemNova,
            descricao: ptS.metaSemNovaDescricao,
            icone: Icons.close_rounded,
          ),
        ]),
      ],
    );
    if (!context.mounted) return;
    switch (escolha) {
      case 'nova':
        final salvou = await abrirFormularioDeMeta(
          context,
          ref,
          alunoId: alunoId,
          ocupadas: {for (final x in metaMetricas) if (x != m.metrica) x},
          metricaInicial: m.metrica,
        );
        if (salvou) await invalidateAluno360Providers(ref, alunoId);
      case 'manter':
        await _rodar(context, ref, () => _repo(ref).manterResultado(alunoId, m.metrica));
      case 'sem':
        await _rodar(
          context,
          ref,
          () => _repo(ref).acaoDeMeta(alunoId, m.id, 'sem-proximo-passo'),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmar = metas.where((m) => m.aConfirmar);
    final proximos = metas.where((m) => m.proximoPassoPendente);
    final manutencao = metas.where((m) => m.aberta && m.manutencao);
    final ativas = metas.where((m) => m.aberta && !m.aConfirmar && !m.manutencao);
    final linhas = <Widget>[
      for (final m in confirmar)
        _LinhaMeta(
          titulo: ptS.metaConfirmarTitulo(metaMetricaRotulo(m.metrica)),
          texto: ptS.metaConfirmarTexto(metaValor(m.metrica, m.valorAtual)),
          destaque: true,
          onMais: () => _confirmar(context, ref, m),
        ),
      for (final m in proximos)
        _LinhaMeta(
          titulo: ptS.metaProximoPassoTitulo(metaMetricaRotulo(m.metrica)),
          texto: ptS.metaProximoPassoTexto,
          destaque: true,
          onMais: () => _proximoPasso(context, ref, m),
        ),
      for (final m in ativas)
        _LinhaMeta(
          titulo: metaMetricaRotulo(m.metrica),
          texto: [
            ptS.metaProgressoLinha(
              metaValor(m.metrica, m.valorInicial),
              metaValor(m.metrica, m.valorAlvo),
              m.progresso,
            ),
            if (m.observacao != null) m.observacao!,
          ].join('\n'),
          onMais: () => _opcoes(context, ref, m),
        ),
      for (final m in manutencao)
        _LinhaMeta(
          titulo: ptS.metaManutencaoTitulo(metaMetricaRotulo(m.metrica)),
          texto:
              m.foraDaFaixa
                  ? ptS.metaForaDaFaixa(metaValor(m.metrica, m.valorAtual))
                  : ptS.metaNaFaixa(metaValor(m.metrica, m.valorAlvo)),
          onMais: () => _opcoes(context, ref, m),
        ),
    ];
    if (linhas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final linha in linhas) ...[
            linha,
            const SizedBox(height: TokensStrip.s2),
          ],
        ],
      ),
    );
  }
}

class _LinhaMeta extends StatelessWidget {
  const _LinhaMeta({
    required this.titulo,
    required this.texto,
    required this.onMais,
    this.destaque = false,
  });

  final String titulo;
  final String texto;
  final VoidCallback onMais;

  /// Pede decisão do personal.
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s3,
        TokensStrip.s2,
        TokensStrip.s1,
        TokensStrip.s2,
      ),
      decoration: fxListCardDecoration(
        context,
        accent: destaque ? Theme.of(context).colorScheme.primary : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: FocuxHubTypography.cardTitle(color: chrome.ink)),
                Text(texto, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
              ],
            ),
          ),
          IconButton(
            tooltip: ptS.metaOpcoes,
            icon: Icon(Icons.more_horiz_rounded, color: chrome.mute),
            onPressed: onMais,
          ),
        ],
      ),
    );
  }
}
