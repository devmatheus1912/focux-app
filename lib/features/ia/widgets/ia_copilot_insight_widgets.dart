import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../../health/data/health_repository.dart';
import '../models/ia_copilot_insight.dart';

class IaCopilotInsightItem extends StatefulWidget {
  const IaCopilotInsightItem({
    super.key,
    required this.index,
    required this.insight,
    required this.highlighted,
    required this.brand,
    required this.mute,
  });

  final int index;
  final IaCopilotInsight insight;
  final bool highlighted;
  final Color brand;
  final Color mute;

  @override
  State<IaCopilotInsightItem> createState() => _IaCopilotInsightItemState();
}

class _IaCopilotInsightItemState extends State<IaCopilotInsightItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final titulo = widget.insight.titulo;
    final detalhe = widget.insight.detalhe;
    final tipo = widget.insight.tipo;

    final shown = _expanded || detalhe.length <= 150
        ? detalhe
        : '${detalhe.substring(0, 150).trim()}…';
    return Semantics(
      button: detalhe.length > 150,
      label: '$titulo. $tipo. $detalhe',
      child: FxSatelliteListTile(
        title: widget.highlighted ? 'Mais importante · $titulo' : titulo,
        subtitle: shown.isEmpty ? null : Text(shown),
        trailing: Text(
          tipo.isNotEmpty ? tipo : '${widget.index + 1}',
          style: TextStyle(
            color: widget.mute,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        accent: widget.highlighted ? widget.brand : null,
        onTap: detalhe.length > 150
            ? () => setState(() => _expanded = !_expanded)
            : null,
      ),
    );
  }
}

class IaCopilotTinyTypeChip extends StatelessWidget {
  const IaCopilotTinyTypeChip({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class IaCopilotReadinessCard extends StatelessWidget {
  const IaCopilotReadinessCard({
    super.key,
    required this.headline,
    required this.modeDisplay,
    required this.icon,
    required this.promise,
    required this.checks,
    required this.alunoNome,
    this.recoveryAsync,
  });

  final String headline;
  final String modeDisplay;
  final IconData icon;
  final String promise;
  final List<String> checks;
  final String? alunoNome;
  final AsyncValue<RecoverySnapshot?>? recoveryAsync;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final mute = chrome.mute;
    final visibleChecks = checks.take(2).toList();
    assert(modeDisplay.isNotEmpty && chrome.ink.a >= 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashboardSectionHeader(title: headline),
        const SizedBox(height: TokensStrip.s2),
        Text(
          promise,
          style: TextStyle(
            color: mute,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: TokensStrip.s3),
        FxSatelliteListTile(
          title: alunoNome == null
              ? 'Escolha um aluno para analisar.'
              : 'Personalizado para $alunoNome.',
          subtitle: visibleChecks.isEmpty
              ? null
              : Text(visibleChecks.join(' · ')),
          trailing: Text(
            'Revisável',
            style: TextStyle(
              color: mute,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: Icon(icon, color: primary, size: 20),
        ),
        if (recoveryAsync != null)
          recoveryAsync!.when(
            loading: () => FxSatelliteListTile(
              title: 'Sync wearable...',
              leading: Icon(Icons.watch_outlined, color: primary, size: 20),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (snapshot) => FxSatelliteListTile(
              title: snapshot == null
                  ? 'Sem wearable'
                  : '${snapshot.recoveryScore}% prontidao',
              trailing: Text(
                'Análise IA',
                style: TextStyle(
                  color: mute,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              leading: Icon(
                snapshot == null
                    ? Icons.watch_off_outlined
                    : Icons.favorite_outline,
                color: primary,
                size: 20,
              ),
            ),
          ),
      ],
    );
  }
}

class IaCopilotInsightsLoading extends StatelessWidget {
  const IaCopilotInsightsLoading({
    super.key,
    required this.ink,
    required this.mute,
    required this.brand,
  });

  final Color ink;
  final Color mute;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final soft = brand.withValues(alpha: 0.10);
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: fxListCardDecoration(context, accent: primary, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.auto_awesome, color: brand, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preparando recomendações',
                      style: TextStyle(
                        color: ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Organizando as recomendações...',
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s4),
          for (final width in const [0.92, 0.74, 0.84])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FractionallySizedBox(
                widthFactor: width,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class IaCopilotPill extends StatelessWidget {
  const IaCopilotPill({
    super.key,
    required this.icon,
    required this.label,
    required this.ink,
    required this.mute,
    required this.line,
    required this.soft,
    required this.brand,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final Color mute;
  final Color line;
  final Color soft;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: brand),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
