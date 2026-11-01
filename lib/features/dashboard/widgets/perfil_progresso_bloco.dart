import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/pt_br_display.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../evolucao/utils/evolucao_series.dart';

String _num(double v) => formatBrDecimal(v).replaceFirst(RegExp(r',0$'), '');

/// Resumo do progresso: peso e três medidas em colunas iguais. O detalhe mora em
/// Meu progresso.
class PerfilProgressoBloco extends StatelessWidget {
  const PerfilProgressoBloco({super.key, required this.medidas});

  final List<MedidaCorporal> medidas;

  void _abrirProgresso(BuildContext context) =>
      context.push('/aluno/progresso');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final pesos = serieDaMetrica(medidas, EvolucaoMetrica.peso);
    final temMedida = medidasEmOrdem(medidas).isNotEmpty;
    return FxSettingsGroup(
      header: s.alunoPerfilGrupoProgresso,
      children: [
        Padding(
          padding: const EdgeInsets.all(FxSettingsLayout.groupPadH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!temMedida)
                Text(
                  s.progressoSemMedida,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                )
              else ...[
                Semantics(
                  button: true,
                  label: s.progressoVerTudo,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TokensStrip.rSm),
                    onTap: () => _abrirProgresso(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.evolucaoPesoAtual,
                                style: FocuxHubTypography.chip(chrome.mute),
                              ),
                            ),
                            Text(
                              s.progressoVerTudo,
                              style: FocuxHubTypography.chip(chrome.mute),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: chrome.mute,
                            ),
                          ],
                        ),
                        Text(
                          pesos.isEmpty
                              ? '—'
                              : s.progressoKg(_num(pesos.last.valor)),
                          style: FocuxHubTypography.metric(
                            color: chrome.ink,
                            fontSize: FocuxHubTypography.metricLg,
                          ),
                        ),
                        if (pesos.length > 1)
                          Text(
                            s.evolucaoDesde(
                              diferencaTexto(
                                pesos.last.valor - pesos.first.valor,
                                'kg',
                              ),
                              dataCurta(pesos.first.data),
                            ),
                            style: FocuxHubTypography.bodyMuted(
                              color: chrome.mute,
                            ),
                          ),
                        const SizedBox(height: TokensStrip.s3),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final metrica in const [
                              EvolucaoMetrica.cintura,
                              EvolucaoMetrica.quadril,
                              EvolucaoMetrica.braco,
                            ])
                              Expanded(
                                child: _ColunaMedida(
                                  metrica: metrica,
                                  serie: serieDaMetrica(medidas, metrica),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: TokensStrip.s3),
              ],
              FxTonalButton(
                label: s.alunoPerfilRegistrarMedida,
                icon: Icons.add_chart,
                expanded: true,
                onPressed:
                    () => context.push('/aluno/perfil/editar?acao=medida'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColunaMedida extends StatelessWidget {
  const _ColunaMedida({required this.metrica, required this.serie});

  final EvolucaoMetrica metrica;
  final dynamic serie;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final vazia = serie.isEmpty as bool;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(metrica.rotulo, style: FocuxHubTypography.chip(chrome.mute)),
        Text(
          vazia ? '—' : '${_num(serie.last.valor as double)} ${metrica.unidade}',
          style: FocuxHubTypography.cardTitle(color: chrome.ink),
        ),
        if (!vazia && (serie.length as int) > 1)
          Text(
            diferencaTexto(
              (serie.last.valor as double) - (serie.first.valor as double),
              metrica.unidade,
            ),
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
      ],
    );
  }
}
