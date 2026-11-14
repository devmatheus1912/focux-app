import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_grafico_linha.dart';
import '../../../core/widgets/fx_grouped_action_sheet.dart';
import '../../../core/widgets/fx_home_sheet.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/pt.dart';
import '../data/evolucao_repository.dart';
import '../utils/evolucao_display.dart';
import '../utils/evolucao_series.dart';
import 'escolher_exercicio_campo.dart';
import '../../../core/theme/fx_icons.dart';
import '../../../core/widgets/fx_link_row.dart';

/// Aba Força, igual para personal e aluno, no mesmo padrão do Corpo: o gráfico
/// do exercício escolhido no topo, a lista embaixo (tocar escolhe) e "Ver
/// registros" (editar e excluir ficam lá, só para o personal).
class EvolucaoRecordesAba extends StatefulWidget {
  const EvolucaoRecordesAba({
    super.key,
    required this.recordes,
    required this.vazioSubtitulo,
    required this.onAtualizar,
    this.onEditar,
    this.onExcluir,
    this.onRegistrar,
    this.depois = const [],
  });

  final List<RecordePessoal> recordes;
  final String vazioSubtitulo;
  final Future<void> Function() onAtualizar;

  /// Só para o personal.
  final ValueChanged<RecordePessoal>? onEditar;
  final ValueChanged<RecordePessoal>? onExcluir;

  /// "Registrar carga" no rodapé dos registros, com o exercício escolhido.
  final ValueChanged<ExercicioEscolhido>? onRegistrar;

  /// Conquistas de força, depois da lista.
  final List<Widget> depois;

  @override
  State<EvolucaoRecordesAba> createState() => _EvolucaoRecordesAbaState();
}

class _EvolucaoRecordesAbaState extends State<EvolucaoRecordesAba> {
  String? _escolhido;

  static String _chave(String nome) => nome.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final progresso = progressoDosRecordes(widget.recordes);
    final destaque = maiorProgresso(progresso);
    if (progresso.isEmpty) {
      return RefreshIndicator(
        onRefresh: widget.onAtualizar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            FxEmptyState(
              key: const ValueKey('evolucao_recordes_empty'),
              icon: FxIcons.estrela,
              title: ptS.evolucaoSemRecordeTitulo,
              subtitle: widget.vazioSubtitulo,
            ),
          ],
        ),
      );
    }
    final escolhido =
        progresso.where((p) => _chave(p.nome) == _escolhido).firstOrNull ??
        progresso.first;
    return RefreshIndicator(
      onRefresh: widget.onAtualizar,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          96,
        ),
        children: [
          // Com um exercício só, o destaque repetia a lista.
          if (destaque != null && progresso.length > 1) ...[
            Text(
              ptS.evolucaoMaiorProgresso,
              style: FocuxHubTypography.chip(chrome.mute),
            ),
            const SizedBox(height: 2),
            Text(
              ptS.evolucaoProgressoFrase(
                destaque.nome,
                diferencaTexto(destaque.ganhoKg, 'kg'),
              ),
              style: FocuxHubTypography.cardTitle(color: chrome.ink),
            ),
            const SizedBox(height: TokensStrip.s3),
          ],
          _BlocoDoExercicio(
            progresso: escolhido,
            onVerRegistros:
                () => abrirRegistrosDoExercicio(
                  context,
                  escolhido,
                  onEditar: widget.onEditar,
                  onExcluir: widget.onExcluir,
                  onRegistrar: widget.onRegistrar,
                ),
          ),
          const SizedBox(height: TokensStrip.s3),
          Container(
            decoration: fxListCardDecoration(context),
            child: Column(
              children: [
                for (final (i, p) in progresso.indexed) ...[
                  if (i > 0) Divider(height: 1, color: chrome.line),
                  _LinhaDoExercicio(
                    progresso: p,
                    selecionada: identical(p, escolhido),
                    onTap: () => setState(() => _escolhido = _chave(p.nome)),
                  ),
                ],
              ],
            ),
          ),
          // Um dia por exercício ainda não tem evolução: diz o que falta.
          if (progresso.every((p) => diasDistintos(p.historico) < 2))
            Padding(
              padding: const EdgeInsets.only(top: TokensStrip.s2),
              child: Text(
                ptS.evolucaoForcaProximo,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ),
          const SizedBox(height: TokensStrip.s4),
          ...widget.depois,
        ],
      ),
    );
  }
}

/// Dias diferentes com registro: dois no mesmo dia não são evolução.
int diasDistintos(List<RecordePessoal> historico) =>
    {for (final r in historico) r.data.length >= 10 ? r.data.substring(0, 10) : r.data}
        .length;

