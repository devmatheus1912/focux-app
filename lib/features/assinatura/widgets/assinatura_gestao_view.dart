import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';

/// Uma linha de consumo: nulo em [limite] é ilimitado.
typedef AssinaturaUso = ({String rotulo, int usado, int? limite});

/// Quem já assina: o plano, o que usa e o que tem. Sem vitrine.
class AssinaturaGestaoView extends StatelessWidget {
  const AssinaturaGestaoView({
    super.key,
    required this.planoNome,
    required this.usos,
    required this.inclusos,
    required this.gerenciarLabel,
    required this.onGerenciar,
    required this.onCancelar,
    this.onRestaurar,
    this.onTermos,
    this.superiorNome,
    this.onSuperior,
  });

  final String planoNome;
  final List<AssinaturaUso> usos;
  final List<String> inclusos;
  final String gerenciarLabel;
  final VoidCallback? onGerenciar;
  final VoidCallback onCancelar;
  final VoidCallback? onRestaurar;
  final VoidCallback? onTermos;

  /// Plano acima, quando existe.
  final String? superiorNome;
  final VoidCallback? onSuperior;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;

    Widget grupo(String titulo, List<Widget> filhos) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s2),
        Container(
          padding: const EdgeInsets.all(TokensStrip.s3),
          decoration: fxListCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: filhos,
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
      ],
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s2,
        TokensStrip.s4,
        TokensStrip.s5,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(TokensStrip.s3),
          decoration: fxListCardDecoration(context, accent: primary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.assinaturaSeuPlano,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
              const SizedBox(height: 2),
              Text(
                planoNome,
                style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                s.assinaturaAtiva,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        if (usos.isNotEmpty)
          grupo(s.assinaturaSeuUso, [
            for (final (i, uso) in usos.indexed) ...[
              if (i > 0) const SizedBox(height: TokensStrip.s3),
              _UsoLinha(uso: uso),
            ],
          ]),
        if (inclusos.isNotEmpty)
          grupo(s.assinaturaIncluso, [
            for (final item in inclusos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded, size: 18, color: primary),
                    const SizedBox(width: TokensStrip.s2),
                    Expanded(
                      child: Text(
                        item,
                        style: FocuxHubTypography.body(color: chrome.ink),
                      ),
                    ),
                  ],
                ),
              ),
          ]),
        if (onGerenciar != null) ...[
          FxLiquidPrimaryButton(label: gerenciarLabel, onPressed: onGerenciar),
          const SizedBox(height: TokensStrip.s3),
        ],
        if (onSuperior != null && superiorNome != null)
          FxSatelliteListTile(
            title: s.assinaturaConhecer(superiorNome!),
            titleCase: false,
            onTap: onSuperior,
          ),
        if (onRestaurar != null)
          FxSatelliteListTile(
            title: s.assinaturaRestaurar,
            titleCase: false,
            onTap: onRestaurar,
          ),
        if (onTermos != null)
          FxSatelliteListTile(
            title: s.assinaturaTermos,
            titleCase: false,
            onTap: onTermos,
          ),
        FxSatelliteListTile(
          title: s.assinaturaCancelar,
          titleCase: false,
          onTap: onCancelar,
        ),
      ],
    );
  }
}

class _UsoLinha extends StatelessWidget {
  const _UsoLinha({required this.uso});

  final AssinaturaUso uso;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final limite = uso.limite;
    final valor =
        limite == null
            ? s.assinaturaUsoLivre(uso.usado)
            : s.assinaturaUsoDe(uso.usado, limite);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                uso.rotulo,
                style: FocuxHubTypography.body(color: chrome.ink),
              ),
            ),
            Text(
              valor,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
          ],
        ),
        if (limite != null && limite > 0) ...[
          const SizedBox(height: TokensStrip.s1),
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensStrip.s1),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: (uso.usado / limite).clamp(0.0, 1.0),
              color: primary,
              backgroundColor: primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ],
    );
  }
}
