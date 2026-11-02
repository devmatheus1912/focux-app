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
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../../alunos/widgets/aluno_inset_form_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/evolucao_repository.dart';
import '../data/meta_corporal.dart';
import '../providers/metas_provider.dart';

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
                Align(
                  alignment: Alignment.centerLeft,
                  child: FxTonalButton(
                    label:
                        prazo == null
                            ? ptS.metaPrazoDefinir
                            : ptS.metaPrazoAte(_dataCurta(prazo!)),
                    icon: Icons.event_outlined,
                    compact: true,
                    onPressed: () async {
                      final hoje = DateTime.now();
                      final data = await showDatePicker(
                        context: context,
                        firstDate: hoje,
                        lastDate: DateTime(hoje.year + 3),
                        initialDate: prazo ?? hoje.add(const Duration(days: 90)),
                      );
                      if (data != null) setSheet(() => prazo = data);
                    },
                  ),
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

String _dataCurta(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
      ref.invalidate(metasDoAlunoProvider(alunoId));
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
      if (salvou) ref.invalidate(metasDoAlunoProvider(alunoId));
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = ShellChrome.of(context);
    final confirmar = metas.where((m) => m.aConfirmar);
    final proximos = metas.where((m) => m.proximoPassoPendente);
    final manutencao = metas.where((m) => m.aberta && m.manutencao);
    final ativas = metas.where((m) => m.aberta && !m.aConfirmar && !m.manutencao);
    final linhas = <Widget>[
      for (final m in confirmar)
        _Cartao(
          titulo: ptS.metaConfirmarTitulo(metaMetricaRotulo(m.metrica)),
          texto: ptS.metaConfirmarTexto(metaValor(m.metrica, m.valorAtual)),
          acoes: [
            FxTonalButton(
              label: ptS.metaConfirmar,
              compact: true,
              onPressed:
                  () => _rodar(context, ref, () => _repo(ref).acaoDeMeta(alunoId, m.id, 'confirmar')),
            ),
            FxTonalButton(
              label: ptS.metaDevolver,
              compact: true,
              onPressed:
                  () => _rodar(context, ref, () => _repo(ref).acaoDeMeta(alunoId, m.id, 'devolver')),
            ),
          ],
        ),
      for (final m in proximos)
        _Cartao(
          titulo: ptS.metaProximoPassoTitulo(metaMetricaRotulo(m.metrica)),
          texto: ptS.metaProximoPassoTexto,
          acoes: [
            FxTonalButton(
              label: ptS.metaNova,
              compact: true,
              onPressed: () async {
                final salvou = await abrirFormularioDeMeta(
                  context,
                  ref,
                  alunoId: alunoId,
                  ocupadas: const {},
                  metricaInicial: m.metrica,
                );
                if (salvou) ref.invalidate(metasDoAlunoProvider(alunoId));
              },
            ),
            FxTonalButton(
              label: ptS.metaManter,
              compact: true,
              onPressed:
                  () => _rodar(context, ref, () => _repo(ref).manterResultado(alunoId, m.metrica)),
            ),
            FxTonalButton(
              label: ptS.metaSemNova,
              compact: true,
              onPressed:
                  () => _rodar(context, ref, () => _repo(ref).acaoDeMeta(alunoId, m.id, 'sem-proximo-passo')),
            ),
          ],
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
          Text(
            ptS.metasTitulo,
            style: FocuxHubTypography.cardTitle(color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s2),
          for (final linha in linhas) ...[
            linha,
            const SizedBox(height: TokensStrip.s2),
          ],
        ],
      ),
    );
  }
}

class _Cartao extends StatelessWidget {
  const _Cartao({required this.titulo, required this.texto, required this.acoes});

  final String titulo;
  final String texto;
  final List<Widget> acoes;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(
        context,
        accent: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: FocuxHubTypography.cardTitle(color: chrome.ink)),
          Text(texto, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
          const SizedBox(height: TokensStrip.s2),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s1,
            children: acoes,
          ),
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
  });

  final String titulo;
  final String texto;
  final VoidCallback onMais;

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
      decoration: fxListCardDecoration(context),
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
