import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/design_tokens.dart';
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
import '../providers/evolucao_home_provider.dart';
import '../utils/evolucao_series.dart';
import '../../alunos/providers/aluno_detail_providers.dart';

double? _numero(String texto) =>
    double.tryParse(texto.trim().replaceAll(',', '.'));

/// Cria ou corrige meta. Devolve true se salvou.
/// Última leitura da medida no aluno: valor e data.
({double valor, String data})? metaLeituraAtual(
  String metrica,
  EvolucaoHomeBundle? home,
) {
  if (home == null) return null;
  if (metrica == 'GORDURA' || metrica == 'MASSA') {
    final ponto = (metrica == 'GORDURA' ? home.gordura : home.massa).firstOrNull;
    return ponto == null ? null : (valor: ponto.valor, data: ponto.data);
  }
  final medida = EvolucaoMetrica.values.firstWhere(
    (m) => m.codigoMeta == metrica,
  );
  final serie = serieDaMetrica(home.medidas, medida);
  final ultimo = serie.lastOrNull;
  return ultimo == null
      ? null
      : (valor: ultimo.valor, data: dataCurta(ultimo.data));
}

/// "Reduzir 5,0 cm" ao digitar; nulo sem alvo ou com alvo igual ao atual.
String? metaLeituraDoAlvo(String metrica, double atual, double? alvo) {
  if (alvo == null || alvo == atual) return null;
  final diferenca = metaValor(metrica, (alvo - atual).abs());
  return alvo < atual ? ptS.metaReduzir(diferenca) : ptS.metaAumentar(diferenca);
}

Future<bool> abrirFormularioDeMeta(
  BuildContext context,
  WidgetRef ref, {
  required int alunoId,
  required Set<String> ocupadas,
  MetaCorporal? meta,
  String? metricaInicial,
  VoidCallback? onRegistrarMedida,
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
  final home = ref.read(evolucaoHomeProvider(alunoId)).value;
  String? erroAlvo;
  ({double valor, String data})? atual() => metaLeituraAtual(metrica, home);
  var registrar = false;
  alvo.addListener(() {
    erroAlvo = null;
    _avisarErro?.call();
  });
  try {
    final ok = await showFxFormSheet(
      context,
      title: meta == null ? ptS.metaDefinir : ptS.metaEditar,
      icon: Icons.flag_outlined,
      confirmLabel: ptS.evolucaoSalvar,
      podeConfirmar: () {
        final valor = _numero(alvo.text);
        final leitura = atual();
        erroAlvo =
            valor == null
                ? ptS.metaAlvoInvalido
                : meta == null && leitura?.valor == valor
                ? ptS.metaAlvoIgualAtual
                : null;
        _avisarErro?.call();
        return erroAlvo == null && (meta != null || home == null || leitura != null);
      },
      child: StatefulBuilder(
        builder: (context, setSheet) {
          _avisarErro = () => setSheet(() {});
          final chrome = ShellChrome.of(context);
          final leitura = atual();
          final doAlvo =
              leitura == null
                  ? null
                  : metaLeituraDoAlvo(metrica, leitura.valor, _numero(alvo.text));
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (meta == null) ...[
                FxQuickChips<String>(
                  itens: metaMetricas,
                  selecionado: metrica,
                  bloqueados: ocupadas,
                  rotuloDe:
                      (m) =>
                          ocupadas.contains(m)
                              ? ptS.metaJaTem(metaMetricaRotulo(m))
                              : metaMetricaRotulo(m),
                  onSelecionar: (m) => setSheet(() {
                    metrica = m;
                    erroAlvo = null;
                  }),
                ),
                const SizedBox(height: TokensStrip.s2),
              ],
              if (leitura != null)
                Text(
                  ptS.metaAtualLinha(metaValor(metrica, leitura.valor), leitura.data),
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                )
              else if (home != null && meta == null) ...[
                Text(
                  ptS.metaSemMedidaTexto,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
                if (onRegistrarMedida != null) ...[
                  const SizedBox(height: TokensStrip.s2),
                  FxTonalButton(
                    label: ptS.alunoPerfilRegistrarMedida,
                    expanded: true,
                    onPressed: () {
                      registrar = true;
                      Navigator.of(context).pop(false);
                    },
                  ),
                ],
              ],
              const SizedBox(height: TokensStrip.s2),
              AlunoInsetFormField(
                rotuloVisivel: true,
                obrigatorio: true,
                controller: alvo,
                label: ptS.metaAlvoCampo(metaUnidade(metrica)),
                icon: Icons.flag_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              if (erroAlvo != null || doAlvo != null)
                Padding(
                  padding: const EdgeInsets.only(top: TokensStrip.s1),
                  child: Text(
                    erroAlvo ?? doAlvo!,
                    style: FocuxHubTypography.bodyMuted(
                      color:
                          erroAlvo != null
                              ? Theme.of(context).colorScheme.error
                              : chrome.mute,
                    ),
                  ),
                ),
              const SizedBox(height: TokensStrip.s3),
              Text(ptS.metaPrazoRotulo, style: FocuxHubTypography.chip(chrome.mute)),
              const SizedBox(height: TokensStrip.s1),
              FxQuickChips<int>(
                itens: const [0, 30, 60, 90],
                selecionado: prazoDias,
                rotuloDe:
                    (d) => d == 0 ? ptS.metaPrazoSem : ptS.metaPrazoDias('$d'),
                onSelecionar:
                    (d) => setSheet(() {
                      prazoDias = d;
                      prazo =
                          d == 0 ? null : DateTime.now().add(Duration(days: d));
                    }),
              ),
              const SizedBox(height: TokensStrip.s2),
              AlunoInsetFormField(
                rotuloVisivel: true,
                controller: observacao,
                label: ptS.metaObservacaoCampo,
                icon: Icons.notes_rounded,
                showDivider: false,
              ),
            ],
          );
        },
      ),
    );
    if (registrar) {
      onRegistrarMedida?.call();
      return false;
    }
    if (!ok || !context.mounted) return false;
    final valor = _numero(alvo.text)!;
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
    _avisarErro = null;
    alvo.dispose();
    observacao.dispose();
  }
}

VoidCallback? _avisarErro;

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
            // 0% esconde quem se afastou: aí a linha diz e mostra o atual.
            if (m.valorAtual case final atual?
                when rumoDaMeta(m, atual) == RumoDaMeta.seAfastando)
              ptS.metaSeAfastandoLinha(
                metaValor(m.metrica, m.valorInicial),
                metaValor(m.metrica, m.valorAlvo),
                metaValor(m.metrica, atual),
              )
            else
              ptS.metaProgressoLinha(
                metaValor(m.metrica, m.valorInicial),
                metaValor(m.metrica, m.valorAlvo),
                m.progresso,
              ),
            if (m.observacao != null) m.observacao!,
          ].join('\n'),
          alerta:
              m.valorAtual != null &&
              rumoDaMeta(m, m.valorAtual!) == RumoDaMeta.seAfastando,
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
    this.alerta = false,
  });

  final String titulo;
  final String texto;
  final VoidCallback onMais;

  /// Medida indo para o lado oposto do alvo: o texto fica na cor de alerta.
  final bool alerta;

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
                Text(
                  texto,
                  style: FocuxHubTypography.bodyMuted(
                    color:
                        alerta
                            ? (chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn)
                            : chrome.mute,
                  ),
                ),
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
