import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../health/data/health_repository.dart';
import '../copilot_insight_text.dart';

class IaCopilotInsightItem extends StatefulWidget {
  const IaCopilotInsightItem({
    super.key,
    required this.index,
    required this.insight,
    required this.isLast,
    required this.highlighted,
    required this.line,
    required this.primarySoft,
    required this.brand,
    required this.ink,
    required this.mute,
    required this.chipBg,
  });

  final int index;
  final Map<String, dynamic> insight;
  final bool isLast;
  final bool highlighted;
  final Color line;
  final Color primarySoft;
  final Color brand;
  final Color ink;
  final Color mute;
  final Color chipBg;

  @override
  State<IaCopilotInsightItem> createState() => _IaCopilotInsightItemState();
}

class _IaCopilotInsightItemState extends State<IaCopilotInsightItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final titulo = copilotInsightTitulo(widget.insight, widget.index);
    final detalhe = copilotInsightDetalhe(widget.insight);
    final tipo = copilotInsightTipo(widget.insight);

    return Semantics(
      button: detalhe.length > 150,
      label: '$titulo. $tipo. $detalhe',
      child: InkWell(
        onTap:
            detalhe.length > 150
                ? () => setState(() => _expanded = !_expanded)
                : null,
        child: Container(
          margin:
              widget.highlighted
                  ? const EdgeInsets.fromLTRB(10, 10, 10, 8)
                  : EdgeInsets.zero,
          padding:
              widget.highlighted
                  ? const EdgeInsets.all(14)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color:
                widget.highlighted
                    ? widget.primarySoft.withValues(alpha: 0.38)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.highlighted ? 16 : 0),
            border:
                widget.highlighted
                    ? Border.all(color: widget.brand.withValues(alpha: 0.18))
                    : Border(
                      bottom:
                          widget.isLast
                              ? BorderSide.none
                              : BorderSide(color: widget.line, width: 0.5),
                    ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: widget.highlighted ? 38 : 30,
                height: widget.highlighted ? 38 : 30,
                decoration: BoxDecoration(
                  color:
                      widget.highlighted
                          ? widget.brand.withValues(alpha: 0.12)
                          : widget.primarySoft,
                  borderRadius: BorderRadius.circular(
                    widget.highlighted ? 12 : 9,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      color: widget.brand,
                      fontSize: widget.highlighted ? 13 : 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.highlighted) ...[
                                Text(
                                  'Mais importante',
                                  style: TextStyle(
                                    color: widget.brand,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                                const SizedBox(height: 3),
                              ],
                              Text(
                                titulo,
                                style: TextStyle(
                                  color: widget.ink,
                                  fontSize: widget.highlighted ? 14 : 13,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (tipo.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IaCopilotTinyTypeChip(
                            label: tipo,
                            color: widget.mute,
                            background: widget.chipBg,
                          ),
                        ],
                      ],
                    ),
                    if (detalhe.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        detalhe,
                        maxLines:
                            _expanded ? null : (widget.highlighted ? 4 : 2),
                        overflow:
                            _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.mute,
                          fontSize: widget.highlighted ? 12.7 : 12.2,
                          height: widget.highlighted ? 1.42 : 1.34,
                        ),
                      ),
                      if (detalhe.length > 150) ...[
                        const SizedBox(height: 7),
                        Text(
                          _expanded ? 'Ver menos' : 'Ver detalhe',
                          style: TextStyle(
                            color: widget.brand,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
    final dark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final soft = BrandPalette.soft(primary, dark: dark);
    final visibleChecks = checks.take(2).toList();

    return Container(
      padding: const EdgeInsets.all(TokensStrip.s4),
      decoration: chrome.panel(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: TextStyle(
                        color: ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alunoNome == null
                          ? 'Escolha um aluno para analisar.'
                          : 'Personalizado para $alunoNome.',
                      style: TextStyle(
                        color: mute,
                        fontSize: 11.8,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: primary.withValues(alpha: 0.14)),
                ),
                child: Text(
                  'Revisável',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            promise,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: mute, fontSize: 12.4, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final check in visibleChecks)
                IaCopilotPill(
                  icon: Icons.check_rounded,
                  label: check,
                  ink: ink,
                  mute: mute,
                  line: line,
                  soft: soft,
                  brand: primary,
                ),
              if (recoveryAsync != null)
                recoveryAsync!.when(
                  loading:
                      () => IaCopilotPill(
                        icon: Icons.watch_outlined,
                        label: 'Sync wearable...',
                        ink: ink,
                        mute: mute,
                        line: line,
                        soft: soft,
                        brand: primary,
                      ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (snapshot) {
                    if (snapshot == null) {
                      return IaCopilotPill(
                        icon: Icons.watch_off_outlined,
                        label: 'Sem wearable',
                        ink: ink,
                        mute: mute,
                        line: line,
                        soft: soft,
                        brand: primary,
                      );
                    }
                    return IaCopilotPill(
                      icon: Icons.favorite_outline,
                      label: '${snapshot.recoveryScore}% prontidao',
                      ink: ink,
                      mute: mute,
                      line: line,
                      soft: soft,
                      brand: primary,
                    );
                  },
                ),
              IaCopilotPill(
                icon: Icons.manage_search_outlined,
                label: 'Análise IA',
                ink: ink,
                mute: mute,
                line: line,
                soft: soft,
                brand: primary,
              ),
            ],
          ),
        ],
      ),
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
