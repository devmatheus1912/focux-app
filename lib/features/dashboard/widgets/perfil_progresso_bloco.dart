import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_sparkline.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../evolucao/data/evolucao_repository.dart';

String _num(double v) => formatBrDecimal(v).replaceFirst(RegExp(r',0$'), '');

String _dataCurta(String bruta) {
  final data = DateTime.tryParse(bruta);
  if (data == null) return bruta;
  return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
}

/// "-3,5" ou "+2". Sem cor: perder ou ganhar depende do objetivo.
String? diferencaDaMedida(double atual, double inicial) {
  final d = atual - inicial;
  if (d == 0) return null;
  return '${d > 0 ? '+' : '−'}${_num(d.abs())}';
}

/// Atual, primeira e os valores da mais antiga para a mais nova. Nulo sem dado.
({double atual, double inicial, String dataInicial, List<double> serie})?
serieDaMedida(List<MedidaCorporal> medidas, double? Function(MedidaCorporal) valor) {
  final comDado = [
    for (final m in medidas)
      if (valor(m) != null) m,
  ];
  if (comDado.isEmpty) return null;
  return (
    atual: valor(comDado.first)!,
    inicial: valor(comDado.last)!,
    dataInicial: _dataCurta(comDado.last.data),
    serie: [for (final m in comDado.reversed) valor(m)!],
  );
}

/// Progresso no Perfil: o peso em destaque, medidas em colunas e fotos em faixa.
/// [medidas] vem da mais nova para a mais antiga.
class PerfilProgressoBloco extends StatelessWidget {
  const PerfilProgressoBloco({super.key, required this.medidas});

  final List<MedidaCorporal> medidas;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final peso = serieDaMedida(medidas, (m) => m.peso);
    final diferenca =
        peso == null ? null : diferencaDaMedida(peso.atual, peso.inicial);
    final colunas = [
      (s.progressoCintura, serieDaMedida(medidas, (m) => m.cintura)),
      (s.progressoQuadril, serieDaMedida(medidas, (m) => m.quadril)),
      (s.progressoBraco, serieDaMedida(medidas, (m) => m.braco)),
    ].where((c) => c.$2 != null).toList();
    final fotos = medidas.where((m) => m.fotoUrl?.isNotEmpty == true).toList();
    final temDado = peso != null || colunas.isNotEmpty || fotos.isNotEmpty;

    return FxSettingsGroup(
      header: s.alunoPerfilGrupoProgresso,
      children: [
        Padding(
          padding: const EdgeInsets.all(FxSettingsLayout.groupPadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!temDado)
                Text(
                  s.progressoSemMedida,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              if (peso != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.progressoKg(_num(peso.atual)),
                            style: FocuxHubTypography.metric(
                              color: chrome.ink,
                              fontSize: FocuxHubTypography.metricLg,
                            ),
                          ),
                          if (diferenca != null)
                            Text(
                              s.progressoDesde(
                                s.progressoKg(diferenca),
                                peso.dataInicial,
                              ),
                              style: FocuxHubTypography.bodyMuted(
                                color: chrome.mute,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (peso.serie.length >= 3)
                      FxSparkline(
                        data: peso.serie,
                        color: primary,
                        width: 120,
                        height: 44,
                      ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s3),
              ],
              if (colunas.isNotEmpty) ...[
                Row(
                  children: [
                    for (final (rotulo, serie) in colunas)
                      Expanded(
                        child: _ColunaMedida(
                          rotulo: rotulo,
                          valor: s.progressoCm(_num(serie!.atual)),
                          diferenca: diferencaDaMedida(
                            serie.atual,
                            serie.inicial,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: TokensStrip.s3),
              ],
              if (fotos.isNotEmpty) ...[
                SizedBox(
                  height: 116,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotos.length,
                    separatorBuilder:
                        (_, __) => const SizedBox(width: TokensStrip.s2),
                    itemBuilder: (_, i) => _Miniatura(medida: fotos[i]),
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
              ],
              Row(
                children: [
                  Expanded(
                    child: FxTonalButton(
                      label: s.alunoPerfilRegistrarMedida,
                      icon: Icons.add_chart,
                      expanded: true,
                      onPressed:
                          () => context.push('/aluno/perfil/editar?acao=medida'),
                    ),
                  ),
                  if (temDado) ...[
                    const SizedBox(width: TokensStrip.s2),
                    FxTonalButton(
                      label: s.progressoVerHistorico,
                      onPressed: () => context.push('/evolucao'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColunaMedida extends StatelessWidget {
  const _ColunaMedida({
    required this.rotulo,
    required this.valor,
    required this.diferenca,
  });

  final String rotulo;
  final String valor;
  final String? diferenca;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: FocuxHubTypography.chip(chrome.mute)),
        Text(valor, style: FocuxHubTypography.cardTitle(color: chrome.ink)),
        if (diferenca != null)
          Text(
            diferenca!,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
      ],
    );
  }
}

class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.medida});

  final MedidaCorporal medida;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final url = medida.fotoUrl!;
    return Semantics(
      button: true,
      label: S.of(context).alunoPerfilVerFoto,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        onTap:
            () => showDialog<void>(
              context: context,
              builder:
                  (ctx) => GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Center(
                      child: FxCachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
            ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(TokensStrip.rSm),
              child: FxCachedNetworkImage(
                imageUrl: url,
                width: 72,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _dataCurta(medida.data),
              style: FocuxHubTypography.chip(chrome.mute),
            ),
          ],
        ),
      ),
    );
  }
}
