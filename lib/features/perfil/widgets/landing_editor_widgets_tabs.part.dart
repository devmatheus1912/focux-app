part of 'landing_editor_widgets.dart';

class _LandingEditorTabChip extends StatelessWidget {
  const _LandingEditorTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rMd - 2),
          onTap: onTap,
          focusColor: scheme.primary.withValues(alpha: 0.14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(TokensStrip.rMd - 2),
              boxShadow:
                  selected
                      ? [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                      : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color:
                      selected
                          ? Colors.white
                          : scheme.onSurface.withValues(alpha: 0.78),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LandingStickySaveBar extends StatelessWidget {
  const LandingStickySaveBar({
    super.key,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      elevation: 8,
      color: scheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 12 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (dirty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Alterações não salvas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.primary.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            Semantics(
              button: true,
              label:
                  dirty
                      ? 'Salvar alterações pendentes da landing'
                      : 'Salvar landing',
              child: FilledButton(
                onPressed: saving ? null : onSave,
                child:
                    saving
                        ? const FxLoading(size: 22, strokeWidth: 2)
                        : Text(dirty ? 'Salvar alterações' : 'Salvar landing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandingSectionOrderTile extends StatelessWidget {
  const LandingSectionOrderTile({
    super.key,
    required this.index,
    required this.sectionKey,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.canMoveUp,
    required this.canMoveDown,
    this.highlighted = false,
  });

  final int index;
  final String sectionKey;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensStrip.rMd),
        boxShadow:
            highlighted
                ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.28),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
                : null,
      ),
      child: Container(
        key: ValueKey('$sectionKey-$index'),
        decoration: fxListCardDecoration(
          context,
          accent: highlighted ? scheme.primary : null,
          radius: TokensStrip.rMd,
          selected: highlighted,
        ).copyWith(
          color:
              highlighted
                  ? scheme.primaryContainer.withValues(alpha: 0.22)
                  : scheme.surface,
          border: Border.all(
            color:
                highlighted
                    ? scheme.primary.withValues(alpha: 0.75)
                    : scheme.outlineVariant.withValues(alpha: 0.55),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.drag_handle,
                    color: scheme.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landingSectionLabel(sectionKey),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Mover para cima',
                onPressed: canMoveUp ? onMoveUp : null,
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
              IconButton(
                tooltip: 'Mover para baixo',
                onPressed: canMoveDown ? onMoveDown : null,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingReadinessProgressBars extends StatelessWidget {
  const LandingReadinessProgressBars({
    super.key,
    required this.configDone,
    required this.configTotal,
    required this.textsReviewed,
    required this.textsTotal,
    this.contentIssueCount = 0,
  });

  final int configDone;
  final int configTotal;
  final int textsReviewed;
  final int textsTotal;
  final int contentIssueCount;

  @override
  Widget build(BuildContext context) {
    const ready = EagleTokens.good;
    final scheme = Theme.of(context).colorScheme;
    final percent = landingPublicationPercent(
      configDone: configDone,
      configTotal: configTotal,
      textsReviewed: textsReviewed,
      textsTotal: textsTotal,
    );
    final unifiedValue = percent / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProgressRow(
          label: 'Progresso para publicar',
          value: unifiedValue,
          caption: '$percent%',
          color: ready,
          track: scheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _ProgressLegendChip(
              label: 'Setup',
              caption: '$configDone/$configTotal',
              complete: configDone == configTotal,
            ),
            const SizedBox(width: 8),
            _ProgressLegendChip(
              label: 'Textos',
              caption: '$textsReviewed/$textsTotal',
              complete: contentIssueCount == 0 && textsTotal > 0,
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressLegendChip extends StatelessWidget {
  const _ProgressLegendChip({
    required this.label,
    required this.caption,
    required this.complete,
  });

  final String label;
  final String caption;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const ready = EagleTokens.good;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color:
              complete
                  ? ready.withValues(alpha: 0.1)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                complete
                    ? ready.withValues(alpha: 0.35)
                    : scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          children: [
            Icon(
              complete
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              size: 14,
              color:
                  complete ? ready : scheme.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              caption,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color:
                    complete ? ready : scheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.track,
  });

  final String label;
  final double value;
  final String caption;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $caption',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                caption,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(end: value.clamp(0, 1)),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 7,
                  backgroundColor: track.withValues(alpha: 0.85),
                  color: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LandingReviewFocusBanner extends StatelessWidget {
  const LandingReviewFocusBanner({
    super.key,
    required this.pendingCount,
    required this.onExit,
  });

  final int pendingCount;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label:
          pendingCount == 1
              ? 'Modo foco. 1 texto pendente.'
              : 'Modo foco. $pendingCount textos pendentes.',
      child: Material(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.45),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              Icon(
                Icons.center_focus_strong_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  pendingCount == 1
                      ? 'Modo foco · 1 texto pendente'
                      : 'Modo foco · $pendingCount textos pendentes',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(onPressed: onExit, child: const Text('Ver tudo')),
            ],
          ),
        ),
      ),
    );
  }
}

class LandingTemplatesCompactCard extends StatelessWidget {
  const LandingTemplatesCompactCard({
    super.key,
    required this.templates,
    required this.nicheCount,
    required this.applying,
    required this.onApplyTemplate,
    required this.onBrowseTemplates,
  });

  final List<LandingCompleteTemplate> templates;
  final int nicheCount;
  final bool applying;
  final ValueChanged<LandingCompleteTemplate> onApplyTemplate;
  final VoidCallback onBrowseTemplates;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final defaultTemplate = templates.isNotEmpty ? templates.first : null;

    return FxSatellitePanel(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      radius: TokensStrip.rLg,
      accent: scheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_fix_high_outlined,
                  color: scheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modelos prontos',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '8 seções · padrão Focux'
                      '${nicheCount > 0 ? ' + $nicheCount nichos' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (defaultTemplate != null)
            OutlinedButton.icon(
              onPressed:
                  applying ? null : () => onApplyTemplate(defaultTemplate),
              icon:
                  applying
                      ? const FxLoading(size: 16, strokeWidth: 2)
                      : const Icon(Icons.auto_fix_high_outlined, size: 18),
              label: Text('Aplicar ${defaultTemplate.label}'),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onBrowseTemplates,
            icon: const Icon(Icons.view_agenda_outlined, size: 18),
            label: Text(
              nicheCount > 0
                  ? 'Ver catálogo e modelos por nicho'
                  : 'Ver catálogo completo',
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showLandingTemplatesSheet(
  BuildContext context, {
  required List<String> sectionOrder,
  required List<LandingCompleteTemplate> templates,
  required bool applying,
  required ValueChanged<LandingCompleteTemplate> onApplyTemplate,
}) {
  HapticFeedback.lightImpact();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar catálogo de modelos',
    barrierColor: Colors.black.withValues(alpha: 0.45),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, _, __) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: _LandingTemplatesSheet(
          sectionOrder: sectionOrder,
          templates: templates,
          applying: applying,
          onApplyTemplate: (template) {
            Navigator.pop(ctx);
            onApplyTemplate(template);
          },
          onClose: () => Navigator.pop(ctx),
        ),
      );
    },
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.12),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