/// Série do exercício: a maior carga de cada dia, do mais antigo ao mais novo.
List<PontoGrafico> serieDoExercicio(ProgressoRecorde p) => umPorDia([
  for (final r in p.historico.reversed)
    if (r.cargaKg != null && DateTime.tryParse(r.data) != null)
      PontoGrafico(DateTime.parse(r.data), r.cargaKg!),
], maior: true);

class _BlocoDoExercicio extends StatelessWidget {
  const _BlocoDoExercicio({required this.progresso, required this.onVerRegistros});

  final ProgressoRecorde progresso;
  final VoidCallback onVerRegistros;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final pontos = serieDoExercicio(progresso);
    final melhor = progresso.melhor;
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  progresso.nome,
                  style: FocuxHubTypography.cardTitle(color: chrome.ink),
                ),
              ),
              if (melhor.cargaKg case final kg?)
                Text(
                  formatBrComUnidade(kg, 'kg'),
                  style: FocuxHubTypography.cardTitle(color: chrome.ink)
                      .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          if (pontos.length >= evolucaoPontosParaGrafico)
            RepaintBoundary(
              child: FxGraficoLinha(
                pontos: pontos,
                unidade: 'kg',
                altura: 160,
                resumo: progresso.nome,
              ),
            )
          else if (DateTime.tryParse(melhor.data) case final data?)
            // Um dia só não é série: valor e data, sem gráfico.
            Text(
              ptS.evolucaoRegistradoEm(dataCurta(data)),
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          const SizedBox(height: TokensStrip.s2),
          FxLinkRow(
            label: ptS.evolucaoVerRegistros,
            icon: FxIcons.historico,
            onTap: onVerRegistros,
          ),
        ],
      ),
    );
  }
}

/// Uma linha por exercício: melhor marca e, com 2 dias ou mais, o ganho.
class _LinhaDoExercicio extends StatelessWidget {
  const _LinhaDoExercicio({
    required this.progresso,
    required this.selecionada,
    required this.onTap,
  });

  final ProgressoRecorde progresso;
  final bool selecionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final melhor = progresso.melhor;
    final estimado = umRmEstimado(melhor);
    final marca = [
      evolucaoRecordeSubtitle(melhor),
      if (estimado != null) ptS.evolucaoRmEstimado(formatBrComUnidade(estimado, 'kg')),
    ].join(' · ');
    final evoluiu = diasDistintos(progresso.historico) >= 2;
    final ganho =
        evoluiu
            ? ptS.evolucaoGanhoDesdeInicio(diferencaTexto(progresso.ganhoKg, 'kg'))
            : null;
    return Semantics(
      button: true,
      selected: selecionada,
      label: [
        progresso.nome,
        ptS.evolucaoMelhorMarca(marca),
        if (ganho != null) ganho,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TokensStrip.s3),
          color: selecionada ? primary.withValues(alpha: 0.07) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                progresso.nome,
                style: FocuxHubTypography.cardTitle(
                  color: selecionada ? primary : chrome.ink,
                ),
              ),
              Text(
                ptS.evolucaoMelhorMarca(marca),
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              if (ganho != null)
                Text(
                  ganho,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// No mesmo dia vale a maior carga (o gráfico tem um ponto por dia): os
/// outros registros do dia não entram.
Set<int> registrosForaDoGrafico(List<RecordePessoal> historico) {
  String dia(String d) => d.length >= 10 ? d.substring(0, 10) : d;
  final maiorDoDia = <String, RecordePessoal>{};
  for (final r in historico) {
    final atual = maiorDoDia[dia(r.data)];
    if (atual == null || (r.cargaKg ?? 0) > (atual.cargaKg ?? 0)) {
      maiorDoDia[dia(r.data)] = r;
    }
  }
  return {
    for (final r in historico)
      if (!identical(maiorDoDia[dia(r.data)], r)) r.id,
  };
}

/// "20,0 kg × 10 reps", ou só a carga.
String evolucaoCargaDoRegistro(RecordePessoal r) {
  final carga = r.cargaKg == null ? '—' : formatBrComUnidade(r.cargaKg!, 'kg');
  return r.repeticoes == null ? carga : ptS.evolucaoCargaXReps(carga, r.repeticoes!);
}

/// Registros do exercício no mesmo padrão do Histórico do Corpo: um cartão por
/// mês, a data como título, carga e repetições embaixo, "Recorde" só no melhor.
/// Para o personal, o toque abre editar/excluir e o rodapé tem "Registrar
/// carga" com o exercício já escolhido.
Future<void> abrirRegistrosDoExercicio(
  BuildContext context,
  ProgressoRecorde progresso, {
  ValueChanged<RecordePessoal>? onEditar,
  ValueChanged<RecordePessoal>? onExcluir,
  ValueChanged<ExercicioEscolhido>? onRegistrar,
}) {
  Future<void> acoes(BuildContext ctx, RecordePessoal r) async {
    final escolha = await showFxGroupedActionSheet<String>(
      ctx,
      titulo: progresso.nome,
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'editar',
            rotulo: ptS.evolucaoRecordeEditar,
            icone: FxIcons.editar,
          ),
          FxActionItem(
            valor: 'excluir',
            rotulo: ptS.evolucaoRecordeExcluir,
            icone: FxIcons.excluir,
            perigo: true,
          ),
        ]),
      ],
    );
    if (!ctx.mounted || escolha == null) return;
    Navigator.pop(ctx);
    if (escolha == 'editar') {
      onEditar?.call(r);
    } else {
      onExcluir?.call(r);
    }
  }

  return showFxHomeSheet<void>(
    context,
    builder:
        (ctx) => _FolhaDeRegistros(
          progresso: progresso,
          onTocar: onEditar == null ? null : (r) => acoes(ctx, r),
          onRegistrar:
              onRegistrar == null
                  ? null
                  : () {
                    Navigator.pop(ctx);
                    final id = progresso.melhor.exercicioId;
                    onRegistrar((id: id == 0 ? null : id, nome: progresso.nome));
                  },
        ),
  );
}

