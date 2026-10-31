import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_status_pill.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../ia/widgets/ia_uso_linha.dart';

/// Uma linha de consumo: nulo em [limite] é ilimitado.
typedef AssinaturaUso = ({String rotulo, int usado, int? limite});

/// Quem já assina: o plano, o que usa e o que tem. Sem vitrine.
/// `planoValidoAte` pode somar bônus de indicação, então não é a data da cobrança.
String? assinaturaAcessoAte(DateTime? data) {
  if (data == null) return null;
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(data.day)}/${dois(data.month)}/${data.year}';
}

class AssinaturaGestaoView extends StatefulWidget {
  const AssinaturaGestaoView({
    super.key,
    required this.planoNome,
    this.validoAte,
    required this.usos,
    this.iaUsada = 0,
    this.iaLimite = 0,
    required this.inclusos,
    required this.gerenciarLabel,
    required this.onGerenciar,
    required this.onCancelar,
    this.onRestaurar,
    this.onTermos,
    this.superiorNome,
    this.onSuperior,
  });

  /// Inclusos à vista antes de "Ver tudo".
  static const inclusosVisiveis = 4;

  final String planoNome;
  final DateTime? validoAte;
  final List<AssinaturaUso> usos;
  final int iaUsada;
  final int iaLimite;
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
  State<AssinaturaGestaoView> createState() => _AssinaturaGestaoViewState();
}

class _AssinaturaGestaoViewState extends State<AssinaturaGestaoView> {
  var _verTudo = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final usos = widget.usos;
    final temIa = widget.iaLimite > 0;
    final inclusos = widget.inclusos;
    final cabeTudo = inclusos.length <= AssinaturaGestaoView.inclusosVisiveis;
    final visiveis =
        _verTudo || cabeTudo
            ? inclusos
            : inclusos.take(AssinaturaGestaoView.inclusosVisiveis);

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
        FxStripCard(
          emphasize: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.assinaturaSeuPlano,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ),
                  FxStatusPill(
                    label: s.assinaturaAtiva,
                    tone: FxPillTone.success,
                  ),
                ],
              ),
              const SizedBox(height: TokensStrip.s1),
              Text(
                widget.planoNome,
                style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
              ),
              if (assinaturaAcessoAte(widget.validoAte) case final data?) ...[
                const SizedBox(height: TokensStrip.s1),
                Text(
                  s.assinaturaAcessoAte(data),
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        if (usos.isNotEmpty || temIa)
          grupo(s.assinaturaSeuUso, [
            for (final (i, uso) in usos.indexed) ...[
              if (i > 0) const SizedBox(height: TokensStrip.s3),
              _UsoLinha(uso: uso),
            ],
            if (temIa) ...[
              if (usos.isNotEmpty) const SizedBox(height: TokensStrip.s3),
              IaUsoLinha(usado: widget.iaUsada, limite: widget.iaLimite),
            ],
          ]),
        if (inclusos.isNotEmpty)
          grupo(s.assinaturaIncluso, [
            for (final item in visiveis)
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
            if (!cabeTudo) ...[
              const SizedBox(height: TokensStrip.s1),
              Align(
                alignment: Alignment.centerLeft,
                child: FxActionLink(
                  label: _verTudo ? s.assinaturaVerMenos : s.assinaturaVerTudo,
                  onTap: () => setState(() => _verTudo = !_verTudo),
                ),
              ),
            ],
          ]),
        if (widget.onSuperior != null && widget.superiorNome != null)
          FxSatelliteListTile(
            title: s.assinaturaConhecer(widget.superiorNome!),
            titleCase: false,
            onTap: widget.onSuperior,
          ),
        if (widget.onGerenciar != null)
          FxSatelliteListTile(
            title: widget.gerenciarLabel,
            titleCase: false,
            onTap: widget.onGerenciar,
          ),
        if (widget.onRestaurar != null)
          FxSatelliteListTile(
            title: s.assinaturaRestaurar,
            titleCase: false,
            onTap: widget.onRestaurar,
          ),
        if (widget.onTermos != null)
          FxSatelliteListTile(
            title: s.assinaturaTermos,
            titleCase: false,
            onTap: widget.onTermos,
          ),
        FxSatelliteListTile(
          title: s.assinaturaCancelar,
          titleCase: false,
          onTap: widget.onCancelar,
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
