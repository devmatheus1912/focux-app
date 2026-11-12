import 'package:flutter/material.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/focux_hub_typography.dart';

import '../../../core/money/fx_money.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_metric_strip.dart';
import '../../../core/widgets/fx_tap_row.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/data/setup_steps_catalog.dart';
import '../constants/dashboard_layout.dart';
import 'dashboard_section_header.dart';
import '../../../core/theme/fx_icons.dart';

/// "A base": três números, cada um leva à lista que o explica.
class HojeBaseSecao extends StatelessWidget {
  const HojeBaseSecao({
    super.key,
    required this.treinaramHoje,
    required this.emRisco,
    required this.fichasAVencer,
    this.rotaDasFichas = '/alunos',
  });

  final int treinaramHoje;
  final int emRisco;
  final int fichasAVencer;

  /// Com uma ficha só, vai direto a ela; com várias, à lista de alunos.
  final String rotaDasFichas;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(title: s.hojeSecaoBase),
          const SizedBox(height: TokensStrip.s2),
          // Zero não aparece (mesma regra do "Agora"); "Treinaram hoje" fica:
          // é o pulso do dia.
          FxMetricStrip(
            metricas: [
              FxMetric(
                valor: treinaramHoje,
                rotulo: s.hojeTreinaramHoje,
                onTap: () => openPersonalRoute(context, '/checkin'),
              ),
              if (emRisco > 0)
                FxMetric(
                  valor: emRisco,
                  rotulo: s.hojeEmRisco,
                  alerta: true,
                  onTap:
                      () => openPersonalRoute(context, '/alunos?filtro=risco'),
                ),
              if (fichasAVencer > 0)
                FxMetric(
                  valor: fichasAVencer,
                  rotulo: s.hojeFichasAVencer,
                  alerta: true,
                  onTap: () => openPersonalRoute(context, rotaDasFichas),
                ),
            ],
          ),
          if (emRisco == 0 && fichasAVencer == 0) ...[
            const SizedBox(height: TokensStrip.s2),
            Text(
              'Ninguém em risco, nenhuma ficha vencendo.',
              style: FocuxHubTypography.bodyMuted(
                color: ShellChrome.of(context).mute,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "Dinheiro": o que entrou no mês e quantos estão em atraso. Zero some.
class HojeDinheiroLinha extends StatelessWidget {
  const HojeDinheiroLinha({
    super.key,
    required this.mes,
    required this.recebido,
    required this.emAtraso,
  });

  final String mes;
  final FxMoney recebido;
  final int emAtraso;

  /// Sem receita e sem atraso não há o que dizer: a linha não aparece.
  bool get visivel => recebido.isPositive || emAtraso > 0;

  @override
  Widget build(BuildContext context) {
    if (!visivel) return const SizedBox.shrink();
    final s = S.of(context);
    final partes = [
      if (recebido.isPositive)
        '${s.hojeRecebidoEm(mes.toLowerCase())} ${recebido.formatCompact()}',
      if (emAtraso > 0) s.hojeEmAtraso(emAtraso),
    ];
    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(title: s.hojeSecaoDinheiro),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          FxTapRow(
            title: partes.join(' · '),
            leading: const Icon(FxIcons.carteira),
            onTap: () => openPersonalRoute(context, '/financeiro'),
          ),
        ],
      ),
    );
  }
}

/// Próximo passo do onboarding, para quem ainda não tem aluno.
class HojeProximoPasso extends StatelessWidget {
  const HojeProximoPasso({super.key, required this.passo});

  final SetupStepCatalogEntry passo;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: DashboardLayout.foldCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardSectionHeader(title: s.hojeProximoPasso),
          const SizedBox(height: FxSettingsLayout.headerToGroup),
          FxTapRow(
            title: passo.title,
            subtitle: passo.description,
            onTap: () => openPersonalRoute(context, passo.actionRoute),
          ),
        ],
      ),
    );
  }
}

/// Porta para a tela Ferramentas (substitui o catálogo em sheet).
class HojeFerramentasLinha extends StatelessWidget {
  const HojeFerramentasLinha({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Padding(
      padding: DashboardLayout.foldCard,
      child: FxTapRow(
        title: s.hojeFerramentas,
        subtitle: s.hojeFerramentasSub,
        leading: const Icon(FxIcons.apps),
        onTap: () => openPersonalRoute(context, '/ferramentas'),
      ),
    );
  }
}