class _FolhaDeRegistros extends StatelessWidget {
  const _FolhaDeRegistros({
    required this.progresso,
    this.onTocar,
    this.onRegistrar,
  });

  final ProgressoRecorde progresso;
  final ValueChanged<RecordePessoal>? onTocar;
  final VoidCallback? onRegistrar;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final fora = registrosForaDoGrafico(progresso.historico);
    final porMes = <String, List<RecordePessoal>>{};
    for (final r in progresso.historico) {
      final d = DateTime.tryParse(r.data);
      porMes.putIfAbsent(d == null ? r.data : evolucaoMesAno(d), () => []).add(r);
    }
    final melhor = progresso.melhor.cargaKg;
    return FxHomeSheetSurface(
      isDark: chrome.isDark,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.maxHeightFactor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: chrome.isDark),
          const SizedBox(height: TokensStrip.s3),
          FxHomeSheetHeader(
            isDark: chrome.isDark,
            title: progresso.nome,
            subtitle:
                melhor == null
                    ? null
                    : ptS.evolucaoRegistrosResumo(
                      progresso.historico.length,
                      formatBrComUnidade(melhor, 'kg'),
                    ),
          ),
          const SizedBox(height: TokensStrip.s2),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final MapEntry(key: mes, value: doMes) in porMes.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                      top: TokensStrip.s2,
                      bottom: TokensStrip.s1,
                    ),
                    child: Text(mes, style: FocuxHubTypography.chip(chrome.mute)),
                  ),
                  Container(
                    decoration: fxListCardDecoration(context),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (i, r) in doMes.indexed) ...[
                          if (i > 0) Divider(height: 1, color: chrome.line),
                          _LinhaDoRegistro(
                            registro: r,
                            recorde: identical(r, progresso.melhor),
                            foraDoGrafico: fora.contains(r.id),
                            onTap: onTocar == null ? null : () => onTocar!(r),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRegistrar != null) ...[
            const SizedBox(height: TokensStrip.s3),
            FxTonalButton(
              label: ptS.evolucaoRegistrarCarga,
              icon: FxIcons.adicionar,
              expanded: true,
              onPressed: onRegistrar,
            ),
          ],
        ],
      ),
    );
  }
}

class _LinhaDoRegistro extends StatelessWidget {
  const _LinhaDoRegistro({
    required this.registro,
    required this.recorde,
    required this.foraDoGrafico,
    this.onTap,
  });

  final RecordePessoal registro;
  final bool recorde;
  final bool foraDoGrafico;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final d = DateTime.tryParse(registro.data);
    final data = d == null ? registro.data : dataCurta(d);
    final carga = evolucaoCargaDoRegistro(registro);
    return Semantics(
      button: onTap != null,
      label: [
        data,
        carga,
        if (recorde) ptS.evolucaoRecordeEtiqueta,
        if (foraDoGrafico) ptS.evolucaoNaoEntraNoGrafico,
      ].join(', '),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data, style: FocuxHubTypography.cardTitle(color: chrome.ink)),
                    Text(
                      carga,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                    if (foraDoGrafico)
                      Text(
                        ptS.evolucaoNaoEntraNoGrafico,
                        style: FocuxHubTypography.chip(chrome.mute),
                      ),
                  ],
                ),
              ),
              if (recorde) FxStatusPill(label: ptS.evolucaoRecordeEtiqueta),
              if (onTap != null) ...[
                const SizedBox(width: TokensStrip.s2),
                Icon(FxIcons.chevronDireita, color: chrome.mute),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
